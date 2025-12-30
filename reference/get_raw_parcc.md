# Reads the raw PARCC Excel files from the state website

Builds a URL and reads the xlsx file into a dataframe.

## Usage

``` r
get_raw_parcc(end_year, grade_or_subj, subj)
```

## Arguments

- end_year:

  A school year. end_year is the end of the academic year - eg 2014-15
  school year is end_year 2015. Valid values are 2015-2018.

- grade_or_subj:

  Grade level (eg 8) OR math subject code (eg ALG1, GEO, ALG2)

- subj:

  PARCC subject. c('ela' or 'math')

## Value

PARCC dataframe
