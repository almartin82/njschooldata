# gets and processes a NJASK file

`fetch_njask` is a wrapper around `get_raw_njask` and
`process_nj_assess` that passes the correct file layout data to each
function, given an end_year and grade.

## Usage

``` r
fetch_njask(end_year, grade)
```

## Arguments

- end_year:

  a school year. end_year is the end of the academic year - eg 2013-14
  school year is end_year '2014'. valid values are 2004-2014.

- grade:

  a grade level. valid values are 3,4,5,6,7,8
