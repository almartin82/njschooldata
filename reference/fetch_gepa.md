# gets and processes a GEPA file

`fetch_gepa` is a wrapper around `get_raw_gepa` and `process_nj_assess`
that passes the correct file layout data to each function, given a
end_year and grade.

## Usage

``` r
fetch_gepa(end_year)
```

## Arguments

- end_year:

  a school end_year. end_year is the end of the academic year - eg
  2006-07 school year is end_year '2007'. valid values are 2004-2007.
