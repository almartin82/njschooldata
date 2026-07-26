# Fetch all Chronic Absenteeism data

Convenience function to download and combine all available chronic
absenteeism data into a single data frame.

## Usage

``` r
fetch_all_chronic_absenteeism(allow_partial = FALSE)
```

## Arguments

- allow_partial:

  If \`FALSE\` (default), any failed year aborts the combined request.
  If \`TRUE\`, successful years are returned with request status
  available from \[get_source_results()\].

## Value

A data frame with all chronic absenteeism results (2017-2019, 2022-2024)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all chronic absenteeism data
all_ca <- fetch_all_chronic_absenteeism()
} # }
```
