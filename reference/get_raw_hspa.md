# read a fixed width, raw HSPA data file from the NJ state website

`get_raw_hspa` builds a url and uses readr's `read_fwf` to get the fixed
width text file into a R data frame

## Usage

``` r
get_raw_hspa(end_year, layout = layout_hspa[c(1:558), ])
```

## Arguments

- end_year:

  a school end_year. end_year is the end of the academic year - eg
  2013-14 school year is end_year '2014'. valid values are 2004-2014.

- layout:

  what layout dataframe to use. default is layout_hspa.
