# What the budgetary per-pupil figure leaves out (incl. on-behalf TPAF pension)

NJ's headline comparative measure, *Budgetary Per Pupil Cost* (CSG1),
deliberately excludes a long list of spending, most notably the
state-paid on-behalf TPAF pension, post-retirement medical, and social
security contributions, which by law are paid by the state and never
appear in a district's own budget. This helper joins the Total Spending
Detail workbook (a 2024+ TGES table) to CSG1 so you can see, per
district-year, every component that sits between budgetary cost and
total spending.

## Usage

``` r
tges_excluded_costs(tges, years = NULL, reliable_max_sent_share = 0.02)
```

## Arguments

- tges:

  Output of
  [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)
  or
  [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md)
  for a 2024+ guide.

- years:

  Optional numeric vector. Keep only these `end_year` values.

- reliable_max_sent_share:

  Numeric in \[0, 1\]; the maximum sent-pupil share for which the
  per-pupil differences are treated as reliable. Default 0.02.

## Value

A tibble with one row per district-year: entity columns, `end_year`,
`budgetary_pp`, the six Detail components, `total_spending_pp`,
`excluded_total_pp`, `gce_excess_pp`, `enrollment_plus_sent`,
`budgetary_denom`, `sent_pupil_share`, and the logical
`residual_reliable`.

## Details

The Detail workbook splits *Total Spending Per Pupil* into six
components that sum to the published total; this helper returns them as
clean per-pupil columns:

- `general_current_expense_pp` – general-fund current expense (this is
  where on-behalf TPAF, transportation, tuition, and judgments live)

- `capital_outlay_pp`, `grants_entitlements_pp`, `food_services_pp`,
  `debt_service_local_pp`, `debt_service_sda_pp` – the other five
  components

It then computes two differences against the budgetary per-pupil cost:

- `excluded_total_pp` = `total_spending_pp - budgetary_pp`. This is the
  full wedge of *everything* excluded from the budgetary figure:
  on-behalf TPAF pension/PRM/social security **plus** transportation,
  capital outlay, grants/entitlements, food service, tuition, debt
  service, and judgments.

- `gce_excess_pp` = `general_current_expense_pp - budgetary_pp`. A
  narrower residual: general-fund items excluded from budgetary cost,
  i.e. roughly *transportation + on-behalf TPAF + tuition + judgments*.

**Neither difference isolates pension.** No public TGES file breaks out
the on-behalf TPAF line; it is buried inside General Current Expense
alongside transportation and tuition. An itemized per-district pension
figure exists only in NJDOE's login-gated AudSum submission. Treat
`gce_excess_pp` as an upper bound on pension, not a measurement of it.

**Denominator caveat.** Budgetary per-pupil cost divides by resident
enrollment; the Detail per-pupil amounts divide by enrollment *plus sent
pupils*. For districts that educate all their own pupils the two agree
within ~1%, but for sending districts (including big cities that place
special-ed or vocational pupils out of district) the denominators
diverge and the per-pupil subtraction breaks down. `sent_pupil_share`
reports
`(enrollment_plus_sent - resident_enrollment) / enrollment_plus_sent`,
and `residual_reliable` is `TRUE` only when that share is at or below
`reliable_max_sent_share`. Filter to `residual_reliable` before reading
anything into `gce_excess_pp`.

Total Spending Detail tables ship only in the 2024 guide onward, so this
needs `fetch_tges(2024)` or later (each guide carries two prior fiscal
years).

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# All excluded-cost components for the latest two fiscal years
tges_excluded_costs(fetch_tges(2025)) %>%
  select(district_name, end_year, budgetary_pp, total_spending_pp,
         excluded_total_pp, gce_excess_pp)

# Only districts where the residual is denominator-reliable (self-contained),
# ranked by the general-fund excess (~ transportation + on-behalf TPAF)
tges_excluded_costs(fetch_tges(2025)) %>%
  filter(residual_reliable, end_year == 2024) %>%
  arrange(desc(gce_excess_pp)) %>%
  select(district_name, budgetary_pp, gce_excess_pp, sent_pupil_share)

# Track one district's excluded-cost wedge across guides
tges_excluded_costs(fetch_many_tges(2024:2025)) %>%
  filter(district_code == "3570") %>%
  select(end_year, budgetary_pp, gce_excess_pp, excluded_total_pp)
} # }
```
