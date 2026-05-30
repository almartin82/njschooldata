# canonicalize school_code in tidy legacy assessment output

Collapses the multiple "no school here" encodings emitted by the raw NJ
DOE NJASK/HSPA/GEPA files into a single canonical value
(`NA_character_`).

Issue \#26 documents that the raw fixed-width layouts use two different
encodings for district-aggregate rows in the same column:

- `""` (whitespace-only, after trimming the padded field)

- `"000"` (a literal three-digit zero sentinel)

Both mean "this row is not a school." Without normalization, downstream
filters silently disagree: `filter(school_code == "000")` drops the
blank-encoded rows, `filter(is.na(school_code))` drops the "000"-encoded
rows, and neither filter returns the full set of district-aggregate
rows.

After this function runs, `is.na(school_code)` is the single, correct
test for "not a school." Real school codes (`"001"`..`"999"` per
layout_njask) are preserved unchanged.

The function is idempotent: applying it twice yields the same result.

## Usage

``` r
canonicalize_legacy_assess_school_code(df)
```

## Arguments

- df:

  a tidied NJASK/HSPA/GEPA data frame (must have a `school_code`
  column).

## Value

`df` with `school_code` normalized.
