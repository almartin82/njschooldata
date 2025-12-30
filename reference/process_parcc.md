# Process a raw PARCC data file

All the logic needed to clean up the raw PARCC files.

## Usage

``` r
process_parcc(parcc_file, end_year, grade, subj)
```

## Arguments

- parcc_file:

  Output of get_raw_parcc

- end_year:

  A school year. end_year is the end of the academic year - eg 2014-15
  school year is end_year 2015. Valid values are 2015-2024.

- grade:

  Integer or character specifying grade level

- subj:

  PARCC subject. c('ela', 'math', or 'science')

## Value

A tbl_df / data frame
