# Reads the raw NJGPA Excel files from the state website

NJGPA (New Jersey Graduation Proficiency Assessment) is the graduation
requirement assessment introduced in 2022.

## Usage

``` r
get_raw_njgpa(end_year, subj)
```

## Arguments

- end_year:

  A school year. Valid values are 2022-2024.

- subj:

  NJGPA subject. c('ela' or 'math')

## Value

NJGPA dataframe
