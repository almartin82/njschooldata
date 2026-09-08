# Gets and cleans up a PARCC data file

\`fetch_parcc\` is a wrapper around \`get_raw_parcc\` and
\`process_parcc\` that gets a parcc file and performs any cleanup.

## Usage

``` r
fetch_parcc(end_year, grade_or_subj, subj, tidy = FALSE)
```

## Arguments

- end_year:

  A school year. end_year is the end of the academic year - eg 2014-15
  school year is end_year 2015. Valid values are 2015-2025.

- grade_or_subj:

  Grade level (eg 8) OR math subject code (eg ALG1, GEO, ALG2). For
  science, valid grades are 5, 8, and 11.

- subj:

  Assessment subject: 'ela', 'math', or 'science'. Science assessments
  are only available for 2019+ and grades 5, 8, 11.

- tidy:

  Clean up the data frame to make it more compatible with NJASK naming
  conventions and do some additional calculations? Default is FALSE.

## Value

Processed PARCC/NJSLA dataframe. \`num_l1\`..\`num_l5\` are computed
from each row's own published performance-level percent and its own
published \`number_of_valid_scale_scores\` (see
\`parcc_perf_level_counts()\`); \`value_source\` marks each row
\`"derived_from_pct"\` or, where \`number_of_valid_scale_scores\` was
NA, \`"published_pct_only"\`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2023 grade 4 math results
parcc_2023 <- fetch_parcc(2023, 4, "math")

# Get 2023 Algebra 1 results
alg1_2023 <- fetch_parcc(2023, "ALG1", "math")

# Get 2023 grade 8 science results
science_2023 <- fetch_parcc(2023, 8, "science")
} # }
```
