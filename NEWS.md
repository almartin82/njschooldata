# njschooldata 0.5

## New features

* support for for PARCC data via the `fetch_parcc()` family of functions.
* support for NJ School Report Card / Performance Report data via the `get_rc_databases()` function
* ability to read longitudinal NJ Report Card SAT data via `extract_pr_SAT()`



# njschooldata 0.4

## New features

* support for HS graduation data via the `fetch_grate()` family of functions




# njschooldata 0.3

## New features

* a `tidy = TRUE` argument to `fetch_nj_assess` that converts the wide data files to long, enabling easier longitudinal analysis

## Bug fixes

* resolved various file layout errors and problems (that were silently dropping data when fixed-width files were read in!)




# njschooldata 0.2

## New features

* support for enrollment data




# njschooldata 0.1

## New features

* support for NJASK and other assessment data
