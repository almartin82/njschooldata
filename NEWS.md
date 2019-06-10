# njschooldata 0.7.6

## New features

* `charter_sector_parcc_aggs` will calculate PARCC composites for city charter sectors. 

## Breaking changes

* PARCC functions now return `_id` (ie `district_id`, `school_id`) instead of `_code`.  This closes [#65](https://github.com/almartin82/njschooldata/issues/65) and makes school/district identifiers consistent across enrollment and PARCC assessment files.


# njschooldata 0.7.5

## New features

* `enr_grade_aggs` will calculate some common grade level aggregations.
- Any K (half + full day K)
- K-12 enrollment (exclude pre-k)
- K-8 enrollment
- HS


# njschooldata 0.7.4

## New features

* `friendly_district_names` will make a legibile vector of unique district names, one per district_id.
* `district_name_to_id` reverses it, giving ids from names.


# njschooldata 0.7.3

## New features

* can calculate aggregates of all public school options in a given city with `allpublic_enr_aggs()`.


# njschooldata 0.7.2

## New features

* older (largely closed) charter schools added to `charter_city` table to allow for accurate calculations of longitudinal charter sector statistics.



# njschooldata 0.7.1

## New features

* can calculate charter sector (eg, charters in Jersey City) enrollment stats using `charter_sector_enr_aggs()`



# njschooldata 0.7.0

## New features

* can pass `tidy = TRUE` argument to `fetch_enr()` to get subgroups tidied
* fetch enr aggregates gender subgroups into racial subgroups (white_m + white_f = white)



# njschooldata 0.6.1

## New features

* ability to standardize / clean / label Taxpayers Guide data with `tidy_tges_data()` 



# njschooldata 0.6

## New features

* ability to read in Taxpayers Guide to Educational Spending data files with `get_raw_tges(2016)` and `fetch_tges(2017)` 



# njschooldata 0.5.2

## New features

* ability to read in Federal ESSA (Every Student Succeeds Act) accountability data files with `get_essa_file(2017)`.



# njschooldata 0.5.1

## New features

* extensions of NJ School Report Card functions with `extract_rc_college_matric()` and  `extract_rc_AP()`.
* ability to put county/district/school names onto longitudinal report card data sets.



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
