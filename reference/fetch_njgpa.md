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

  A school year. Valid values are 2022-2024.

- subj:

  Assessment subject: 'ela' or 'math'

- tidy:

  Clean up the data frame? Default is FALSE.

## Value

Processed NJGPA dataframe

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2023 NJGPA ELA results
njgpa_ela <- fetch_njgpa(2023, "ela")

# Get 2024 NJGPA Math results
njgpa_math <- fetch_njgpa(2024, "math")
} # }
```
