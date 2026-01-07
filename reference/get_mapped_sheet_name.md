# Get Mapped Sheet Name

Returns the correct sheet name for a given year, handling historical
name variations. If no mapping exists, returns the input name.

## Usage

``` r
get_mapped_sheet_name(canonical_name, end_year)
```

## Arguments

- canonical_name:

  Canonical sheet name (e.g., "chronic_absenteeism_by_grade")

- end_year:

  School year end

## Value

Actual sheet name to use with fetch_spr_data()
