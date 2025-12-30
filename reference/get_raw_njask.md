# read a fixed width, raw NJASK data file from the NJ state website

`get_raw_njask` builds a url and uses readr's `read_fwf` to get the
fixed width text file into a R data frame

## Usage

``` r
get_raw_njask(end_year, grade, layout = layout_njask)
```

## Arguments

- end_year:

  a school year. end_year is the end of the academic year - eg 2013-14
  school year is end_year '2014'. valid values are 2004-2014.

- grade:

  a grade level. valid values are 3,4,5,6,7,8

- layout:

  what layout dataframe to use. default is layout_njask.
