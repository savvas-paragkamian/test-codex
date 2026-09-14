# Run after 01_tidy_data.R, from the repository root.
library(dplyr)
library(tidyr)
library(ggplot2)

if (!file.exists("results/data_long.csv")) stop("Run scripts/01_tidy_data.R first.")
long <- readr::read_csv("results/data_long.csv", show_col_types = FALSE)
dir.create("figures", showWarnings = FALSE)

# Return NA for empty groups rather than NaN or Inf.
safe_stat <- function(x, fun, ...) {
  x <- x[!is.na(x)]
  if (!length(x)) return(NA_real_)
  fun(x, ...)
}
summarise_values <- function(data, groups) {
  data |>
    group_by(across(all_of(c(groups, "variable", "unit")))) |>
    summarise(
      n_total = n(), n_observed = sum(!is.na(value)), n_missing = sum(is.na(value)),
      mean = safe_stat(value, mean), sd = safe_stat(value, sd),
      median = safe_stat(value, median),
      q1 = safe_stat(value, quantile, probs = 0.25),
      q3 = safe_stat(value, quantile, probs = 0.75),
      min = safe_stat(value, min), max = safe_stat(value, max),
      .groups = "drop"
    )
}
readr::write_csv(summarise_values(long, character()), "results/summary_by_variable.csv")
readr::write_csv(summarise_values(long, "year"), "results/summary_by_year_variable.csv")
readr::write_csv(summarise_values(long, "region"), "results/summary_by_region_variable.csv")
readr::write_csv(summarise_values(long, c("year", "region")),
                 "results/summary_by_year_region_variable.csv")

# Each facet has its own scale because counts and ratios have different units.
plot_data <- long |>
  filter(!is.na(value)) |>
  mutate(label = paste(gsub("_", " ", variable), unit, sep = "\n"))
common_theme <- theme_bw(base_size = 10) +
  theme(axis.text.x = element_text(angle = 35, hjust = 1),
        strip.text = element_text(size = 8), legend.position = "bottom")

# One boxplot builder shared by the year and region views below, so the two
# figures stay in sync instead of drifting apart as separate copies.
make_boxplot <- function(data, x, colour, x_lab, colour_lab, title, caption) {
  ggplot(data, aes(x = .data[[x]], y = value)) +
    geom_boxplot(outlier.shape = NA, fill = "grey95") +
    geom_point(aes(colour = .data[[colour]]),
               position = position_jitter(width = 0.1, height = 0, seed = 42),
               size = 1.8) +
    facet_wrap(~label, scales = "free_y", ncol = 2) + common_theme +
    labs(title = title, x = x_lab, y = "Value", colour = colour_lab, caption = caption)
}

by_year <- make_boxplot(
  plot_data |> mutate(year = factor(year)), "year", "region",
  "Year", "Region", "Reproductive measurements by year",
  "Each box summarises four regional values; points show all observed values."
)
by_region <- make_boxplot(
  plot_data |> mutate(year = factor(year)), "region", "year",
  "Region", "Year", "Reproductive measurements by region",
  "Each box summarises five annual values; points show all observed values."
)
ggsave("figures/boxplots_by_year.png", by_year, width = 13, height = 16, dpi = 180)
ggsave("figures/boxplots_by_region.png", by_region, width = 13, height = 16, dpi = 180)

# Trend lines complement the boxplots above by showing each region's own
# trajectory across years, instead of the year-to-year spread across regions.
trends <- ggplot(plot_data, aes(x = year, y = value, colour = region)) +
  geom_line() +
  geom_point(size = 1.8) +
  scale_x_continuous(breaks = 2019:2023) +
  facet_wrap(~label, scales = "free_y", ncol = 2) + common_theme +
  labs(title = "Reproductive measurements by year, one line per region",
       x = "Year", y = "Value", colour = "Region",
       caption = "Lines connect each region's own annual values; gaps mark missing measurements.")
ggsave("figures/trends_by_region.png", trends, width = 13, height = 16, dpi = 180)

# The five count variables share one unit and form a breeding funnel
# (territories -> occupied -> egg-laying pairs -> successful pairs ->
# fledglings), so their regional means can be compared directly on one plot.
funnel_levels <- c("n_territories", "n_occupied_territories", "n_egg_laying_pairs",
                    "n_successful_pairs", "n_fledglings")
funnel_data <- summarise_values(long, "region") |>
  filter(variable %in% funnel_levels) |>
  mutate(variable = factor(gsub("^n_", "", variable),
                            levels = gsub("^n_", "", funnel_levels)))
funnel <- ggplot(funnel_data, aes(x = variable, y = mean, fill = variable)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~region, ncol = 2) + common_theme +
  labs(title = "Breeding funnel by region, mean count across years",
       x = NULL, y = "Mean count",
       caption = "Bars show the mean of five annual counts per region; error bars are omitted, see summary_by_region_variable.csv for spread.")
ggsave("figures/breeding_funnel_by_region.png", funnel, width = 10, height = 8, dpi = 180)

writeLines(capture.output(sessionInfo()), "results/session_info.txt")
message("Saved four summary tables and four figures.")
