# Run from the repository root: Rscript scripts/01_tidy_data.R
# Use only the tidyverse packages needed here, plus readxl for Excel.
required <- c("readxl", "dplyr", "tidyr", "readr", "ggplot2")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install missing packages: ", paste(missing, collapse = ", "))
library(dplyr)
library(tidyr)

input <- "data/Revised_Breeding_&_Survival_LIFEBonelli_EastMed_2025.5.16_for Stavros.xlsx"
sheet <- "New calculations"
dir.create("results", showWarnings = FALSE)

# A1:U12 is the primary table. Lower tables repeat these measurements.
raw <- readxl::read_excel(input, sheet = sheet, range = "A1:U12",
                         col_names = FALSE, col_types = "text",
                         .name_repair = "minimal")
names(raw) <- c("source_variable", paste0("column_", 2:21))

dictionary <- tibble::tibble(
  source_variable = c(
    "N. territories (including unknown & abandoned)",
    "N. of occupied territories (territories with BE present)",
    "N. of egg laying pairs", "N. of successful territorial pairs",
    "N. fledglings", "Breeding success", "Territory success rate",
    "Breeding success / successful pair", "Productivity", "Territory occupacy"
  ),
  variable = c("n_territories", "n_occupied_territories", "n_egg_laying_pairs",
               "n_successful_pairs", "n_fledglings", "breeding_success",
               "territory_success_rate", "breeding_success_per_successful_pair",
               "productivity", "territory_occupancy"),
  unit = c(rep("count", 5), "fledglings per egg-laying pair", "proportion",
           "fledglings per successful pair", "fledglings per occupied territory",
           "proportion")
)

# The year headers are merged in Excel; carry each year to its region columns.
headers <- tibble::tibble(
  column = names(raw)[-1],
  year = as.integer(unlist(raw[1, -1], use.names = FALSE)),
  region = trimws(unlist(raw[2, -1], use.names = FALSE))
) |> fill(year)
stopifnot(identical(headers$year, rep(2019:2023, each = 4)),
          identical(headers$region, rep(c("Crete", "Cyprus", "Aegean",
                                         "Attica - Peloponnese"), 5)))

body <- raw[3:12, ] |> mutate(source_variable = trimws(source_variable))
# Fail visibly if the spreadsheet layout or labels change.
stopifnot(identical(body$source_variable, dictionary$source_variable))
long <- body |>
  mutate(source_row = 3:12) |>
  pivot_longer(starts_with("column_"), names_to = "column", values_to = "raw_value") |>
  left_join(headers, by = "column") |>
  left_join(dictionary, by = "source_variable") |>
  mutate(value = readr::parse_double(raw_value, na = c("", "NA")),
         source_file = basename(input), source_sheet = sheet) |>
  select(year, region, variable, value, unit, source_variable,
         source_file, source_sheet, source_row)
bad <- !is.na(long$value) & (!is.finite(long$value) | long$value < 0)
numeric_cells <- body |> select(-source_variable) |> unlist(use.names = FALSE)
parsed <- readr::parse_double(numeric_cells, na = c("", "NA"))
if (nrow(readr::problems(parsed))) stop("Unexpected nonnumeric data in the main table.")
stopifnot(nrow(long) == 200L, !any(bad),
          !anyDuplicated(long[c("year", "region", "variable")]))
if (any(long$unit == "count" & long$value != floor(long$value), na.rm = TRUE)) {
  stop("Counts must be whole numbers.")
}
if (any(long$unit == "proportion" & long$value > 1, na.rm = TRUE)) {
  stop("Proportions must be between zero and one.")
}

wide <- long |>
  select(year, region, variable, value) |>
  pivot_wider(names_from = variable, values_from = value) |>
  arrange(year, region)
stopifnot(nrow(wide) == 20L)
# Verify reshaping preserves every observation, including missing values.
roundtrip <- wide |>
  pivot_longer(-c(year, region), names_to = "variable", values_to = "value") |>
  arrange(year, region, variable)
expected <- long |> select(year, region, variable, value) |>
  arrange(year, region, variable)
stopifnot(isTRUE(all.equal(roundtrip, expected)))

readr::write_csv(long |> arrange(year, region, variable), "results/data_long.csv")
readr::write_csv(wide, "results/data_wide.csv")
readr::write_csv(dictionary, "results/variable_dictionary.csv")
writeLines(c(paste("Source:", input), paste("Sheet:", sheet), "Range: A1:U12",
             paste("MD5:", unname(tools::md5sum(input))),
             paste("Missing measurements:", sum(is.na(long$value)))),
           "results/input_provenance.txt")
message("Saved 200 long-format rows and 20 wide-format rows in results/.")
