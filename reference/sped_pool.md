# Pool special education rows into one share

Counts over enrollment where every row has a count. A rate-only row
enters as a range from its published bounds. A suppressed row with
published bounds, such as a count under 10, enters at those bounds. A
row with enrollment and nothing else enters the range as 0 to 100, so a
suppressed school can only widen the answer. A row with no enrollment
cannot be weighted and is reported, not used.

## Usage

``` r
sped_pool(rows)
```

## Arguments

- rows:

  Rows of
  [`fetch_sped_share()`](https://almartin82.github.io/njschooldata/reference/fetch_sped_share.md).

## Value

One-row data frame: pct, pct_lo, pct_hi, method, n_rows, the enrollment
behind the figure, the shares of it with a count, a rate, bounds only or
nothing, and rows_no_enrollment. pct is NA when any row has no point
value, since only the range is then known.
