# Specification 2: like for like by grade band

Builds what the comparison group's share would read with the focal
group's mix of grades. Each band's comparison share is pooled from rows
published by band where the state has them, otherwise from schools whose
span sits inside that band. The composite weights those shares by the
focal group's enrollment in each band. A band the focal group enrolls
with no comparison data leaves the composite NA with the reason.

## Usage

``` r
sped_like_for_like(rows, focal, comparison, focal_bands)
```

## Arguments

- rows:

  Rows of
  [`fetch_sped_share()`](https://almartin82.github.io/njschooldata/reference/fetch_sped_share.md)
  for one year.

- focal, comparison:

  As in
  [`sped_all_vs_all()`](https://almartin82.github.io/njschooldata/reference/sped_all_vs_all.md).

- focal_bands:

  Data frame: grade_band, n_enrolled, the focal group's K-12 enrollment
  by band, from
  [`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
  grade rows.

## Value

One-row data frame: pct, pct_lo, pct_hi, method, source (by_band or
single_band_schools), n_bands, mixed_share (comparison enrollment left
out as crossing bands), share_neither, and reason.
