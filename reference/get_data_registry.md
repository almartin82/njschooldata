# What this package holds, serves and is missing, by family and year

Computed offline at call time from the package's own coverage table, its
source-contract manifests and its two known-fact files. There is no
stored copy to fall out of date. Status \`not_searched\` means nobody
has looked: read it as unknown, never as absent.

## Usage

``` r
get_data_registry(family = NULL, end_year = NULL)
```

## Arguments

- family:

  Optional family to keep, such as \`"enrollment"\`.

- end_year:

  Optional years to keep.

## Value

A data frame with one row per family, year and source. See
\`vignette("data-sources")\` for the columns.

## Examples

``` r
reg <- get_data_registry()
subset(reg, status == "served")
#>     state           family end_year                               source_id
#> 1      NJ          absence     2017           essa_accountability_workbooks
#> 2      NJ          absence     2017     school_performance_reports_database
#> 3      NJ          absence     2018           essa_accountability_workbooks
#> 4      NJ          absence     2018     school_performance_reports_database
#> 5      NJ          absence     2019           essa_accountability_workbooks
#> 6      NJ          absence     2019     school_performance_reports_database
#> 8      NJ          absence     2021     school_performance_reports_database
#> 9      NJ          absence     2022           essa_accountability_workbooks
#> 10     NJ          absence     2022     school_performance_reports_database
#> 11     NJ          absence     2023           essa_accountability_workbooks
#> 12     NJ          absence     2023     school_performance_reports_database
#> 13     NJ          absence     2024           essa_accountability_workbooks
#> 14     NJ          absence     2024     school_performance_reports_database
#> 15     NJ          absence     2025     school_performance_reports_database
#> 29     NJ       assessment     2022                 access_for_ells_results
#> 30     NJ       assessment     2023                 access_for_ells_results
#> 31     NJ       assessment     2024                 access_for_ells_results
#> 32     NJ       assessment     2025                 access_for_ells_results
#> 34     NJ              ell     2006                 fall_enrollment_reports
#> 35     NJ              ell     2007                 fall_enrollment_reports
#> 36     NJ              ell     2008                 fall_enrollment_reports
#> 37     NJ              ell     2009                 fall_enrollment_reports
#> 38     NJ              ell     2010                 fall_enrollment_reports
#> 39     NJ              ell     2011                 fall_enrollment_reports
#> 40     NJ              ell     2012                 fall_enrollment_reports
#> 41     NJ              ell     2013                 fall_enrollment_reports
#> 42     NJ              ell     2014                 fall_enrollment_reports
#> 43     NJ              ell     2015                 fall_enrollment_reports
#> 44     NJ              ell     2016                 fall_enrollment_reports
#> 45     NJ              ell     2017                 fall_enrollment_reports
#> 46     NJ              ell     2018                 fall_enrollment_reports
#> 47     NJ              ell     2019                 fall_enrollment_reports
#> 48     NJ              ell     2020                 fall_enrollment_reports
#> 49     NJ              ell     2021                 fall_enrollment_reports
#> 50     NJ              ell     2022                 fall_enrollment_reports
#> 51     NJ              ell     2023                 fall_enrollment_reports
#> 52     NJ              ell     2024                 fall_enrollment_reports
#> 53     NJ              ell     2025                 fall_enrollment_reports
#> 54     NJ              ell     2026                 fall_enrollment_reports
#> 55     NJ       enrollment     1999                 fall_enrollment_reports
#> 56     NJ       enrollment     2000                 fall_enrollment_reports
#> 57     NJ       enrollment     2001                 fall_enrollment_reports
#> 58     NJ       enrollment     2002                 fall_enrollment_reports
#> 59     NJ       enrollment     2003                 fall_enrollment_reports
#> 60     NJ       enrollment     2004                 fall_enrollment_reports
#> 61     NJ       enrollment     2005                 fall_enrollment_reports
#> 62     NJ       enrollment     2006                 fall_enrollment_reports
#> 63     NJ       enrollment     2007                 fall_enrollment_reports
#> 64     NJ       enrollment     2008                 fall_enrollment_reports
#> 65     NJ       enrollment     2009                 fall_enrollment_reports
#> 66     NJ       enrollment     2010                 fall_enrollment_reports
#> 67     NJ       enrollment     2011                 fall_enrollment_reports
#> 68     NJ       enrollment     2012                 fall_enrollment_reports
#> 69     NJ       enrollment     2013                 fall_enrollment_reports
#> 70     NJ       enrollment     2014                 fall_enrollment_reports
#> 71     NJ       enrollment     2015                 fall_enrollment_reports
#> 72     NJ       enrollment     2016                 fall_enrollment_reports
#> 73     NJ       enrollment     2017                 fall_enrollment_reports
#> 74     NJ       enrollment     2018                 fall_enrollment_reports
#> 75     NJ       enrollment     2019                 fall_enrollment_reports
#> 76     NJ       enrollment     2020                 fall_enrollment_reports
#> 77     NJ       enrollment     2021                 fall_enrollment_reports
#> 78     NJ       enrollment     2022                 fall_enrollment_reports
#> 79     NJ       enrollment     2023                 fall_enrollment_reports
#> 80     NJ       enrollment     2024                 fall_enrollment_reports
#> 81     NJ       enrollment     2025                 fall_enrollment_reports
#> 82     NJ       enrollment     2026                 fall_enrollment_reports
#> 83     NJ          finance     2001 taxpayers_guide_to_educational_spending
#> 84     NJ          finance     2002 taxpayers_guide_to_educational_spending
#> 85     NJ          finance     2003 taxpayers_guide_to_educational_spending
#> 86     NJ          finance     2004 taxpayers_guide_to_educational_spending
#> 87     NJ          finance     2005 taxpayers_guide_to_educational_spending
#> 88     NJ          finance     2006 taxpayers_guide_to_educational_spending
#> 89     NJ          finance     2007 taxpayers_guide_to_educational_spending
#> 90     NJ          finance     2008 taxpayers_guide_to_educational_spending
#> 91     NJ          finance     2009 taxpayers_guide_to_educational_spending
#> 92     NJ          finance     2010 taxpayers_guide_to_educational_spending
#> 93     NJ          finance     2011 taxpayers_guide_to_educational_spending
#> 94     NJ          finance     2012 taxpayers_guide_to_educational_spending
#> 95     NJ          finance     2013 taxpayers_guide_to_educational_spending
#> 96     NJ          finance     2014 taxpayers_guide_to_educational_spending
#> 97     NJ          finance     2015 taxpayers_guide_to_educational_spending
#> 98     NJ          finance     2016 taxpayers_guide_to_educational_spending
#> 99     NJ          finance     2017 taxpayers_guide_to_educational_spending
#> 100    NJ          finance     2018 taxpayers_guide_to_educational_spending
#> 101    NJ          finance     2019              state_aid_district_details
#> 102    NJ          finance     2019 taxpayers_guide_to_educational_spending
#> 103    NJ          finance     2020              state_aid_district_details
#> 104    NJ          finance     2020 taxpayers_guide_to_educational_spending
#> 105    NJ          finance     2021              state_aid_district_details
#> 106    NJ          finance     2021 taxpayers_guide_to_educational_spending
#> 107    NJ          finance     2022              state_aid_district_details
#> 108    NJ          finance     2022 taxpayers_guide_to_educational_spending
#> 109    NJ          finance     2023              state_aid_district_details
#> 110    NJ          finance     2023 taxpayers_guide_to_educational_spending
#> 111    NJ          finance     2024              state_aid_district_details
#> 112    NJ          finance     2024 taxpayers_guide_to_educational_spending
#> 113    NJ          finance     2025              state_aid_district_details
#> 114    NJ          finance     2026              state_aid_district_details
#> 115    NJ          finance     2027              state_aid_district_details
#> 116    NJ       graduation     2011 adjusted_cohort_graduation_rate_reports
#> 117    NJ       graduation     2012 adjusted_cohort_graduation_rate_reports
#> 118    NJ       graduation     2013 adjusted_cohort_graduation_rate_reports
#> 119    NJ       graduation     2014 adjusted_cohort_graduation_rate_reports
#> 120    NJ       graduation     2015 adjusted_cohort_graduation_rate_reports
#> 121    NJ       graduation     2016 adjusted_cohort_graduation_rate_reports
#> 122    NJ       graduation     2017 adjusted_cohort_graduation_rate_reports
#> 123    NJ       graduation     2018 adjusted_cohort_graduation_rate_reports
#> 124    NJ       graduation     2019 adjusted_cohort_graduation_rate_reports
#> 125    NJ       graduation     2020 adjusted_cohort_graduation_rate_reports
#> 126    NJ       graduation     2021 adjusted_cohort_graduation_rate_reports
#> 127    NJ       graduation     2022 adjusted_cohort_graduation_rate_reports
#> 128    NJ       graduation     2023 adjusted_cohort_graduation_rate_reports
#> 129    NJ       graduation     2024 adjusted_cohort_graduation_rate_reports
#> 130    NJ       graduation     2025 adjusted_cohort_graduation_rate_reports
#> 131    NJ             sped     2015  idea_618_district_classification_rates
#> 132    NJ             sped     2015      idea_618_public_reporting_archives
#> 133    NJ             sped     2016  idea_618_district_classification_rates
#> 134    NJ             sped     2016      idea_618_public_reporting_archives
#> 135    NJ             sped     2017  idea_618_district_classification_rates
#> 136    NJ             sped     2017      idea_618_public_reporting_archives
#> 137    NJ             sped     2018  idea_618_district_classification_rates
#> 138    NJ             sped     2018      idea_618_public_reporting_archives
#> 139    NJ             sped     2019      idea_618_public_reporting_archives
#> 140    NJ             sped     2020      idea_618_public_reporting_archives
#> 141    NJ             sped     2021      idea_618_public_reporting_archives
#> 142    NJ             sped     2022  idea_618_district_classification_rates
#> 143    NJ             sped     2023      idea_618_public_reporting_archives
#> 144    NJ             sped     2023       opra_response_iep_counts_by_grade
#> 145    NJ             sped     2024      idea_618_public_reporting_archives
#> 146    NJ             sped     2024       opra_response_iep_counts_by_grade
#> 147    NJ             sped     2025      idea_618_public_reporting_archives
#> 148    NJ             sped     2025       opra_response_iep_counts_by_grade
#> 149    NJ             sped     2026       opra_response_iep_counts_by_grade
#> 150    NJ sped_environment     2023            nj_sped_environment_snapshot
#> 151    NJ sped_environment     2024            nj_sped_environment_snapshot
#> 152    NJ sped_environment     2025            nj_sped_environment_snapshot
#> 154    NJ       sped_share     2023                  nj_sped_share_snapshot
#> 155    NJ       sped_share     2023       opra_response_iep_counts_by_grade
#> 156    NJ       sped_share     2024                  nj_sped_share_snapshot
#> 157    NJ       sped_share     2024       opra_response_iep_counts_by_grade
#> 158    NJ       sped_share     2025                  nj_sped_share_snapshot
#> 159    NJ       sped_share     2025       opra_response_iep_counts_by_grade
#> 160    NJ       sped_share     2026       opra_response_iep_counts_by_grade
#> 163    NJ        stability     2024                   nj_stability_snapshot
#> 164    NJ        stability     2025                   nj_stability_snapshot
#>     variant status mode                                                fetcher
#> 1      <NA> served live          fetch_absence; fetch_essa_chronic_absenteeism
#> 2      <NA> served live          fetch_absence; fetch_essa_chronic_absenteeism
#> 3      <NA> served live          fetch_absence; fetch_essa_chronic_absenteeism
#> 4      <NA> served live          fetch_absence; fetch_essa_chronic_absenteeism
#> 5      <NA> served live          fetch_absence; fetch_essa_chronic_absenteeism
#> 6      <NA> served live          fetch_absence; fetch_essa_chronic_absenteeism
#> 8      <NA> served live                                          fetch_absence
#> 9      <NA> served live          fetch_absence; fetch_essa_chronic_absenteeism
#> 10     <NA> served live          fetch_absence; fetch_essa_chronic_absenteeism
#> 11     <NA> served live          fetch_absence; fetch_essa_chronic_absenteeism
#> 12     <NA> served live          fetch_absence; fetch_essa_chronic_absenteeism
#> 13     <NA> served live          fetch_absence; fetch_essa_chronic_absenteeism
#> 14     <NA> served live          fetch_absence; fetch_essa_chronic_absenteeism
#> 15     <NA> served live                                          fetch_absence
#> 29     <NA> served live                                           fetch_access
#> 30     <NA> served live                                           fetch_access
#> 31     <NA> served live                                           fetch_access
#> 32     <NA> served live                                           fetch_access
#> 34     <NA> served live                                              fetch_ell
#> 35     <NA> served live                                              fetch_ell
#> 36     <NA> served live                                              fetch_ell
#> 37     <NA> served live                                              fetch_ell
#> 38     <NA> served live                                              fetch_ell
#> 39     <NA> served live                                              fetch_ell
#> 40     <NA> served live                                              fetch_ell
#> 41     <NA> served live                                              fetch_ell
#> 42     <NA> served live                                              fetch_ell
#> 43     <NA> served live                                              fetch_ell
#> 44     <NA> served live                                              fetch_ell
#> 45     <NA> served live                                              fetch_ell
#> 46     <NA> served live                                              fetch_ell
#> 47     <NA> served live                                              fetch_ell
#> 48     <NA> served live                                              fetch_ell
#> 49     <NA> served live                                              fetch_ell
#> 50     <NA> served live                                              fetch_ell
#> 51     <NA> served live                                              fetch_ell
#> 52     <NA> served live                                              fetch_ell
#> 53     <NA> served live                                              fetch_ell
#> 54     <NA> served live                                              fetch_ell
#> 55     <NA> served live                                              fetch_enr
#> 56     <NA> served live                                              fetch_enr
#> 57     <NA> served live                                              fetch_enr
#> 58     <NA> served live                                              fetch_enr
#> 59     <NA> served live                                              fetch_enr
#> 60     <NA> served live                                              fetch_enr
#> 61     <NA> served live                                              fetch_enr
#> 62     <NA> served live                                              fetch_enr
#> 63     <NA> served live                                              fetch_enr
#> 64     <NA> served live                                              fetch_enr
#> 65     <NA> served live                                              fetch_enr
#> 66     <NA> served live                                              fetch_enr
#> 67     <NA> served live                                              fetch_enr
#> 68     <NA> served live                                              fetch_enr
#> 69     <NA> served live                                              fetch_enr
#> 70     <NA> served live                                              fetch_enr
#> 71     <NA> served live                                              fetch_enr
#> 72     <NA> served live                                              fetch_enr
#> 73     <NA> served live                                              fetch_enr
#> 74     <NA> served live                                              fetch_enr
#> 75     <NA> served live                                              fetch_enr
#> 76     <NA> served live                                              fetch_enr
#> 77     <NA> served live                                              fetch_enr
#> 78     <NA> served live                                              fetch_enr
#> 79     <NA> served live                                              fetch_enr
#> 80     <NA> served live                                              fetch_enr
#> 81     <NA> served live                                              fetch_enr
#> 82     <NA> served live                                              fetch_enr
#> 83     <NA> served live                                          fetch_finance
#> 84     <NA> served live                                          fetch_finance
#> 85     <NA> served live                                          fetch_finance
#> 86     <NA> served live                                          fetch_finance
#> 87     <NA> served live                                          fetch_finance
#> 88     <NA> served live                                          fetch_finance
#> 89     <NA> served live                                          fetch_finance
#> 90     <NA> served live                                          fetch_finance
#> 91     <NA> served live                                          fetch_finance
#> 92     <NA> served live                                          fetch_finance
#> 93     <NA> served live                                          fetch_finance
#> 94     <NA> served live                                          fetch_finance
#> 95     <NA> served live                                          fetch_finance
#> 96     <NA> served live                                          fetch_finance
#> 97     <NA> served live                                          fetch_finance
#> 98     <NA> served live                                          fetch_finance
#> 99     <NA> served live                                          fetch_finance
#> 100    <NA> served live                                          fetch_finance
#> 101    <NA> served live                         fetch_finance; fetch_state_aid
#> 102    <NA> served live                         fetch_finance; fetch_state_aid
#> 103    <NA> served live                         fetch_finance; fetch_state_aid
#> 104    <NA> served live                         fetch_finance; fetch_state_aid
#> 105    <NA> served live                         fetch_finance; fetch_state_aid
#> 106    <NA> served live                         fetch_finance; fetch_state_aid
#> 107    <NA> served live                         fetch_finance; fetch_state_aid
#> 108    <NA> served live                         fetch_finance; fetch_state_aid
#> 109    <NA> served live                         fetch_finance; fetch_state_aid
#> 110    <NA> served live                         fetch_finance; fetch_state_aid
#> 111    <NA> served live                         fetch_finance; fetch_state_aid
#> 112    <NA> served live                         fetch_finance; fetch_state_aid
#> 113    <NA> served live                         fetch_finance; fetch_state_aid
#> 114    <NA> served live                         fetch_finance; fetch_state_aid
#> 115    <NA> served live                                        fetch_state_aid
#> 116    <NA> served live                                        fetch_grad_rate
#> 117    <NA> served live                      fetch_grad_count; fetch_grad_rate
#> 118    <NA> served live                      fetch_grad_count; fetch_grad_rate
#> 119    <NA> served live                      fetch_grad_count; fetch_grad_rate
#> 120    <NA> served live                      fetch_grad_count; fetch_grad_rate
#> 121    <NA> served live                      fetch_grad_count; fetch_grad_rate
#> 122    <NA> served live                      fetch_grad_count; fetch_grad_rate
#> 123    <NA> served live                      fetch_grad_count; fetch_grad_rate
#> 124    <NA> served live                      fetch_grad_count; fetch_grad_rate
#> 125    <NA> served live                      fetch_grad_count; fetch_grad_rate
#> 126    <NA> served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 127    <NA> served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 128    <NA> served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 129    <NA> served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 130    <NA> served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 131    <NA> served live                                             fetch_sped
#> 132    <NA> served live                                             fetch_sped
#> 133    <NA> served live                                             fetch_sped
#> 134    <NA> served live                                             fetch_sped
#> 135    <NA> served live                                             fetch_sped
#> 136    <NA> served live                                             fetch_sped
#> 137    <NA> served live                                             fetch_sped
#> 138    <NA> served live                                             fetch_sped
#> 139    <NA> served live                                             fetch_sped
#> 140    <NA> served live                                             fetch_sped
#> 141    <NA> served live                                             fetch_sped
#> 142    <NA> served live                        fetch_sped; fetch_sped_by_grade
#> 143    <NA> served live                        fetch_sped; fetch_sped_by_grade
#> 144    <NA> served live                        fetch_sped; fetch_sped_by_grade
#> 145    <NA> served live                        fetch_sped; fetch_sped_by_grade
#> 146    <NA> served live                        fetch_sped; fetch_sped_by_grade
#> 147    <NA> served live                        fetch_sped; fetch_sped_by_grade
#> 148    <NA> served live                        fetch_sped; fetch_sped_by_grade
#> 149    <NA> served live                                    fetch_sped_by_grade
#> 150    <NA> served live                                 fetch_sped_environment
#> 151    <NA> served live                                 fetch_sped_environment
#> 152    <NA> served live                                 fetch_sped_environment
#> 154    <NA> served live                                       fetch_sped_share
#> 155    <NA> served live                                       fetch_sped_share
#> 156    <NA> served live                                       fetch_sped_share
#> 157    <NA> served live                                       fetch_sped_share
#> 158    <NA> served live                                       fetch_sped_share
#> 159    <NA> served live                                       fetch_sped_share
#> 160    <NA> served live                                       fetch_sped_share
#> 163    <NA> served live                                        fetch_stability
#> 164    <NA> served live                                        fetch_stability
#>     n_source_files n_derived_files   bytes
#> 1                0               0       0
#> 2                0               0       0
#> 3                0               0       0
#> 4                0               0       0
#> 5                0               0       0
#> 6                0               0       0
#> 8                0               0       0
#> 9                0               0       0
#> 10               0               0       0
#> 11               0               0       0
#> 12               0               0       0
#> 13               0               0       0
#> 14               0               0       0
#> 15               0               0       0
#> 29               0               0       0
#> 30               0               0       0
#> 31               0               0       0
#> 32               0               0       0
#> 34               0               0       0
#> 35               0               0       0
#> 36               0               0       0
#> 37               0               0       0
#> 38               0               0       0
#> 39               0               0       0
#> 40               0               0       0
#> 41               0               0       0
#> 42               0               0       0
#> 43               0               0       0
#> 44               0               0       0
#> 45               0               0       0
#> 46               0               0       0
#> 47               0               0       0
#> 48               0               0       0
#> 49               0               0       0
#> 50               0               0       0
#> 51               0               0       0
#> 52               0               0       0
#> 53               0               0       0
#> 54               0               0       0
#> 55               1               0  465739
#> 56               1               0  536664
#> 57               1               0  446887
#> 58               1               0  485025
#> 59               1               0  459473
#> 60               1               0  537620
#> 61               1               0  456027
#> 62               1               0  459687
#> 63               1               0  481166
#> 64               1               0  569533
#> 65               1               0  575500
#> 66               1               0 1338684
#> 67               1               0 1095496
#> 68               1               0 2591290
#> 69               1               0 2578254
#> 70               1               0 2339971
#> 71               1               0 2616791
#> 72               1               0 2619194
#> 73               1               0 2627985
#> 74               1               0 2634898
#> 75               1               0 2678851
#> 76               1               0  763907
#> 77               1               0  733786
#> 78               1               0  734021
#> 79               1               0 1119856
#> 80               1               0 1061242
#> 81               1               0 1095121
#> 82               1               0 1061437
#> 83               1               0  572766
#> 84               1               0  585513
#> 85               1               0 1140308
#> 86               1               0 2259434
#> 87               1               0 2283208
#> 88               1               0 2294833
#> 89               1               0 1331465
#> 90               1               0 2325550
#> 91               1               0 2213595
#> 92               1               0 2358982
#> 93               1               0  590610
#> 94               1               0  649722
#> 95               1               0  599308
#> 96               1               0  593519
#> 97               1               0  802071
#> 98               1               0  804033
#> 99               1               0  810538
#> 100              1               0  970438
#> 101              1               0 1292364
#> 102              1               0 1040892
#> 103              1               0 1642279
#> 104              1               0 1343893
#> 105              1               0  921846
#> 106              1               0 1110723
#> 107              1               0 1867828
#> 108              1               0 1621328
#> 109              1               0 1760402
#> 110              1               0  871679
#> 111              1               0  961889
#> 112              1               0  772998
#> 113              1               0 1088273
#> 114              1               0   77477
#> 115              1               0   77136
#> 116              0               0       0
#> 117              2               0 1441280
#> 118              1               0  339427
#> 119              1               0  342473
#> 120              1               0  345650
#> 121              1               0  359302
#> 122              1               0  362336
#> 123              1               0  523505
#> 124              1               0  557043
#> 125              1               0  534643
#> 126              1               0  536015
#> 127              1               0  567385
#> 128              1               0  548651
#> 129              1               0  563820
#> 130              1               0  563176
#> 131              0               0       0
#> 132              0               0       0
#> 133              0               0       0
#> 134              0               0       0
#> 135              0               0       0
#> 136              0               0       0
#> 137              0               0       0
#> 138              0               0       0
#> 139              1               0 7937226
#> 140              1               0 5551373
#> 141              1               0 7510855
#> 142              1               0   91960
#> 143              0               0       0
#> 144              0               0       0
#> 145              0               0       0
#> 146              0               0       0
#> 147              0               0       0
#> 148              0               0       0
#> 149              0               0       0
#> 150              0               0       0
#> 151              0               0       0
#> 152              0               0       0
#> 154              0               0       0
#> 155              0               0       0
#> 156              0               0       0
#> 157              0               0       0
#> 158              0               0       0
#> 159              0               0       0
#> 160              0               0       0
#> 163              0               0       0
#> 164              0               0       0
#>                                                                                                                           source_url
#> 1                                                                                                                               <NA>
#> 2                                                                                                                               <NA>
#> 3                                                                                                                               <NA>
#> 4                                                                                                                               <NA>
#> 5                                                                                                                               <NA>
#> 6                                                                                                                               <NA>
#> 8                                                                                                                               <NA>
#> 9                                                                                                                               <NA>
#> 10                                                                                                                              <NA>
#> 11                                                                                                                              <NA>
#> 12                                                                                                                              <NA>
#> 13                                                                                                                              <NA>
#> 14                                                                                                                              <NA>
#> 15                                                                                                                              <NA>
#> 29                                                                                                                              <NA>
#> 30                                                                                                                              <NA>
#> 31                                                                                                                              <NA>
#> 32                                                                                                                              <NA>
#> 34                                                                                                                              <NA>
#> 35                                                                                                                              <NA>
#> 36                                                                                                                              <NA>
#> 37                                                                                                                              <NA>
#> 38                                                                                                                              <NA>
#> 39                                                                                                                              <NA>
#> 40                                                                                                                              <NA>
#> 41                                                                                                                              <NA>
#> 42                                                                                                                              <NA>
#> 43                                                                                                                              <NA>
#> 44                                                                                                                              <NA>
#> 45                                                                                                                              <NA>
#> 46                                                                                                                              <NA>
#> 47                                                                                                                              <NA>
#> 48                                                                                                                              <NA>
#> 49                                                                                                                              <NA>
#> 50                                                                                                                              <NA>
#> 51                                                                                                                              <NA>
#> 52                                                                                                                              <NA>
#> 53                                                                                                                              <NA>
#> 54                                                                                                                              <NA>
#> 55                                                                https://www.nj.gov/education/doedata/enr/enr99/enrollment_9899.zip
#> 56                                                                https://www.nj.gov/education/doedata/enr/enr00/enrollment_9900.zip
#> 57                                                                https://www.nj.gov/education/doedata/enr/enr01/enrollment_0001.zip
#> 58                                                                https://www.nj.gov/education/doedata/enr/enr02/enrollment_0102.zip
#> 59                                                                https://www.nj.gov/education/doedata/enr/enr03/enrollment_0203.zip
#> 60                                                                https://www.nj.gov/education/doedata/enr/enr04/enrollment_0304.zip
#> 61                                                                https://www.nj.gov/education/doedata/enr/enr05/enrollment_0405.zip
#> 62                                                                https://www.nj.gov/education/doedata/enr/enr06/enrollment_0506.zip
#> 63                                                                https://www.nj.gov/education/doedata/enr/enr07/enrollment_0607.zip
#> 64                                                                https://www.nj.gov/education/doedata/enr/enr08/enrollment_0708.zip
#> 65                                                                https://www.nj.gov/education/doedata/enr/enr09/enrollment_0809.zip
#> 66                                                                https://www.nj.gov/education/doedata/enr/enr10/enrollment_0910.zip
#> 67                                                                https://www.nj.gov/education/doedata/enr/enr11/enrollment_1011.zip
#> 68                                                                https://www.nj.gov/education/doedata/enr/enr12/enrollment_1112.zip
#> 69                                                                https://www.nj.gov/education/doedata/enr/enr13/enrollment_1213.zip
#> 70                                                                https://www.nj.gov/education/doedata/enr/enr14/enrollment_1314.zip
#> 71                                                                https://www.nj.gov/education/doedata/enr/enr15/enrollment_1415.zip
#> 72                                                                https://www.nj.gov/education/doedata/enr/enr16/enrollment_1516.zip
#> 73                                                                https://www.nj.gov/education/doedata/enr/enr17/enrollment_1617.zip
#> 74                                                                https://www.nj.gov/education/doedata/enr/enr18/enrollment_1718.zip
#> 75                                                                https://www.nj.gov/education/doedata/enr/enr19/enrollment_1819.zip
#> 76                                                                https://www.nj.gov/education/doedata/enr/enr20/enrollment_1920.zip
#> 77                                                                https://www.nj.gov/education/doedata/enr/enr21/enrollment_2021.zip
#> 78                                                                https://www.nj.gov/education/doedata/enr/enr22/enrollment_2122.zip
#> 79                                                                https://www.nj.gov/education/doedata/enr/enr23/enrollment_2223.zip
#> 80                                                                https://www.nj.gov/education/doedata/enr/enr24/enrollment_2324.zip
#> 81                                                                https://www.nj.gov/education/doedata/enr/enr25/enrollment_2425.zip
#> 82                                                                https://www.nj.gov/education/doedata/enr/enr26/Enrollment_2526.zip
#> 83                                                                              https://www.nj.gov/education/guide/docs/2001_CSG.zip
#> 84                                                                              https://www.nj.gov/education/guide/docs/2002_CSG.zip
#> 85                                                                              https://www.nj.gov/education/guide/docs/2003_CSG.zip
#> 86                                                                              https://www.nj.gov/education/guide/docs/2004_CSG.zip
#> 87                                                                              https://www.nj.gov/education/guide/docs/2005_CSG.zip
#> 88                                                                              https://www.nj.gov/education/guide/docs/2006_CSG.zip
#> 89                                                                              https://www.nj.gov/education/guide/docs/2007_CSG.zip
#> 90                                                                              https://www.nj.gov/education/guide/docs/2008_CSG.zip
#> 91                                                                              https://www.nj.gov/education/guide/docs/2009_CSG.zip
#> 92                                                                              https://www.nj.gov/education/guide/docs/2010_CSG.zip
#> 93                                                                             https://www.nj.gov/education/guide/docs/2011_TGES.zip
#> 94                                                                             https://www.nj.gov/education/guide/docs/2012_TGES.zip
#> 95                                                                             https://www.nj.gov/education/guide/docs/2013_TGES.zip
#> 96                                                                             https://www.nj.gov/education/guide/docs/2014_TGES.zip
#> 97                                                                             https://www.nj.gov/education/guide/docs/2015_TGES.zip
#> 98                                                                             https://www.nj.gov/education/guide/docs/2016_TGES.zip
#> 99                                                                             https://www.nj.gov/education/guide/docs/2017_TGES.zip
#> 100                                                                            https://www.nj.gov/education/guide/docs/2018_TGES.zip
#> 101                                                                       https://www.nj.gov/education/stateaid/zippedfiles/1819.zip
#> 102                                                                            https://www.nj.gov/education/guide/docs/2019_TGES.zip
#> 103                                                                       https://www.nj.gov/education/stateaid/zippedfiles/1920.zip
#> 104                                                                            https://www.nj.gov/education/guide/docs/2020_TGES.zip
#> 105                                                                       https://www.nj.gov/education/stateaid/zippedfiles/2021.zip
#> 106                                                                            https://www.nj.gov/education/guide/docs/2021_TGES.zip
#> 107                                                                       https://www.nj.gov/education/stateaid/zippedfiles/2122.zip
#> 108                                                                            https://www.nj.gov/education/guide/docs/2022_TGES.zip
#> 109                                                                       https://www.nj.gov/education/stateaid/zippedfiles/2223.zip
#> 110                                                                            https://www.nj.gov/education/guide/docs/2023_TGES.zip
#> 111                                                                       https://www.nj.gov/education/stateaid/zippedfiles/2324.zip
#> 112                                                                   https://www.nj.gov/education/guide/docs/2024/TGES24_Zipped.zip
#> 113                                                                       https://www.nj.gov/education/stateaid/zippedfiles/2425.zip
#> 114                                                        https://www.nj.gov/education/stateaid/2526/FY26_GBM_District_Details.xlsx
#> 115                                                        https://www.nj.gov/education/stateaid/2627/FY27_GBM_District_Details.xlsx
#> 116                                                                                                                             <NA>
#> 117                                                      https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2012_gradrate.xls
#> 118                                                        https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2013_4Year.xlsx
#> 119                                                        https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2014_4Year.xlsx
#> 120                                                        https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2015_4Year.xlsx
#> 121                                                        https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2016_4Year.xlsx
#> 122                                                        https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2017_4Year.xlsx
#> 123                                              https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2018_4YearGraduation.xlsx
#> 124 https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2019_Cohort2019_4-YearAdjustedCohortGraduationRatesByStudentGroup.xlsx
#> 125  https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2020_4YearAdjustedCohortGraduationRatesandCountsbyStudentGroup.xlsx
#> 126  https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2021_4YearAdjustedCohortGraduationRatesandCountsbyStudentGroup.xlsx
#> 127  https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2022_4YearAdjustedCohortGraduationRatesandCountsbyStudentGroup.xlsx
#> 128           https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2023_4YearAdjustedCohortGraduationRatesbyStudentGroup.xlsx
#> 129           https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2024_4YearAdjustedCohortGraduationRatesbyStudentGroup.xlsx
#> 130           https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2025_4YearAdjustedCohortGraduationRatesbyStudentGroup.xlsx
#> 131                                                                                                                             <NA>
#> 132                                                                                                                             <NA>
#> 133                                                                                                                             <NA>
#> 134                                                                                                                             <NA>
#> 135                                                                                                                             <NA>
#> 136                                                                                                                             <NA>
#> 137                                                                                                                             <NA>
#> 138                                                                                                                             <NA>
#> 139                                                      https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2018.zip
#> 140                                                      https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2019.zip
#> 141                                                      https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2020.zip
#> 142                       https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2022%20data/Lea_Classification_Pub.xlsx
#> 143                                                                                                                             <NA>
#> 144                                                                                                                             <NA>
#> 145                                                                                                                             <NA>
#> 146                                                                                                                             <NA>
#> 147                                                                                                                             <NA>
#> 148                                                                                                                             <NA>
#> 149                                                                                                                             <NA>
#> 150                                                                                                                             <NA>
#> 151                                                                                                                             <NA>
#> 152                                                                                                                             <NA>
#> 154                                                                                                                             <NA>
#> 155                                                                                                                             <NA>
#> 156                                                                                                                             <NA>
#> 157                                                                                                                             <NA>
#> 158                                                                                                                             <NA>
#> 159                                                                                                                             <NA>
#> 160                                                                                                                             <NA>
#> 163                                                                                                                             <NA>
#> 164                                                                                                                             <NA>
#>                              publisher publisher_type
#> 1   New Jersey Department of Education      state_doe
#> 2   New Jersey Department of Education      state_doe
#> 3   New Jersey Department of Education      state_doe
#> 4   New Jersey Department of Education      state_doe
#> 5   New Jersey Department of Education      state_doe
#> 6   New Jersey Department of Education      state_doe
#> 8   New Jersey Department of Education      state_doe
#> 9   New Jersey Department of Education      state_doe
#> 10  New Jersey Department of Education      state_doe
#> 11  New Jersey Department of Education      state_doe
#> 12  New Jersey Department of Education      state_doe
#> 13  New Jersey Department of Education      state_doe
#> 14  New Jersey Department of Education      state_doe
#> 15  New Jersey Department of Education      state_doe
#> 29  New Jersey Department of Education      state_doe
#> 30  New Jersey Department of Education      state_doe
#> 31  New Jersey Department of Education      state_doe
#> 32  New Jersey Department of Education      state_doe
#> 34  New Jersey Department of Education      state_doe
#> 35  New Jersey Department of Education      state_doe
#> 36  New Jersey Department of Education      state_doe
#> 37  New Jersey Department of Education      state_doe
#> 38  New Jersey Department of Education      state_doe
#> 39  New Jersey Department of Education      state_doe
#> 40  New Jersey Department of Education      state_doe
#> 41  New Jersey Department of Education      state_doe
#> 42  New Jersey Department of Education      state_doe
#> 43  New Jersey Department of Education      state_doe
#> 44  New Jersey Department of Education      state_doe
#> 45  New Jersey Department of Education      state_doe
#> 46  New Jersey Department of Education      state_doe
#> 47  New Jersey Department of Education      state_doe
#> 48  New Jersey Department of Education      state_doe
#> 49  New Jersey Department of Education      state_doe
#> 50  New Jersey Department of Education      state_doe
#> 51  New Jersey Department of Education      state_doe
#> 52  New Jersey Department of Education      state_doe
#> 53  New Jersey Department of Education      state_doe
#> 54  New Jersey Department of Education      state_doe
#> 55  New Jersey Department of Education      state_doe
#> 56  New Jersey Department of Education      state_doe
#> 57  New Jersey Department of Education      state_doe
#> 58  New Jersey Department of Education      state_doe
#> 59  New Jersey Department of Education      state_doe
#> 60  New Jersey Department of Education      state_doe
#> 61  New Jersey Department of Education      state_doe
#> 62  New Jersey Department of Education      state_doe
#> 63  New Jersey Department of Education      state_doe
#> 64  New Jersey Department of Education      state_doe
#> 65  New Jersey Department of Education      state_doe
#> 66  New Jersey Department of Education      state_doe
#> 67  New Jersey Department of Education      state_doe
#> 68  New Jersey Department of Education      state_doe
#> 69  New Jersey Department of Education      state_doe
#> 70  New Jersey Department of Education      state_doe
#> 71  New Jersey Department of Education      state_doe
#> 72  New Jersey Department of Education      state_doe
#> 73  New Jersey Department of Education      state_doe
#> 74  New Jersey Department of Education      state_doe
#> 75  New Jersey Department of Education      state_doe
#> 76  New Jersey Department of Education      state_doe
#> 77  New Jersey Department of Education      state_doe
#> 78  New Jersey Department of Education      state_doe
#> 79  New Jersey Department of Education      state_doe
#> 80  New Jersey Department of Education      state_doe
#> 81  New Jersey Department of Education      state_doe
#> 82  New Jersey Department of Education      state_doe
#> 83  New Jersey Department of Education      state_doe
#> 84  New Jersey Department of Education      state_doe
#> 85  New Jersey Department of Education      state_doe
#> 86  New Jersey Department of Education      state_doe
#> 87  New Jersey Department of Education      state_doe
#> 88  New Jersey Department of Education      state_doe
#> 89  New Jersey Department of Education      state_doe
#> 90  New Jersey Department of Education      state_doe
#> 91  New Jersey Department of Education      state_doe
#> 92  New Jersey Department of Education      state_doe
#> 93  New Jersey Department of Education      state_doe
#> 94  New Jersey Department of Education      state_doe
#> 95  New Jersey Department of Education      state_doe
#> 96  New Jersey Department of Education      state_doe
#> 97  New Jersey Department of Education      state_doe
#> 98  New Jersey Department of Education      state_doe
#> 99  New Jersey Department of Education      state_doe
#> 100 New Jersey Department of Education      state_doe
#> 101 New Jersey Department of Education      state_doe
#> 102 New Jersey Department of Education      state_doe
#> 103 New Jersey Department of Education      state_doe
#> 104 New Jersey Department of Education      state_doe
#> 105 New Jersey Department of Education      state_doe
#> 106 New Jersey Department of Education      state_doe
#> 107 New Jersey Department of Education      state_doe
#> 108 New Jersey Department of Education      state_doe
#> 109 New Jersey Department of Education      state_doe
#> 110 New Jersey Department of Education      state_doe
#> 111 New Jersey Department of Education      state_doe
#> 112 New Jersey Department of Education      state_doe
#> 113 New Jersey Department of Education      state_doe
#> 114 New Jersey Department of Education      state_doe
#> 115 New Jersey Department of Education      state_doe
#> 116 New Jersey Department of Education      state_doe
#> 117 New Jersey Department of Education      state_doe
#> 118 New Jersey Department of Education      state_doe
#> 119 New Jersey Department of Education      state_doe
#> 120 New Jersey Department of Education      state_doe
#> 121 New Jersey Department of Education      state_doe
#> 122 New Jersey Department of Education      state_doe
#> 123 New Jersey Department of Education      state_doe
#> 124 New Jersey Department of Education      state_doe
#> 125 New Jersey Department of Education      state_doe
#> 126 New Jersey Department of Education      state_doe
#> 127 New Jersey Department of Education      state_doe
#> 128 New Jersey Department of Education      state_doe
#> 129 New Jersey Department of Education      state_doe
#> 130 New Jersey Department of Education      state_doe
#> 131 New Jersey Department of Education      state_doe
#> 132 New Jersey Department of Education      state_doe
#> 133 New Jersey Department of Education      state_doe
#> 134 New Jersey Department of Education      state_doe
#> 135 New Jersey Department of Education      state_doe
#> 136 New Jersey Department of Education      state_doe
#> 137 New Jersey Department of Education      state_doe
#> 138 New Jersey Department of Education      state_doe
#> 139 New Jersey Department of Education      state_doe
#> 140 New Jersey Department of Education      state_doe
#> 141 New Jersey Department of Education      state_doe
#> 142 New Jersey Department of Education      state_doe
#> 143 New Jersey Department of Education      state_doe
#> 144 New Jersey Department of Education      state_doe
#> 145 New Jersey Department of Education      state_doe
#> 146 New Jersey Department of Education      state_doe
#> 147 New Jersey Department of Education      state_doe
#> 148 New Jersey Department of Education      state_doe
#> 149 New Jersey Department of Education      state_doe
#> 150 New Jersey Department of Education      state_doe
#> 151 New Jersey Department of Education      state_doe
#> 152 New Jersey Department of Education      state_doe
#> 154 New Jersey Department of Education      state_doe
#> 155 New Jersey Department of Education      state_doe
#> 156 New Jersey Department of Education      state_doe
#> 157 New Jersey Department of Education      state_doe
#> 158 New Jersey Department of Education      state_doe
#> 159 New Jersey Department of Education      state_doe
#> 160 New Jersey Department of Education      state_doe
#> 163 New Jersey Department of Education      state_doe
#> 164 New Jersey Department of Education      state_doe
#>                                                                         title
#> 1   ESSA accountability workbook files, Comprehensive Support and Improvement
#> 2        School Performance Reports downloadable data, school detail database
#> 3   ESSA accountability workbook files, Comprehensive Support and Improvement
#> 4        School Performance Reports downloadable data, school detail database
#> 5   ESSA accountability workbook files, Comprehensive Support and Improvement
#> 6        School Performance Reports downloadable data, school detail database
#> 8        School Performance Reports downloadable data, school detail database
#> 9   ESSA accountability workbook files, Comprehensive Support and Improvement
#> 10       School Performance Reports downloadable data, school detail database
#> 11  ESSA accountability workbook files, Comprehensive Support and Improvement
#> 12       School Performance Reports downloadable data, school detail database
#> 13  ESSA accountability workbook files, Comprehensive Support and Improvement
#> 14       School Performance Reports downloadable data, school detail database
#> 15       School Performance Reports downloadable data, school detail database
#> 29                                         ACCESS for ELLs results data files
#> 30                                         ACCESS for ELLs results data files
#> 31                                         ACCESS for ELLs results data files
#> 32                                         ACCESS for ELLs results data files
#> 34                                                    Fall Enrollment Reports
#> 35                                                    Fall Enrollment Reports
#> 36                                                    Fall Enrollment Reports
#> 37                                                    Fall Enrollment Reports
#> 38                                                    Fall Enrollment Reports
#> 39                                                    Fall Enrollment Reports
#> 40                                                    Fall Enrollment Reports
#> 41                                                    Fall Enrollment Reports
#> 42                                                    Fall Enrollment Reports
#> 43                                                    Fall Enrollment Reports
#> 44                                                    Fall Enrollment Reports
#> 45                                                    Fall Enrollment Reports
#> 46                                                    Fall Enrollment Reports
#> 47                                                    Fall Enrollment Reports
#> 48                                                    Fall Enrollment Reports
#> 49                                                    Fall Enrollment Reports
#> 50                                                    Fall Enrollment Reports
#> 51                                                    Fall Enrollment Reports
#> 52                                                    Fall Enrollment Reports
#> 53                                                    Fall Enrollment Reports
#> 54                                                    Fall Enrollment Reports
#> 55                                                    Fall Enrollment Reports
#> 56                                                    Fall Enrollment Reports
#> 57                                                    Fall Enrollment Reports
#> 58                                                    Fall Enrollment Reports
#> 59                                                    Fall Enrollment Reports
#> 60                                                    Fall Enrollment Reports
#> 61                                                    Fall Enrollment Reports
#> 62                                                    Fall Enrollment Reports
#> 63                                                    Fall Enrollment Reports
#> 64                                                    Fall Enrollment Reports
#> 65                                                    Fall Enrollment Reports
#> 66                                                    Fall Enrollment Reports
#> 67                                                    Fall Enrollment Reports
#> 68                                                    Fall Enrollment Reports
#> 69                                                    Fall Enrollment Reports
#> 70                                                    Fall Enrollment Reports
#> 71                                                    Fall Enrollment Reports
#> 72                                                    Fall Enrollment Reports
#> 73                                                    Fall Enrollment Reports
#> 74                                                    Fall Enrollment Reports
#> 75                                                    Fall Enrollment Reports
#> 76                                                    Fall Enrollment Reports
#> 77                                                    Fall Enrollment Reports
#> 78                                                    Fall Enrollment Reports
#> 79                                                    Fall Enrollment Reports
#> 80                                                    Fall Enrollment Reports
#> 81                                                    Fall Enrollment Reports
#> 82                                                    Fall Enrollment Reports
#> 83                                   Taxpayers' Guide to Educational Spending
#> 84                                   Taxpayers' Guide to Educational Spending
#> 85                                   Taxpayers' Guide to Educational Spending
#> 86                                   Taxpayers' Guide to Educational Spending
#> 87                                   Taxpayers' Guide to Educational Spending
#> 88                                   Taxpayers' Guide to Educational Spending
#> 89                                   Taxpayers' Guide to Educational Spending
#> 90                                   Taxpayers' Guide to Educational Spending
#> 91                                   Taxpayers' Guide to Educational Spending
#> 92                                   Taxpayers' Guide to Educational Spending
#> 93                                   Taxpayers' Guide to Educational Spending
#> 94                                   Taxpayers' Guide to Educational Spending
#> 95                                   Taxpayers' Guide to Educational Spending
#> 96                                   Taxpayers' Guide to Educational Spending
#> 97                                   Taxpayers' Guide to Educational Spending
#> 98                                   Taxpayers' Guide to Educational Spending
#> 99                                   Taxpayers' Guide to Educational Spending
#> 100                                  Taxpayers' Guide to Educational Spending
#> 101                            State aid summaries, district details workbook
#> 102                                  Taxpayers' Guide to Educational Spending
#> 103                            State aid summaries, district details workbook
#> 104                                  Taxpayers' Guide to Educational Spending
#> 105                            State aid summaries, district details workbook
#> 106                                  Taxpayers' Guide to Educational Spending
#> 107                            State aid summaries, district details workbook
#> 108                                  Taxpayers' Guide to Educational Spending
#> 109                            State aid summaries, district details workbook
#> 110                                  Taxpayers' Guide to Educational Spending
#> 111                            State aid summaries, district details workbook
#> 112                                  Taxpayers' Guide to Educational Spending
#> 113                            State aid summaries, district details workbook
#> 114                            State aid summaries, district details workbook
#> 115                            State aid summaries, district details workbook
#> 116                                   Adjusted Cohort Graduation Rate Reports
#> 117                                   Adjusted Cohort Graduation Rate Reports
#> 118                                   Adjusted Cohort Graduation Rate Reports
#> 119                                   Adjusted Cohort Graduation Rate Reports
#> 120                                   Adjusted Cohort Graduation Rate Reports
#> 121                                   Adjusted Cohort Graduation Rate Reports
#> 122                                   Adjusted Cohort Graduation Rate Reports
#> 123                                   Adjusted Cohort Graduation Rate Reports
#> 124                                   Adjusted Cohort Graduation Rate Reports
#> 125                                   Adjusted Cohort Graduation Rate Reports
#> 126                                   Adjusted Cohort Graduation Rate Reports
#> 127                                   Adjusted Cohort Graduation Rate Reports
#> 128                                   Adjusted Cohort Graduation Rate Reports
#> 129                                   Adjusted Cohort Graduation Rate Reports
#> 130                                   Adjusted Cohort Graduation Rate Reports
#> 131               IDEA Part B public reporting, district classification rates
#> 132                         IDEA Part B public reporting, yearly archive zips
#> 133               IDEA Part B public reporting, district classification rates
#> 134                         IDEA Part B public reporting, yearly archive zips
#> 135               IDEA Part B public reporting, district classification rates
#> 136                         IDEA Part B public reporting, yearly archive zips
#> 137               IDEA Part B public reporting, district classification rates
#> 138                         IDEA Part B public reporting, yearly archive zips
#> 139                         IDEA Part B public reporting, yearly archive zips
#> 140                         IDEA Part B public reporting, yearly archive zips
#> 141                         IDEA Part B public reporting, yearly archive zips
#> 142               IDEA Part B public reporting, district classification rates
#> 143                         IDEA Part B public reporting, yearly archive zips
#> 144 Response to OPRA request C255254, active IEP counts by district and grade
#> 145                         IDEA Part B public reporting, yearly archive zips
#> 146 Response to OPRA request C255254, active IEP counts by district and grade
#> 147                         IDEA Part B public reporting, yearly archive zips
#> 148 Response to OPRA request C255254, active IEP counts by district and grade
#> 149 Response to OPRA request C255254, active IEP counts by district and grade
#> 150                                   Local Special Education Profiles IND_5C
#> 151                                   Local Special Education Profiles IND_5C
#> 152                                   Local Special Education Profiles IND_5C
#> 154                 School Performance Reports EnrollmentTrendsByStudentGroup
#> 155 Response to OPRA request C255254, active IEP counts by district and grade
#> 156                 School Performance Reports EnrollmentTrendsByStudentGroup
#> 157 Response to OPRA request C255254, active IEP counts by district and grade
#> 158                 School Performance Reports EnrollmentTrendsByStudentGroup
#> 159 Response to OPRA request C255254, active IEP counts by district and grade
#> 160 Response to OPRA request C255254, active IEP counts by district and grade
#> 163               School Performance Reports six-year high school persistence
#> 164               School Performance Reports six-year high school persistence
#>          year_basis
#> 1   school_year_end
#> 2   school_year_end
#> 3   school_year_end
#> 4   school_year_end
#> 5   school_year_end
#> 6   school_year_end
#> 8   school_year_end
#> 9   school_year_end
#> 10  school_year_end
#> 11  school_year_end
#> 12  school_year_end
#> 13  school_year_end
#> 14  school_year_end
#> 15  school_year_end
#> 29  school_year_end
#> 30  school_year_end
#> 31  school_year_end
#> 32  school_year_end
#> 34  school_year_end
#> 35  school_year_end
#> 36  school_year_end
#> 37  school_year_end
#> 38  school_year_end
#> 39  school_year_end
#> 40  school_year_end
#> 41  school_year_end
#> 42  school_year_end
#> 43  school_year_end
#> 44  school_year_end
#> 45  school_year_end
#> 46  school_year_end
#> 47  school_year_end
#> 48  school_year_end
#> 49  school_year_end
#> 50  school_year_end
#> 51  school_year_end
#> 52  school_year_end
#> 53  school_year_end
#> 54  school_year_end
#> 55  school_year_end
#> 56  school_year_end
#> 57  school_year_end
#> 58  school_year_end
#> 59  school_year_end
#> 60  school_year_end
#> 61  school_year_end
#> 62  school_year_end
#> 63  school_year_end
#> 64  school_year_end
#> 65  school_year_end
#> 66  school_year_end
#> 67  school_year_end
#> 68  school_year_end
#> 69  school_year_end
#> 70  school_year_end
#> 71  school_year_end
#> 72  school_year_end
#> 73  school_year_end
#> 74  school_year_end
#> 75  school_year_end
#> 76  school_year_end
#> 77  school_year_end
#> 78  school_year_end
#> 79  school_year_end
#> 80  school_year_end
#> 81  school_year_end
#> 82  school_year_end
#> 83      fiscal_year
#> 84      fiscal_year
#> 85      fiscal_year
#> 86      fiscal_year
#> 87      fiscal_year
#> 88      fiscal_year
#> 89      fiscal_year
#> 90      fiscal_year
#> 91      fiscal_year
#> 92      fiscal_year
#> 93      fiscal_year
#> 94      fiscal_year
#> 95      fiscal_year
#> 96      fiscal_year
#> 97      fiscal_year
#> 98      fiscal_year
#> 99      fiscal_year
#> 100     fiscal_year
#> 101     fiscal_year
#> 102     fiscal_year
#> 103     fiscal_year
#> 104     fiscal_year
#> 105     fiscal_year
#> 106     fiscal_year
#> 107     fiscal_year
#> 108     fiscal_year
#> 109     fiscal_year
#> 110     fiscal_year
#> 111     fiscal_year
#> 112     fiscal_year
#> 113     fiscal_year
#> 114     fiscal_year
#> 115     fiscal_year
#> 116     cohort_year
#> 117     cohort_year
#> 118     cohort_year
#> 119     cohort_year
#> 120     cohort_year
#> 121     cohort_year
#> 122     cohort_year
#> 123     cohort_year
#> 124     cohort_year
#> 125     cohort_year
#> 126     cohort_year
#> 127     cohort_year
#> 128     cohort_year
#> 129     cohort_year
#> 130     cohort_year
#> 131 school_year_end
#> 132 school_year_end
#> 133 school_year_end
#> 134 school_year_end
#> 135 school_year_end
#> 136 school_year_end
#> 137 school_year_end
#> 138 school_year_end
#> 139 school_year_end
#> 140 school_year_end
#> 141 school_year_end
#> 142 school_year_end
#> 143 school_year_end
#> 144 school_year_end
#> 145 school_year_end
#> 146 school_year_end
#> 147 school_year_end
#> 148 school_year_end
#> 149 school_year_end
#> 150 school_year_end
#> 151 school_year_end
#> 152 school_year_end
#> 154 school_year_end
#> 155 school_year_end
#> 156 school_year_end
#> 157 school_year_end
#> 158 school_year_end
#> 159 school_year_end
#> 160 school_year_end
#> 163 school_year_end
#> 164 school_year_end
#>                                                          landing_url reason
#> 1                https://www.nj.gov/education/title1/accountability/   <NA>
#> 2                         https://www.nj.gov/education/spr/download/   <NA>
#> 3                https://www.nj.gov/education/title1/accountability/   <NA>
#> 4                         https://www.nj.gov/education/spr/download/   <NA>
#> 5                https://www.nj.gov/education/title1/accountability/   <NA>
#> 6                         https://www.nj.gov/education/spr/download/   <NA>
#> 8                         https://www.nj.gov/education/spr/download/   <NA>
#> 9                https://www.nj.gov/education/title1/accountability/   <NA>
#> 10                        https://www.nj.gov/education/spr/download/   <NA>
#> 11               https://www.nj.gov/education/title1/accountability/   <NA>
#> 12                        https://www.nj.gov/education/spr/download/   <NA>
#> 13               https://www.nj.gov/education/title1/accountability/   <NA>
#> 14                        https://www.nj.gov/education/spr/download/   <NA>
#> 15                        https://www.nj.gov/education/spr/download/   <NA>
#> 29          https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 30          https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 31          https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 32          https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 34                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 35                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 36                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 37                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 38                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 39                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 40                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 41                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 42                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 43                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 44                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 45                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 46                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 47                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 48                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 49                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 50                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 51                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 52                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 53                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 54                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 55                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 56                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 57                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 58                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 59                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 60                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 61                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 62                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 63                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 64                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 65                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 66                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 67                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 68                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 69                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 70                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 71                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 72                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 73                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 74                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 75                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 76                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 77                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 78                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 79                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 80                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 81                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 82                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 83                               https://www.nj.gov/education/guide/   <NA>
#> 84                               https://www.nj.gov/education/guide/   <NA>
#> 85                               https://www.nj.gov/education/guide/   <NA>
#> 86                               https://www.nj.gov/education/guide/   <NA>
#> 87                               https://www.nj.gov/education/guide/   <NA>
#> 88                               https://www.nj.gov/education/guide/   <NA>
#> 89                               https://www.nj.gov/education/guide/   <NA>
#> 90                               https://www.nj.gov/education/guide/   <NA>
#> 91                               https://www.nj.gov/education/guide/   <NA>
#> 92                               https://www.nj.gov/education/guide/   <NA>
#> 93                               https://www.nj.gov/education/guide/   <NA>
#> 94                               https://www.nj.gov/education/guide/   <NA>
#> 95                               https://www.nj.gov/education/guide/   <NA>
#> 96                               https://www.nj.gov/education/guide/   <NA>
#> 97                               https://www.nj.gov/education/guide/   <NA>
#> 98                               https://www.nj.gov/education/guide/   <NA>
#> 99                               https://www.nj.gov/education/guide/   <NA>
#> 100                              https://www.nj.gov/education/guide/   <NA>
#> 101                           https://www.nj.gov/education/stateaid/   <NA>
#> 102                              https://www.nj.gov/education/guide/   <NA>
#> 103                           https://www.nj.gov/education/stateaid/   <NA>
#> 104                              https://www.nj.gov/education/guide/   <NA>
#> 105                           https://www.nj.gov/education/stateaid/   <NA>
#> 106                              https://www.nj.gov/education/guide/   <NA>
#> 107                           https://www.nj.gov/education/stateaid/   <NA>
#> 108                              https://www.nj.gov/education/guide/   <NA>
#> 109                           https://www.nj.gov/education/stateaid/   <NA>
#> 110                              https://www.nj.gov/education/guide/   <NA>
#> 111                           https://www.nj.gov/education/stateaid/   <NA>
#> 112                              https://www.nj.gov/education/guide/   <NA>
#> 113                           https://www.nj.gov/education/stateaid/   <NA>
#> 114                           https://www.nj.gov/education/stateaid/   <NA>
#> 115                           https://www.nj.gov/education/stateaid/   <NA>
#> 116                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 117                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 118                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 119                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 120                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 121                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 122                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 123                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 124                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 125                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 126                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 127                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 128                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 129                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 130                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 131   https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 132                                                             <NA>   <NA>
#> 133   https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 134                                                             <NA>   <NA>
#> 135   https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 136                                                             <NA>   <NA>
#> 137   https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 138                                                             <NA>   <NA>
#> 139                                                             <NA>   <NA>
#> 140                                                             <NA>   <NA>
#> 141                                                             <NA>   <NA>
#> 142   https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 143                                                             <NA>   <NA>
#> 144                                                             <NA>   <NA>
#> 145                                                             <NA>   <NA>
#> 146                                                             <NA>   <NA>
#> 147                                                             <NA>   <NA>
#> 148                                                             <NA>   <NA>
#> 149                                                             <NA>   <NA>
#> 150 https://www.nj.gov/education/specialed/monitor/dataandresources/   <NA>
#> 151 https://www.nj.gov/education/specialed/monitor/dataandresources/   <NA>
#> 152 https://www.nj.gov/education/specialed/monitor/dataandresources/   <NA>
#> 154                       https://www.nj.gov/education/spr/download/   <NA>
#> 155                                                             <NA>   <NA>
#> 156                       https://www.nj.gov/education/spr/download/   <NA>
#> 157                                                             <NA>   <NA>
#> 158                       https://www.nj.gov/education/spr/download/   <NA>
#> 159                                                             <NA>   <NA>
#> 160                                                             <NA>   <NA>
#> 163                       https://www.nj.gov/education/spr/download/   <NA>
#> 164                       https://www.nj.gov/education/spr/download/   <NA>
#>     evidence checked_on
#> 1       <NA>       <NA>
#> 2       <NA>       <NA>
#> 3       <NA>       <NA>
#> 4       <NA>       <NA>
#> 5       <NA>       <NA>
#> 6       <NA>       <NA>
#> 8       <NA>       <NA>
#> 9       <NA>       <NA>
#> 10      <NA>       <NA>
#> 11      <NA>       <NA>
#> 12      <NA>       <NA>
#> 13      <NA>       <NA>
#> 14      <NA>       <NA>
#> 15      <NA>       <NA>
#> 29      <NA>       <NA>
#> 30      <NA>       <NA>
#> 31      <NA>       <NA>
#> 32      <NA>       <NA>
#> 34      <NA>       <NA>
#> 35      <NA>       <NA>
#> 36      <NA>       <NA>
#> 37      <NA>       <NA>
#> 38      <NA>       <NA>
#> 39      <NA>       <NA>
#> 40      <NA>       <NA>
#> 41      <NA>       <NA>
#> 42      <NA>       <NA>
#> 43      <NA>       <NA>
#> 44      <NA>       <NA>
#> 45      <NA>       <NA>
#> 46      <NA>       <NA>
#> 47      <NA>       <NA>
#> 48      <NA>       <NA>
#> 49      <NA>       <NA>
#> 50      <NA>       <NA>
#> 51      <NA>       <NA>
#> 52      <NA>       <NA>
#> 53      <NA>       <NA>
#> 54      <NA>       <NA>
#> 55      <NA>       <NA>
#> 56      <NA>       <NA>
#> 57      <NA>       <NA>
#> 58      <NA>       <NA>
#> 59      <NA>       <NA>
#> 60      <NA>       <NA>
#> 61      <NA>       <NA>
#> 62      <NA>       <NA>
#> 63      <NA>       <NA>
#> 64      <NA>       <NA>
#> 65      <NA>       <NA>
#> 66      <NA>       <NA>
#> 67      <NA>       <NA>
#> 68      <NA>       <NA>
#> 69      <NA>       <NA>
#> 70      <NA>       <NA>
#> 71      <NA>       <NA>
#> 72      <NA>       <NA>
#> 73      <NA>       <NA>
#> 74      <NA>       <NA>
#> 75      <NA>       <NA>
#> 76      <NA>       <NA>
#> 77      <NA>       <NA>
#> 78      <NA>       <NA>
#> 79      <NA>       <NA>
#> 80      <NA>       <NA>
#> 81      <NA>       <NA>
#> 82      <NA>       <NA>
#> 83      <NA>       <NA>
#> 84      <NA>       <NA>
#> 85      <NA>       <NA>
#> 86      <NA>       <NA>
#> 87      <NA>       <NA>
#> 88      <NA>       <NA>
#> 89      <NA>       <NA>
#> 90      <NA>       <NA>
#> 91      <NA>       <NA>
#> 92      <NA>       <NA>
#> 93      <NA>       <NA>
#> 94      <NA>       <NA>
#> 95      <NA>       <NA>
#> 96      <NA>       <NA>
#> 97      <NA>       <NA>
#> 98      <NA>       <NA>
#> 99      <NA>       <NA>
#> 100     <NA>       <NA>
#> 101     <NA>       <NA>
#> 102     <NA>       <NA>
#> 103     <NA>       <NA>
#> 104     <NA>       <NA>
#> 105     <NA>       <NA>
#> 106     <NA>       <NA>
#> 107     <NA>       <NA>
#> 108     <NA>       <NA>
#> 109     <NA>       <NA>
#> 110     <NA>       <NA>
#> 111     <NA>       <NA>
#> 112     <NA>       <NA>
#> 113     <NA>       <NA>
#> 114     <NA>       <NA>
#> 115     <NA>       <NA>
#> 116     <NA>       <NA>
#> 117     <NA>       <NA>
#> 118     <NA>       <NA>
#> 119     <NA>       <NA>
#> 120     <NA>       <NA>
#> 121     <NA>       <NA>
#> 122     <NA>       <NA>
#> 123     <NA>       <NA>
#> 124     <NA>       <NA>
#> 125     <NA>       <NA>
#> 126     <NA>       <NA>
#> 127     <NA>       <NA>
#> 128     <NA>       <NA>
#> 129     <NA>       <NA>
#> 130     <NA>       <NA>
#> 131     <NA>       <NA>
#> 132     <NA>       <NA>
#> 133     <NA>       <NA>
#> 134     <NA>       <NA>
#> 135     <NA>       <NA>
#> 136     <NA>       <NA>
#> 137     <NA>       <NA>
#> 138     <NA>       <NA>
#> 139     <NA>       <NA>
#> 140     <NA>       <NA>
#> 141     <NA>       <NA>
#> 142     <NA>       <NA>
#> 143     <NA>       <NA>
#> 144     <NA>       <NA>
#> 145     <NA>       <NA>
#> 146     <NA>       <NA>
#> 147     <NA>       <NA>
#> 148     <NA>       <NA>
#> 149     <NA>       <NA>
#> 150     <NA>       <NA>
#> 151     <NA>       <NA>
#> 152     <NA>       <NA>
#> 154     <NA>       <NA>
#> 155     <NA>       <NA>
#> 156     <NA>       <NA>
#> 157     <NA>       <NA>
#> 158     <NA>       <NA>
#> 159     <NA>       <NA>
#> 160     <NA>       <NA>
#> 163     <NA>       <NA>
#> 164     <NA>       <NA>
get_data_registry(family = "enrollment", end_year = 2024)
#>    state     family end_year               source_id variant status mode
#> 80    NJ enrollment     2024 fall_enrollment_reports    <NA> served live
#>      fetcher n_source_files n_derived_files   bytes
#> 80 fetch_enr              1               0 1061242
#>                                                            source_url
#> 80 https://www.nj.gov/education/doedata/enr/enr24/enrollment_2324.zip
#>                             publisher publisher_type                   title
#> 80 New Jersey Department of Education      state_doe Fall Enrollment Reports
#>         year_basis                               landing_url reason evidence
#> 80 school_year_end https://www.nj.gov/education/doedata/enr/   <NA>     <NA>
#>    checked_on
#> 80       <NA>
```
