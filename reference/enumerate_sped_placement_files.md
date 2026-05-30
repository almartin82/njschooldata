# Enumerate the per-year SPED placement files for an end_year

For end_years 2020-2024, returns a tibble describing every workbook
published for the year, including its url, expected sheet structure, and
the readxl skip value. For end_year 2025, returns a single-row tibble
pointing at the consolidated workbook.

## Usage

``` r
enumerate_sped_placement_files(end_year)
```

## Arguments

- end_year:

  ending school year

## Value

tibble with columns: end_year, subgroup_dim, age_group, level, url,
zip_member (NA for non-zip years), skip
