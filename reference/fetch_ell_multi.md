# Fetch NJ English Learner population data for multiple years

Fetch NJ English Learner population data for multiple years

## Usage

``` r
fetch_ell_multi(end_years, tidy = TRUE, use_cache = FALSE, with_status = FALSE)
```

## Arguments

- end_years:

  integer vector of ending academic years (2006-2026).

- tidy:

  if \`TRUE\` (default), returns the long tidy contract.

- use_cache:

  if \`TRUE\`, uses the session cache.

- with_status:

  if \`TRUE\` (and \`tidy = TRUE\`), appends the additive
  \`value_status\` column (see \[fetch_ell()\]).

## Value

combined data.frame of EL population data for all available requested
years. Unavailable years are skipped with a warning.

## See also

\[fetch_access()\] for EL proficiency (WIDA ACCESS).

## Examples

``` r
if (FALSE) { # \dontrun{
# State EL share over a decade
library(dplyr)
fetch_ell_multi(2015:2025) %>%
  filter(is_state) %>%
  select(end_year, n_students, pct_of_enrollment)
} # }
```
