# Charter status for a host-joined frame, combining every available evidence

The charter-sector and all-public aggregation helpers all begin by
joining to the bundled `charter_city` host map. They used to derive
charter status as `!is.na(host_district_id)` - pure roster membership -
which is wrong in both directions:

## Usage

``` r
charter_flag_host_aware(df)
```

## Arguments

- df:

  output of
  [`id_charter_hosts`](https://almartin82.github.io/njschooldata/reference/id_charter_hosts.md)
  (carries `host_district_id`).

## Value

A three-valued logical vector, one element per row of `df`.

## Details

- It **overwrites a sourced flag with a guess.**
  [`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
  output already carries `is_charter` from NJDOE's own county-80 code.
  Replacing it with "is this id in our bundled table" discards the
  published fact.

- **Absence from the roster is not evidence of anything.** NJ opens
  charters faster than a bundled table is refreshed. Measured against
  live NJ DOE enrollment on 2026-08-10, the roster missed 2 real
  county-80 charters in end_year 2024 (Kindle Education Public Charter
  School, People's Achieve Community Charter School) and 4 in 2026
  (those two plus Paterson Preparatory Charter School and Thrive Charter
  School). Every one was typed `is_charter = FALSE` while the same row's
  county code said `"80"`.

**The county-80 convention is vintage-dependent** and must not be
applied backwards. NJ enrollment files use county `"80"` for the charter
sector only from `end_year` 2010; in 2006-2009 charters carry their HOST
county code (verified live: 50 name-charter LEAs in 2006-2008 sit in
counties 01, 07, 13 and 25, and county 80 does not appear in those files
at all). So county 80 is read as *affirmative* evidence, never as the
sole source of a denial, and roster membership supplements it rather
than replacing it.

Evidence is combined, never discarded:

1.  start from any `is_charter` the caller already carried in;

2.  fill unknowns from the published county code;

3.  roster membership is affirmative - it can raise an unknown or a
    stale FALSE to TRUE, because every LEA in `charter_city` is a real
    NJ charter;

4.  anything still unevidenced stays `NA`.
