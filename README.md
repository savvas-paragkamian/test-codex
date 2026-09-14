# Bonelli’s eagle reproductive data

A simple R workflow to tidy the supplied Excel workbook, calculate descriptive
statistics, and draw boxplots. The original workbook stays unchanged in `data/`.

## Run

Work from the repository root, the folder containing `scripts/` and `data/`.
Install the required packages once in R:

```r
install.packages(c("readxl", "dplyr", "tidyr", "readr", "ggplot2"))
```

These are the needed tidyverse components plus the Excel reader. Installing the
full tidyverse is unnecessary. Run everything from a terminal:

```sh
Rscript scripts/run_all.R
```

Or from R with the repository root as the working directory:

```r
source("scripts/run_all.R")
```

To run the steps separately:

```sh
Rscript scripts/01_tidy_data.R
Rscript scripts/02_statistics_and_boxplots.R
```

## Source and cleaning

Input: `data/Revised_Breeding_&_Survival_LIFEBonelli_EastMed_2025.5.16_for Stavros.xlsx`,
sheet `New calculations`, range `A1:U12`. The primary table has ten reproductive
variables, five years (2019–2023), and four regions (Crete, Cyprus, Aegean,
Attica - Peloponnese). Despite the filename, this table has no survival observations.

The first row has merged year headers, the second has regions, and rows 3–12
have measurements. The script fills the year headers across their region columns,
trims label whitespace, and uses `pivot_longer()` and `pivot_wider()`. Lower rows
contain definitions and repeated tables; they are excluded to avoid double counting.

Clean variable names use lower-case words separated by underscores. The typo
`Territory occupacy` becomes `territory_occupancy`; source labels are preserved
in the long table and dictionary. Values are retained without rounding or
recalculating ratios. Blank measurements remain `NA`; zero remains zero.
No values are imputed.

Checks stop the workflow on changed headers or labels, unexpected nonnumeric
cells, duplicate observation keys, negative values, fractional counts, or
proportions outside 0–1. A long/wide round-trip check verifies value preservation.
The range and expected dimensions are deliberately specific to this workbook;
update the script and documentation if the workbook layout changes.

## Generated files

Re-running overwrites the workflow’s outputs.

| File | Contents |
| --- | --- |
| `results/data_long.csv` | 200 rows: one year × region × variable, with value, unit, original label and source metadata |
| `results/data_wide.csv` | 20 rows: one year × region, with ten measurement columns |
| `results/variable_dictionary.csv` | Original labels, clean names and units |
| `results/summary_by_variable.csv` | Each variable across all 20 regional annual observations |
| `results/summary_by_year_variable.csv` | Each variable within a year, across four regions |
| `results/summary_by_region_variable.csv` | Each variable within a region, across five years |
| `results/summary_by_year_region_variable.csv` | One observation per year–region–variable group |
| `results/input_provenance.txt` | Source path, sheet, range, MD5 checksum and missing-value count |
| `results/session_info.txt` | R, platform and loaded package versions |
| `figures/boxplots_by_year.png` | Boxplots across regions within each year, faceted by variable |
| `figures/boxplots_by_region.png` | Boxplots across years within each region, faceted by variable |

Summaries include total, observed and missing counts, mean, sample standard
deviation, median, first and third quartiles, minimum and maximum. Missing values
are excluded from calculations; empty groups return `NA`. Standard deviation is
`NA` for a single observation. Quartiles use R’s default method (type 7).
CSV missing values are written as `NA`.

## Interpretation

Counts describe territories, pairs and fledglings. Ratio meanings follow the workbook:

| Variable | Meaning |
| --- | --- |
| `breeding_success` | Fledglings per egg-laying pair |
| `territory_success_rate` | Successful pairs divided by occupied territories |
| `breeding_success_per_successful_pair` | Fledglings per successful pair |
| `productivity` | Fledglings per occupied territory |
| `territory_occupancy` | Occupied territories divided by all territories |

The workbook’s occupancy definition uses “active” territories while its main
table labels the count “occupied” territories. Ratios are preserved as supplied.
Fledglings-per-pair and productivity values may exceed one; occupancy and
territory success are proportions between zero and one.

Each facet has its own vertical scale and unit. Points show every observed value
with deterministic horizontal jitter (seed 42). Boxes show the median and
interquartile range; whiskers reach the most extreme values within 1.5
interquartile ranges. Outliers appear as points without duplicate symbols.

There is one measurement per year–region–variable, so boxplots within that exact
combination would not describe variation. Year boxes summarise four regions;
region boxes summarise five years. These are small samples of regional annual
aggregates, with repeated observations of the same regions and unequal territory
counts. Means weight each regional or annual value equally and are not pooled
demographic rates. No significance tests or causal claims are made.

For reproduction elsewhere, retain the workbook and scripts, compare the input
checksum, and use `session_info.txt` to match package versions. Versions are
recorded, not automatically pinned or installed by the scripts.
