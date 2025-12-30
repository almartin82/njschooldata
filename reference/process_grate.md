# Process graduation rate data

Does cleanup of the grad rate ('grate') file.

## Usage

``` r
process_grate(df, end_year)
```

## Arguments

- df:

  The output of get_raw_grad_file

- end_year:

  A school year. Year is the end of the academic year - eg 2006-07
  school year is year '2007'. Valid values are 1998-2024.

## Value

Cleaned graduation data frame
