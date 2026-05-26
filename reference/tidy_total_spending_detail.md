# tidy Total Spending Detail

Cleans the Total Spending Detail workbooks (`Detail_FY##.xlsx`) that
ship inside the 2024+ TGES bundles. These break a district's *Total
Spending Per Pupil* into the six components that, summed, equal the
published per-pupil total: General Current Expense, Capital Outlay,
Grants & Entitlements, Food Services, Debt Service on locally issued
bonds, and Debt Service on School Development Authority (SDA) bonds.

Unlike the budget indicators (CSG1-15), the per-pupil amounts here are
divided by *daily enrollment plus sent pupils*, not resident enrollment,
so they are only directly comparable to CSG1's budgetary per-pupil cost
for districts that educate all of their own pupils.
[`tges_excluded_costs()`](https://almartin82.github.io/njschooldata/reference/tges_excluded_costs.md)
carries the enrollment denominator through and flags sending districts
for this reason.

The data year is taken from the `FY##` token in the file name (the 2025
guide ships `Detail_FY24` = end_year 2024 and `Detail_FY23` = end_year
2023), not from the report `end_year`.

## Usage

``` r
tidy_total_spending_detail(df, end_year)
```

## Arguments

- df:

  a raw Total Spending Detail data frame from
  [`get_raw_tges()`](https://almartin82.github.io/njschooldata/reference/get_raw_tges.md)
  (read with the two-row banner skipped, so column names are the row-3
  headers)

- end_year:

  the report year the bundle was published under (used as `report_year`;
  the row's `end_year` comes from the file name)

## Value

long, tidy data frame
