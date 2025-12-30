# Tidy list of TGES data frames

Tidy list of TGES data frames

## Usage

``` r
tidy_tges_data(list_of_dfs, end_year)
```

## Arguments

- list_of_dfs:

  list of TGES data frames, eg output of get_raw_tges(). Current valid
  values are 2011 to 2017.

- end_year:

  year that the report was published

## Value

list of cleaned (wide to long, tidy) dataframes
