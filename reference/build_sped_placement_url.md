# Build the IDEA 618 placement workbook URL (2025 only)

Retained for backwards compatibility with the v1 (PR \#278) API. For
end_years 2020-2024 use
[`enumerate_sped_placement_files`](https://almartin82.github.io/njschooldata/reference/enumerate_sped_placement_files.md),
which returns a tibble of (subgroup_dim, age_group, level, url, skip)
rows.

## Usage

``` r
build_sped_placement_url(end_year)
```

## Arguments

- end_year:

  ending school year (2025)

## Value

character URL
