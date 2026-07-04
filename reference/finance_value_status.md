# Classify finance value status from structural context

Finance values do not always have a raw cell token to parse. Per-pupil
actuals beyond the latest published actual year are not yet observed;
missing per-pupil values with zero or absent denominators are not
published; present numeric values are actual.

## Usage

``` r
finance_value_status(
  metric,
  value,
  end_year,
  is_per_pupil = NULL,
  enrollment_denominator = NULL,
  latest_observed_per_pupil_year = 2024L,
  structural_not_published = NULL
)
```

## Arguments

- metric:

  Finance metric name.

- value:

  Numeric finance value.

- end_year:

  School/fiscal year end.

- is_per_pupil:

  Logical vector indicating per-pupil metrics. If omitted, inferred from
  metric names beginning with `per_pupil`.

- enrollment_denominator:

  Optional denominator vector for per-pupil rows.

- latest_observed_per_pupil_year:

  Latest year with per-pupil actuals in the current finance source.

- structural_not_published:

  Optional logical vector for structural gaps known by the caller to be
  unpublished regardless of year.

## Value

A value-status factor.
