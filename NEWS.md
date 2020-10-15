## njschooldata 0.8.13

## New features

* postsecondary matriculation aggregations - `district_matric_aggs` and `allpublic_matric_aggs`

* bug fixes for mSGP and for njsla/parcc assessment file location changes


## njschooldata 0.8.12

## New features

* `K12UG` aggregate published - K12 w/ ungraded students.


## njschooldata 0.8.11

## New features

* `ward_grate_aggs()` and `ward_gcount_aggs()` calculate grad rate and grad count for supported ward geographies


## njschooldata 0.8.10

## New features

* `charter_sector_spec_pop_aggs()` and `allpublic_spec_pop_aggs()` calculate sector wide special population aggregations
* `charter_sector_sped_aggs()` and `allpublic_sped_aggs()` calculate sector-wide SPED aggregations
* `extract_rc_enrollment()` extracts and cleans spring enrollment data from report card databases
* `fetch_enr` now also returns the count and percentage of free *or* reduced lunch students

## njschooldata 0.8.9

## New features

* `ward_parcc_aggs()` aggregates PARCC data for city ward / neighborhood geographies (currently supported: Newark)


## njschooldata 0.8.8

## New features

* `fetch_grad_rate()` and `fetch_grad_count()` support 2019 data


## njschooldata 0.8.7

## New features

* `fetch_msgp()` supports 2019 data

* msgp data supports new subgroups: female, male, homeless, foster care, military-connected, migrant


## njschooldata 0.8.6

## New features

* `get_reportcard_special_pop()` supports 2019 data


## njschooldata 0.8.3

## New features

* `fetch_parcc()` supports 2019 NJSLA data


## njschooldata 0.8.2

## New features

* `enrich_school_latlong()` will add the address and latitude / longitude of a school

* `enrich_school_city_ward()` will return the relevant administrative subdivision of a school for supported cities.  Currently supported: Newark

* `enrich_school_city_neighborhood()` will return the relevant neighborhood subdivision for supported cities.  Currently supported: Newark


# njschooldata 0.8.1

## New features

* `fetch_msgp()` reads msgp data from report card files.

* `fetch_reportcard_special_pop()`


# njschooldata 0.8.0

## New features

* Method for combining school/district Report Card data.

* PARCC Percentile Rank functions are more thoroughly tested, with some errors corrected.


# njschooldata 0.7.9

## New features

* Grad Count data (`fetch_grad_count`) from 1999-present.
* Grad rate and count charter sector and all public aggregations.


# njschooldata 0.7.8

## New features

* `fetch_grate` takes a calc type argument, and will return 5 year cohort grad rates for 2012-present.



# njschooldata 0.7.7

## New features

* `statewide_peer_percentile` will calculate PARCC scale and proficiency percentile rank across NJ.
* `dfg_peer_percentile` will calculate PARCC scale and proficiency percentile rank across NJ.



# njschooldata 0.7.6

## New features

* `charter_sector_parcc_aggs` will calculate PARCC composites for city charter sectors.
* `allpublic_parcc_aggs` will calculate PARCC composites across city and charter schools.

## Breaking changes

* PARCC functions now return `_id` (ie `district_id`, `school_id`) instead of `_code`.  This closes [#65](https://github.com/almartin82/njschooldata/issues/65) and makes school/district identifiers consistent across enrollment and PARCC assessment files.

* `parcc_aggregate_calcs` expects a field called `is_charter`. 



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
