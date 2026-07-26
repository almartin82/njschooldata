# Fetch all NJGPA results

Convenience function to download and combine all NJGPA (graduation
proficiency) results into a single data frame.

## Usage

``` r
fetch_all_njgpa(allow_partial = FALSE)
```

## Arguments

- allow_partial:

  If \`FALSE\` (default), any unavailable or unparseable subject fails
  the request. If \`TRUE\`, successful subjects are returned and all
  subject/year statuses are available through \[get_source_results()\].

## Value

A data frame with all NJGPA results (ELA and Math) and source status.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all NJGPA results
all_njgpa <- fetch_all_njgpa()
} # }
```
