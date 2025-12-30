# Add DFG classification to district data

Joins District Factor Group classification to any district-level
dataframe. Handles both full CDS format (county+district, e.g.,
"133570") and district-only format (e.g., "3570").

## Usage

``` r
add_dfg(df, revision = 2000)
```

## Arguments

- df:

  Dataframe with district_id column

- revision:

  Numeric. DFG revision year (2000 or 1990). Default 2000.

## Value

df with 'dfg' column added
