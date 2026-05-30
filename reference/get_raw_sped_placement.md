# Read one raw sheet from the SPED placement workbook

For end_year 2025, returns the raw tibble for a single sheet (district
5-21, district 3-5, state 5-21, or state 3-5).

## Usage

``` r
get_raw_sped_placement(end_year, age_group = "5-21", level = "district")
```

## Arguments

- end_year:

  ending school year (2020-2025)

- age_group:

  "5-21" or "3-5"

- level:

  "district" or "state"

## Value

tibble (2025) or named list of tibbles (2020-2024). Each tibble carries
an `end_year` column appended for downstream joining.

## Details

For end_years 2020-2024, returns a named list of raw tibbles – one per
single-subgroup workbook (race, gender, disability, lep) needed for the
requested (age_group, level) slice. State-level 5-21 across 2020-2022
and state-level 3-5 across 2020-2022 ship as PDF transcriptions; for
those slices the function returns a single tidy tibble (already in the
state-level output schema) read from
`inst/extdata/sped-placement-pdf-transcribed/`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Raw district-level school-age placement (2025: one tibble)
raw <- get_raw_sped_placement(2025, age_group = "5-21", level = "district")

# 2024 district 5-21: returns list("race" = ..., "gender" = ..., ...)
raw_2024 <- get_raw_sped_placement(2024, age_group = "5-21",
                                   level = "district")

# Raw preschool statewide (2025)
raw_state_3_5 <- get_raw_sped_placement(2025, age_group = "3-5",
                                        level = "state")
} # }
```
