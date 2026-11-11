# Fetch NJGPA (NJ Graduation Proficiency Assessment) data

Downloads and processes NJGPA assessment results. NJGPA is the
graduation requirement assessment introduced in 2022, replacing the
previous PARCC-based graduation pathway.

## Usage

``` r
fetch_njgpa(end_year, subj, tidy = FALSE)
```

## Arguments

- end_year:

  A school year. Valid values are 2022-2026.

- subj:

  Assessment subject: 'ela' or 'math'

- tidy:

  Clean up the data frame? Default is FALSE.

## Value

Processed NJGPA dataframe, carrying the same
\`num_l1\`/\`num_l2\`-plus-\`value_source\` derivation as
\[fetch_parcc()\]. \`assessment_era\` distinguishes the 2026 scale;
scores are not rescaled. \`suppressed\` flags rows with any
asterisk-masked valid-score count, mean scale score or level percent.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2023 NJGPA ELA results
njgpa_ela <- fetch_njgpa(2023, "ela")

# Get 2024 NJGPA Math results
njgpa_math <- fetch_njgpa(2024, "math")
} # }
```
