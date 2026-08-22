# Check if an entity is in the NJ charter sector

The single decider for charter status in this package. NJDOE assigns
every charter LEA to county `"80"`, so the county code is the evidence
and **the answer is three-valued**:

## Usage

``` r
is_charter_district(county_id)
```

## Arguments

- county_id:

  County ID (character), as published.

## Value

Logical vector, `NA` where `county_id` is `NA`.

## Details

- `TRUE` - the source published county `"80"`: the charter sector,
  affirmed.

- `FALSE` - the source published some OTHER county code (a real county
  `"01".."41"`, the statewide sentinel `"99"`, a DFG letter,
  `"ST"`/`"NS"`/`"SN"`): outside the charter sector, also affirmed. This
  is a sourced fact and must be kept.

- `NA` - the source published no county code at all (e.g. the
  `"STATE SUM"` row of the certificated-staff files): it said nothing
  about charter status, so neither did we.

`==` propagates the NA on its own. Do NOT wrap this in
`!is.na(x) & ...`: that expression cannot return NA, so it answers "not
a charter" for rows the source never typed.

Verified against NJ DOE fall enrollment (2019, 26,508 rows): all 842
rows whose LEA name contains "Charter" carry county 80, and NO
name-charter LEA sits outside county 80. County 80 additionally covers
768 rows whose names do not say "charter", so the code is both stricter
and broader than a name guess.
