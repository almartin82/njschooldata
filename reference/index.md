# Package index

## Enrollment Data

Functions for fetching and processing NJ school enrollment data

- [`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
  : Gets and processes a NJ enrollment file
- [`fetch_enr_cached()`](https://almartin82.github.io/njschooldata/reference/fetch_enr_cached.md)
  : Fetch enrollment data with caching
- [`fetch_enr_years()`](https://almartin82.github.io/njschooldata/reference/fetch_enr_years.md)
  : Fetch multiple years of enrollment data with progress
- [`tidy_enr()`](https://almartin82.github.io/njschooldata/reference/tidy_enr.md)
  : Tidy enrollment data
- [`enr_grade_aggs()`](https://almartin82.github.io/njschooldata/reference/enr_grade_aggs.md)
  : Custom Enrollment Grade Level Aggregates
- [`id_enr_aggs()`](https://almartin82.github.io/njschooldata/reference/id_enr_aggs.md)
  : Identify enrollment aggregation levels

## Assessment Data (NJSLA/PARCC)

Functions for NJSLA (2019+) and PARCC (2015-2018) assessment results

- [`fetch_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_parcc.md)
  : Gets and cleans up a PARCC data file
- [`fetch_all_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_all_parcc.md)
  : Fetch all PARCC results
- [`fetch_all_parcc_with_progress()`](https://almartin82.github.io/njschooldata/reference/fetch_all_parcc_with_progress.md)
  : Fetch all PARCC/NJSLA results with progress
- [`fetch_njgpa()`](https://almartin82.github.io/njschooldata/reference/fetch_njgpa.md)
  : Fetch NJGPA (NJ Graduation Proficiency Assessment) data
- [`fetch_all_njgpa()`](https://almartin82.github.io/njschooldata/reference/fetch_all_njgpa.md)
  : Fetch all NJGPA results
- [`fetch_access()`](https://almartin82.github.io/njschooldata/reference/fetch_access.md)
  : Fetch ACCESS for ELLs data
- [`fetch_all_access()`](https://almartin82.github.io/njschooldata/reference/fetch_all_access.md)
  : Fetch all ACCESS for ELLs results
- [`parcc_aggregate_calcs()`](https://almartin82.github.io/njschooldata/reference/parcc_aggregate_calcs.md)
  : Aggregate multiple PARCC rows and produce summary statistics
- [`parcc_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/parcc_percentile_rank.md)
  : Assessment proficiency percentile rank
- [`parcc_perf_level_counts()`](https://almartin82.github.io/njschooldata/reference/parcc_perf_level_counts.md)
  : PARCC counts by performance level
- [`tidy_parcc_subgroup()`](https://almartin82.github.io/njschooldata/reference/tidy_parcc_subgroup.md)
  : Tidy PARCC subgroup names

## Assessment Data (Legacy - NJASK/HSPA/GEPA)

Functions for historical NJ assessment data (2004-2014)

- [`fetch_old_nj_assess()`](https://almartin82.github.io/njschooldata/reference/fetch_old_nj_assess.md)
  : a simplified interface into NJ assessment data
- [`fetch_njask()`](https://almartin82.github.io/njschooldata/reference/fetch_njask.md)
  : gets and processes a NJASK file
- [`fetch_hspa()`](https://almartin82.github.io/njschooldata/reference/fetch_hspa.md)
  : gets and processes a HSPA file
- [`fetch_gepa()`](https://almartin82.github.io/njschooldata/reference/fetch_gepa.md)
  : gets and processes a GEPA file
- [`tidy_nj_assess()`](https://almartin82.github.io/njschooldata/reference/tidy_nj_assess.md)
  : tidies NJ assessment data

## Graduation Data

Functions for graduation rates and counts

- [`fetch_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md)
  : Fetch Grad Rate
- [`fetch_grad_count()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_count.md)
  : Fetch Grad Counts
- [`fetch_6yr_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_6yr_grad_rate.md)
  : Fetch 6-Year Graduation Rate data
- [`fetch_all_6yr_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_all_6yr_grad_rate.md)
  : Fetch all 6-Year Graduation Rate data
- [`id_grad_aggs()`](https://almartin82.github.io/njschooldata/reference/id_grad_aggs.md)
  : Identify graduation aggregation levels
- [`grate_aggregate_calcs()`](https://almartin82.github.io/njschooldata/reference/grate_aggregate_calcs.md)
  : Aggregate multiple grad rate rows and produce summary statistics
- [`gcount_aggregate_calcs()`](https://almartin82.github.io/njschooldata/reference/gcount_aggregate_calcs.md)
  : Aggregate multiple grad count rows and produce summary statistics
- [`grate_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/grate_percentile_rank.md)
  : Graduation rate percentile rank
- [`grate_validation_summary()`](https://almartin82.github.io/njschooldata/reference/grate_validation_summary.md)
  : Get graduation rate validation summary
- [`recover_suppressed_grate()`](https://almartin82.github.io/njschooldata/reference/recover_suppressed_grate.md)
  : Recover suppressed district graduation rates from school data

## School Performance Reports (SPR)

Functions for SPR database data (2017-2024)

- [`fetch_spr_data()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md)
  : Fetch SPR Data
- [`list_spr_sheets()`](https://almartin82.github.io/njschooldata/reference/list_spr_sheets.md)
  : List Available SPR Sheets
- [`fetch_chronic_absenteeism()`](https://almartin82.github.io/njschooldata/reference/fetch_chronic_absenteeism.md)
  : Fetch Chronic Absenteeism Data
- [`fetch_absenteeism_by_grade()`](https://almartin82.github.io/njschooldata/reference/fetch_absenteeism_by_grade.md)
  : Fetch Absenteeism by Grade
- [`fetch_days_absent()`](https://almartin82.github.io/njschooldata/reference/fetch_days_absent.md)
  : Fetch Days Absent Data
- [`fetch_sat_participation()`](https://almartin82.github.io/njschooldata/reference/fetch_sat_participation.md)
  : Fetch SAT/ACT/PSAT Participation Data
- [`fetch_sat_performance()`](https://almartin82.github.io/njschooldata/reference/fetch_sat_performance.md)
  : Fetch SAT/ACT/PSAT Performance Data
- [`fetch_ap_participation()`](https://almartin82.github.io/njschooldata/reference/fetch_ap_participation.md)
  : Fetch AP/IB Participation and Performance Data
- [`fetch_ap_performance()`](https://almartin82.github.io/njschooldata/reference/fetch_ap_performance.md)
  : Fetch AP/IB Performance Data (Alias)
- [`fetch_ib_participation()`](https://almartin82.github.io/njschooldata/reference/fetch_ib_participation.md)
  : Fetch IB Participation Data
- [`fetch_cte_participation()`](https://almartin82.github.io/njschooldata/reference/fetch_cte_participation.md)
  : Fetch CTE Participation Data
- [`fetch_industry_credentials()`](https://almartin82.github.io/njschooldata/reference/fetch_industry_credentials.md)
  : Fetch Industry Valued Credentials Data
- [`fetch_work_based_learning()`](https://almartin82.github.io/njschooldata/reference/fetch_work_based_learning.md)
  : Fetch Work-Based Learning Data
- [`fetch_apprenticeship_data()`](https://almartin82.github.io/njschooldata/reference/fetch_apprenticeship_data.md)
  : Fetch Apprenticeship Data
- [`fetch_biliteracy_seal()`](https://almartin82.github.io/njschooldata/reference/fetch_biliteracy_seal.md)
  : Fetch Seal of Biliteracy Data
- [`fetch_violence_vandalism_hib()`](https://almartin82.github.io/njschooldata/reference/fetch_violence_vandalism_hib.md)
  : Fetch Violence/Vandalism/HIB Data
- [`fetch_disciplinary_removals()`](https://almartin82.github.io/njschooldata/reference/fetch_disciplinary_removals.md)
  : Fetch Disciplinary Removals Data
- [`fetch_teacher_experience()`](https://almartin82.github.io/njschooldata/reference/fetch_teacher_experience.md)
  : Fetch Teacher Experience Data
- [`fetch_staff_demographics()`](https://almartin82.github.io/njschooldata/reference/fetch_staff_demographics.md)
  : Fetch Staff Demographics Data
- [`fetch_staff_ratios()`](https://almartin82.github.io/njschooldata/reference/fetch_staff_ratios.md)
  : Fetch Student-Staff Ratio Data
- [`fetch_dropout_rates()`](https://almartin82.github.io/njschooldata/reference/fetch_dropout_rates.md)
  : Fetch Dropout Rate Data
- [`fetch_essa_status()`](https://almartin82.github.io/njschooldata/reference/fetch_essa_status.md)
  : Fetch ESSA Accountability Status
- [`fetch_math_course_enrollment()`](https://almartin82.github.io/njschooldata/reference/fetch_math_course_enrollment.md)
  : Fetch Math Course Enrollment Data

## School/District Directories

Functions for school and district metadata

- [`get_school_directory()`](https://almartin82.github.io/njschooldata/reference/get_school_directory.md)
  : Get NJ School Directory Data
- [`get_district_directory()`](https://almartin82.github.io/njschooldata/reference/get_district_directory.md)
  : Get NJ District Directory Data

## Charter Aggregations

Functions for charter school sector aggregations

- [`charter_sector_enr_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_enr_aggs.md)
  : Calculate Charter Sector Enrollment Aggregates
- [`charter_sector_gcount_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_gcount_aggs.md)
  : Calculate Charter Sector Grad Count aggregates
- [`charter_sector_grate_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_grate_aggs.md)
  : Calculate Charter Sector Grad Rate aggregates
- [`charter_sector_matric_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_matric_aggs.md)
  : Calculate Charter Sector postsecondary matriculation aggregates
- [`charter_sector_parcc_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_parcc_aggs.md)
  : Calculate Charter Sector PARCC aggregates
- [`charter_sector_spec_pop_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_spec_pop_aggs.md)
  : Calculate Charter Sector Special Populations Aggregates
- [`charter_sector_sped_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_sped_aggs.md)
  : Calculate Charter Sector SPED Aggregates
- [`allpublic_enr_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_enr_aggs.md)
  : Calculate All Public Enrollment Aggregates
- [`allpublic_gcount_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_gcount_aggs.md)
  : Calculate Charter Sector Grad Count aggregates
- [`allpublic_grate_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_grate_aggs.md)
  : Calculate All Public Grad Rate aggregates
- [`allpublic_matric_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_matric_aggs.md)
  : Calculate All Public matriculation aggregates
- [`allpublic_parcc_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_parcc_aggs.md)
  : Calculate All Public Options PARCC Aggregates
- [`allpublic_spec_pop_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_spec_pop_aggs.md)
  : Calculate All City Special Populations aggregates
- [`allpublic_sped_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_sped_aggs.md)
  : Calculate Charter Sector SPED aggregates
- [`id_charter_hosts()`](https://almartin82.github.io/njschooldata/reference/id_charter_hosts.md)
  : Identify charter host districts

## Special Populations

Functions for special education and other subgroup data

- [`fetch_sped()`](https://almartin82.github.io/njschooldata/reference/fetch_sped.md)
  : Fetch Special Education Classification Data
- [`fetch_reportcard_special_pop()`](https://almartin82.github.io/njschooldata/reference/fetch_reportcard_special_pop.md)
  : Fetch Special Population data
- [`fetch_chronic_absenteeism()`](https://almartin82.github.io/njschooldata/reference/fetch_chronic_absenteeism.md)
  : Fetch Chronic Absenteeism Data
- [`fetch_all_chronic_absenteeism()`](https://almartin82.github.io/njschooldata/reference/fetch_all_chronic_absenteeism.md)
  : Fetch all Chronic Absenteeism data
- [`sped_aggregate_calcs()`](https://almartin82.github.io/njschooldata/reference/sped_aggregate_calcs.md)
  : Aggregate multiple sped rows and produce summary statistics
- [`spec_pop_aggregate_calcs()`](https://almartin82.github.io/njschooldata/reference/spec_pop_aggregate_calcs.md)
  : Aggregate multiple special populations rows and produce summary
  statistics

## Other Data Sources

Additional NJ DOE data functions

- [`fetch_msgp()`](https://almartin82.github.io/njschooldata/reference/fetch_msgp.md)
  : Fetch mSGP
- [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)
  : Fetch Cleaned Taxpayer's Guide to Educational Spending
- [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md)
  : Fetch Multiple Cleaned Taxpayer's Guides to Educational Spending
- [`fetch_dfg()`](https://almartin82.github.io/njschooldata/reference/fetch_dfg.md)
  : Fetch NJ District Factor Group (DFG) data
- [`fetch_postsecondary()`](https://almartin82.github.io/njschooldata/reference/fetch_postsecondary.md)
  : Fetch Postsecondary Enrollment Rates
- [`get_one_rc_database()`](https://almartin82.github.io/njschooldata/reference/get_one_rc_database.md)
  : Get Raw Report Card Database
- [`get_merged_rc_database()`](https://almartin82.github.io/njschooldata/reference/get_merged_rc_database.md)
  : Combines school and district Performance Reports for 2017-on, when
  two files were released.
- [`get_rc_databases()`](https://almartin82.github.io/njschooldata/reference/get_rc_databases.md)
  : Get multiple RC databases
- [`get_dfg_districts()`](https://almartin82.github.io/njschooldata/reference/get_dfg_districts.md)
  : Get districts in a specific District Factor Group
- [`get_dfg_a_districts()`](https://almartin82.github.io/njschooldata/reference/get_dfg_a_districts.md)
  : Get DFG A districts (highest-need peer group)

## Utilities

Helper functions and lookups

- [`pad_grade()`](https://almartin82.github.io/njschooldata/reference/pad_grade.md)
  : Pad grade level
- [`pad_cds()`](https://almartin82.github.io/njschooldata/reference/pad_cds.md)
  : Pad CDS fields
- [`pad_leading()`](https://almartin82.github.io/njschooldata/reference/pad_leading.md)
  : Pad leading digits
- [`trim_whitespace()`](https://almartin82.github.io/njschooldata/reference/trim_whitespace.md)
  : Trim whitespace
- [`enrich_grad_count()`](https://almartin82.github.io/njschooldata/reference/enrich_grad_count.md)
  : Enrich report card matriculation percentages with grad counts
- [`enrich_matric_counts()`](https://almartin82.github.io/njschooldata/reference/enrich_matric_counts.md)
  : Enrich matriculation rates with counts from grad counts
- [`enrich_rc_enrollment()`](https://almartin82.github.io/njschooldata/reference/enrich_rc_enrollment.md)
  : Enrich report card subgroup percentages with best guesses at
  subgroup numbers
- [`enrich_school_city_ward()`](https://almartin82.github.io/njschooldata/reference/enrich_school_city_ward.md)
  : Enrich School Data with City Ward
- [`enrich_school_latlong()`](https://almartin82.github.io/njschooldata/reference/enrich_school_latlong.md)
  : Enrich School Data with Lat / Long
- [`validate_end_year()`](https://almartin82.github.io/njschooldata/reference/validate_end_year.md)
  : Validate end_year parameter
- [`validate_grade()`](https://almartin82.github.io/njschooldata/reference/validate_grade.md)
  : Validate grade parameter
- [`validate_grate_aggregation()`](https://almartin82.github.io/njschooldata/reference/validate_grate_aggregation.md)
  : Validate graduation rate aggregation

## Caching

Cache management functions

- [`njsd_cache_clear()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_clear.md)
  : Clear the session cache
- [`njsd_cache_enable()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_enable.md)
  : Enable or disable the session cache
- [`njsd_cache_enabled()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_enabled.md)
  : Check if caching is enabled
- [`njsd_cache_info()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_info.md)
  : Get cache statistics and information
- [`njsd_cache_list()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_list.md)
  : List all cached items
- [`njsd_cache_remove()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_remove.md)
  : Remove a specific item from cache
- [`njsd_progress_enable()`](https://almartin82.github.io/njschooldata/reference/njsd_progress_enable.md)
  : Enable or disable progress indicators

## All Other Functions

Additional exported functions

- [`SUBGROUP_PAIRS`](https://almartin82.github.io/njschooldata/reference/SUBGROUP_PAIRS.md)
  : Standard subgroup pairs for gap analysis
- [`add_dfg()`](https://almartin82.github.io/njschooldata/reference/add_dfg.md)
  : Add DFG classification to district data
- [`add_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/add_percentile_rank.md)
  : Add percentile rank columns for any metric
- [`agg_enr_column_order()`](https://almartin82.github.io/njschooldata/reference/agg_enr_column_order.md)
  : Helper function to return aggregate enrollment columns in correct
  order
- [`agg_enr_pct_total()`](https://almartin82.github.io/njschooldata/reference/agg_enr_pct_total.md)
  : Helper function to support calculating pct_total on aggregate enr
  dataframes
- [`agg_spec_pop_column_order()`](https://almartin82.github.io/njschooldata/reference/agg_spec_pop_column_order.md)
  : Helper function to return aggregate special populations columns in
  correct order
- [`agg_sped_column_order()`](https://almartin82.github.io/njschooldata/reference/agg_sped_column_order.md)
  : Helper function to return aggregate sped columns in correct order
- [`allpublic_enr_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_enr_aggs.md)
  : Calculate All Public Enrollment Aggregates
- [`allpublic_gcount_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_gcount_aggs.md)
  : Calculate Charter Sector Grad Count aggregates
- [`allpublic_grate_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_grate_aggs.md)
  : Calculate All Public Grad Rate aggregates
- [`allpublic_matric_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_matric_aggs.md)
  : Calculate All Public matriculation aggregates
- [`allpublic_parcc_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_parcc_aggs.md)
  : Calculate All Public Options PARCC Aggregates
- [`allpublic_spec_pop_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_spec_pop_aggs.md)
  : Calculate All City Special Populations aggregates
- [`allpublic_sped_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_sped_aggs.md)
  : Calculate Charter Sector SPED aggregates
- [`analyze_course_access_equity()`](https://almartin82.github.io/njschooldata/reference/analyze_course_access_equity.md)
  : Analyze Course Access Equity
- [`analyze_retention_patterns()`](https://almartin82.github.io/njschooldata/reference/analyze_retention_patterns.md)
  : Analyze Staff Retention Patterns
- [`calc_ap_access_rate()`](https://almartin82.github.io/njschooldata/reference/calc_ap_access_rate.md)
  : Calculate AP/IB Access Rate
- [`calc_discipline_rates_by_subgroup()`](https://almartin82.github.io/njschooldata/reference/calc_discipline_rates_by_subgroup.md)
  : Calculate Discipline Rates by Subgroup
- [`calc_staff_diversity_metrics()`](https://almartin82.github.io/njschooldata/reference/calc_staff_diversity_metrics.md)
  : Calculate Staff Diversity Metrics
- [`calc_stem_participation_rate()`](https://almartin82.github.io/njschooldata/reference/calc_stem_participation_rate.md)
  : Calculate STEM Participation Rate
- [`calc_student_staff_ratio()`](https://almartin82.github.io/njschooldata/reference/calc_student_staff_ratio.md)
  : Calculate and Analyze Student-Staff Ratios
- [`calculate_access_rate()`](https://almartin82.github.io/njschooldata/reference/calculate_access_rate.md)
  : Calculate equity access rate
- [`calculate_agg_parcc_prof()`](https://almartin82.github.io/njschooldata/reference/calculate_agg_parcc_prof.md)
  : Aggregate PARCC results across multiple grade levels
- [`calculate_subgroup_gap()`](https://almartin82.github.io/njschooldata/reference/calculate_subgroup_gap.md)
  : Calculate achievement gap between two subgroups
- [`charter_city`](https://almartin82.github.io/njschooldata/reference/charter_city.md)
  : Charter School Host District Mapping
- [`charter_market_share()`](https://almartin82.github.io/njschooldata/reference/charter_market_share.md)
  : Calculate charter market share for host cities
- [`charter_sector_enr_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_enr_aggs.md)
  : Calculate Charter Sector Enrollment Aggregates
- [`charter_sector_gcount_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_gcount_aggs.md)
  : Calculate Charter Sector Grad Count aggregates
- [`charter_sector_grate_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_grate_aggs.md)
  : Calculate Charter Sector Grad Rate aggregates
- [`charter_sector_matric_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_matric_aggs.md)
  : Calculate Charter Sector postsecondary matriculation aggregates
- [`charter_sector_parcc_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_parcc_aggs.md)
  : Calculate Charter Sector PARCC aggregates
- [`charter_sector_spec_pop_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_spec_pop_aggs.md)
  : Calculate Charter Sector Special Populations Aggregates
- [`charter_sector_sped_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_sped_aggs.md)
  : Calculate Charter Sector SPED Aggregates
- [`check_url_accessible()`](https://almartin82.github.io/njschooldata/reference/check_url_accessible.md)
  : Check if a URL is accessible
- [`city_ecosystem_summary()`](https://almartin82.github.io/njschooldata/reference/city_ecosystem_summary.md)
  : Summarize sector performance within a city
- [`clean_cds_fields()`](https://almartin82.github.io/njschooldata/reference/clean_cds_fields.md)
  : Clean up CDS field names
- [`clean_sped_df()`](https://almartin82.github.io/njschooldata/reference/clean_sped_df.md)
  : Clean SPED data
- [`compare_discipline_across_years()`](https://almartin82.github.io/njschooldata/reference/compare_discipline_across_years.md)
  : Compare Discipline Across Years
- [`define_peer_group()`](https://almartin82.github.io/njschooldata/reference/define_peer_group.md)
  : Define a peer comparison group
- [`dfg_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/dfg_percentile_rank.md)
  : Calculate DFG peer percentile for any metric
- [`district_matric_aggs()`](https://almartin82.github.io/njschooldata/reference/district_matric_aggs.md)
  : Aggregates matriculation data by district
- [`download_and_clean_pr()`](https://almartin82.github.io/njschooldata/reference/download_and_clean_pr.md)
  : Download and clean performance report data
- [`ecosystem_trend()`](https://almartin82.github.io/njschooldata/reference/ecosystem_trend.md)
  : Track sector ecosystem dynamics over time
- [`enr_grade_aggs()`](https://almartin82.github.io/njschooldata/reference/enr_grade_aggs.md)
  : Custom Enrollment Grade Level Aggregates
- [`enrich_grad_count()`](https://almartin82.github.io/njschooldata/reference/enrich_grad_count.md)
  : Enrich report card matriculation percentages with grad counts
- [`enrich_matric_counts()`](https://almartin82.github.io/njschooldata/reference/enrich_matric_counts.md)
  : Enrich matriculation rates with counts from grad counts
- [`enrich_rc_enrollment()`](https://almartin82.github.io/njschooldata/reference/enrich_rc_enrollment.md)
  : Enrich report card subgroup percentages with best guesses at
  subgroup numbers
- [`enrich_school_city_ward()`](https://almartin82.github.io/njschooldata/reference/enrich_school_city_ward.md)
  : Enrich School Data with City Ward
- [`enrich_school_latlong()`](https://almartin82.github.io/njschooldata/reference/enrich_school_latlong.md)
  : Enrich School Data with Lat / Long
- [`extract_rc_AP()`](https://almartin82.github.io/njschooldata/reference/extract_rc_AP.md)
  : Extract Report Card Advanced Placement Data
- [`extract_rc_SAT()`](https://almartin82.github.io/njschooldata/reference/extract_rc_SAT.md)
  : Extract Report Card SAT School Averages
- [`extract_rc_cds()`](https://almartin82.github.io/njschooldata/reference/extract_rc_cds.md)
  : Extract Report Card CDS
- [`extract_rc_college_matric()`](https://almartin82.github.io/njschooldata/reference/extract_rc_college_matric.md)
  : Extract Report Card Matriculation Rates
- [`extract_rc_enrollment()`](https://almartin82.github.io/njschooldata/reference/extract_rc_enrollment.md)
  : Extract Report Card Enrollment
- [`fetch_6yr_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_6yr_grad_rate.md)
  : Fetch 6-Year Graduation Rate data
- [`fetch_absenteeism_by_grade()`](https://almartin82.github.io/njschooldata/reference/fetch_absenteeism_by_grade.md)
  : Fetch Absenteeism by Grade
- [`fetch_access()`](https://almartin82.github.io/njschooldata/reference/fetch_access.md)
  : Fetch ACCESS for ELLs data
- [`fetch_all_6yr_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_all_6yr_grad_rate.md)
  : Fetch all 6-Year Graduation Rate data
- [`fetch_all_access()`](https://almartin82.github.io/njschooldata/reference/fetch_all_access.md)
  : Fetch all ACCESS for ELLs results
- [`fetch_all_chronic_absenteeism()`](https://almartin82.github.io/njschooldata/reference/fetch_all_chronic_absenteeism.md)
  : Fetch all Chronic Absenteeism data
- [`fetch_all_njgpa()`](https://almartin82.github.io/njschooldata/reference/fetch_all_njgpa.md)
  : Fetch all NJGPA results
- [`fetch_all_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_all_parcc.md)
  : Fetch all PARCC results
- [`fetch_all_parcc_with_progress()`](https://almartin82.github.io/njschooldata/reference/fetch_all_parcc_with_progress.md)
  : Fetch all PARCC/NJSLA results with progress
- [`fetch_ap_participation()`](https://almartin82.github.io/njschooldata/reference/fetch_ap_participation.md)
  : Fetch AP/IB Participation and Performance Data
- [`fetch_ap_performance()`](https://almartin82.github.io/njschooldata/reference/fetch_ap_performance.md)
  : Fetch AP/IB Performance Data (Alias)
- [`fetch_apprenticeship_data()`](https://almartin82.github.io/njschooldata/reference/fetch_apprenticeship_data.md)
  : Fetch Apprenticeship Data
- [`fetch_arts_enrollment()`](https://almartin82.github.io/njschooldata/reference/fetch_arts_enrollment.md)
  : Fetch Visual and Performing Arts Enrollment Data
- [`fetch_biliteracy_seal()`](https://almartin82.github.io/njschooldata/reference/fetch_biliteracy_seal.md)
  : Fetch Seal of Biliteracy Data
- [`fetch_chronic_absenteeism()`](https://almartin82.github.io/njschooldata/reference/fetch_chronic_absenteeism.md)
  : Fetch Chronic Absenteeism Data
- [`fetch_cs_enrollment()`](https://almartin82.github.io/njschooldata/reference/fetch_cs_enrollment.md)
  : Fetch Computer Science Enrollment Data
- [`fetch_cte_participation()`](https://almartin82.github.io/njschooldata/reference/fetch_cte_participation.md)
  : Fetch CTE Participation Data
- [`fetch_days_absent()`](https://almartin82.github.io/njschooldata/reference/fetch_days_absent.md)
  : Fetch Days Absent Data
- [`fetch_dfg()`](https://almartin82.github.io/njschooldata/reference/fetch_dfg.md)
  : Fetch NJ District Factor Group (DFG) data
- [`fetch_disciplinary_removals()`](https://almartin82.github.io/njschooldata/reference/fetch_disciplinary_removals.md)
  : Fetch Disciplinary Removals Data
- [`fetch_dropout_rates()`](https://almartin82.github.io/njschooldata/reference/fetch_dropout_rates.md)
  : Fetch Dropout Rate Data
- [`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
  : Gets and processes a NJ enrollment file
- [`fetch_enr_cached()`](https://almartin82.github.io/njschooldata/reference/fetch_enr_cached.md)
  : Fetch enrollment data with caching
- [`fetch_enr_years()`](https://almartin82.github.io/njschooldata/reference/fetch_enr_years.md)
  : Fetch multiple years of enrollment data with progress
- [`fetch_essa_chronic_absenteeism()`](https://almartin82.github.io/njschooldata/reference/fetch_essa_chronic_absenteeism.md)
  : Fetch ESSA Chronic Absenteeism data
- [`fetch_essa_progress()`](https://almartin82.github.io/njschooldata/reference/fetch_essa_progress.md)
  : Fetch ESSA Accountability Progress
- [`fetch_essa_status()`](https://almartin82.github.io/njschooldata/reference/fetch_essa_status.md)
  : Fetch ESSA Accountability Status
- [`fetch_gepa()`](https://almartin82.github.io/njschooldata/reference/fetch_gepa.md)
  : gets and processes a GEPA file
- [`fetch_grad_count()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_count.md)
  : Fetch Grad Counts
- [`fetch_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md)
  : Fetch Grad Rate
- [`fetch_hspa()`](https://almartin82.github.io/njschooldata/reference/fetch_hspa.md)
  : gets and processes a HSPA file
- [`fetch_ib_participation()`](https://almartin82.github.io/njschooldata/reference/fetch_ib_participation.md)
  : Fetch IB Participation Data
- [`fetch_industry_credentials()`](https://almartin82.github.io/njschooldata/reference/fetch_industry_credentials.md)
  : Fetch Industry Valued Credentials Data
- [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md)
  : Fetch Multiple Cleaned Taxpayer's Guides to Educational Spending
- [`fetch_math_course_enrollment()`](https://almartin82.github.io/njschooldata/reference/fetch_math_course_enrollment.md)
  : Fetch Math Course Enrollment Data
- [`fetch_msgp()`](https://almartin82.github.io/njschooldata/reference/fetch_msgp.md)
  : Fetch mSGP
- [`fetch_njask()`](https://almartin82.github.io/njschooldata/reference/fetch_njask.md)
  : gets and processes a NJASK file
- [`fetch_njgpa()`](https://almartin82.github.io/njschooldata/reference/fetch_njgpa.md)
  : Fetch NJGPA (NJ Graduation Proficiency Assessment) data
- [`fetch_old_nj_assess()`](https://almartin82.github.io/njschooldata/reference/fetch_old_nj_assess.md)
  : a simplified interface into NJ assessment data
- [`fetch_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_parcc.md)
  : Gets and cleans up a PARCC data file
- [`fetch_postsecondary()`](https://almartin82.github.io/njschooldata/reference/fetch_postsecondary.md)
  : Fetch Postsecondary Enrollment Rates
- [`fetch_reportcard_special_pop()`](https://almartin82.github.io/njschooldata/reference/fetch_reportcard_special_pop.md)
  : Fetch Special Population data
- [`fetch_sat_participation()`](https://almartin82.github.io/njschooldata/reference/fetch_sat_participation.md)
  : Fetch SAT/ACT/PSAT Participation Data
- [`fetch_sat_performance()`](https://almartin82.github.io/njschooldata/reference/fetch_sat_performance.md)
  : Fetch SAT/ACT/PSAT Performance Data
- [`fetch_science_course_enrollment()`](https://almartin82.github.io/njschooldata/reference/fetch_science_course_enrollment.md)
  : Fetch Science Course Enrollment Data
- [`fetch_social_studies_enrollment()`](https://almartin82.github.io/njschooldata/reference/fetch_social_studies_enrollment.md)
  : Fetch Social Studies Enrollment Data
- [`fetch_sped()`](https://almartin82.github.io/njschooldata/reference/fetch_sped.md)
  : Fetch Special Education Classification Data
- [`fetch_spr_data()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md)
  : Fetch SPR Data
- [`fetch_staff_demographics()`](https://almartin82.github.io/njschooldata/reference/fetch_staff_demographics.md)
  : Fetch Staff Demographics Data
- [`fetch_staff_ratios()`](https://almartin82.github.io/njschooldata/reference/fetch_staff_ratios.md)
  : Fetch Student-Staff Ratio Data
- [`fetch_teacher_experience()`](https://almartin82.github.io/njschooldata/reference/fetch_teacher_experience.md)
  : Fetch Teacher Experience Data
- [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)
  : Fetch Cleaned Taxpayer's Guide to Educational Spending
- [`fetch_violence_vandalism_hib()`](https://almartin82.github.io/njschooldata/reference/fetch_violence_vandalism_hib.md)
  : Fetch Violence/Vandalism/HIB Data
- [`fetch_work_based_learning()`](https://almartin82.github.io/njschooldata/reference/fetch_work_based_learning.md)
  : Fetch Work-Based Learning Data
- [`fetch_world_language_enrollment()`](https://almartin82.github.io/njschooldata/reference/fetch_world_language_enrollment.md)
  : Fetch World Language Enrollment Data
- [`gap_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/gap_percentile_rank.md)
  : Rank entities by achievement gap within peer group
- [`gap_trajectory()`](https://almartin82.github.io/njschooldata/reference/gap_trajectory.md)
  : Track achievement gap trends over time
- [`gcount_aggregate_calcs()`](https://almartin82.github.io/njschooldata/reference/gcount_aggregate_calcs.md)
  : Aggregate multiple grad count rows and produce summary statistics
- [`geocoded`](https://almartin82.github.io/njschooldata/reference/geocoded.md)
  : Geocoded School Addresses
- [`get_dfg_a_districts()`](https://almartin82.github.io/njschooldata/reference/get_dfg_a_districts.md)
  : Get DFG A districts (highest-need peer group)
- [`get_dfg_districts()`](https://almartin82.github.io/njschooldata/reference/get_dfg_districts.md)
  : Get districts in a specific District Factor Group
- [`get_district_directory()`](https://almartin82.github.io/njschooldata/reference/get_district_directory.md)
  : Get NJ District Directory Data
- [`get_essa_file()`](https://almartin82.github.io/njschooldata/reference/get_essa_file.md)
  : Get an ESSA comprehensive or targeted accountability file
- [`get_merged_rc_database()`](https://almartin82.github.io/njschooldata/reference/get_merged_rc_database.md)
  : Combines school and district Performance Reports for 2017-on, when
  two files were released.
- [`get_one_rc_database()`](https://almartin82.github.io/njschooldata/reference/get_one_rc_database.md)
  : Get Raw Report Card Database
- [`get_percentile_cols()`](https://almartin82.github.io/njschooldata/reference/get_percentile_cols.md)
  : Get percentile cols
- [`get_rc_databases()`](https://almartin82.github.io/njschooldata/reference/get_rc_databases.md)
  : Get multiple RC databases
- [`get_school_directory()`](https://almartin82.github.io/njschooldata/reference/get_school_directory.md)
  : Get NJ School Directory Data
- [`get_standalone_rc_database()`](https://almartin82.github.io/njschooldata/reference/get_standalone_rc_database.md)
  : Get Standalone Raw Report Card Database
- [`get_valid_grades()`](https://almartin82.github.io/njschooldata/reference/get_valid_grades.md)
  : Get valid grades for an assessment type and year
- [`grate_aggregate_calcs()`](https://almartin82.github.io/njschooldata/reference/grate_aggregate_calcs.md)
  : Aggregate multiple grad rate rows and produce summary statistics
- [`grate_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/grate_percentile_rank.md)
  : Graduation rate percentile rank
- [`grate_validation_summary()`](https://almartin82.github.io/njschooldata/reference/grate_validation_summary.md)
  : Get graduation rate validation summary
- [`id_charter_hosts()`](https://almartin82.github.io/njschooldata/reference/id_charter_hosts.md)
  : Identify charter host districts
- [`id_enr_aggs()`](https://almartin82.github.io/njschooldata/reference/id_enr_aggs.md)
  : Identify enrollment aggregation levels
- [`id_grad_aggs()`](https://almartin82.github.io/njschooldata/reference/id_grad_aggs.md)
  : Identify graduation aggregation levels
- [`identify_focus_schools()`](https://almartin82.github.io/njschooldata/reference/identify_focus_schools.md)
  : Identify Focus Schools
- [`kill_padformulas()`](https://almartin82.github.io/njschooldata/reference/kill_padformulas.md)
  : Kill Excel Formula Padding For Numeric Strings
- [`layout_gepa`](https://almartin82.github.io/njschooldata/reference/layout_gepa.md)
  : GEPA Fixed-Width File Layout
- [`layout_gepa05`](https://almartin82.github.io/njschooldata/reference/layout_gepa05.md)
  : GEPA 2005 Fixed-Width File Layout
- [`layout_gepa06`](https://almartin82.github.io/njschooldata/reference/layout_gepa06.md)
  : GEPA 2006 Fixed-Width File Layout
- [`layout_hspa`](https://almartin82.github.io/njschooldata/reference/layout_hspa.md)
  : HSPA Fixed-Width File Layout
- [`layout_hspa04`](https://almartin82.github.io/njschooldata/reference/layout_hspa04.md)
  : HSPA 2004 Fixed-Width File Layout
- [`layout_hspa05`](https://almartin82.github.io/njschooldata/reference/layout_hspa05.md)
  : HSPA 2005 Fixed-Width File Layout
- [`layout_hspa06`](https://almartin82.github.io/njschooldata/reference/layout_hspa06.md)
  : HSPA 2006 Fixed-Width File Layout
- [`layout_hspa10`](https://almartin82.github.io/njschooldata/reference/layout_hspa10.md)
  : HSPA 2010 Fixed-Width File Layout
- [`layout_njask`](https://almartin82.github.io/njschooldata/reference/layout_njask.md)
  : NJASK Fixed-Width File Layout
- [`layout_njask04`](https://almartin82.github.io/njschooldata/reference/layout_njask04.md)
  : NJASK 2004 Fixed-Width File Layout
- [`layout_njask05`](https://almartin82.github.io/njschooldata/reference/layout_njask05.md)
  : NJASK 2005 Fixed-Width File Layout
- [`layout_njask06gr3`](https://almartin82.github.io/njschooldata/reference/layout_njask06gr3.md)
  : NJASK 2006 Grade 3 Fixed-Width File Layout
- [`layout_njask06gr5`](https://almartin82.github.io/njschooldata/reference/layout_njask06gr5.md)
  : NJASK 2006 Grade 5 Fixed-Width File Layout
- [`layout_njask07gr3`](https://almartin82.github.io/njschooldata/reference/layout_njask07gr3.md)
  : NJASK 2007 Grade 3 Fixed-Width File Layout
- [`layout_njask07gr5`](https://almartin82.github.io/njschooldata/reference/layout_njask07gr5.md)
  : NJASK 2007 Grade 5 Fixed-Width File Layout
- [`layout_njask09`](https://almartin82.github.io/njschooldata/reference/layout_njask09.md)
  : NJASK 2009 Fixed-Width File Layout
- [`layout_njask10`](https://almartin82.github.io/njschooldata/reference/layout_njask10.md)
  : NJASK 2010 Fixed-Width File Layout
- [`list_spr_sheets()`](https://almartin82.github.io/njschooldata/reference/list_spr_sheets.md)
  : List Available SPR Sheets
- [`matric_aggregate_calcs()`](https://almartin82.github.io/njschooldata/reference/matric_aggregate_calcs.md)
  : Aggregate multiple postsecondary matriculation rows and produce
  summary statistics
- [`matric_column_order()`](https://almartin82.github.io/njschooldata/reference/matric_column_order.md)
  : Matriculation column order
- [`njsd_cache_clear()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_clear.md)
  : Clear the session cache
- [`njsd_cache_enable()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_enable.md)
  : Enable or disable the session cache
- [`njsd_cache_enabled()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_enabled.md)
  : Check if caching is enabled
- [`njsd_cache_info()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_info.md)
  : Get cache statistics and information
- [`njsd_cache_list()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_list.md)
  : List all cached items
- [`njsd_cache_remove()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_remove.md)
  : Remove a specific item from cache
- [`njsd_progress_enable()`](https://almartin82.github.io/njschooldata/reference/njsd_progress_enable.md)
  : Enable or disable progress indicators
- [`nwk_address_addendum`](https://almartin82.github.io/njschooldata/reference/nwk_address_addendum.md)
  : Newark Address Addendum
- [`pad_cds()`](https://almartin82.github.io/njschooldata/reference/pad_cds.md)
  : Pad CDS fields
- [`pad_grade()`](https://almartin82.github.io/njschooldata/reference/pad_grade.md)
  : Pad grade level
- [`pad_leading()`](https://almartin82.github.io/njschooldata/reference/pad_leading.md)
  : Pad leading digits
- [`parcc_aggregate_calcs()`](https://almartin82.github.io/njschooldata/reference/parcc_aggregate_calcs.md)
  : Aggregate multiple PARCC rows and produce summary statistics
- [`parcc_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/parcc_percentile_rank.md)
  : Assessment proficiency percentile rank
- [`parcc_perf_level_counts()`](https://almartin82.github.io/njschooldata/reference/parcc_perf_level_counts.md)
  : PARCC counts by performance level
- [`percentile_rank()`](https://almartin82.github.io/njschooldata/reference/percentile_rank.md)
  : Percentile Rank
- [`percentile_rank_trend()`](https://almartin82.github.io/njschooldata/reference/percentile_rank_trend.md)
  : Calculate percentile rank change over time
- [`print(`*`<njsd_cache_info>`*`)`](https://almartin82.github.io/njschooldata/reference/print.njsd_cache_info.md)
  : Print cache information
- [`prog_codes`](https://almartin82.github.io/njschooldata/reference/prog_codes.md)
  : NJ Program Codes
- [`rc_numeric_cleaner()`](https://almartin82.github.io/njschooldata/reference/rc_numeric_cleaner.md)
  : Report Card Numeric Data Cleaner
- [`recover_suppressed_grate()`](https://almartin82.github.io/njschooldata/reference/recover_suppressed_grate.md)
  : Recover suppressed district graduation rates from school data
- [`sector_gap()`](https://almartin82.github.io/njschooldata/reference/sector_gap.md)
  : Calculate performance gap between charter and district sectors
- [`sector_percentile_comparison()`](https://almartin82.github.io/njschooldata/reference/sector_percentile_comparison.md)
  : Compare percentile ranks across sectors
- [`spec_pop_aggregate_calcs()`](https://almartin82.github.io/njschooldata/reference/spec_pop_aggregate_calcs.md)
  : Aggregate multiple special populations rows and produce summary
  statistics
- [`sped_aggregate_calcs()`](https://almartin82.github.io/njschooldata/reference/sped_aggregate_calcs.md)
  : Aggregate multiple sped rows and produce summary statistics
- [`sped_lookup_map`](https://almartin82.github.io/njschooldata/reference/sped_lookup_map.md)
  : Special Education District Lookup Map
- [`tges_name_cleaner()`](https://almartin82.github.io/njschooldata/reference/tges_name_cleaner.md)
  : TGES name cleaner
- [`tidy_budgetary_per_pupil_cost()`](https://almartin82.github.io/njschooldata/reference/tidy_budgetary_per_pupil_cost.md)
  : Tidy Budgetary Per Pupil data frame
- [`tidy_enr()`](https://almartin82.github.io/njschooldata/reference/tidy_enr.md)
  : Tidy enrollment data
- [`tidy_nj_assess()`](https://almartin82.github.io/njschooldata/reference/tidy_nj_assess.md)
  : tidies NJ assessment data
- [`tidy_parcc_subgroup()`](https://almartin82.github.io/njschooldata/reference/tidy_parcc_subgroup.md)
  : Tidy PARCC subgroup names
- [`tidy_tges_data()`](https://almartin82.github.io/njschooldata/reference/tidy_tges_data.md)
  : Tidy list of TGES data frames
- [`tidy_vitstat()`](https://almartin82.github.io/njschooldata/reference/tidy_vitstat.md)
  : Tidy Vital Statistics
- [`track_essa_progress_over_time()`](https://almartin82.github.io/njschooldata/reference/track_essa_progress_over_time.md)
  : Track ESSA Progress Over Time
- [`trim_whitespace()`](https://almartin82.github.io/njschooldata/reference/trim_whitespace.md)
  : Trim whitespace
- [`trunc2()`](https://almartin82.github.io/njschooldata/reference/trunc2.md)
  : Truncate with configurable precision
- [`validate_end_year()`](https://almartin82.github.io/njschooldata/reference/validate_end_year.md)
  : Validate end_year parameter
- [`validate_grade()`](https://almartin82.github.io/njschooldata/reference/validate_grade.md)
  : Validate grade parameter
- [`validate_grate_aggregation()`](https://almartin82.github.io/njschooldata/reference/validate_grate_aggregation.md)
  : Validate graduation rate aggregation
- [`verify_data_urls()`](https://almartin82.github.io/njschooldata/reference/verify_data_urls.md)
  : Verify all configured URLs for a data type
- [`ward_enr_aggs()`](https://almartin82.github.io/njschooldata/reference/ward_enr_aggs.md)
  : Aggregates enrollment data by ward
- [`ward_gcount_aggs()`](https://almartin82.github.io/njschooldata/reference/ward_gcount_aggs.md)
  : Aggregates grad counts data by ward
- [`ward_grate_aggs()`](https://almartin82.github.io/njschooldata/reference/ward_grate_aggs.md)
  : Aggregates grad rate data by ward
- [`ward_matric_aggs()`](https://almartin82.github.io/njschooldata/reference/ward_matric_aggs.md)
  : Aggregates matriculation data by ward
- [`ward_parcc_aggs()`](https://almartin82.github.io/njschooldata/reference/ward_parcc_aggs.md)
  : Aggregates assessment data by ward
