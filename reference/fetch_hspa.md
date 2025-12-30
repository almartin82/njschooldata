# gets and processes a HSPA file

`fetch_njask` is a wrapper around `get_raw_hspa` and `process_nj_assess`
that passes the correct file layout data to each function, given a
end_year and grade.

## Usage

``` r
fetch_hspa(end_year)
```

## Arguments

- end_year:

  a school end_year. end_year is the end of the academic year - eg
  2013-14 school year is end_year '2014'. valid values are 2004-2014.
