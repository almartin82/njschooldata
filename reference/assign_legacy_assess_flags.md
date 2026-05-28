# assign PARCC-parity selector flags to legacy NJ assessment data

tags each row of tidy NJASK/HSPA/GEPA output with the same
entity-classification flags emitted by \`process_parcc()\` (`is_state`,
`is_dfg`, `is_district`, `is_school`, `is_charter`, `is_charter_sector`,
`is_allpublic`) so downstream code can filter cross-format data on the
same predicates.

The legacy NJ DOE files encode entity type in the
`County_Code/DFG/Aggregation_Code` column:

- `"ST"` = statewide

- DFG letter (A, B, CD, DE, FG, GH, I, J, R, V) = DFG aggregate

- numeric county code (01..41 or 80) = district/school row; `"80"`
  specifically tags the charter sector

- `"NS"` / `"SN"` = Non-/Special-Needs aggregates (none of `is_state` /
  `is_dfg` / `is_district` / `is_school` apply to these rows)

\`is_charter_sector\` and \`is_allpublic\` are FALSE on every row -
matching the placeholder behavior of \`process_parcc()\`, where these
flags only become TRUE in downstream aggregation. Emitted for schema
parity with PARCC tidy output.

## Usage

``` r
assign_legacy_assess_flags(df)
```

## Arguments

- df:

  a tidied NJASK/HSPA/GEPA data frame

## Value

df with seven additional logical columns
