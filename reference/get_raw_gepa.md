# read a fixed width, raw GEPA data file from the NJ state website

`get_raw_gepa` builds a url and uses readr's `read_fwf` to get the fixed
width text file into a R data frame

## Usage

``` r
get_raw_gepa(end_year, layout = layout_gepa)
```

## Arguments

- end_year:

  a school year. end_year is the end of the academic year - eg 2006-07
  school year is end_year '2007'. valid values are 2004-2007.

- layout:

  what layout dataframe to use. default is layout_gepa.
