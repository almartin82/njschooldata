# Assign standard entity-level flags

Derives standard aggregation flags from `county_id`, `district_id`, and
`school_id` columns.

## Usage

``` r
assign_entity_flags(
  df,
  district_school_ids = c("888", "997", "999"),
  recognize_state_label = TRUE,
  charter_county_id = "80",
  na_school_is_district = FALSE
)
```

## Arguments

- df:

  Data frame with CDS identifier columns.

- district_school_ids:

  School identifiers that represent district-level aggregate rows.

- recognize_state_label:

  Whether `county_id == "STATE"` should be treated as the statewide row,
  case-insensitively.

- charter_county_id:

  County identifier used for charter rows.

- na_school_is_district:

  Whether rows with missing `school_id` and non-missing `district_id`
  should be treated as district rows.

## Value

`df` with standard entity flags added.
