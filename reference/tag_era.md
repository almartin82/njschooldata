# Tag rows with era identifiers

Adds `era_id` and `is_break_year` to a data frame. The `era_id` starts
at 1 and increments at each `scale_break` or `definition_change` break
year in the selected break set. The break year itself starts the new
era. COVID gap years are flagged with `is_break_year = TRUE` but do not
increment `era_id`, because they represent missing or disrupted years
rather than a new assessment scale.

## Usage

``` r
tag_era(df, break_set, year_col = "end_year")
```

## Arguments

- df:

  Data frame containing a year column.

- break_set:

  Single break-set key, such as `"njsla"` or `"attendance"`.

- year_col:

  Name of the year column in `df`; defaults to `"end_year"`.

## Value

`df` with `era_id` and `is_break_year` columns added.

## Examples

``` r
sample_years <- data.frame(end_year = 2014:2016, value = 1:3)
tag_era(sample_years, "njsla")
#>   end_year value era_id is_break_year
#> 1     2014     1      1         FALSE
#> 2     2015     2      2          TRUE
#> 3     2016     3      2         FALSE
tag_era(data.frame(end_year = 2019:2022), "njsla")
#>   end_year era_id is_break_year
#> 1     2019      3          TRUE
#> 2     2020      3          TRUE
#> 3     2021      3          TRUE
#> 4     2022      4          TRUE
tag_era(data.frame(school_year = 2024:2025), "econ_disadv", year_col = "school_year")
#>   school_year era_id is_break_year
#> 1        2024      1         FALSE
#> 2        2025      2          TRUE
```
