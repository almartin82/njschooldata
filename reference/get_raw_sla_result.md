# Retrieve raw NJSLA data with source provenance

Retrieve raw NJSLA data with source provenance

## Usage

``` r
get_raw_sla_result(
  end_year,
  grade_or_subj,
  subj,
  request_fn = .default_source_request
)
```

## Arguments

- end_year:

  School-year end year.

- grade_or_subj:

  Grade or course.

- subj:

  Subject.

- request_fn:

  Injectable transport request function.

## Value

An \`njsd_source_result\`.
