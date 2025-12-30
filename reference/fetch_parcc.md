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
  school year is end_year 2015. Valid values are 2015-2024.

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

Processed PARCC/NJSLA dataframe

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
