# Attach federal NCES ids to an enrollment data frame

Adds two columns to (wide or tidy) enrollment data:

- `nces_dist` — the 7-digit NCES `LEAID` for the district, attached to
  district rows (`school_id == "999"`) and school rows.

- `nces_sch` — the 12-digit NCES `NCESSCH` for the school, attached to
  school rows only (`NA` for district/state rows).

## Usage

``` r
attach_nces_ids(df)
```

## Arguments

- df:

  An enrollment data frame carrying `county_id`, `district_id`, and
  `school_id` (wide output of
  [`fetch_enr`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
  or tidy output of
  [`tidy_enr`](https://almartin82.github.io/njschooldata/reference/tidy_enr.md)).

## Value

`df` with `nces_dist` and `nces_sch` columns added.

## Details

The join is exact, on the NJ County-District-School (CDS) code. Entities
not present in the bundled crosswalk (new/closed/charter additions,
state and county aggregate rows) keep `NA` — an id is never fabricated
or guessed.

## Examples

``` r
if (FALSE) { # \dontrun{
# wide enrollment with NCES ids
enr <- fetch_enr(2024)
dplyr::distinct(enr, district_id, district_name, nces_dist)

# tidy enrollment also carries the ids
enr_tidy <- fetch_enr(2024, tidy = TRUE)
dplyr::filter(enr_tidy, is_school, !is.na(nces_sch))
} # }
```
