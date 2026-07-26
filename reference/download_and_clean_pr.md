# Download and clean performance report data

Download and clean performance report data

## Usage

``` r
download_and_clean_pr(
  tmp_pr,
  url,
  end_year,
  request_fn = .default_source_request
)
```

## Arguments

- tmp_pr:

  path to tempfile

- url:

  url to download

- end_year:

  report year

- request_fn:

  Injectable transport request used by offline contract tests.

## Value

list of dataframes
