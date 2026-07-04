# Era Break Metadata

A documented metadata table of New Jersey assessment, attendance,
graduation, and economically disadvantaged definition break years. These
rows identify years where trend code should segment or flag results
rather than drawing a continuous line across a regime change or COVID
disruption.

## Usage

``` r
era_breaks
```

## Format

A data frame with 11 rows and 6 columns:

- break_set:

  Metric family key, such as `"njsla"`, `"grad"`, `"attendance"`, or
  `"econ_disadv"`

- break_year:

  School year ending year for the break

- break_type:

  Break type: one of `"scale_break"`, `"covid_gap"`, or
  `"definition_change"`

- label:

  Short human-readable break label

- comparable_prior:

  Logical flag indicating whether the prior-year value is comparable
  across the break; `NA` for COVID gap rows where comparability is not a
  scale question

- notes:

  Public-record justification for the break

## Source

NJDOE and NJDA public assessment, school-performance, graduation,
attendance, school-meals, and ASSA guidance; rebuild with
`data-raw/build_era_breaks.R`

## Details

The `break_set` values align to the package's metric registry era
groups. `scale_break` and `definition_change` rows start a new
[`tag_era`](https://almartin82.github.io/njschooldata/reference/tag_era.md)
era. `covid_gap` rows are flagged as break years but do not start a new
scale era.

## See also

[`get_era_breaks`](https://almartin82.github.io/njschooldata/reference/get_era_breaks.md),
[`tag_era`](https://almartin82.github.io/njschooldata/reference/tag_era.md),
[`assert_no_break_span`](https://almartin82.github.io/njschooldata/reference/assert_no_break_span.md)
