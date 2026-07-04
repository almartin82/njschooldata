# Tidy the 2025+ "State Rates" by-disability sheet

Reshapes the state-level child-count-by-disability table (NJ DOE IDEA
618 "State Rates" sheet) into a tidy frame with one row per disability
category. Counts are the Dec-1 child count of students with IEPs; the
published classification rate is stored as a 0-100 percent (the source
reports it as a decimal). The "Statewide Total" rollup row maps to
`disability_category == "all_disabilities"`.

## Usage

``` r
tidy_sped_state_disability(df, end_year, with_status = FALSE)
```

## Arguments

- df:

  cleaned data frame: output of get_raw_sped(level = "state") passed
  through clean_sped_names()

- end_year:

  ending school year

## Value

tidy tibble: end_year, is_state, disability_category, n_students,
sped_rate, suppressed
