# Repository instructions

Keep this R workflow simple and readable for a biodiversity researcher learning R.

- Run commands from the repository root.
- Keep original workbooks in `data/` unchanged. Never alter measurements to pass checks.
- Use `scripts/01_tidy_data.R` for import and tidying,
  `scripts/02_statistics_and_boxplots.R` for analysis, and `scripts/run_all.R`
  as the entry point.
- Prefer the existing dependencies: readxl, dplyr, tidyr, readr and ggplot2.
  Avoid new packages and automatic installation for simple operations.
- The long-data key is year, region and variable. Preserve source labels,
  provenance, missing values and true zeros.
- Import the primary table only: currently `New calculations!A1:U12`.
  Lower repeated tables are not additional observations.
- If the workbook changes, inspect it and update the range, header checks,
  variable dictionary, expected dimensions and README together.
- Keep variables separate in statistics and plot facets. Do not mix counts and
  ratios or describe unweighted means of ratios as pooled demographic rates.
- These are regional annual aggregates, not individual bird or nest records.
  Inferential tests require a justified sampling model.
- Write generated tables to `results/` and figures to `figures/`. The workflow
  may overwrite its own outputs. Keep jitter reproducible and record session
  information and source checksum on each full run.
- After changes, run `Rscript scripts/run_all.R`. For the current workbook,
  confirm 200 long rows, 20 wide rows, ten variables, unique observation keys,
  successful long/wide round-trip validation and two nonempty PNG figures.
  Inspect warnings and at least one plot. Report any inability to run R.
- Update README.md when commands, inputs, outputs or interpretation change.
