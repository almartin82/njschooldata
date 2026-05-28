# Rename CDS `*_code` columns to `*_id`

Converts the `county_code`, `district_code`, and `school_code` columns
produced by
[`clean_cds_fields`](https://almartin82.github.io/njschooldata/reference/clean_cds_fields.md)
to the package-standard `*_id` names. `clean_cds_fields` stays `*_code`
because it is the shared raw-name normalizer; call this immediately
after it on any data family whose public output should use the `*_id`
convention.

## Usage

``` r
cds_codes_to_ids(df)
```

## Arguments

- df:

  data frame that may contain `county_code`, `district_code`, and/or
  `school_code` columns

## Value

df, with any present `*_code` CDS columns renamed to `*_id`
