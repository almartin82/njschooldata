# Place a pooled focal group on a distribution of comparison rows

The focal group is pooled into one share with
[`sped_pool()`](https://almartin82.github.io/njschooldata/reference/sped_pool.md)
and placed among the comparison rows, each row one point. Quantiles and
the percentile come back as ranges: a row known only to rounding or
published bounds moves them, and nothing is taken at a midpoint. A row
with no count, rate or bounds is excluded and reported, never counted as
zero. So is a rate above 100. Focal rows are removed from the comparison
set.

## Usage

``` r
sped_position(rows, focal, comparison, weight = c("row", "enrollment"),
  focal_bands = NULL, min_gap = 1)
```

## Arguments

- rows:

  Rows of
  [`fetch_sped_share()`](https://almartin82.github.io/njschooldata/reference/fetch_sped_share.md)
  for one year.

- focal, comparison:

  As in
  [`sped_all_vs_all()`](https://almartin82.github.io/njschooldata/reference/sped_all_vs_all.md).

- weight:

  "row" counts each row once. "enrollment" weights by enrollment.

- focal_bands:

  Optional data frame: grade_band, n_enrolled.

- min_gap:

  Points the gap must exceed, rounded half up to the nearest 0.5, to
  read as above or below the median.

## Value

One-row data frame: focal_pct, focal_lo, focal_hi; comparison_lo and
comparison_hi, the pooled share of the rows used; p25, median and p75,
each \_lo and \_hi; percentile_lo, percentile_hi; direction (above,
below, close or unknown); inside_middle_half (NA when the ranges overlap
a quartile line); n_used, n_focal_removed, n_no_enrollment, n_no_value,
n_impossible, n_mixed; enrollment_used and coverage, the used share of
comparison enrollment; reason.

## Details

With `focal_bands`, only rows inside one grade band are used, published
band rows first, and each band carries the focal group's share of
enrollment.
