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
  mutate(year = factor(year),
         label = paste(gsub("_", " ", variable), unit, sep = "\n"))
common_theme <- theme_bw(base_size = 10) +
  theme(axis.text.x = element_text(angle = 35, hjust = 1),
        strip.text = element_text(size = 8), legend.position = "bottom")

by_year <- ggplot(plot_data, aes(x = year, y = value)) +
  geom_boxplot(outlier.shape = NA, fill = "grey95") +
  geom_point(aes(colour = region), position = position_jitter(width = 0.1, height = 0, seed = 42),
             size = 1.8) +
  facet_wrap(~label, scales = "free_y", ncol = 2) + common_theme +
  labs(title = "Reproductive measurements by year", x = "Year", y = "Value",
       colour = "Region", caption = "Each box summarises four regional values; points show all observed values.")
by_region <- ggplot(plot_data, aes(x = region, y = value)) +
  geom_boxplot(outlier.shape = NA, fill = "grey95") +
  geom_point(aes(colour = year), position = position_jitter(width = 0.1, height = 0, seed = 42),
             size = 1.8) +
  facet_wrap(~label, scales = "free_y", ncol = 2) + common_theme +
  labs(title = "Reproductive measurements by region", x = "Region", y = "Value",
       colour = "Year", caption = "Each box summarises five annual values; points show all observed values.")
ggsave("figures/boxplots_by_year.png", by_year, width = 13, height = 16, dpi = 180)
ggsave("figures/boxplots_by_region.png", by_region, width = 13, height = 16, dpi = 180)
writeLines(capture.output(sessionInfo()), "results/session_info.txt")
message("Saved four summary tables and two boxplot figures.")
