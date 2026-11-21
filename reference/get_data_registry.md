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
#> 30     NJ       assessment     2015          njsla_parcc_results_data_files
#> 31     NJ       assessment     2016          njsla_parcc_results_data_files
#> 32     NJ       assessment     2017          njsla_parcc_results_data_files
#> 33     NJ       assessment     2018          njsla_parcc_results_data_files
#> 34     NJ       assessment     2019          njsla_parcc_results_data_files
#> 37     NJ       assessment     2022                 access_for_ells_results
#> 38     NJ       assessment     2022                njgpa_results_data_files
#> 39     NJ       assessment     2022          njsla_parcc_results_data_files
#> 40     NJ       assessment     2023                 access_for_ells_results
#> 41     NJ       assessment     2023                njgpa_results_data_files
#> 42     NJ       assessment     2023          njsla_parcc_results_data_files
#> 43     NJ       assessment     2024                 access_for_ells_results
#> 44     NJ       assessment     2024                njgpa_results_data_files
#> 45     NJ       assessment     2024          njsla_parcc_results_data_files
#> 46     NJ       assessment     2025                 access_for_ells_results
#> 47     NJ       assessment     2025                njgpa_results_data_files
#> 48     NJ       assessment     2025          njsla_parcc_results_data_files
#> 49     NJ       assessment     2026                njgpa_results_data_files
#> 50     NJ       assessment     2026          njsla_parcc_results_data_files
#> 52     NJ              ell     2006                 fall_enrollment_reports
#> 53     NJ              ell     2007                 fall_enrollment_reports
#> 54     NJ              ell     2008                 fall_enrollment_reports
#> 55     NJ              ell     2009                 fall_enrollment_reports
#> 56     NJ              ell     2010                 fall_enrollment_reports
#> 57     NJ              ell     2011                 fall_enrollment_reports
#> 58     NJ              ell     2012                 fall_enrollment_reports
#> 59     NJ              ell     2013                 fall_enrollment_reports
#> 60     NJ              ell     2014                 fall_enrollment_reports
#> 61     NJ              ell     2015                 fall_enrollment_reports
#> 62     NJ              ell     2016                 fall_enrollment_reports
#> 63     NJ              ell     2017                 fall_enrollment_reports
#> 64     NJ              ell     2018                 fall_enrollment_reports
#> 65     NJ              ell     2019                 fall_enrollment_reports
#> 66     NJ              ell     2020                 fall_enrollment_reports
#> 67     NJ              ell     2021                 fall_enrollment_reports
#> 68     NJ              ell     2022                 fall_enrollment_reports
#> 69     NJ              ell     2023                 fall_enrollment_reports
#> 70     NJ              ell     2024                 fall_enrollment_reports
#> 71     NJ              ell     2025                 fall_enrollment_reports
#> 72     NJ              ell     2026                 fall_enrollment_reports
#> 73     NJ       enrollment     1999                 fall_enrollment_reports
#> 74     NJ       enrollment     2000                 fall_enrollment_reports
#> 75     NJ       enrollment     2001                 fall_enrollment_reports
#> 76     NJ       enrollment     2002                 fall_enrollment_reports
#> 77     NJ       enrollment     2003                 fall_enrollment_reports
#> 78     NJ       enrollment     2004                 fall_enrollment_reports
#> 79     NJ       enrollment     2005                 fall_enrollment_reports
#> 80     NJ       enrollment     2006                 fall_enrollment_reports
#> 81     NJ       enrollment     2007                 fall_enrollment_reports
#> 82     NJ       enrollment     2008                 fall_enrollment_reports
#> 83     NJ       enrollment     2009                 fall_enrollment_reports
#> 84     NJ       enrollment     2010                 fall_enrollment_reports
#> 85     NJ       enrollment     2011                 fall_enrollment_reports
#> 86     NJ       enrollment     2012                 fall_enrollment_reports
#> 87     NJ       enrollment     2013                 fall_enrollment_reports
#> 88     NJ       enrollment     2014                 fall_enrollment_reports
#> 89     NJ       enrollment     2015                 fall_enrollment_reports
#> 90     NJ       enrollment     2016                 fall_enrollment_reports
#> 91     NJ       enrollment     2017                 fall_enrollment_reports
#> 92     NJ       enrollment     2018                 fall_enrollment_reports
#> 93     NJ       enrollment     2019                 fall_enrollment_reports
#> 94     NJ       enrollment     2020                 fall_enrollment_reports
#> 95     NJ       enrollment     2021                 fall_enrollment_reports
#> 96     NJ       enrollment     2022                 fall_enrollment_reports
#> 97     NJ       enrollment     2023                 fall_enrollment_reports
#> 98     NJ       enrollment     2024                 fall_enrollment_reports
#> 99     NJ       enrollment     2025                 fall_enrollment_reports
#> 100    NJ       enrollment     2026                 fall_enrollment_reports
#> 104    NJ          finance     2001 taxpayers_guide_to_educational_spending
#> 105    NJ          finance     2002 taxpayers_guide_to_educational_spending
#> 106    NJ          finance     2003 taxpayers_guide_to_educational_spending
#> 107    NJ          finance     2004 taxpayers_guide_to_educational_spending
#> 108    NJ          finance     2005 taxpayers_guide_to_educational_spending
#> 109    NJ          finance     2006 taxpayers_guide_to_educational_spending
#> 110    NJ          finance     2007 taxpayers_guide_to_educational_spending
#> 111    NJ          finance     2008 taxpayers_guide_to_educational_spending
#> 112    NJ          finance     2009 taxpayers_guide_to_educational_spending
#> 113    NJ          finance     2010 taxpayers_guide_to_educational_spending
#> 114    NJ          finance     2011 taxpayers_guide_to_educational_spending
#> 115    NJ          finance     2012 taxpayers_guide_to_educational_spending
#> 116    NJ          finance     2013 taxpayers_guide_to_educational_spending
#> 117    NJ          finance     2014 taxpayers_guide_to_educational_spending
#> 118    NJ          finance     2015 taxpayers_guide_to_educational_spending
#> 119    NJ          finance     2016 taxpayers_guide_to_educational_spending
#> 120    NJ          finance     2017 taxpayers_guide_to_educational_spending
#> 121    NJ          finance     2018 taxpayers_guide_to_educational_spending
#> 122    NJ          finance     2019              state_aid_district_details
#> 123    NJ          finance     2019 taxpayers_guide_to_educational_spending
#> 124    NJ          finance     2020              state_aid_district_details
#> 125    NJ          finance     2020 taxpayers_guide_to_educational_spending
#> 126    NJ          finance     2021              state_aid_district_details
#> 127    NJ          finance     2021 taxpayers_guide_to_educational_spending
#> 128    NJ          finance     2022              state_aid_district_details
#> 129    NJ          finance     2022 taxpayers_guide_to_educational_spending
#> 130    NJ          finance     2023              state_aid_district_details
#> 131    NJ          finance     2023 taxpayers_guide_to_educational_spending
#> 132    NJ          finance     2024              state_aid_district_details
#> 133    NJ          finance     2024 taxpayers_guide_to_educational_spending
#> 134    NJ          finance     2025              state_aid_district_details
#> 135    NJ          finance     2026              state_aid_district_details
#> 136    NJ          finance     2027              state_aid_district_details
#> 137    NJ       graduation     2011 adjusted_cohort_graduation_rate_reports
#> 138    NJ       graduation     2012 adjusted_cohort_graduation_rate_reports
#> 139    NJ       graduation     2013 adjusted_cohort_graduation_rate_reports
#> 140    NJ       graduation     2014 adjusted_cohort_graduation_rate_reports
#> 141    NJ       graduation     2015 adjusted_cohort_graduation_rate_reports
#> 142    NJ       graduation     2016 adjusted_cohort_graduation_rate_reports
#> 143    NJ       graduation     2017 adjusted_cohort_graduation_rate_reports
#> 144    NJ       graduation     2018 adjusted_cohort_graduation_rate_reports
#> 145    NJ       graduation     2019 adjusted_cohort_graduation_rate_reports
#> 146    NJ       graduation     2020 adjusted_cohort_graduation_rate_reports
#> 147    NJ       graduation     2021 adjusted_cohort_graduation_rate_reports
#> 148    NJ       graduation     2021     school_performance_reports_database
#> 149    NJ       graduation     2022 adjusted_cohort_graduation_rate_reports
#> 150    NJ       graduation     2022     school_performance_reports_database
#> 151    NJ       graduation     2023 adjusted_cohort_graduation_rate_reports
#> 152    NJ       graduation     2023     school_performance_reports_database
#> 153    NJ       graduation     2024 adjusted_cohort_graduation_rate_reports
#> 154    NJ       graduation     2024     school_performance_reports_database
#> 155    NJ       graduation     2025 adjusted_cohort_graduation_rate_reports
#> 156    NJ       graduation     2025     school_performance_reports_database
#> 157    NJ             sped     2015  idea_618_district_classification_rates
#> 158    NJ             sped     2015      idea_618_public_reporting_archives
#> 159    NJ             sped     2016  idea_618_district_classification_rates
#> 160    NJ             sped     2016      idea_618_public_reporting_archives
#> 161    NJ             sped     2017  idea_618_district_classification_rates
#> 162    NJ             sped     2017      idea_618_public_reporting_archives
#> 163    NJ             sped     2018  idea_618_district_classification_rates
#> 164    NJ             sped     2018      idea_618_public_reporting_archives
#> 165    NJ             sped     2019      idea_618_public_reporting_archives
#> 166    NJ             sped     2020      idea_618_public_reporting_archives
#> 167    NJ             sped     2021      idea_618_public_reporting_archives
#> 168    NJ             sped     2022  idea_618_district_classification_rates
#> 169    NJ             sped     2022       opra_response_iep_counts_by_grade
#> 170    NJ             sped     2023      idea_618_public_reporting_archives
#> 171    NJ             sped     2023       opra_response_iep_counts_by_grade
#> 172    NJ             sped     2024      idea_618_public_reporting_archives
#> 173    NJ             sped     2024       opra_response_iep_counts_by_grade
#> 174    NJ             sped     2025      idea_618_public_reporting_archives
#> 175    NJ             sped     2025       opra_response_iep_counts_by_grade
#> 176    NJ             sped     2026       opra_response_iep_counts_by_grade
#> 177    NJ sped_environment     2023            nj_sped_environment_snapshot
#> 178    NJ sped_environment     2024            nj_sped_environment_snapshot
#> 179    NJ sped_environment     2025            nj_sped_environment_snapshot
#> 181    NJ       sped_share     2023                  nj_sped_share_snapshot
#> 182    NJ       sped_share     2023       opra_response_iep_counts_by_grade
#> 183    NJ       sped_share     2024                  nj_sped_share_snapshot
#> 184    NJ       sped_share     2024       opra_response_iep_counts_by_grade
#> 185    NJ       sped_share     2025                  nj_sped_share_snapshot
#> 186    NJ       sped_share     2025       opra_response_iep_counts_by_grade
#> 187    NJ       sped_share     2026       opra_response_iep_counts_by_grade
#> 190    NJ        stability     2024                   nj_stability_snapshot
#> 191    NJ        stability     2025                   nj_stability_snapshot
#>     variant status mode                        fetcher n_source_files
#> 1      <NA> served live fetch_essa_chronic_absenteeism              0
#> 2      <NA> served live                  fetch_absence              0
#> 3      <NA> served live fetch_essa_chronic_absenteeism              0
#> 4      <NA> served live                  fetch_absence              0
#> 5      <NA> served live fetch_essa_chronic_absenteeism              0
#> 6      <NA> served live                  fetch_absence              0
#> 8      <NA> served live                  fetch_absence              0
#> 9      <NA> served live fetch_essa_chronic_absenteeism              0
#> 10     <NA> served live                  fetch_absence              0
#> 11     <NA> served live fetch_essa_chronic_absenteeism              0
#> 12     <NA> served live                  fetch_absence              0
#> 13     <NA> served live fetch_essa_chronic_absenteeism              0
#> 14     <NA> served live                  fetch_absence              0
#> 15     <NA> served live                  fetch_absence              0
#> 30     <NA> served live                    fetch_parcc              0
#> 31     <NA> served live                    fetch_parcc              0
#> 32     <NA> served live                    fetch_parcc              0
#> 33     <NA> served live                    fetch_parcc              1
#> 34     <NA> served live                    fetch_parcc              1
#> 37     <NA> served live                   fetch_access              0
#> 38     <NA> served live                    fetch_njgpa              0
#> 39     <NA> served live                    fetch_parcc              1
#> 40     <NA> served live                   fetch_access              0
#> 41     <NA> served live                    fetch_njgpa              0
#> 42     <NA> served live                    fetch_parcc              1
#> 43     <NA> served live                   fetch_access              0
#> 44     <NA> served live                    fetch_njgpa              0
#> 45     <NA> served live                    fetch_parcc              1
#> 46     <NA> served live                   fetch_access              0
#> 47     <NA> served live                    fetch_njgpa              0
#> 48     <NA> served live                    fetch_parcc              1
#> 49     <NA> served live                    fetch_njgpa              0
#> 50     <NA> served live                    fetch_parcc              0
#> 52     <NA> served live                      fetch_ell              0
#> 53     <NA> served live                      fetch_ell              0
#> 54     <NA> served live                      fetch_ell              0
#> 55     <NA> served live                      fetch_ell              0
#> 56     <NA> served live                      fetch_ell              0
#> 57     <NA> served live                      fetch_ell              0
#> 58     <NA> served live                      fetch_ell              0
#> 59     <NA> served live                      fetch_ell              0
#> 60     <NA> served live                      fetch_ell              0
#> 61     <NA> served live                      fetch_ell              0
#> 62     <NA> served live                      fetch_ell              0
#> 63     <NA> served live                      fetch_ell              0
#> 64     <NA> served live                      fetch_ell              0
#> 65     <NA> served live                      fetch_ell              0
#> 66     <NA> served live                      fetch_ell              0
#> 67     <NA> served live                      fetch_ell              0
#> 68     <NA> served live                      fetch_ell              0
#> 69     <NA> served live                      fetch_ell              0
#> 70     <NA> served live                      fetch_ell              0
#> 71     <NA> served live                      fetch_ell              0
#> 72     <NA> served live                      fetch_ell              0
#> 73     <NA> served live                      fetch_enr              1
#> 74     <NA> served live                      fetch_enr              1
#> 75     <NA> served live                      fetch_enr              1
#> 76     <NA> served live                      fetch_enr              1
#> 77     <NA> served live                      fetch_enr              1
#> 78     <NA> served live                      fetch_enr              1
#> 79     <NA> served live                      fetch_enr              1
#> 80     <NA> served live                      fetch_enr              1
#> 81     <NA> served live                      fetch_enr              1
#> 82     <NA> served live                      fetch_enr              1
#> 83     <NA> served live                      fetch_enr              1
#> 84     <NA> served live                      fetch_enr              1
#> 85     <NA> served live                      fetch_enr              1
#> 86     <NA> served live                      fetch_enr              1
#> 87     <NA> served live                      fetch_enr              1
#> 88     <NA> served live                      fetch_enr              1
#> 89     <NA> served live                      fetch_enr              1
#> 90     <NA> served live                      fetch_enr              1
#> 91     <NA> served live                      fetch_enr              1
#> 92     <NA> served live                      fetch_enr              1
#> 93     <NA> served live                      fetch_enr              1
#> 94     <NA> served live                      fetch_enr              1
#> 95     <NA> served live                      fetch_enr              1
#> 96     <NA> served live                      fetch_enr              1
#> 97     <NA> served live                      fetch_enr              1
#> 98     <NA> served live                      fetch_enr              1
#> 99     <NA> served live                      fetch_enr              1
#> 100    <NA> served live                      fetch_enr              1
#> 104    <NA> served live                  fetch_finance              1
#> 105    <NA> served live                  fetch_finance              1
#> 106    <NA> served live                  fetch_finance              1
#> 107    <NA> served live                  fetch_finance              1
#> 108    <NA> served live                  fetch_finance              1
#> 109    <NA> served live                  fetch_finance              1
#> 110    <NA> served live                  fetch_finance              1
#> 111    <NA> served live                  fetch_finance              1
#> 112    <NA> served live                  fetch_finance              1
#> 113    <NA> served live                  fetch_finance              1
#> 114    <NA> served live                  fetch_finance              1
#> 115    <NA> served live                  fetch_finance              1
#> 116    <NA> served live                  fetch_finance              1
#> 117    <NA> served live                  fetch_finance              1
#> 118    <NA> served live                  fetch_finance              1
#> 119    <NA> served live                  fetch_finance              1
#> 120    <NA> served live                  fetch_finance              1
#> 121    <NA> served live                  fetch_finance              1
#> 122    <NA> served live fetch_finance; fetch_state_aid              1
#> 123    <NA> served live                  fetch_finance              1
#> 124    <NA> served live fetch_finance; fetch_state_aid              1
#> 125    <NA> served live                  fetch_finance              1
#> 126    <NA> served live fetch_finance; fetch_state_aid              1
#> 127    <NA> served live                  fetch_finance              1
#> 128    <NA> served live fetch_finance; fetch_state_aid              1
#> 129    <NA> served live                  fetch_finance              1
#> 130    <NA> served live fetch_finance; fetch_state_aid              1
#> 131    <NA> served live                  fetch_finance              1
#> 132    <NA> served live fetch_finance; fetch_state_aid              1
#> 133    <NA> served live                  fetch_finance              1
#> 134    <NA> served live fetch_finance; fetch_state_aid              1
#> 135    <NA> served live fetch_finance; fetch_state_aid              1
#> 136    <NA> served live                fetch_state_aid              1
#> 137    <NA> served live                fetch_grad_rate              0
#> 138    <NA> served live                fetch_grad_rate              3
#> 139    <NA> served live                fetch_grad_rate              2
#> 140    <NA> served live                fetch_grad_rate              2
#> 141    <NA> served live                fetch_grad_rate              2
#> 142    <NA> served live                fetch_grad_rate              2
#> 143    <NA> served live                fetch_grad_rate              2
#> 144    <NA> served live                fetch_grad_rate              2
#> 145    <NA> served live                fetch_grad_rate              2
#> 146    <NA> served live                fetch_grad_rate              1
#> 147    <NA> served live                fetch_grad_rate              1
#> 148    <NA> served live            fetch_6yr_grad_rate              0
#> 149    <NA> served live                fetch_grad_rate              1
#> 150    <NA> served live            fetch_6yr_grad_rate              0
#> 151    <NA> served live                fetch_grad_rate              1
#> 152    <NA> served live            fetch_6yr_grad_rate              0
#> 153    <NA> served live                fetch_grad_rate              1
#> 154    <NA> served live            fetch_6yr_grad_rate              0
#> 155    <NA> served live                fetch_grad_rate              1
#> 156    <NA> served live            fetch_6yr_grad_rate              0
#> 157    <NA> served live                     fetch_sped              0
#> 158    <NA> served live                     fetch_sped              0
#> 159    <NA> served live                     fetch_sped              0
#> 160    <NA> served live                     fetch_sped              0
#> 161    <NA> served live                     fetch_sped              0
#> 162    <NA> served live                     fetch_sped              0
#> 163    <NA> served live                     fetch_sped              0
#> 164    <NA> served live                     fetch_sped              0
#> 165    <NA> served live                     fetch_sped              1
#> 166    <NA> served live                     fetch_sped              1
#> 167    <NA> served live                     fetch_sped              1
#> 168    <NA> served live                     fetch_sped              1
#> 169    <NA> served live            fetch_sped_by_grade              0
#> 170    <NA> served live                     fetch_sped              0
#> 171    <NA> served live            fetch_sped_by_grade              0
#> 172    <NA> served live                     fetch_sped              0
#> 173    <NA> served live            fetch_sped_by_grade              0
#> 174    <NA> served live                     fetch_sped              0
#> 175    <NA> served live            fetch_sped_by_grade              0
#> 176    <NA> served live            fetch_sped_by_grade              0
#> 177    <NA> served live         fetch_sped_environment              0
#> 178    <NA> served live         fetch_sped_environment              0
#> 179    <NA> served live         fetch_sped_environment              0
#> 181    <NA> served live               fetch_sped_share              0
#> 182    <NA> served live               fetch_sped_share              0
#> 183    <NA> served live               fetch_sped_share              0
#> 184    <NA> served live               fetch_sped_share              0
#> 185    <NA> served live               fetch_sped_share              0
#> 186    <NA> served live               fetch_sped_share              0
#> 187    <NA> served live               fetch_sped_share              0
#> 190    <NA> served live                fetch_stability              0
#> 191    <NA> served live                fetch_stability              0
#>     n_derived_files   bytes
#> 1                 0       0
#> 2                 0       0
#> 3                 0       0
#> 4                 0       0
#> 5                 0       0
#> 6                 0       0
#> 8                 0       0
#> 9                 0       0
#> 10                0       0
#> 11                0       0
#> 12                0       0
#> 13                0       0
#> 14                0       0
#> 15                0       0
#> 30                0       0
#> 31                0       0
#> 32                0       0
#> 33                0 1978116
#> 34                0 1887597
#> 37                0       0
#> 38                0       0
#> 39                0 1821684
#> 40                0       0
#> 41                0       0
#> 42                0 1829780
#> 43                0       0
#> 44                0       0
#> 45                0 1821168
#> 46                0       0
#> 47                0       0
#> 48                0 1843456
#> 49                0       0
#> 50                0       0
#> 52                0       0
#> 53                0       0
#> 54                0       0
#> 55                0       0
#> 56                0       0
#> 57                0       0
#> 58                0       0
#> 59                0       0
#> 60                0       0
#> 61                0       0
#> 62                0       0
#> 63                0       0
#> 64                0       0
#> 65                0       0
#> 66                0       0
#> 67                0       0
#> 68                0       0
#> 69                0       0
#> 70                0       0
#> 71                0       0
#> 72                0       0
#> 73                0  465739
#> 74                0  536664
#> 75                0  446887
#> 76                0  485025
#> 77                0  459473
#> 78                0  537620
#> 79                0  456027
#> 80                0  459687
#> 81                0  481166
#> 82                0  569533
#> 83                0  575500
#> 84                0 1338684
#> 85                0 1095496
#> 86                0 2591290
#> 87                0 2578254
#> 88                0 2339971
#> 89                0 2616791
#> 90                0 2619194
#> 91                0 2627985
#> 92                0 2634898
#> 93                0 2678851
#> 94                0  763907
#> 95                0  733786
#> 96                0  734021
#> 97                0 1119856
#> 98                0 1061242
#> 99                0 1095121
#> 100               0 1061437
#> 104               0  572766
#> 105               0  585513
#> 106               0 1140308
#> 107               0 2259434
#> 108               0 2283208
#> 109               0 2294833
#> 110               0 1331465
#> 111               0 2325550
#> 112               0 2213595
#> 113               0 2358982
#> 114               0  590610
#> 115               0  649722
#> 116               0  599308
#> 117               0  593519
#> 118               0  802071
#> 119               0  804033
#> 120               0  810538
#> 121               0  970438
#> 122               0 1292364
#> 123               0 1040892
#> 124               0 1642279
#> 125               0 1343893
#> 126               0  921846
#> 127               0 1110723
#> 128               0 1867828
#> 129               0 1621328
#> 130               0 1760402
#> 131               0  871679
#> 132               0  961889
#> 133               0  772998
#> 134               0 1088273
#> 135               0   77477
#> 136               0   77136
#> 137               0       0
#> 138               0 1483762
#> 139               0  373695
#> 140               0  377170
#> 141               0  381277
#> 142               0  399324
#> 143               0  401845
#> 144               0  574120
#> 145               0  608863
#> 146               0  534643
#> 147               0  536015
#> 148               0       0
#> 149               0  567385
#> 150               0       0
#> 151               0  548651
#> 152               0       0
#> 153               0  563820
#> 154               0       0
#> 155               0  563176
#> 156               0       0
#> 157               0       0
#> 158               0       0
#> 159               0       0
#> 160               0       0
#> 161               0       0
#> 162               0       0
#> 163               0       0
#> 164               0       0
#> 165               0 7937226
#> 166               0 5551373
#> 167               0 7510855
#> 168               0   91960
#> 169               0       0
#> 170               0       0
#> 171               0       0
#> 172               0       0
#> 173               0       0
#> 174               0       0
#> 175               0       0
#> 176               0       0
#> 177               0       0
#> 178               0       0
#> 179               0       0
#> 181               0       0
#> 182               0       0
#> 183               0       0
#> 184               0       0
#> 185               0       0
#> 186               0       0
#> 187               0       0
#> 190               0       0
#> 191               0       0
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
#> 30                                                                                                                              <NA>
#> 31                                                                                                                              <NA>
#> 32                                                                                                                              <NA>
#> 33                                                   https://www.nj.gov/education/assessment/results/reports/1718/spring/ELA004.xlsx
#> 34                           https://www.nj.gov/education/assessment/results/reports/1819/spring/ELA04%20NJSLA%20DATA%202018-19.xlsx
#> 37                                                                                                                              <NA>
#> 38                                                                                                                              <NA>
#> 39                                 https://www.nj.gov/education/assessment/results/reports/2122/spring/ELA04_NJSLA_DATA_2021-22.xlsx
#> 40                                                                                                                              <NA>
#> 41                                                                                                                              <NA>
#> 42                                 https://www.nj.gov/education/assessment/results/reports/2223/spring/ELA04_NJSLA_DATA_2022-23.xlsx
#> 43                                                                                                                              <NA>
#> 44                                                                                                                              <NA>
#> 45                                 https://www.nj.gov/education/assessment/results/reports/2324/spring/ELA04_NJSLA_DATA_2023-24.xlsx
#> 46                                                                                                                              <NA>
#> 47                                                                                                                              <NA>
#> 48                           https://www.nj.gov/education/assessment/results/reports/2425/spring/ELA04%20NJSLA%20DATA%202024-25.xlsx
#> 49                                                                                                                              <NA>
#> 50                                                                                                                              <NA>
#> 52                                                                                                                              <NA>
#> 53                                                                                                                              <NA>
#> 54                                                                                                                              <NA>
#> 55                                                                                                                              <NA>
#> 56                                                                                                                              <NA>
#> 57                                                                                                                              <NA>
#> 58                                                                                                                              <NA>
#> 59                                                                                                                              <NA>
#> 60                                                                                                                              <NA>
#> 61                                                                                                                              <NA>
#> 62                                                                                                                              <NA>
#> 63                                                                                                                              <NA>
#> 64                                                                                                                              <NA>
#> 65                                                                                                                              <NA>
#> 66                                                                                                                              <NA>
#> 67                                                                                                                              <NA>
#> 68                                                                                                                              <NA>
#> 69                                                                                                                              <NA>
#> 70                                                                                                                              <NA>
#> 71                                                                                                                              <NA>
#> 72                                                                                                                              <NA>
#> 73                                                                https://www.nj.gov/education/doedata/enr/enr99/enrollment_9899.zip
#> 74                                                                https://www.nj.gov/education/doedata/enr/enr00/enrollment_9900.zip
#> 75                                                                https://www.nj.gov/education/doedata/enr/enr01/enrollment_0001.zip
#> 76                                                                https://www.nj.gov/education/doedata/enr/enr02/enrollment_0102.zip
#> 77                                                                https://www.nj.gov/education/doedata/enr/enr03/enrollment_0203.zip
#> 78                                                                https://www.nj.gov/education/doedata/enr/enr04/enrollment_0304.zip
#> 79                                                                https://www.nj.gov/education/doedata/enr/enr05/enrollment_0405.zip
#> 80                                                                https://www.nj.gov/education/doedata/enr/enr06/enrollment_0506.zip
#> 81                                                                https://www.nj.gov/education/doedata/enr/enr07/enrollment_0607.zip
#> 82                                                                https://www.nj.gov/education/doedata/enr/enr08/enrollment_0708.zip
#> 83                                                                https://www.nj.gov/education/doedata/enr/enr09/enrollment_0809.zip
#> 84                                                                https://www.nj.gov/education/doedata/enr/enr10/enrollment_0910.zip
#> 85                                                                https://www.nj.gov/education/doedata/enr/enr11/enrollment_1011.zip
#> 86                                                                https://www.nj.gov/education/doedata/enr/enr12/enrollment_1112.zip
#> 87                                                                https://www.nj.gov/education/doedata/enr/enr13/enrollment_1213.zip
#> 88                                                                https://www.nj.gov/education/doedata/enr/enr14/enrollment_1314.zip
#> 89                                                                https://www.nj.gov/education/doedata/enr/enr15/enrollment_1415.zip
#> 90                                                                https://www.nj.gov/education/doedata/enr/enr16/enrollment_1516.zip
#> 91                                                                https://www.nj.gov/education/doedata/enr/enr17/enrollment_1617.zip
#> 92                                                                https://www.nj.gov/education/doedata/enr/enr18/enrollment_1718.zip
#> 93                                                                https://www.nj.gov/education/doedata/enr/enr19/enrollment_1819.zip
#> 94                                                                https://www.nj.gov/education/doedata/enr/enr20/enrollment_1920.zip
#> 95                                                                https://www.nj.gov/education/doedata/enr/enr21/enrollment_2021.zip
#> 96                                                                https://www.nj.gov/education/doedata/enr/enr22/enrollment_2122.zip
#> 97                                                                https://www.nj.gov/education/doedata/enr/enr23/enrollment_2223.zip
#> 98                                                                https://www.nj.gov/education/doedata/enr/enr24/enrollment_2324.zip
#> 99                                                                https://www.nj.gov/education/doedata/enr/enr25/enrollment_2425.zip
#> 100                                                               https://www.nj.gov/education/doedata/enr/enr26/Enrollment_2526.zip
#> 104                                                                             https://www.nj.gov/education/guide/docs/2001_CSG.zip
#> 105                                                                             https://www.nj.gov/education/guide/docs/2002_CSG.zip
#> 106                                                                             https://www.nj.gov/education/guide/docs/2003_CSG.zip
#> 107                                                                             https://www.nj.gov/education/guide/docs/2004_CSG.zip
#> 108                                                                             https://www.nj.gov/education/guide/docs/2005_CSG.zip
#> 109                                                                             https://www.nj.gov/education/guide/docs/2006_CSG.zip
#> 110                                                                             https://www.nj.gov/education/guide/docs/2007_CSG.zip
#> 111                                                                             https://www.nj.gov/education/guide/docs/2008_CSG.zip
#> 112                                                                             https://www.nj.gov/education/guide/docs/2009_CSG.zip
#> 113                                                                             https://www.nj.gov/education/guide/docs/2010_CSG.zip
#> 114                                                                            https://www.nj.gov/education/guide/docs/2011_TGES.zip
#> 115                                                                            https://www.nj.gov/education/guide/docs/2012_TGES.zip
#> 116                                                                            https://www.nj.gov/education/guide/docs/2013_TGES.zip
#> 117                                                                            https://www.nj.gov/education/guide/docs/2014_TGES.zip
#> 118                                                                            https://www.nj.gov/education/guide/docs/2015_TGES.zip
#> 119                                                                            https://www.nj.gov/education/guide/docs/2016_TGES.zip
#> 120                                                                            https://www.nj.gov/education/guide/docs/2017_TGES.zip
#> 121                                                                            https://www.nj.gov/education/guide/docs/2018_TGES.zip
#> 122                                                                       https://www.nj.gov/education/stateaid/zippedfiles/1819.zip
#> 123                                                                            https://www.nj.gov/education/guide/docs/2019_TGES.zip
#> 124                                                                       https://www.nj.gov/education/stateaid/zippedfiles/1920.zip
#> 125                                                                            https://www.nj.gov/education/guide/docs/2020_TGES.zip
#> 126                                                                       https://www.nj.gov/education/stateaid/zippedfiles/2021.zip
#> 127                                                                            https://www.nj.gov/education/guide/docs/2021_TGES.zip
#> 128                                                                       https://www.nj.gov/education/stateaid/zippedfiles/2122.zip
#> 129                                                                            https://www.nj.gov/education/guide/docs/2022_TGES.zip
#> 130                                                                       https://www.nj.gov/education/stateaid/zippedfiles/2223.zip
#> 131                                                                            https://www.nj.gov/education/guide/docs/2023_TGES.zip
#> 132                                                                       https://www.nj.gov/education/stateaid/zippedfiles/2324.zip
#> 133                                                                   https://www.nj.gov/education/guide/docs/2024/TGES24_Zipped.zip
#> 134                                                                       https://www.nj.gov/education/stateaid/zippedfiles/2425.zip
#> 135                                                        https://www.nj.gov/education/stateaid/2526/FY26_GBM_District_Details.xlsx
#> 136                                                        https://www.nj.gov/education/stateaid/2627/FY27_GBM_District_Details.xlsx
#> 137                                                                                                                             <NA>
#> 138                                                      https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2012_gradrate.xls
#> 139                                                        https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2013_4Year.xlsx
#> 140                                                        https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2014_4Year.xlsx
#> 141                                                        https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2015_4Year.xlsx
#> 142                                                        https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2016_4Year.xlsx
#> 143                                                        https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2017_4Year.xlsx
#> 144                                              https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2018_4YearGraduation.xlsx
#> 145 https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2019_Cohort2019_4-YearAdjustedCohortGraduationRatesByStudentGroup.xlsx
#> 146  https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2020_4YearAdjustedCohortGraduationRatesandCountsbyStudentGroup.xlsx
#> 147  https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2021_4YearAdjustedCohortGraduationRatesandCountsbyStudentGroup.xlsx
#> 148                                                                                                                             <NA>
#> 149  https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2022_4YearAdjustedCohortGraduationRatesandCountsbyStudentGroup.xlsx
#> 150                                                                                                                             <NA>
#> 151           https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2023_4YearAdjustedCohortGraduationRatesbyStudentGroup.xlsx
#> 152                                                                                                                             <NA>
#> 153           https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2024_4YearAdjustedCohortGraduationRatesbyStudentGroup.xlsx
#> 154                                                                                                                             <NA>
#> 155           https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2025_4YearAdjustedCohortGraduationRatesbyStudentGroup.xlsx
#> 156                                                                                                                             <NA>
#> 157                                                                                                                             <NA>
#> 158                                                                                                                             <NA>
#> 159                                                                                                                             <NA>
#> 160                                                                                                                             <NA>
#> 161                                                                                                                             <NA>
#> 162                                                                                                                             <NA>
#> 163                                                                                                                             <NA>
#> 164                                                                                                                             <NA>
#> 165                                                      https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2018.zip
#> 166                                                      https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2019.zip
#> 167                                                      https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2020.zip
#> 168                       https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2022%20data/Lea_Classification_Pub.xlsx
#> 169                                                                                                                             <NA>
#> 170                                                                                                                             <NA>
#> 171                                                                                                                             <NA>
#> 172                                                                                                                             <NA>
#> 173                                                                                                                             <NA>
#> 174                                                                                                                             <NA>
#> 175                                                                                                                             <NA>
#> 176                                                                                                                             <NA>
#> 177                                                                                                                             <NA>
#> 178                                                                                                                             <NA>
#> 179                                                                                                                             <NA>
#> 181                                                                                                                             <NA>
#> 182                                                                                                                             <NA>
#> 183                                                                                                                             <NA>
#> 184                                                                                                                             <NA>
#> 185                                                                                                                             <NA>
#> 186                                                                                                                             <NA>
#> 187                                                                                                                             <NA>
#> 190                                                                                                                             <NA>
#> 191                                                                                                                             <NA>
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
#> 30  New Jersey Department of Education      state_doe
#> 31  New Jersey Department of Education      state_doe
#> 32  New Jersey Department of Education      state_doe
#> 33  New Jersey Department of Education      state_doe
#> 34  New Jersey Department of Education      state_doe
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
#> 153 New Jersey Department of Education      state_doe
#> 154 New Jersey Department of Education      state_doe
#> 155 New Jersey Department of Education      state_doe
#> 156 New Jersey Department of Education      state_doe
#> 157 New Jersey Department of Education      state_doe
#> 158 New Jersey Department of Education      state_doe
#> 159 New Jersey Department of Education      state_doe
#> 160 New Jersey Department of Education      state_doe
#> 161 New Jersey Department of Education      state_doe
#> 162 New Jersey Department of Education      state_doe
#> 163 New Jersey Department of Education      state_doe
#> 164 New Jersey Department of Education      state_doe
#> 165 New Jersey Department of Education      state_doe
#> 166 New Jersey Department of Education      state_doe
#> 167 New Jersey Department of Education      state_doe
#> 168 New Jersey Department of Education      state_doe
#> 169 New Jersey Department of Education      state_doe
#> 170 New Jersey Department of Education      state_doe
#> 171 New Jersey Department of Education      state_doe
#> 172 New Jersey Department of Education      state_doe
#> 173 New Jersey Department of Education      state_doe
#> 174 New Jersey Department of Education      state_doe
#> 175 New Jersey Department of Education      state_doe
#> 176 New Jersey Department of Education      state_doe
#> 177 New Jersey Department of Education      state_doe
#> 178 New Jersey Department of Education      state_doe
#> 179 New Jersey Department of Education      state_doe
#> 181 New Jersey Department of Education      state_doe
#> 182 New Jersey Department of Education      state_doe
#> 183 New Jersey Department of Education      state_doe
#> 184 New Jersey Department of Education      state_doe
#> 185 New Jersey Department of Education      state_doe
#> 186 New Jersey Department of Education      state_doe
#> 187 New Jersey Department of Education      state_doe
#> 190 New Jersey Department of Education      state_doe
#> 191 New Jersey Department of Education      state_doe
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
#> 30                    NJSLA and PARCC results data files by grade and subject
#> 31                    NJSLA and PARCC results data files by grade and subject
#> 32                    NJSLA and PARCC results data files by grade and subject
#> 33                    NJSLA and PARCC results data files by grade and subject
#> 34                    NJSLA and PARCC results data files by grade and subject
#> 37                                         ACCESS for ELLs results data files
#> 38            New Jersey Graduation Proficiency Assessment results data files
#> 39                    NJSLA and PARCC results data files by grade and subject
#> 40                                         ACCESS for ELLs results data files
#> 41            New Jersey Graduation Proficiency Assessment results data files
#> 42                    NJSLA and PARCC results data files by grade and subject
#> 43                                         ACCESS for ELLs results data files
#> 44            New Jersey Graduation Proficiency Assessment results data files
#> 45                    NJSLA and PARCC results data files by grade and subject
#> 46                                         ACCESS for ELLs results data files
#> 47            New Jersey Graduation Proficiency Assessment results data files
#> 48                    NJSLA and PARCC results data files by grade and subject
#> 49            New Jersey Graduation Proficiency Assessment results data files
#> 50                    NJSLA and PARCC results data files by grade and subject
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
#> 83                                                    Fall Enrollment Reports
#> 84                                                    Fall Enrollment Reports
#> 85                                                    Fall Enrollment Reports
#> 86                                                    Fall Enrollment Reports
#> 87                                                    Fall Enrollment Reports
#> 88                                                    Fall Enrollment Reports
#> 89                                                    Fall Enrollment Reports
#> 90                                                    Fall Enrollment Reports
#> 91                                                    Fall Enrollment Reports
#> 92                                                    Fall Enrollment Reports
#> 93                                                    Fall Enrollment Reports
#> 94                                                    Fall Enrollment Reports
#> 95                                                    Fall Enrollment Reports
#> 96                                                    Fall Enrollment Reports
#> 97                                                    Fall Enrollment Reports
#> 98                                                    Fall Enrollment Reports
#> 99                                                    Fall Enrollment Reports
#> 100                                                   Fall Enrollment Reports
#> 104                                  Taxpayers' Guide to Educational Spending
#> 105                                  Taxpayers' Guide to Educational Spending
#> 106                                  Taxpayers' Guide to Educational Spending
#> 107                                  Taxpayers' Guide to Educational Spending
#> 108                                  Taxpayers' Guide to Educational Spending
#> 109                                  Taxpayers' Guide to Educational Spending
#> 110                                  Taxpayers' Guide to Educational Spending
#> 111                                  Taxpayers' Guide to Educational Spending
#> 112                                  Taxpayers' Guide to Educational Spending
#> 113                                  Taxpayers' Guide to Educational Spending
#> 114                                  Taxpayers' Guide to Educational Spending
#> 115                                  Taxpayers' Guide to Educational Spending
#> 116                                  Taxpayers' Guide to Educational Spending
#> 117                                  Taxpayers' Guide to Educational Spending
#> 118                                  Taxpayers' Guide to Educational Spending
#> 119                                  Taxpayers' Guide to Educational Spending
#> 120                                  Taxpayers' Guide to Educational Spending
#> 121                                  Taxpayers' Guide to Educational Spending
#> 122                            State aid summaries, district details workbook
#> 123                                  Taxpayers' Guide to Educational Spending
#> 124                            State aid summaries, district details workbook
#> 125                                  Taxpayers' Guide to Educational Spending
#> 126                            State aid summaries, district details workbook
#> 127                                  Taxpayers' Guide to Educational Spending
#> 128                            State aid summaries, district details workbook
#> 129                                  Taxpayers' Guide to Educational Spending
#> 130                            State aid summaries, district details workbook
#> 131                                  Taxpayers' Guide to Educational Spending
#> 132                            State aid summaries, district details workbook
#> 133                                  Taxpayers' Guide to Educational Spending
#> 134                            State aid summaries, district details workbook
#> 135                            State aid summaries, district details workbook
#> 136                            State aid summaries, district details workbook
#> 137                                   Adjusted Cohort Graduation Rate Reports
#> 138                                   Adjusted Cohort Graduation Rate Reports
#> 139                                   Adjusted Cohort Graduation Rate Reports
#> 140                                   Adjusted Cohort Graduation Rate Reports
#> 141                                   Adjusted Cohort Graduation Rate Reports
#> 142                                   Adjusted Cohort Graduation Rate Reports
#> 143                                   Adjusted Cohort Graduation Rate Reports
#> 144                                   Adjusted Cohort Graduation Rate Reports
#> 145                                   Adjusted Cohort Graduation Rate Reports
#> 146                                   Adjusted Cohort Graduation Rate Reports
#> 147                                   Adjusted Cohort Graduation Rate Reports
#> 148      School Performance Reports downloadable data, school detail database
#> 149                                   Adjusted Cohort Graduation Rate Reports
#> 150      School Performance Reports downloadable data, school detail database
#> 151                                   Adjusted Cohort Graduation Rate Reports
#> 152      School Performance Reports downloadable data, school detail database
#> 153                                   Adjusted Cohort Graduation Rate Reports
#> 154      School Performance Reports downloadable data, school detail database
#> 155                                   Adjusted Cohort Graduation Rate Reports
#> 156      School Performance Reports downloadable data, school detail database
#> 157               IDEA Part B public reporting, district classification rates
#> 158                         IDEA Part B public reporting, yearly archive zips
#> 159               IDEA Part B public reporting, district classification rates
#> 160                         IDEA Part B public reporting, yearly archive zips
#> 161               IDEA Part B public reporting, district classification rates
#> 162                         IDEA Part B public reporting, yearly archive zips
#> 163               IDEA Part B public reporting, district classification rates
#> 164                         IDEA Part B public reporting, yearly archive zips
#> 165                         IDEA Part B public reporting, yearly archive zips
#> 166                         IDEA Part B public reporting, yearly archive zips
#> 167                         IDEA Part B public reporting, yearly archive zips
#> 168               IDEA Part B public reporting, district classification rates
#> 169 Response to OPRA request C255254, active IEP counts by district and grade
#> 170                         IDEA Part B public reporting, yearly archive zips
#> 171 Response to OPRA request C255254, active IEP counts by district and grade
#> 172                         IDEA Part B public reporting, yearly archive zips
#> 173 Response to OPRA request C255254, active IEP counts by district and grade
#> 174                         IDEA Part B public reporting, yearly archive zips
#> 175 Response to OPRA request C255254, active IEP counts by district and grade
#> 176 Response to OPRA request C255254, active IEP counts by district and grade
#> 177                                   Local Special Education Profiles IND_5C
#> 178                                   Local Special Education Profiles IND_5C
#> 179                                   Local Special Education Profiles IND_5C
#> 181                 School Performance Reports EnrollmentTrendsByStudentGroup
#> 182 Response to OPRA request C255254, active IEP counts by district and grade
#> 183                 School Performance Reports EnrollmentTrendsByStudentGroup
#> 184 Response to OPRA request C255254, active IEP counts by district and grade
#> 185                 School Performance Reports EnrollmentTrendsByStudentGroup
#> 186 Response to OPRA request C255254, active IEP counts by district and grade
#> 187 Response to OPRA request C255254, active IEP counts by district and grade
#> 190               School Performance Reports six-year high school persistence
#> 191               School Performance Reports six-year high school persistence
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
#> 30  school_year_end
#> 31  school_year_end
#> 32  school_year_end
#> 33  school_year_end
#> 34  school_year_end
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
#> 83  school_year_end
#> 84  school_year_end
#> 85  school_year_end
#> 86  school_year_end
#> 87  school_year_end
#> 88  school_year_end
#> 89  school_year_end
#> 90  school_year_end
#> 91  school_year_end
#> 92  school_year_end
#> 93  school_year_end
#> 94  school_year_end
#> 95  school_year_end
#> 96  school_year_end
#> 97  school_year_end
#> 98  school_year_end
#> 99  school_year_end
#> 100 school_year_end
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
#> 116     fiscal_year
#> 117     fiscal_year
#> 118     fiscal_year
#> 119     fiscal_year
#> 120     fiscal_year
#> 121     fiscal_year
#> 122     fiscal_year
#> 123     fiscal_year
#> 124     fiscal_year
#> 125     fiscal_year
#> 126     fiscal_year
#> 127     fiscal_year
#> 128     fiscal_year
#> 129     fiscal_year
#> 130     fiscal_year
#> 131     fiscal_year
#> 132     fiscal_year
#> 133     fiscal_year
#> 134     fiscal_year
#> 135     fiscal_year
#> 136     fiscal_year
#> 137     cohort_year
#> 138     cohort_year
#> 139     cohort_year
#> 140     cohort_year
#> 141     cohort_year
#> 142     cohort_year
#> 143     cohort_year
#> 144     cohort_year
#> 145     cohort_year
#> 146     cohort_year
#> 147     cohort_year
#> 148 school_year_end
#> 149     cohort_year
#> 150 school_year_end
#> 151     cohort_year
#> 152 school_year_end
#> 153     cohort_year
#> 154 school_year_end
#> 155     cohort_year
#> 156 school_year_end
#> 157 school_year_end
#> 158 school_year_end
#> 159 school_year_end
#> 160 school_year_end
#> 161 school_year_end
#> 162 school_year_end
#> 163 school_year_end
#> 164 school_year_end
#> 165 school_year_end
#> 166 school_year_end
#> 167 school_year_end
#> 168 school_year_end
#> 169 school_year_end
#> 170 school_year_end
#> 171 school_year_end
#> 172 school_year_end
#> 173 school_year_end
#> 174 school_year_end
#> 175 school_year_end
#> 176 school_year_end
#> 177 school_year_end
#> 178 school_year_end
#> 179 school_year_end
#> 181 school_year_end
#> 182 school_year_end
#> 183 school_year_end
#> 184 school_year_end
#> 185 school_year_end
#> 186 school_year_end
#> 187 school_year_end
#> 190 school_year_end
#> 191 school_year_end
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
#> 30                                                              <NA>   <NA>
#> 31                                                              <NA>   <NA>
#> 32                                                              <NA>   <NA>
#> 33                                                              <NA>   <NA>
#> 34                                                              <NA>   <NA>
#> 37          https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 38          https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 39                                                              <NA>   <NA>
#> 40          https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 41          https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 42                                                              <NA>   <NA>
#> 43          https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 44          https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 45                                                              <NA>   <NA>
#> 46          https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 47          https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 48                                                              <NA>   <NA>
#> 49          https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 50                                                              <NA>   <NA>
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
#> 83                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 84                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 85                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 86                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 87                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 88                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 89                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 90                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 91                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 92                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 93                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 94                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 95                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 96                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 97                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 98                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 99                         https://www.nj.gov/education/doedata/enr/   <NA>
#> 100                        https://www.nj.gov/education/doedata/enr/   <NA>
#> 104                              https://www.nj.gov/education/guide/   <NA>
#> 105                              https://www.nj.gov/education/guide/   <NA>
#> 106                              https://www.nj.gov/education/guide/   <NA>
#> 107                              https://www.nj.gov/education/guide/   <NA>
#> 108                              https://www.nj.gov/education/guide/   <NA>
#> 109                              https://www.nj.gov/education/guide/   <NA>
#> 110                              https://www.nj.gov/education/guide/   <NA>
#> 111                              https://www.nj.gov/education/guide/   <NA>
#> 112                              https://www.nj.gov/education/guide/   <NA>
#> 113                              https://www.nj.gov/education/guide/   <NA>
#> 114                              https://www.nj.gov/education/guide/   <NA>
#> 115                              https://www.nj.gov/education/guide/   <NA>
#> 116                              https://www.nj.gov/education/guide/   <NA>
#> 117                              https://www.nj.gov/education/guide/   <NA>
#> 118                              https://www.nj.gov/education/guide/   <NA>
#> 119                              https://www.nj.gov/education/guide/   <NA>
#> 120                              https://www.nj.gov/education/guide/   <NA>
#> 121                              https://www.nj.gov/education/guide/   <NA>
#> 122                           https://www.nj.gov/education/stateaid/   <NA>
#> 123                              https://www.nj.gov/education/guide/   <NA>
#> 124                           https://www.nj.gov/education/stateaid/   <NA>
#> 125                              https://www.nj.gov/education/guide/   <NA>
#> 126                           https://www.nj.gov/education/stateaid/   <NA>
#> 127                              https://www.nj.gov/education/guide/   <NA>
#> 128                           https://www.nj.gov/education/stateaid/   <NA>
#> 129                              https://www.nj.gov/education/guide/   <NA>
#> 130                           https://www.nj.gov/education/stateaid/   <NA>
#> 131                              https://www.nj.gov/education/guide/   <NA>
#> 132                           https://www.nj.gov/education/stateaid/   <NA>
#> 133                              https://www.nj.gov/education/guide/   <NA>
#> 134                           https://www.nj.gov/education/stateaid/   <NA>
#> 135                           https://www.nj.gov/education/stateaid/   <NA>
#> 136                           https://www.nj.gov/education/stateaid/   <NA>
#> 137                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 138                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 139                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 140                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 141                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 142                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 143                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 144                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 145                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 146                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 147                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 148                       https://www.nj.gov/education/spr/download/   <NA>
#> 149                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 150                       https://www.nj.gov/education/spr/download/   <NA>
#> 151                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 152                       https://www.nj.gov/education/spr/download/   <NA>
#> 153                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 154                       https://www.nj.gov/education/spr/download/   <NA>
#> 155                        https://www.nj.gov/education/spr/adddata/   <NA>
#> 156                       https://www.nj.gov/education/spr/download/   <NA>
#> 157   https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 158                                                             <NA>   <NA>
#> 159   https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 160                                                             <NA>   <NA>
#> 161   https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 162                                                             <NA>   <NA>
#> 163   https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 164                                                             <NA>   <NA>
#> 165                                                             <NA>   <NA>
#> 166                                                             <NA>   <NA>
#> 167                                                             <NA>   <NA>
#> 168   https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 169                                                             <NA>   <NA>
#> 170                                                             <NA>   <NA>
#> 171                                                             <NA>   <NA>
#> 172                                                             <NA>   <NA>
#> 173                                                             <NA>   <NA>
#> 174                                                             <NA>   <NA>
#> 175                                                             <NA>   <NA>
#> 176                                                             <NA>   <NA>
#> 177 https://www.nj.gov/education/specialed/monitor/dataandresources/   <NA>
#> 178 https://www.nj.gov/education/specialed/monitor/dataandresources/   <NA>
#> 179 https://www.nj.gov/education/specialed/monitor/dataandresources/   <NA>
#> 181                       https://www.nj.gov/education/spr/download/   <NA>
#> 182                                                             <NA>   <NA>
#> 183                       https://www.nj.gov/education/spr/download/   <NA>
#> 184                                                             <NA>   <NA>
#> 185                       https://www.nj.gov/education/spr/download/   <NA>
#> 186                                                             <NA>   <NA>
#> 187                                                             <NA>   <NA>
#> 190                       https://www.nj.gov/education/spr/download/   <NA>
#> 191                       https://www.nj.gov/education/spr/download/   <NA>
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
#> 30      <NA>       <NA>
#> 31      <NA>       <NA>
#> 32      <NA>       <NA>
#> 33      <NA>       <NA>
#> 34      <NA>       <NA>
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
#> 153     <NA>       <NA>
#> 154     <NA>       <NA>
#> 155     <NA>       <NA>
#> 156     <NA>       <NA>
#> 157     <NA>       <NA>
#> 158     <NA>       <NA>
#> 159     <NA>       <NA>
#> 160     <NA>       <NA>
#> 161     <NA>       <NA>
#> 162     <NA>       <NA>
#> 163     <NA>       <NA>
#> 164     <NA>       <NA>
#> 165     <NA>       <NA>
#> 166     <NA>       <NA>
#> 167     <NA>       <NA>
#> 168     <NA>       <NA>
#> 169     <NA>       <NA>
#> 170     <NA>       <NA>
#> 171     <NA>       <NA>
#> 172     <NA>       <NA>
#> 173     <NA>       <NA>
#> 174     <NA>       <NA>
#> 175     <NA>       <NA>
#> 176     <NA>       <NA>
#> 177     <NA>       <NA>
#> 178     <NA>       <NA>
#> 179     <NA>       <NA>
#> 181     <NA>       <NA>
#> 182     <NA>       <NA>
#> 183     <NA>       <NA>
#> 184     <NA>       <NA>
#> 185     <NA>       <NA>
#> 186     <NA>       <NA>
#> 187     <NA>       <NA>
#> 190     <NA>       <NA>
#> 191     <NA>       <NA>
get_data_registry(family = "enrollment", end_year = 2024)
#>    state     family end_year               source_id variant status mode
#> 98    NJ enrollment     2024 fall_enrollment_reports    <NA> served live
#>      fetcher n_source_files n_derived_files   bytes
#> 98 fetch_enr              1               0 1061242
#>                                                            source_url
#> 98 https://www.nj.gov/education/doedata/enr/enr24/enrollment_2324.zip
#>                             publisher publisher_type                   title
#> 98 New Jersey Department of Education      state_doe Fall Enrollment Reports
#>         year_basis                               landing_url reason evidence
#> 98 school_year_end https://www.nj.gov/education/doedata/enr/   <NA>     <NA>
#>    checked_on
#> 98       <NA>
```
