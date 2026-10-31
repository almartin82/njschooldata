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
#>     state     family end_year                               source_id variant
#> 1      NJ    absence     2017     school_performance_reports_database    <NA>
#> 2      NJ    absence     2018     school_performance_reports_database    <NA>
#> 3      NJ    absence     2019     school_performance_reports_database    <NA>
#> 5      NJ    absence     2021     school_performance_reports_database    <NA>
#> 6      NJ    absence     2022     school_performance_reports_database    <NA>
#> 7      NJ    absence     2023     school_performance_reports_database    <NA>
#> 8      NJ    absence     2024     school_performance_reports_database    <NA>
#> 9      NJ    absence     2025     school_performance_reports_database    <NA>
#> 10     NJ assessment     2022                 access_for_ells_results    <NA>
#> 11     NJ assessment     2023                 access_for_ells_results    <NA>
#> 12     NJ assessment     2024                 access_for_ells_results    <NA>
#> 13     NJ assessment     2025                 access_for_ells_results    <NA>
#> 15     NJ        ell     2006                 fall_enrollment_reports    <NA>
#> 16     NJ        ell     2007                 fall_enrollment_reports    <NA>
#> 17     NJ        ell     2008                 fall_enrollment_reports    <NA>
#> 18     NJ        ell     2009                 fall_enrollment_reports    <NA>
#> 19     NJ        ell     2010                 fall_enrollment_reports    <NA>
#> 20     NJ        ell     2011                 fall_enrollment_reports    <NA>
#> 21     NJ        ell     2012                 fall_enrollment_reports    <NA>
#> 22     NJ        ell     2013                 fall_enrollment_reports    <NA>
#> 23     NJ        ell     2014                 fall_enrollment_reports    <NA>
#> 24     NJ        ell     2015                 fall_enrollment_reports    <NA>
#> 25     NJ        ell     2016                 fall_enrollment_reports    <NA>
#> 26     NJ        ell     2017                 fall_enrollment_reports    <NA>
#> 27     NJ        ell     2018                 fall_enrollment_reports    <NA>
#> 28     NJ        ell     2019                 fall_enrollment_reports    <NA>
#> 29     NJ        ell     2020                 fall_enrollment_reports    <NA>
#> 30     NJ        ell     2021                 fall_enrollment_reports    <NA>
#> 31     NJ        ell     2022                 fall_enrollment_reports    <NA>
#> 32     NJ        ell     2023                 fall_enrollment_reports    <NA>
#> 33     NJ        ell     2024                 fall_enrollment_reports    <NA>
#> 34     NJ        ell     2025                 fall_enrollment_reports    <NA>
#> 35     NJ        ell     2026                 fall_enrollment_reports    <NA>
#> 36     NJ enrollment     1999                 fall_enrollment_reports    <NA>
#> 37     NJ enrollment     2000                 fall_enrollment_reports    <NA>
#> 38     NJ enrollment     2001                 fall_enrollment_reports    <NA>
#> 39     NJ enrollment     2002                 fall_enrollment_reports    <NA>
#> 40     NJ enrollment     2003                 fall_enrollment_reports    <NA>
#> 41     NJ enrollment     2004                 fall_enrollment_reports    <NA>
#> 42     NJ enrollment     2005                 fall_enrollment_reports    <NA>
#> 43     NJ enrollment     2006                 fall_enrollment_reports    <NA>
#> 44     NJ enrollment     2007                 fall_enrollment_reports    <NA>
#> 45     NJ enrollment     2008                 fall_enrollment_reports    <NA>
#> 46     NJ enrollment     2009                 fall_enrollment_reports    <NA>
#> 47     NJ enrollment     2010                 fall_enrollment_reports    <NA>
#> 48     NJ enrollment     2011                 fall_enrollment_reports    <NA>
#> 49     NJ enrollment     2012                 fall_enrollment_reports    <NA>
#> 50     NJ enrollment     2013                 fall_enrollment_reports    <NA>
#> 51     NJ enrollment     2014                 fall_enrollment_reports    <NA>
#> 52     NJ enrollment     2015                 fall_enrollment_reports    <NA>
#> 53     NJ enrollment     2016                 fall_enrollment_reports    <NA>
#> 54     NJ enrollment     2017                 fall_enrollment_reports    <NA>
#> 55     NJ enrollment     2018                 fall_enrollment_reports    <NA>
#> 56     NJ enrollment     2019                 fall_enrollment_reports    <NA>
#> 57     NJ enrollment     2020                 fall_enrollment_reports    <NA>
#> 58     NJ enrollment     2021                 fall_enrollment_reports    <NA>
#> 59     NJ enrollment     2022                 fall_enrollment_reports    <NA>
#> 60     NJ enrollment     2023                 fall_enrollment_reports    <NA>
#> 61     NJ enrollment     2024                 fall_enrollment_reports    <NA>
#> 62     NJ enrollment     2025                 fall_enrollment_reports    <NA>
#> 63     NJ enrollment     2026                 fall_enrollment_reports    <NA>
#> 64     NJ    finance     2001 taxpayers_guide_to_educational_spending    <NA>
#> 65     NJ    finance     2002 taxpayers_guide_to_educational_spending    <NA>
#> 66     NJ    finance     2003 taxpayers_guide_to_educational_spending    <NA>
#> 67     NJ    finance     2004 taxpayers_guide_to_educational_spending    <NA>
#> 68     NJ    finance     2005 taxpayers_guide_to_educational_spending    <NA>
#> 69     NJ    finance     2006 taxpayers_guide_to_educational_spending    <NA>
#> 70     NJ    finance     2007 taxpayers_guide_to_educational_spending    <NA>
#> 71     NJ    finance     2008 taxpayers_guide_to_educational_spending    <NA>
#> 72     NJ    finance     2009 taxpayers_guide_to_educational_spending    <NA>
#> 73     NJ    finance     2010 taxpayers_guide_to_educational_spending    <NA>
#> 74     NJ    finance     2011 taxpayers_guide_to_educational_spending    <NA>
#> 75     NJ    finance     2012 taxpayers_guide_to_educational_spending    <NA>
#> 76     NJ    finance     2013 taxpayers_guide_to_educational_spending    <NA>
#> 77     NJ    finance     2014 taxpayers_guide_to_educational_spending    <NA>
#> 78     NJ    finance     2015 taxpayers_guide_to_educational_spending    <NA>
#> 79     NJ    finance     2016 taxpayers_guide_to_educational_spending    <NA>
#> 80     NJ    finance     2017 taxpayers_guide_to_educational_spending    <NA>
#> 81     NJ    finance     2018 taxpayers_guide_to_educational_spending    <NA>
#> 82     NJ    finance     2019              state_aid_district_details    <NA>
#> 83     NJ    finance     2019 taxpayers_guide_to_educational_spending    <NA>
#> 84     NJ    finance     2020              state_aid_district_details    <NA>
#> 85     NJ    finance     2020 taxpayers_guide_to_educational_spending    <NA>
#> 86     NJ    finance     2021              state_aid_district_details    <NA>
#> 87     NJ    finance     2021 taxpayers_guide_to_educational_spending    <NA>
#> 88     NJ    finance     2022              state_aid_district_details    <NA>
#> 89     NJ    finance     2022 taxpayers_guide_to_educational_spending    <NA>
#> 90     NJ    finance     2023              state_aid_district_details    <NA>
#> 91     NJ    finance     2023 taxpayers_guide_to_educational_spending    <NA>
#> 92     NJ    finance     2024              state_aid_district_details    <NA>
#> 93     NJ    finance     2024 taxpayers_guide_to_educational_spending    <NA>
#> 94     NJ    finance     2025              state_aid_district_details    <NA>
#> 95     NJ    finance     2026              state_aid_district_details    <NA>
#> 96     NJ graduation     2011 adjusted_cohort_graduation_rate_reports    <NA>
#> 97     NJ graduation     2012 adjusted_cohort_graduation_rate_reports    <NA>
#> 98     NJ graduation     2013 adjusted_cohort_graduation_rate_reports    <NA>
#> 99     NJ graduation     2014 adjusted_cohort_graduation_rate_reports    <NA>
#> 100    NJ graduation     2015 adjusted_cohort_graduation_rate_reports    <NA>
#> 101    NJ graduation     2016 adjusted_cohort_graduation_rate_reports    <NA>
#> 102    NJ graduation     2017 adjusted_cohort_graduation_rate_reports    <NA>
#> 103    NJ graduation     2018 adjusted_cohort_graduation_rate_reports    <NA>
#> 104    NJ graduation     2019 adjusted_cohort_graduation_rate_reports    <NA>
#> 105    NJ graduation     2020 adjusted_cohort_graduation_rate_reports    <NA>
#> 106    NJ graduation     2021 adjusted_cohort_graduation_rate_reports    <NA>
#> 107    NJ graduation     2021     school_performance_reports_database    <NA>
#> 108    NJ graduation     2022 adjusted_cohort_graduation_rate_reports    <NA>
#> 109    NJ graduation     2022     school_performance_reports_database    <NA>
#> 110    NJ graduation     2023 adjusted_cohort_graduation_rate_reports    <NA>
#> 111    NJ graduation     2023     school_performance_reports_database    <NA>
#> 112    NJ graduation     2024 adjusted_cohort_graduation_rate_reports    <NA>
#> 113    NJ graduation     2024     school_performance_reports_database    <NA>
#> 114    NJ graduation     2025 adjusted_cohort_graduation_rate_reports    <NA>
#> 115    NJ graduation     2025     school_performance_reports_database    <NA>
#> 116    NJ      other     2017           essa_accountability_workbooks    <NA>
#> 117    NJ      other     2018           essa_accountability_workbooks    <NA>
#> 118    NJ      other     2019           essa_accountability_workbooks    <NA>
#> 119    NJ      other     2019              state_aid_district_details    <NA>
#> 120    NJ      other     2020              state_aid_district_details    <NA>
#> 121    NJ      other     2021              state_aid_district_details    <NA>
#> 122    NJ      other     2022           essa_accountability_workbooks    <NA>
#> 123    NJ      other     2022              state_aid_district_details    <NA>
#> 124    NJ      other     2023           essa_accountability_workbooks    <NA>
#> 125    NJ      other     2023              state_aid_district_details    <NA>
#> 126    NJ      other     2024           essa_accountability_workbooks    <NA>
#> 127    NJ      other     2024              state_aid_district_details    <NA>
#> 128    NJ      other     2025              state_aid_district_details    <NA>
#> 129    NJ      other     2026              state_aid_district_details    <NA>
#> 130    NJ      other     2027              state_aid_district_details    <NA>
#> 131    NJ       sped     2015  idea_618_district_classification_rates    <NA>
#> 132    NJ       sped     2016  idea_618_district_classification_rates    <NA>
#> 133    NJ       sped     2017  idea_618_district_classification_rates    <NA>
#> 134    NJ       sped     2018  idea_618_district_classification_rates    <NA>
#> 135    NJ       sped     2019  idea_618_district_classification_rates    <NA>
#> 136    NJ       sped     2020  idea_618_district_classification_rates    <NA>
#> 137    NJ       sped     2021  idea_618_district_classification_rates    <NA>
#> 138    NJ       sped     2022  idea_618_district_classification_rates    <NA>
#> 139    NJ       sped     2023       opra_response_iep_counts_by_grade    <NA>
#> 140    NJ       sped     2024       opra_response_iep_counts_by_grade    <NA>
#> 141    NJ       sped     2025       opra_response_iep_counts_by_grade    <NA>
#> 142    NJ       sped     2026       opra_response_iep_counts_by_grade    <NA>
#>     status mode                                                fetcher
#> 1   served live                                          fetch_absence
#> 2   served live                                          fetch_absence
#> 3   served live                                          fetch_absence
#> 5   served live                                          fetch_absence
#> 6   served live                                          fetch_absence
#> 7   served live                                          fetch_absence
#> 8   served live                                          fetch_absence
#> 9   served live                                          fetch_absence
#> 10  served live                                           fetch_access
#> 11  served live                                           fetch_access
#> 12  served live                                           fetch_access
#> 13  served live                                           fetch_access
#> 15  served live                                              fetch_ell
#> 16  served live                                              fetch_ell
#> 17  served live                                              fetch_ell
#> 18  served live                                              fetch_ell
#> 19  served live                                              fetch_ell
#> 20  served live                                              fetch_ell
#> 21  served live                                              fetch_ell
#> 22  served live                                              fetch_ell
#> 23  served live                                              fetch_ell
#> 24  served live                                              fetch_ell
#> 25  served live                                              fetch_ell
#> 26  served live                                              fetch_ell
#> 27  served live                                              fetch_ell
#> 28  served live                                              fetch_ell
#> 29  served live                                              fetch_ell
#> 30  served live                                              fetch_ell
#> 31  served live                                              fetch_ell
#> 32  served live                                              fetch_ell
#> 33  served live                                              fetch_ell
#> 34  served live                                              fetch_ell
#> 35  served live                                              fetch_ell
#> 36  served live                                              fetch_enr
#> 37  served live                                              fetch_enr
#> 38  served live                                              fetch_enr
#> 39  served live                                              fetch_enr
#> 40  served live                                              fetch_enr
#> 41  served live                                              fetch_enr
#> 42  served live                                              fetch_enr
#> 43  served live                                              fetch_enr
#> 44  served live                                              fetch_enr
#> 45  served live                                              fetch_enr
#> 46  served live                                              fetch_enr
#> 47  served live                                              fetch_enr
#> 48  served live                                              fetch_enr
#> 49  served live                                              fetch_enr
#> 50  served live                                              fetch_enr
#> 51  served live                                              fetch_enr
#> 52  served live                                              fetch_enr
#> 53  served live                                              fetch_enr
#> 54  served live                                              fetch_enr
#> 55  served live                                              fetch_enr
#> 56  served live                                              fetch_enr
#> 57  served live                                              fetch_enr
#> 58  served live                                              fetch_enr
#> 59  served live                                              fetch_enr
#> 60  served live                                              fetch_enr
#> 61  served live                                              fetch_enr
#> 62  served live                                              fetch_enr
#> 63  served live                                              fetch_enr
#> 64  served live                                          fetch_finance
#> 65  served live                                          fetch_finance
#> 66  served live                                          fetch_finance
#> 67  served live                                          fetch_finance
#> 68  served live                                          fetch_finance
#> 69  served live                                          fetch_finance
#> 70  served live                                          fetch_finance
#> 71  served live                                          fetch_finance
#> 72  served live                                          fetch_finance
#> 73  served live                                          fetch_finance
#> 74  served live                                          fetch_finance
#> 75  served live                                          fetch_finance
#> 76  served live                                          fetch_finance
#> 77  served live                                          fetch_finance
#> 78  served live                                          fetch_finance
#> 79  served live                                          fetch_finance
#> 80  served live                                          fetch_finance
#> 81  served live                                          fetch_finance
#> 82  served live                                          fetch_finance
#> 83  served live                                          fetch_finance
#> 84  served live                                          fetch_finance
#> 85  served live                                          fetch_finance
#> 86  served live                                          fetch_finance
#> 87  served live                                          fetch_finance
#> 88  served live                                          fetch_finance
#> 89  served live                                          fetch_finance
#> 90  served live                                          fetch_finance
#> 91  served live                                          fetch_finance
#> 92  served live                                          fetch_finance
#> 93  served live                                          fetch_finance
#> 94  served live                                          fetch_finance
#> 95  served live                                          fetch_finance
#> 96  served live                                        fetch_grad_rate
#> 97  served live                      fetch_grad_count; fetch_grad_rate
#> 98  served live                      fetch_grad_count; fetch_grad_rate
#> 99  served live                      fetch_grad_count; fetch_grad_rate
#> 100 served live                      fetch_grad_count; fetch_grad_rate
#> 101 served live                      fetch_grad_count; fetch_grad_rate
#> 102 served live                      fetch_grad_count; fetch_grad_rate
#> 103 served live                      fetch_grad_count; fetch_grad_rate
#> 104 served live                      fetch_grad_count; fetch_grad_rate
#> 105 served live                      fetch_grad_count; fetch_grad_rate
#> 106 served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 107 served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 108 served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 109 served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 110 served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 111 served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 112 served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 113 served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 114 served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 115 served live fetch_6yr_grad_rate; fetch_grad_count; fetch_grad_rate
#> 116 served live                         fetch_essa_chronic_absenteeism
#> 117 served live                         fetch_essa_chronic_absenteeism
#> 118 served live        fetch_essa_chronic_absenteeism; fetch_state_aid
#> 119 served live        fetch_essa_chronic_absenteeism; fetch_state_aid
#> 120 served live                                        fetch_state_aid
#> 121 served live                                        fetch_state_aid
#> 122 served live        fetch_essa_chronic_absenteeism; fetch_state_aid
#> 123 served live        fetch_essa_chronic_absenteeism; fetch_state_aid
#> 124 served live        fetch_essa_chronic_absenteeism; fetch_state_aid
#> 125 served live        fetch_essa_chronic_absenteeism; fetch_state_aid
#> 126 served live        fetch_essa_chronic_absenteeism; fetch_state_aid
#> 127 served live        fetch_essa_chronic_absenteeism; fetch_state_aid
#> 128 served live                                        fetch_state_aid
#> 129 served live                                        fetch_state_aid
#> 130 served live                                        fetch_state_aid
#> 131 served live                                             fetch_sped
#> 132 served live                                             fetch_sped
#> 133 served live                                             fetch_sped
#> 134 served live                                             fetch_sped
#> 135 served live                                             fetch_sped
#> 136 served live                                             fetch_sped
#> 137 served live                                             fetch_sped
#> 138 served live                        fetch_sped; fetch_sped_by_grade
#> 139 served live      fetch_sped; fetch_sped_by_grade; fetch_sped_share
#> 140 served live      fetch_sped; fetch_sped_by_grade; fetch_sped_share
#> 141 served live      fetch_sped; fetch_sped_by_grade; fetch_sped_share
#> 142 served live                  fetch_sped_by_grade; fetch_sped_share
#>     n_source_files n_derived_files   bytes
#> 1                0               0       0
#> 2                0               0       0
#> 3                0               0       0
#> 5                0               0       0
#> 6                0               0       0
#> 7                0               0       0
#> 8                0               0       0
#> 9                0               0       0
#> 10               0               0       0
#> 11               0               0       0
#> 12               0               0       0
#> 13               0               0       0
#> 15               0               0       0
#> 16               0               0       0
#> 17               0               0       0
#> 18               0               0       0
#> 19               0               0       0
#> 20               0               0       0
#> 21               0               0       0
#> 22               0               0       0
#> 23               0               0       0
#> 24               0               0       0
#> 25               0               0       0
#> 26               0               0       0
#> 27               0               0       0
#> 28               0               0       0
#> 29               0               0       0
#> 30               0               0       0
#> 31               0               0       0
#> 32               0               0       0
#> 33               0               0       0
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
#> 55               0               0       0
#> 56               0               0       0
#> 57               0               0       0
#> 58               0               0       0
#> 59               0               0       0
#> 60               1               0 1119856
#> 61               1               0 1061242
#> 62               1               0 1095121
#> 63               1               0 1061437
#> 64               0               0       0
#> 65               0               0       0
#> 66               0               0       0
#> 67               0               0       0
#> 68               0               0       0
#> 69               0               0       0
#> 70               0               0       0
#> 71               0               0       0
#> 72               0               0       0
#> 73               0               0       0
#> 74               0               0       0
#> 75               0               0       0
#> 76               0               0       0
#> 77               0               0       0
#> 78               0               0       0
#> 79               0               0       0
#> 80               0               0       0
#> 81               0               0       0
#> 82               0               0       0
#> 83               0               0       0
#> 84               0               0       0
#> 85               0               0       0
#> 86               0               0       0
#> 87               0               0       0
#> 88               0               0       0
#> 89               0               0       0
#> 90               0               0       0
#> 91               0               0       0
#> 92               0               0       0
#> 93               0               0       0
#> 94               0               0       0
#> 95               0               0       0
#> 96               0               0       0
#> 97               0               0       0
#> 98               0               0       0
#> 99               0               0       0
#> 100              0               0       0
#> 101              0               0       0
#> 102              0               0       0
#> 103              0               0       0
#> 104              0               0       0
#> 105              0               0       0
#> 106              0               0       0
#> 107              0               0       0
#> 108              0               0       0
#> 109              0               0       0
#> 110              0               0       0
#> 111              0               0       0
#> 112              0               0       0
#> 113              0               0       0
#> 114              0               0       0
#> 115              0               0       0
#> 116              0               0       0
#> 117              0               0       0
#> 118              0               0       0
#> 119              0               0       0
#> 120              0               0       0
#> 121              0               0       0
#> 122              0               0       0
#> 123              0               0       0
#> 124              0               0       0
#> 125              0               0       0
#> 126              0               0       0
#> 127              0               0       0
#> 128              0               0       0
#> 129              0               0       0
#> 130              0               0       0
#> 131              0               0       0
#> 132              0               0       0
#> 133              0               0       0
#> 134              0               0       0
#> 135              0               0       0
#> 136              0               0       0
#> 137              0               0       0
#> 138              0               0       0
#> 139              0               0       0
#> 140              0               0       0
#> 141              0               0       0
#> 142              0               0       0
#>                                                             source_url
#> 1                                                                 <NA>
#> 2                                                                 <NA>
#> 3                                                                 <NA>
#> 5                                                                 <NA>
#> 6                                                                 <NA>
#> 7                                                                 <NA>
#> 8                                                                 <NA>
#> 9                                                                 <NA>
#> 10                                                                <NA>
#> 11                                                                <NA>
#> 12                                                                <NA>
#> 13                                                                <NA>
#> 15                                                                <NA>
#> 16                                                                <NA>
#> 17                                                                <NA>
#> 18                                                                <NA>
#> 19                                                                <NA>
#> 20                                                                <NA>
#> 21                                                                <NA>
#> 22                                                                <NA>
#> 23                                                                <NA>
#> 24                                                                <NA>
#> 25                                                                <NA>
#> 26                                                                <NA>
#> 27                                                                <NA>
#> 28                                                                <NA>
#> 29                                                                <NA>
#> 30                                                                <NA>
#> 31                                                                <NA>
#> 32                                                                <NA>
#> 33                                                                <NA>
#> 34                                                                <NA>
#> 35                                                                <NA>
#> 36                                                                <NA>
#> 37                                                                <NA>
#> 38                                                                <NA>
#> 39                                                                <NA>
#> 40                                                                <NA>
#> 41                                                                <NA>
#> 42                                                                <NA>
#> 43                                                                <NA>
#> 44                                                                <NA>
#> 45                                                                <NA>
#> 46                                                                <NA>
#> 47                                                                <NA>
#> 48                                                                <NA>
#> 49                                                                <NA>
#> 50                                                                <NA>
#> 51                                                                <NA>
#> 52                                                                <NA>
#> 53                                                                <NA>
#> 54                                                                <NA>
#> 55                                                                <NA>
#> 56                                                                <NA>
#> 57                                                                <NA>
#> 58                                                                <NA>
#> 59                                                                <NA>
#> 60  https://www.nj.gov/education/doedata/enr/enr23/enrollment_2223.zip
#> 61  https://www.nj.gov/education/doedata/enr/enr24/enrollment_2324.zip
#> 62  https://www.nj.gov/education/doedata/enr/enr25/enrollment_2425.zip
#> 63  https://www.nj.gov/education/doedata/enr/enr26/Enrollment_2526.zip
#> 64                                                                <NA>
#> 65                                                                <NA>
#> 66                                                                <NA>
#> 67                                                                <NA>
#> 68                                                                <NA>
#> 69                                                                <NA>
#> 70                                                                <NA>
#> 71                                                                <NA>
#> 72                                                                <NA>
#> 73                                                                <NA>
#> 74                                                                <NA>
#> 75                                                                <NA>
#> 76                                                                <NA>
#> 77                                                                <NA>
#> 78                                                                <NA>
#> 79                                                                <NA>
#> 80                                                                <NA>
#> 81                                                                <NA>
#> 82                                                                <NA>
#> 83                                                                <NA>
#> 84                                                                <NA>
#> 85                                                                <NA>
#> 86                                                                <NA>
#> 87                                                                <NA>
#> 88                                                                <NA>
#> 89                                                                <NA>
#> 90                                                                <NA>
#> 91                                                                <NA>
#> 92                                                                <NA>
#> 93                                                                <NA>
#> 94                                                                <NA>
#> 95                                                                <NA>
#> 96                                                                <NA>
#> 97                                                                <NA>
#> 98                                                                <NA>
#> 99                                                                <NA>
#> 100                                                               <NA>
#> 101                                                               <NA>
#> 102                                                               <NA>
#> 103                                                               <NA>
#> 104                                                               <NA>
#> 105                                                               <NA>
#> 106                                                               <NA>
#> 107                                                               <NA>
#> 108                                                               <NA>
#> 109                                                               <NA>
#> 110                                                               <NA>
#> 111                                                               <NA>
#> 112                                                               <NA>
#> 113                                                               <NA>
#> 114                                                               <NA>
#> 115                                                               <NA>
#> 116                                                               <NA>
#> 117                                                               <NA>
#> 118                                                               <NA>
#> 119                                                               <NA>
#> 120                                                               <NA>
#> 121                                                               <NA>
#> 122                                                               <NA>
#> 123                                                               <NA>
#> 124                                                               <NA>
#> 125                                                               <NA>
#> 126                                                               <NA>
#> 127                                                               <NA>
#> 128                                                               <NA>
#> 129                                                               <NA>
#> 130                                                               <NA>
#> 131                                                               <NA>
#> 132                                                               <NA>
#> 133                                                               <NA>
#> 134                                                               <NA>
#> 135                                                               <NA>
#> 136                                                               <NA>
#> 137                                                               <NA>
#> 138                                                               <NA>
#> 139                                                               <NA>
#> 140                                                               <NA>
#> 141                                                               <NA>
#> 142                                                               <NA>
#>                              publisher publisher_type
#> 1   New Jersey Department of Education      state_doe
#> 2   New Jersey Department of Education      state_doe
#> 3   New Jersey Department of Education      state_doe
#> 5   New Jersey Department of Education      state_doe
#> 6   New Jersey Department of Education      state_doe
#> 7   New Jersey Department of Education      state_doe
#> 8   New Jersey Department of Education      state_doe
#> 9   New Jersey Department of Education      state_doe
#> 10  New Jersey Department of Education      state_doe
#> 11  New Jersey Department of Education      state_doe
#> 12  New Jersey Department of Education      state_doe
#> 13  New Jersey Department of Education      state_doe
#> 15  New Jersey Department of Education      state_doe
#> 16  New Jersey Department of Education      state_doe
#> 17  New Jersey Department of Education      state_doe
#> 18  New Jersey Department of Education      state_doe
#> 19  New Jersey Department of Education      state_doe
#> 20  New Jersey Department of Education      state_doe
#> 21  New Jersey Department of Education      state_doe
#> 22  New Jersey Department of Education      state_doe
#> 23  New Jersey Department of Education      state_doe
#> 24  New Jersey Department of Education      state_doe
#> 25  New Jersey Department of Education      state_doe
#> 26  New Jersey Department of Education      state_doe
#> 27  New Jersey Department of Education      state_doe
#> 28  New Jersey Department of Education      state_doe
#> 29  New Jersey Department of Education      state_doe
#> 30  New Jersey Department of Education      state_doe
#> 31  New Jersey Department of Education      state_doe
#> 32  New Jersey Department of Education      state_doe
#> 33  New Jersey Department of Education      state_doe
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
#>                                                                         title
#> 1        School Performance Reports downloadable data, school detail database
#> 2        School Performance Reports downloadable data, school detail database
#> 3        School Performance Reports downloadable data, school detail database
#> 5        School Performance Reports downloadable data, school detail database
#> 6        School Performance Reports downloadable data, school detail database
#> 7        School Performance Reports downloadable data, school detail database
#> 8        School Performance Reports downloadable data, school detail database
#> 9        School Performance Reports downloadable data, school detail database
#> 10                                         ACCESS for ELLs results data files
#> 11                                         ACCESS for ELLs results data files
#> 12                                         ACCESS for ELLs results data files
#> 13                                         ACCESS for ELLs results data files
#> 15                                                    Fall Enrollment Reports
#> 16                                                    Fall Enrollment Reports
#> 17                                                    Fall Enrollment Reports
#> 18                                                    Fall Enrollment Reports
#> 19                                                    Fall Enrollment Reports
#> 20                                                    Fall Enrollment Reports
#> 21                                                    Fall Enrollment Reports
#> 22                                                    Fall Enrollment Reports
#> 23                                                    Fall Enrollment Reports
#> 24                                                    Fall Enrollment Reports
#> 25                                                    Fall Enrollment Reports
#> 26                                                    Fall Enrollment Reports
#> 27                                                    Fall Enrollment Reports
#> 28                                                    Fall Enrollment Reports
#> 29                                                    Fall Enrollment Reports
#> 30                                                    Fall Enrollment Reports
#> 31                                                    Fall Enrollment Reports
#> 32                                                    Fall Enrollment Reports
#> 33                                                    Fall Enrollment Reports
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
#> 64                                   Taxpayers' Guide to Educational Spending
#> 65                                   Taxpayers' Guide to Educational Spending
#> 66                                   Taxpayers' Guide to Educational Spending
#> 67                                   Taxpayers' Guide to Educational Spending
#> 68                                   Taxpayers' Guide to Educational Spending
#> 69                                   Taxpayers' Guide to Educational Spending
#> 70                                   Taxpayers' Guide to Educational Spending
#> 71                                   Taxpayers' Guide to Educational Spending
#> 72                                   Taxpayers' Guide to Educational Spending
#> 73                                   Taxpayers' Guide to Educational Spending
#> 74                                   Taxpayers' Guide to Educational Spending
#> 75                                   Taxpayers' Guide to Educational Spending
#> 76                                   Taxpayers' Guide to Educational Spending
#> 77                                   Taxpayers' Guide to Educational Spending
#> 78                                   Taxpayers' Guide to Educational Spending
#> 79                                   Taxpayers' Guide to Educational Spending
#> 80                                   Taxpayers' Guide to Educational Spending
#> 81                                   Taxpayers' Guide to Educational Spending
#> 82                             State aid summaries, district details workbook
#> 83                                   Taxpayers' Guide to Educational Spending
#> 84                             State aid summaries, district details workbook
#> 85                                   Taxpayers' Guide to Educational Spending
#> 86                             State aid summaries, district details workbook
#> 87                                   Taxpayers' Guide to Educational Spending
#> 88                             State aid summaries, district details workbook
#> 89                                   Taxpayers' Guide to Educational Spending
#> 90                             State aid summaries, district details workbook
#> 91                                   Taxpayers' Guide to Educational Spending
#> 92                             State aid summaries, district details workbook
#> 93                                   Taxpayers' Guide to Educational Spending
#> 94                             State aid summaries, district details workbook
#> 95                             State aid summaries, district details workbook
#> 96                                    Adjusted Cohort Graduation Rate Reports
#> 97                                    Adjusted Cohort Graduation Rate Reports
#> 98                                    Adjusted Cohort Graduation Rate Reports
#> 99                                    Adjusted Cohort Graduation Rate Reports
#> 100                                   Adjusted Cohort Graduation Rate Reports
#> 101                                   Adjusted Cohort Graduation Rate Reports
#> 102                                   Adjusted Cohort Graduation Rate Reports
#> 103                                   Adjusted Cohort Graduation Rate Reports
#> 104                                   Adjusted Cohort Graduation Rate Reports
#> 105                                   Adjusted Cohort Graduation Rate Reports
#> 106                                   Adjusted Cohort Graduation Rate Reports
#> 107      School Performance Reports downloadable data, school detail database
#> 108                                   Adjusted Cohort Graduation Rate Reports
#> 109      School Performance Reports downloadable data, school detail database
#> 110                                   Adjusted Cohort Graduation Rate Reports
#> 111      School Performance Reports downloadable data, school detail database
#> 112                                   Adjusted Cohort Graduation Rate Reports
#> 113      School Performance Reports downloadable data, school detail database
#> 114                                   Adjusted Cohort Graduation Rate Reports
#> 115      School Performance Reports downloadable data, school detail database
#> 116 ESSA accountability workbook files, Comprehensive Support and Improvement
#> 117 ESSA accountability workbook files, Comprehensive Support and Improvement
#> 118 ESSA accountability workbook files, Comprehensive Support and Improvement
#> 119                            State aid summaries, district details workbook
#> 120                            State aid summaries, district details workbook
#> 121                            State aid summaries, district details workbook
#> 122 ESSA accountability workbook files, Comprehensive Support and Improvement
#> 123                            State aid summaries, district details workbook
#> 124 ESSA accountability workbook files, Comprehensive Support and Improvement
#> 125                            State aid summaries, district details workbook
#> 126 ESSA accountability workbook files, Comprehensive Support and Improvement
#> 127                            State aid summaries, district details workbook
#> 128                            State aid summaries, district details workbook
#> 129                            State aid summaries, district details workbook
#> 130                            State aid summaries, district details workbook
#> 131               IDEA Part B public reporting, district classification rates
#> 132               IDEA Part B public reporting, district classification rates
#> 133               IDEA Part B public reporting, district classification rates
#> 134               IDEA Part B public reporting, district classification rates
#> 135               IDEA Part B public reporting, district classification rates
#> 136               IDEA Part B public reporting, district classification rates
#> 137               IDEA Part B public reporting, district classification rates
#> 138               IDEA Part B public reporting, district classification rates
#> 139 Response to OPRA request C255254, active IEP counts by district and grade
#> 140 Response to OPRA request C255254, active IEP counts by district and grade
#> 141 Response to OPRA request C255254, active IEP counts by district and grade
#> 142 Response to OPRA request C255254, active IEP counts by district and grade
#>          year_basis
#> 1   school_year_end
#> 2   school_year_end
#> 3   school_year_end
#> 5   school_year_end
#> 6   school_year_end
#> 7   school_year_end
#> 8   school_year_end
#> 9   school_year_end
#> 10  school_year_end
#> 11  school_year_end
#> 12  school_year_end
#> 13  school_year_end
#> 15  school_year_end
#> 16  school_year_end
#> 17  school_year_end
#> 18  school_year_end
#> 19  school_year_end
#> 20  school_year_end
#> 21  school_year_end
#> 22  school_year_end
#> 23  school_year_end
#> 24  school_year_end
#> 25  school_year_end
#> 26  school_year_end
#> 27  school_year_end
#> 28  school_year_end
#> 29  school_year_end
#> 30  school_year_end
#> 31  school_year_end
#> 32  school_year_end
#> 33  school_year_end
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
#> 64      fiscal_year
#> 65      fiscal_year
#> 66      fiscal_year
#> 67      fiscal_year
#> 68      fiscal_year
#> 69      fiscal_year
#> 70      fiscal_year
#> 71      fiscal_year
#> 72      fiscal_year
#> 73      fiscal_year
#> 74      fiscal_year
#> 75      fiscal_year
#> 76      fiscal_year
#> 77      fiscal_year
#> 78      fiscal_year
#> 79      fiscal_year
#> 80      fiscal_year
#> 81      fiscal_year
#> 82      fiscal_year
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
#> 96      cohort_year
#> 97      cohort_year
#> 98      cohort_year
#> 99      cohort_year
#> 100     cohort_year
#> 101     cohort_year
#> 102     cohort_year
#> 103     cohort_year
#> 104     cohort_year
#> 105     cohort_year
#> 106     cohort_year
#> 107 school_year_end
#> 108     cohort_year
#> 109 school_year_end
#> 110     cohort_year
#> 111 school_year_end
#> 112     cohort_year
#> 113 school_year_end
#> 114     cohort_year
#> 115 school_year_end
#> 116 school_year_end
#> 117 school_year_end
#> 118 school_year_end
#> 119     fiscal_year
#> 120     fiscal_year
#> 121     fiscal_year
#> 122 school_year_end
#> 123     fiscal_year
#> 124 school_year_end
#> 125     fiscal_year
#> 126 school_year_end
#> 127     fiscal_year
#> 128     fiscal_year
#> 129     fiscal_year
#> 130     fiscal_year
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
#>                                                        landing_url reason
#> 1                       https://www.nj.gov/education/spr/download/   <NA>
#> 2                       https://www.nj.gov/education/spr/download/   <NA>
#> 3                       https://www.nj.gov/education/spr/download/   <NA>
#> 5                       https://www.nj.gov/education/spr/download/   <NA>
#> 6                       https://www.nj.gov/education/spr/download/   <NA>
#> 7                       https://www.nj.gov/education/spr/download/   <NA>
#> 8                       https://www.nj.gov/education/spr/download/   <NA>
#> 9                       https://www.nj.gov/education/spr/download/   <NA>
#> 10        https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 11        https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 12        https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 13        https://www.nj.gov/education/assessment/results/reports/   <NA>
#> 15                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 16                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 17                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 18                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 19                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 20                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 21                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 22                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 23                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 24                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 25                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 26                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 27                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 28                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 29                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 30                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 31                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 32                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 33                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 34                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 35                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 36                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 37                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 38                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 39                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 40                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 41                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 42                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 43                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 44                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 45                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 46                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 47                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 48                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 49                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 50                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 51                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 52                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 53                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 54                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 55                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 56                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 57                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 58                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 59                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 60                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 61                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 62                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 63                       https://www.nj.gov/education/doedata/enr/   <NA>
#> 64                             https://www.nj.gov/education/guide/   <NA>
#> 65                             https://www.nj.gov/education/guide/   <NA>
#> 66                             https://www.nj.gov/education/guide/   <NA>
#> 67                             https://www.nj.gov/education/guide/   <NA>
#> 68                             https://www.nj.gov/education/guide/   <NA>
#> 69                             https://www.nj.gov/education/guide/   <NA>
#> 70                             https://www.nj.gov/education/guide/   <NA>
#> 71                             https://www.nj.gov/education/guide/   <NA>
#> 72                             https://www.nj.gov/education/guide/   <NA>
#> 73                             https://www.nj.gov/education/guide/   <NA>
#> 74                             https://www.nj.gov/education/guide/   <NA>
#> 75                             https://www.nj.gov/education/guide/   <NA>
#> 76                             https://www.nj.gov/education/guide/   <NA>
#> 77                             https://www.nj.gov/education/guide/   <NA>
#> 78                             https://www.nj.gov/education/guide/   <NA>
#> 79                             https://www.nj.gov/education/guide/   <NA>
#> 80                             https://www.nj.gov/education/guide/   <NA>
#> 81                             https://www.nj.gov/education/guide/   <NA>
#> 82                          https://www.nj.gov/education/stateaid/   <NA>
#> 83                             https://www.nj.gov/education/guide/   <NA>
#> 84                          https://www.nj.gov/education/stateaid/   <NA>
#> 85                             https://www.nj.gov/education/guide/   <NA>
#> 86                          https://www.nj.gov/education/stateaid/   <NA>
#> 87                             https://www.nj.gov/education/guide/   <NA>
#> 88                          https://www.nj.gov/education/stateaid/   <NA>
#> 89                             https://www.nj.gov/education/guide/   <NA>
#> 90                          https://www.nj.gov/education/stateaid/   <NA>
#> 91                             https://www.nj.gov/education/guide/   <NA>
#> 92                          https://www.nj.gov/education/stateaid/   <NA>
#> 93                             https://www.nj.gov/education/guide/   <NA>
#> 94                          https://www.nj.gov/education/stateaid/   <NA>
#> 95                          https://www.nj.gov/education/stateaid/   <NA>
#> 96                       https://www.nj.gov/education/spr/adddata/   <NA>
#> 97                       https://www.nj.gov/education/spr/adddata/   <NA>
#> 98                       https://www.nj.gov/education/spr/adddata/   <NA>
#> 99                       https://www.nj.gov/education/spr/adddata/   <NA>
#> 100                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 101                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 102                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 103                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 104                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 105                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 106                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 107                     https://www.nj.gov/education/spr/download/   <NA>
#> 108                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 109                     https://www.nj.gov/education/spr/download/   <NA>
#> 110                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 111                     https://www.nj.gov/education/spr/download/   <NA>
#> 112                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 113                     https://www.nj.gov/education/spr/download/   <NA>
#> 114                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 115                     https://www.nj.gov/education/spr/download/   <NA>
#> 116            https://www.nj.gov/education/title1/accountability/   <NA>
#> 117            https://www.nj.gov/education/title1/accountability/   <NA>
#> 118            https://www.nj.gov/education/title1/accountability/   <NA>
#> 119                         https://www.nj.gov/education/stateaid/   <NA>
#> 120                         https://www.nj.gov/education/stateaid/   <NA>
#> 121                         https://www.nj.gov/education/stateaid/   <NA>
#> 122            https://www.nj.gov/education/title1/accountability/   <NA>
#> 123                         https://www.nj.gov/education/stateaid/   <NA>
#> 124            https://www.nj.gov/education/title1/accountability/   <NA>
#> 125                         https://www.nj.gov/education/stateaid/   <NA>
#> 126            https://www.nj.gov/education/title1/accountability/   <NA>
#> 127                         https://www.nj.gov/education/stateaid/   <NA>
#> 128                         https://www.nj.gov/education/stateaid/   <NA>
#> 129                         https://www.nj.gov/education/stateaid/   <NA>
#> 130                         https://www.nj.gov/education/stateaid/   <NA>
#> 131 https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 132 https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 133 https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 134 https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 135 https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 136 https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 137 https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 138 https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 139                                                           <NA>   <NA>
#> 140                                                           <NA>   <NA>
#> 141                                                           <NA>   <NA>
#> 142                                                           <NA>   <NA>
#>     evidence checked_on
#> 1       <NA>       <NA>
#> 2       <NA>       <NA>
#> 3       <NA>       <NA>
#> 5       <NA>       <NA>
#> 6       <NA>       <NA>
#> 7       <NA>       <NA>
#> 8       <NA>       <NA>
#> 9       <NA>       <NA>
#> 10      <NA>       <NA>
#> 11      <NA>       <NA>
#> 12      <NA>       <NA>
#> 13      <NA>       <NA>
#> 15      <NA>       <NA>
#> 16      <NA>       <NA>
#> 17      <NA>       <NA>
#> 18      <NA>       <NA>
#> 19      <NA>       <NA>
#> 20      <NA>       <NA>
#> 21      <NA>       <NA>
#> 22      <NA>       <NA>
#> 23      <NA>       <NA>
#> 24      <NA>       <NA>
#> 25      <NA>       <NA>
#> 26      <NA>       <NA>
#> 27      <NA>       <NA>
#> 28      <NA>       <NA>
#> 29      <NA>       <NA>
#> 30      <NA>       <NA>
#> 31      <NA>       <NA>
#> 32      <NA>       <NA>
#> 33      <NA>       <NA>
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
get_data_registry(family = "enrollment", end_year = 2024)
#>    state     family end_year               source_id variant status mode
#> 61    NJ enrollment     2024 fall_enrollment_reports    <NA> served live
#>      fetcher n_source_files n_derived_files   bytes
#> 61 fetch_enr              1               0 1061242
#>                                                            source_url
#> 61 https://www.nj.gov/education/doedata/enr/enr24/enrollment_2324.zip
#>                             publisher publisher_type                   title
#> 61 New Jersey Department of Education      state_doe Fall Enrollment Reports
#>         year_basis                               landing_url reason evidence
#> 61 school_year_end https://www.nj.gov/education/doedata/enr/   <NA>     <NA>
#>    checked_on
#> 61       <NA>
```
