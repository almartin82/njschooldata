# Validate graduation rate aggregation

Compares district-level graduation rates against weighted averages
calculated from school-level data. Flags discrepancies that exceed a
threshold, which may indicate data quality issues in the source files.

## Usage

``` r
validate_grate_aggregation(df, tolerance = 2, log_dir = tempdir())
```

## Arguments

- df:

  Graduation rate data frame with both school and district level data

- tolerance:

  Maximum allowed difference (in percentage points) between reported
  district rate and calculated rate. Default is 2 (2 percentage points).

- log_dir:

  Directory for log files. Default is tempdir().

## Value

Data frame with validation columns added: - \`calculated_from_schools\`:
Rate calculated from school-level data - \`rate_discrepancy_pp\`:
Difference in percentage points - \`aggregation_flag\`: "OK",
"DISCREPANCY", "MISSING_SCHOOL_DATA", or "SUPPRESSED"

## Details

This function helps identify potential data quality issues where: -
District totals don't match sum of school data - Rates are
mathematically inconsistent - Data may have been incorrectly entered or
processed

A detailed log file is written documenting all discrepancies found.
