# Fetch NJ English Learner population data for multiple years

Fetch NJ English Learner population data for multiple years

## Usage

``` r
fetch_ell_multi(
  end_years,
  tidy = TRUE,
  use_cache = FALSE,
  with_status = FALSE,
  allow_partial = FALSE
)
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

- allow_partial:

  If \`FALSE\` (default), unavailable or failed years abort the request.
  If \`TRUE\`, successful years are returned with every request reported
  by \[get_source_results()\].

## Value

combined data.frame of EL population data and source-result status.

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
