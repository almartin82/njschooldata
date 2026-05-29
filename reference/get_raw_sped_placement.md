# Read one raw sheet from the SPED placement workbook

Returns the raw tibble for a single sheet with minimal cleaning – column
names are kept as-is from the workbook and all values are kept as
character (the workbook embeds "\*" suppression flags).

## Usage

``` r
get_raw_sped_placement(end_year, age_group = "5-21", level = "district")
```

## Arguments

- end_year:

  ending school year (currently only 2025)

- age_group:

  "5-21" or "3-5"

- level:

  "district" or "state"

## Value

tibble of the raw sheet, with an `end_year` column appended

## Examples

``` r
if (FALSE) { # \dontrun{
# Raw district-level school-age placement
raw <- get_raw_sped_placement(2025, age_group = "5-21", level = "district")

# Raw preschool statewide
raw_state_3_5 <- get_raw_sped_placement(2025, age_group = "3-5", level = "state")
} # }
```
