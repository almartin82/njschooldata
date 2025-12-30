# determine if a end_year/grade pairing can be downloaded from the state website

`valid_call` returns a boolean value indicating if a given
end_year/grade pairing is valid for assessment data

## Usage

``` r
valid_call(end_year, grade)
```

## Arguments

- end_year:

  a school year. end_year is the end of the academic year - eg 2013-14
  school year is end_year '2014'. valid values are 2004-2014.

- grade:

  a grade level. valid values are 3,4,5,6,7,8
