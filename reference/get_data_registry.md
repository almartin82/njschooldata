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
#>    state     family end_year                               source_id variant
#> 1     NJ    absence     2017     school_performance_reports_database    <NA>
#> 2     NJ    absence     2018     school_performance_reports_database    <NA>
#> 3     NJ    absence     2019     school_performance_reports_database    <NA>
#> 5     NJ    absence     2021     school_performance_reports_database    <NA>
#> 6     NJ    absence     2022     school_performance_reports_database    <NA>
#> 7     NJ    absence     2023     school_performance_reports_database    <NA>
#> 8     NJ    absence     2024     school_performance_reports_database    <NA>
#> 9     NJ    absence     2025     school_performance_reports_database    <NA>
#> 11    NJ enrollment     1999                 fall_enrollment_reports    <NA>
#> 12    NJ enrollment     2000                 fall_enrollment_reports    <NA>
#> 13    NJ enrollment     2001                 fall_enrollment_reports    <NA>
#> 14    NJ enrollment     2002                 fall_enrollment_reports    <NA>
#> 15    NJ enrollment     2003                 fall_enrollment_reports    <NA>
#> 16    NJ enrollment     2004                 fall_enrollment_reports    <NA>
#> 17    NJ enrollment     2005                 fall_enrollment_reports    <NA>
#> 18    NJ enrollment     2006                 fall_enrollment_reports    <NA>
#> 19    NJ enrollment     2007                 fall_enrollment_reports    <NA>
#> 20    NJ enrollment     2008                 fall_enrollment_reports    <NA>
#> 21    NJ enrollment     2009                 fall_enrollment_reports    <NA>
#> 22    NJ enrollment     2010                 fall_enrollment_reports    <NA>
#> 23    NJ enrollment     2011                 fall_enrollment_reports    <NA>
#> 24    NJ enrollment     2012                 fall_enrollment_reports    <NA>
#> 25    NJ enrollment     2013                 fall_enrollment_reports    <NA>
#> 26    NJ enrollment     2014                 fall_enrollment_reports    <NA>
#> 27    NJ enrollment     2015                 fall_enrollment_reports    <NA>
#> 28    NJ enrollment     2016                 fall_enrollment_reports    <NA>
#> 29    NJ enrollment     2017                 fall_enrollment_reports    <NA>
#> 30    NJ enrollment     2018                 fall_enrollment_reports    <NA>
#> 31    NJ enrollment     2019                 fall_enrollment_reports    <NA>
#> 32    NJ enrollment     2020                 fall_enrollment_reports    <NA>
#> 33    NJ enrollment     2021                 fall_enrollment_reports    <NA>
#> 34    NJ enrollment     2022                 fall_enrollment_reports    <NA>
#> 35    NJ enrollment     2023                 fall_enrollment_reports    <NA>
#> 36    NJ enrollment     2024                 fall_enrollment_reports    <NA>
#> 37    NJ enrollment     2025                 fall_enrollment_reports    <NA>
#> 38    NJ enrollment     2026                 fall_enrollment_reports    <NA>
#> 39    NJ    finance     2001 taxpayers_guide_to_educational_spending    <NA>
#> 40    NJ    finance     2002 taxpayers_guide_to_educational_spending    <NA>
#> 41    NJ    finance     2003 taxpayers_guide_to_educational_spending    <NA>
#> 42    NJ    finance     2004 taxpayers_guide_to_educational_spending    <NA>
#> 43    NJ    finance     2005 taxpayers_guide_to_educational_spending    <NA>
#> 44    NJ    finance     2006 taxpayers_guide_to_educational_spending    <NA>
#> 45    NJ    finance     2007 taxpayers_guide_to_educational_spending    <NA>
#> 46    NJ    finance     2008 taxpayers_guide_to_educational_spending    <NA>
#> 47    NJ    finance     2009 taxpayers_guide_to_educational_spending    <NA>
#> 48    NJ    finance     2010 taxpayers_guide_to_educational_spending    <NA>
#> 49    NJ    finance     2011 taxpayers_guide_to_educational_spending    <NA>
#> 50    NJ    finance     2012 taxpayers_guide_to_educational_spending    <NA>
#> 51    NJ    finance     2013 taxpayers_guide_to_educational_spending    <NA>
#> 52    NJ    finance     2014 taxpayers_guide_to_educational_spending    <NA>
#> 53    NJ    finance     2015 taxpayers_guide_to_educational_spending    <NA>
#> 54    NJ    finance     2016 taxpayers_guide_to_educational_spending    <NA>
#> 55    NJ    finance     2017 taxpayers_guide_to_educational_spending    <NA>
#> 56    NJ    finance     2018 taxpayers_guide_to_educational_spending    <NA>
#> 57    NJ    finance     2019              state_aid_district_details    <NA>
#> 58    NJ    finance     2019 taxpayers_guide_to_educational_spending    <NA>
#> 59    NJ    finance     2020              state_aid_district_details    <NA>
#> 60    NJ    finance     2020 taxpayers_guide_to_educational_spending    <NA>
#> 61    NJ    finance     2021              state_aid_district_details    <NA>
#> 62    NJ    finance     2021 taxpayers_guide_to_educational_spending    <NA>
#> 63    NJ    finance     2022              state_aid_district_details    <NA>
#> 64    NJ    finance     2022 taxpayers_guide_to_educational_spending    <NA>
#> 65    NJ    finance     2023              state_aid_district_details    <NA>
#> 66    NJ    finance     2023 taxpayers_guide_to_educational_spending    <NA>
#> 67    NJ    finance     2024              state_aid_district_details    <NA>
#> 68    NJ    finance     2024 taxpayers_guide_to_educational_spending    <NA>
#> 69    NJ    finance     2025              state_aid_district_details    <NA>
#> 70    NJ    finance     2026              state_aid_district_details    <NA>
#> 71    NJ graduation     2011 adjusted_cohort_graduation_rate_reports    <NA>
#> 72    NJ graduation     2012 adjusted_cohort_graduation_rate_reports    <NA>
#> 73    NJ graduation     2013 adjusted_cohort_graduation_rate_reports    <NA>
#> 74    NJ graduation     2014 adjusted_cohort_graduation_rate_reports    <NA>
#> 75    NJ graduation     2015 adjusted_cohort_graduation_rate_reports    <NA>
#> 76    NJ graduation     2016 adjusted_cohort_graduation_rate_reports    <NA>
#> 77    NJ graduation     2017 adjusted_cohort_graduation_rate_reports    <NA>
#> 78    NJ graduation     2018 adjusted_cohort_graduation_rate_reports    <NA>
#> 79    NJ graduation     2019 adjusted_cohort_graduation_rate_reports    <NA>
#> 80    NJ graduation     2020 adjusted_cohort_graduation_rate_reports    <NA>
#> 81    NJ graduation     2021 adjusted_cohort_graduation_rate_reports    <NA>
#> 82    NJ graduation     2022 adjusted_cohort_graduation_rate_reports    <NA>
#> 83    NJ graduation     2023 adjusted_cohort_graduation_rate_reports    <NA>
#> 84    NJ graduation     2024 adjusted_cohort_graduation_rate_reports    <NA>
#> 85    NJ graduation     2025 adjusted_cohort_graduation_rate_reports    <NA>
#> 86    NJ       sped     2023  idea_618_district_classification_rates    <NA>
#> 87    NJ       sped     2023     idea_618_state_classification_rates    <NA>
#> 88    NJ       sped     2024  idea_618_district_classification_rates    <NA>
#> 89    NJ       sped     2024     idea_618_state_classification_rates    <NA>
#> 90    NJ       sped     2025  idea_618_district_classification_rates    <NA>
#> 91    NJ       sped     2026       opra_response_iep_counts_by_grade    <NA>
#>    status mode          fetcher n_source_files n_derived_files   bytes
#> 1  served live    fetch_absence              0               0       0
#> 2  served live    fetch_absence              0               0       0
#> 3  served live    fetch_absence              0               0       0
#> 5  served live    fetch_absence              0               0       0
#> 6  served live    fetch_absence              0               0       0
#> 7  served live    fetch_absence              0               0       0
#> 8  served live    fetch_absence              0               0       0
#> 9  served live    fetch_absence              0               0       0
#> 11 served live        fetch_enr              0               0       0
#> 12 served live        fetch_enr              0               0       0
#> 13 served live        fetch_enr              0               0       0
#> 14 served live        fetch_enr              0               0       0
#> 15 served live        fetch_enr              0               0       0
#> 16 served live        fetch_enr              0               0       0
#> 17 served live        fetch_enr              0               0       0
#> 18 served live        fetch_enr              0               0       0
#> 19 served live        fetch_enr              0               0       0
#> 20 served live        fetch_enr              0               0       0
#> 21 served live        fetch_enr              0               0       0
#> 22 served live        fetch_enr              0               0       0
#> 23 served live        fetch_enr              0               0       0
#> 24 served live        fetch_enr              0               0       0
#> 25 served live        fetch_enr              0               0       0
#> 26 served live        fetch_enr              0               0       0
#> 27 served live        fetch_enr              0               0       0
#> 28 served live        fetch_enr              0               0       0
#> 29 served live        fetch_enr              0               0       0
#> 30 served live        fetch_enr              0               0       0
#> 31 served live        fetch_enr              0               0       0
#> 32 served live        fetch_enr              0               0       0
#> 33 served live        fetch_enr              0               0       0
#> 34 served live        fetch_enr              0               0       0
#> 35 served live        fetch_enr              1               0 1119856
#> 36 served live        fetch_enr              1               0 1061242
#> 37 served live        fetch_enr              1               0 1095121
#> 38 served live        fetch_enr              1               0 1061437
#> 39 served live    fetch_finance              0               0       0
#> 40 served live    fetch_finance              0               0       0
#> 41 served live    fetch_finance              0               0       0
#> 42 served live    fetch_finance              0               0       0
#> 43 served live    fetch_finance              0               0       0
#> 44 served live    fetch_finance              0               0       0
#> 45 served live    fetch_finance              0               0       0
#> 46 served live    fetch_finance              0               0       0
#> 47 served live    fetch_finance              0               0       0
#> 48 served live    fetch_finance              0               0       0
#> 49 served live    fetch_finance              0               0       0
#> 50 served live    fetch_finance              0               0       0
#> 51 served live    fetch_finance              0               0       0
#> 52 served live    fetch_finance              0               0       0
#> 53 served live    fetch_finance              0               0       0
#> 54 served live    fetch_finance              0               0       0
#> 55 served live    fetch_finance              0               0       0
#> 56 served live    fetch_finance              0               0       0
#> 57 served live    fetch_finance              0               0       0
#> 58 served live    fetch_finance              0               0       0
#> 59 served live    fetch_finance              0               0       0
#> 60 served live    fetch_finance              0               0       0
#> 61 served live    fetch_finance              0               0       0
#> 62 served live    fetch_finance              0               0       0
#> 63 served live    fetch_finance              0               0       0
#> 64 served live    fetch_finance              0               0       0
#> 65 served live    fetch_finance              0               0       0
#> 66 served live    fetch_finance              0               0       0
#> 67 served live    fetch_finance              0               0       0
#> 68 served live    fetch_finance              0               0       0
#> 69 served live    fetch_finance              0               0       0
#> 70 served live    fetch_finance              0               0       0
#> 71 served live  fetch_grad_rate              0               0       0
#> 72 served live  fetch_grad_rate              0               0       0
#> 73 served live  fetch_grad_rate              0               0       0
#> 74 served live  fetch_grad_rate              0               0       0
#> 75 served live  fetch_grad_rate              0               0       0
#> 76 served live  fetch_grad_rate              0               0       0
#> 77 served live  fetch_grad_rate              0               0       0
#> 78 served live  fetch_grad_rate              0               0       0
#> 79 served live  fetch_grad_rate              0               0       0
#> 80 served live  fetch_grad_rate              0               0       0
#> 81 served live  fetch_grad_rate              0               0       0
#> 82 served live  fetch_grad_rate              0               0       0
#> 83 served live  fetch_grad_rate              0               0       0
#> 84 served live  fetch_grad_rate              0               0       0
#> 85 served live  fetch_grad_rate              0               0       0
#> 86 served live fetch_sped_share              1               0   50069
#> 87 served live fetch_sped_share              1               0   12905
#> 88 served live fetch_sped_share              1               0   46536
#> 89 served live fetch_sped_share              1               0   12523
#> 90 served live fetch_sped_share              1               0  200265
#> 91 served live fetch_sped_share              0               0       0
#>                                                                                                                                             source_url
#> 1                                                                                                                                                 <NA>
#> 2                                                                                                                                                 <NA>
#> 3                                                                                                                                                 <NA>
#> 5                                                                                                                                                 <NA>
#> 6                                                                                                                                                 <NA>
#> 7                                                                                                                                                 <NA>
#> 8                                                                                                                                                 <NA>
#> 9                                                                                                                                                 <NA>
#> 11                                                                                                                                                <NA>
#> 12                                                                                                                                                <NA>
#> 13                                                                                                                                                <NA>
#> 14                                                                                                                                                <NA>
#> 15                                                                                                                                                <NA>
#> 16                                                                                                                                                <NA>
#> 17                                                                                                                                                <NA>
#> 18                                                                                                                                                <NA>
#> 19                                                                                                                                                <NA>
#> 20                                                                                                                                                <NA>
#> 21                                                                                                                                                <NA>
#> 22                                                                                                                                                <NA>
#> 23                                                                                                                                                <NA>
#> 24                                                                                                                                                <NA>
#> 25                                                                                                                                                <NA>
#> 26                                                                                                                                                <NA>
#> 27                                                                                                                                                <NA>
#> 28                                                                                                                                                <NA>
#> 29                                                                                                                                                <NA>
#> 30                                                                                                                                                <NA>
#> 31                                                                                                                                                <NA>
#> 32                                                                                                                                                <NA>
#> 33                                                                                                                                                <NA>
#> 34                                                                                                                                                <NA>
#> 35                                                                                  https://www.nj.gov/education/doedata/enr/enr23/enrollment_2223.zip
#> 36                                                                                  https://www.nj.gov/education/doedata/enr/enr24/enrollment_2324.zip
#> 37                                                                                  https://www.nj.gov/education/doedata/enr/enr25/enrollment_2425.zip
#> 38                                                                                  https://www.nj.gov/education/doedata/enr/enr26/Enrollment_2526.zip
#> 39                                                                                                                                                <NA>
#> 40                                                                                                                                                <NA>
#> 41                                                                                                                                                <NA>
#> 42                                                                                                                                                <NA>
#> 43                                                                                                                                                <NA>
#> 44                                                                                                                                                <NA>
#> 45                                                                                                                                                <NA>
#> 46                                                                                                                                                <NA>
#> 47                                                                                                                                                <NA>
#> 48                                                                                                                                                <NA>
#> 49                                                                                                                                                <NA>
#> 50                                                                                                                                                <NA>
#> 51                                                                                                                                                <NA>
#> 52                                                                                                                                                <NA>
#> 53                                                                                                                                                <NA>
#> 54                                                                                                                                                <NA>
#> 55                                                                                                                                                <NA>
#> 56                                                                                                                                                <NA>
#> 57                                                                                                                                                <NA>
#> 58                                                                                                                                                <NA>
#> 59                                                                                                                                                <NA>
#> 60                                                                                                                                                <NA>
#> 61                                                                                                                                                <NA>
#> 62                                                                                                                                                <NA>
#> 63                                                                                                                                                <NA>
#> 64                                                                                                                                                <NA>
#> 65                                                                                                                                                <NA>
#> 66                                                                                                                                                <NA>
#> 67                                                                                                                                                <NA>
#> 68                                                                                                                                                <NA>
#> 69                                                                                                                                                <NA>
#> 70                                                                                                                                                <NA>
#> 71                                                                                                                                                <NA>
#> 72                                                                                                                                                <NA>
#> 73                                                                                                                                                <NA>
#> 74                                                                                                                                                <NA>
#> 75                                                                                                                                                <NA>
#> 76                                                                                                                                                <NA>
#> 77                                                                                                                                                <NA>
#> 78                                                                                                                                                <NA>
#> 79                                                                                                                                                <NA>
#> 80                                                                                                                                                <NA>
#> 81                                                                                                                                                <NA>
#> 82                                                                                                                                                <NA>
#> 83                                                                                                                                                <NA>
#> 84                                                                                                                                                <NA>
#> 85                                                                                                                                                <NA>
#> 86 https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2022public618data/District_Enrollment_vs_SpecialED_Rates_Publicdata_3_21Age.xlsx
#> 87                   https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2022public618data/StateClassificationRates_SpecialED_3-21.xlsx
#> 88                    https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2023_618data/DistrictWide_ClassificationRate_2324_public.xlsx
#> 89                               https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2023_618data/StatewideClassificationRate_2324.xlsx
#> 90                 https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2025_618data/2025IDEA618PublicReporting_ClassificationRates.xlsx
#> 91                                                                                                                                                <NA>
#>                             publisher publisher_type
#> 1  New Jersey Department of Education      state_doe
#> 2  New Jersey Department of Education      state_doe
#> 3  New Jersey Department of Education      state_doe
#> 5  New Jersey Department of Education      state_doe
#> 6  New Jersey Department of Education      state_doe
#> 7  New Jersey Department of Education      state_doe
#> 8  New Jersey Department of Education      state_doe
#> 9  New Jersey Department of Education      state_doe
#> 11 New Jersey Department of Education      state_doe
#> 12 New Jersey Department of Education      state_doe
#> 13 New Jersey Department of Education      state_doe
#> 14 New Jersey Department of Education      state_doe
#> 15 New Jersey Department of Education      state_doe
#> 16 New Jersey Department of Education      state_doe
#> 17 New Jersey Department of Education      state_doe
#> 18 New Jersey Department of Education      state_doe
#> 19 New Jersey Department of Education      state_doe
#> 20 New Jersey Department of Education      state_doe
#> 21 New Jersey Department of Education      state_doe
#> 22 New Jersey Department of Education      state_doe
#> 23 New Jersey Department of Education      state_doe
#> 24 New Jersey Department of Education      state_doe
#> 25 New Jersey Department of Education      state_doe
#> 26 New Jersey Department of Education      state_doe
#> 27 New Jersey Department of Education      state_doe
#> 28 New Jersey Department of Education      state_doe
#> 29 New Jersey Department of Education      state_doe
#> 30 New Jersey Department of Education      state_doe
#> 31 New Jersey Department of Education      state_doe
#> 32 New Jersey Department of Education      state_doe
#> 33 New Jersey Department of Education      state_doe
#> 34 New Jersey Department of Education      state_doe
#> 35 New Jersey Department of Education      state_doe
#> 36 New Jersey Department of Education      state_doe
#> 37 New Jersey Department of Education      state_doe
#> 38 New Jersey Department of Education      state_doe
#> 39 New Jersey Department of Education      state_doe
#> 40 New Jersey Department of Education      state_doe
#> 41 New Jersey Department of Education      state_doe
#> 42 New Jersey Department of Education      state_doe
#> 43 New Jersey Department of Education      state_doe
#> 44 New Jersey Department of Education      state_doe
#> 45 New Jersey Department of Education      state_doe
#> 46 New Jersey Department of Education      state_doe
#> 47 New Jersey Department of Education      state_doe
#> 48 New Jersey Department of Education      state_doe
#> 49 New Jersey Department of Education      state_doe
#> 50 New Jersey Department of Education      state_doe
#> 51 New Jersey Department of Education      state_doe
#> 52 New Jersey Department of Education      state_doe
#> 53 New Jersey Department of Education      state_doe
#> 54 New Jersey Department of Education      state_doe
#> 55 New Jersey Department of Education      state_doe
#> 56 New Jersey Department of Education      state_doe
#> 57 New Jersey Department of Education      state_doe
#> 58 New Jersey Department of Education      state_doe
#> 59 New Jersey Department of Education      state_doe
#> 60 New Jersey Department of Education      state_doe
#> 61 New Jersey Department of Education      state_doe
#> 62 New Jersey Department of Education      state_doe
#> 63 New Jersey Department of Education      state_doe
#> 64 New Jersey Department of Education      state_doe
#> 65 New Jersey Department of Education      state_doe
#> 66 New Jersey Department of Education      state_doe
#> 67 New Jersey Department of Education      state_doe
#> 68 New Jersey Department of Education      state_doe
#> 69 New Jersey Department of Education      state_doe
#> 70 New Jersey Department of Education      state_doe
#> 71 New Jersey Department of Education      state_doe
#> 72 New Jersey Department of Education      state_doe
#> 73 New Jersey Department of Education      state_doe
#> 74 New Jersey Department of Education      state_doe
#> 75 New Jersey Department of Education      state_doe
#> 76 New Jersey Department of Education      state_doe
#> 77 New Jersey Department of Education      state_doe
#> 78 New Jersey Department of Education      state_doe
#> 79 New Jersey Department of Education      state_doe
#> 80 New Jersey Department of Education      state_doe
#> 81 New Jersey Department of Education      state_doe
#> 82 New Jersey Department of Education      state_doe
#> 83 New Jersey Department of Education      state_doe
#> 84 New Jersey Department of Education      state_doe
#> 85 New Jersey Department of Education      state_doe
#> 86 New Jersey Department of Education      state_doe
#> 87 New Jersey Department of Education      state_doe
#> 88 New Jersey Department of Education      state_doe
#> 89 New Jersey Department of Education      state_doe
#> 90 New Jersey Department of Education      state_doe
#> 91 New Jersey Department of Education      state_doe
#>                                                                        title
#> 1       School Performance Reports downloadable data, school detail database
#> 2       School Performance Reports downloadable data, school detail database
#> 3       School Performance Reports downloadable data, school detail database
#> 5       School Performance Reports downloadable data, school detail database
#> 6       School Performance Reports downloadable data, school detail database
#> 7       School Performance Reports downloadable data, school detail database
#> 8       School Performance Reports downloadable data, school detail database
#> 9       School Performance Reports downloadable data, school detail database
#> 11                                                   Fall Enrollment Reports
#> 12                                                   Fall Enrollment Reports
#> 13                                                   Fall Enrollment Reports
#> 14                                                   Fall Enrollment Reports
#> 15                                                   Fall Enrollment Reports
#> 16                                                   Fall Enrollment Reports
#> 17                                                   Fall Enrollment Reports
#> 18                                                   Fall Enrollment Reports
#> 19                                                   Fall Enrollment Reports
#> 20                                                   Fall Enrollment Reports
#> 21                                                   Fall Enrollment Reports
#> 22                                                   Fall Enrollment Reports
#> 23                                                   Fall Enrollment Reports
#> 24                                                   Fall Enrollment Reports
#> 25                                                   Fall Enrollment Reports
#> 26                                                   Fall Enrollment Reports
#> 27                                                   Fall Enrollment Reports
#> 28                                                   Fall Enrollment Reports
#> 29                                                   Fall Enrollment Reports
#> 30                                                   Fall Enrollment Reports
#> 31                                                   Fall Enrollment Reports
#> 32                                                   Fall Enrollment Reports
#> 33                                                   Fall Enrollment Reports
#> 34                                                   Fall Enrollment Reports
#> 35                                                   Fall Enrollment Reports
#> 36                                                   Fall Enrollment Reports
#> 37                                                   Fall Enrollment Reports
#> 38                                                   Fall Enrollment Reports
#> 39                                  Taxpayers' Guide to Educational Spending
#> 40                                  Taxpayers' Guide to Educational Spending
#> 41                                  Taxpayers' Guide to Educational Spending
#> 42                                  Taxpayers' Guide to Educational Spending
#> 43                                  Taxpayers' Guide to Educational Spending
#> 44                                  Taxpayers' Guide to Educational Spending
#> 45                                  Taxpayers' Guide to Educational Spending
#> 46                                  Taxpayers' Guide to Educational Spending
#> 47                                  Taxpayers' Guide to Educational Spending
#> 48                                  Taxpayers' Guide to Educational Spending
#> 49                                  Taxpayers' Guide to Educational Spending
#> 50                                  Taxpayers' Guide to Educational Spending
#> 51                                  Taxpayers' Guide to Educational Spending
#> 52                                  Taxpayers' Guide to Educational Spending
#> 53                                  Taxpayers' Guide to Educational Spending
#> 54                                  Taxpayers' Guide to Educational Spending
#> 55                                  Taxpayers' Guide to Educational Spending
#> 56                                  Taxpayers' Guide to Educational Spending
#> 57                            State aid summaries, district details workbook
#> 58                                  Taxpayers' Guide to Educational Spending
#> 59                            State aid summaries, district details workbook
#> 60                                  Taxpayers' Guide to Educational Spending
#> 61                            State aid summaries, district details workbook
#> 62                                  Taxpayers' Guide to Educational Spending
#> 63                            State aid summaries, district details workbook
#> 64                                  Taxpayers' Guide to Educational Spending
#> 65                            State aid summaries, district details workbook
#> 66                                  Taxpayers' Guide to Educational Spending
#> 67                            State aid summaries, district details workbook
#> 68                                  Taxpayers' Guide to Educational Spending
#> 69                            State aid summaries, district details workbook
#> 70                            State aid summaries, district details workbook
#> 71                                   Adjusted Cohort Graduation Rate Reports
#> 72                                   Adjusted Cohort Graduation Rate Reports
#> 73                                   Adjusted Cohort Graduation Rate Reports
#> 74                                   Adjusted Cohort Graduation Rate Reports
#> 75                                   Adjusted Cohort Graduation Rate Reports
#> 76                                   Adjusted Cohort Graduation Rate Reports
#> 77                                   Adjusted Cohort Graduation Rate Reports
#> 78                                   Adjusted Cohort Graduation Rate Reports
#> 79                                   Adjusted Cohort Graduation Rate Reports
#> 80                                   Adjusted Cohort Graduation Rate Reports
#> 81                                   Adjusted Cohort Graduation Rate Reports
#> 82                                   Adjusted Cohort Graduation Rate Reports
#> 83                                   Adjusted Cohort Graduation Rate Reports
#> 84                                   Adjusted Cohort Graduation Rate Reports
#> 85                                   Adjusted Cohort Graduation Rate Reports
#> 86               IDEA Part B public reporting, district classification rates
#> 87              IDEA Part B public reporting, statewide classification rates
#> 88               IDEA Part B public reporting, district classification rates
#> 89              IDEA Part B public reporting, statewide classification rates
#> 90               IDEA Part B public reporting, district classification rates
#> 91 Response to OPRA request C255254, active IEP counts by district and grade
#>         year_basis
#> 1  school_year_end
#> 2  school_year_end
#> 3  school_year_end
#> 5  school_year_end
#> 6  school_year_end
#> 7  school_year_end
#> 8  school_year_end
#> 9  school_year_end
#> 11 school_year_end
#> 12 school_year_end
#> 13 school_year_end
#> 14 school_year_end
#> 15 school_year_end
#> 16 school_year_end
#> 17 school_year_end
#> 18 school_year_end
#> 19 school_year_end
#> 20 school_year_end
#> 21 school_year_end
#> 22 school_year_end
#> 23 school_year_end
#> 24 school_year_end
#> 25 school_year_end
#> 26 school_year_end
#> 27 school_year_end
#> 28 school_year_end
#> 29 school_year_end
#> 30 school_year_end
#> 31 school_year_end
#> 32 school_year_end
#> 33 school_year_end
#> 34 school_year_end
#> 35 school_year_end
#> 36 school_year_end
#> 37 school_year_end
#> 38 school_year_end
#> 39     fiscal_year
#> 40     fiscal_year
#> 41     fiscal_year
#> 42     fiscal_year
#> 43     fiscal_year
#> 44     fiscal_year
#> 45     fiscal_year
#> 46     fiscal_year
#> 47     fiscal_year
#> 48     fiscal_year
#> 49     fiscal_year
#> 50     fiscal_year
#> 51     fiscal_year
#> 52     fiscal_year
#> 53     fiscal_year
#> 54     fiscal_year
#> 55     fiscal_year
#> 56     fiscal_year
#> 57     fiscal_year
#> 58     fiscal_year
#> 59     fiscal_year
#> 60     fiscal_year
#> 61     fiscal_year
#> 62     fiscal_year
#> 63     fiscal_year
#> 64     fiscal_year
#> 65     fiscal_year
#> 66     fiscal_year
#> 67     fiscal_year
#> 68     fiscal_year
#> 69     fiscal_year
#> 70     fiscal_year
#> 71     cohort_year
#> 72     cohort_year
#> 73     cohort_year
#> 74     cohort_year
#> 75     cohort_year
#> 76     cohort_year
#> 77     cohort_year
#> 78     cohort_year
#> 79     cohort_year
#> 80     cohort_year
#> 81     cohort_year
#> 82     cohort_year
#> 83     cohort_year
#> 84     cohort_year
#> 85     cohort_year
#> 86 school_year_end
#> 87 school_year_end
#> 88 school_year_end
#> 89 school_year_end
#> 90 school_year_end
#> 91 school_year_end
#>                                                       landing_url reason
#> 1                      https://www.nj.gov/education/spr/download/   <NA>
#> 2                      https://www.nj.gov/education/spr/download/   <NA>
#> 3                      https://www.nj.gov/education/spr/download/   <NA>
#> 5                      https://www.nj.gov/education/spr/download/   <NA>
#> 6                      https://www.nj.gov/education/spr/download/   <NA>
#> 7                      https://www.nj.gov/education/spr/download/   <NA>
#> 8                      https://www.nj.gov/education/spr/download/   <NA>
#> 9                      https://www.nj.gov/education/spr/download/   <NA>
#> 11                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 12                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 13                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 14                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 15                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 16                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 17                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 18                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 19                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 20                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 21                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 22                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 23                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 24                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 25                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 26                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 27                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 28                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 29                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 30                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 31                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 32                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 33                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 34                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 35                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 36                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 37                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 38                      https://www.nj.gov/education/doedata/enr/   <NA>
#> 39                            https://www.nj.gov/education/guide/   <NA>
#> 40                            https://www.nj.gov/education/guide/   <NA>
#> 41                            https://www.nj.gov/education/guide/   <NA>
#> 42                            https://www.nj.gov/education/guide/   <NA>
#> 43                            https://www.nj.gov/education/guide/   <NA>
#> 44                            https://www.nj.gov/education/guide/   <NA>
#> 45                            https://www.nj.gov/education/guide/   <NA>
#> 46                            https://www.nj.gov/education/guide/   <NA>
#> 47                            https://www.nj.gov/education/guide/   <NA>
#> 48                            https://www.nj.gov/education/guide/   <NA>
#> 49                            https://www.nj.gov/education/guide/   <NA>
#> 50                            https://www.nj.gov/education/guide/   <NA>
#> 51                            https://www.nj.gov/education/guide/   <NA>
#> 52                            https://www.nj.gov/education/guide/   <NA>
#> 53                            https://www.nj.gov/education/guide/   <NA>
#> 54                            https://www.nj.gov/education/guide/   <NA>
#> 55                            https://www.nj.gov/education/guide/   <NA>
#> 56                            https://www.nj.gov/education/guide/   <NA>
#> 57                         https://www.nj.gov/education/stateaid/   <NA>
#> 58                            https://www.nj.gov/education/guide/   <NA>
#> 59                         https://www.nj.gov/education/stateaid/   <NA>
#> 60                            https://www.nj.gov/education/guide/   <NA>
#> 61                         https://www.nj.gov/education/stateaid/   <NA>
#> 62                            https://www.nj.gov/education/guide/   <NA>
#> 63                         https://www.nj.gov/education/stateaid/   <NA>
#> 64                            https://www.nj.gov/education/guide/   <NA>
#> 65                         https://www.nj.gov/education/stateaid/   <NA>
#> 66                            https://www.nj.gov/education/guide/   <NA>
#> 67                         https://www.nj.gov/education/stateaid/   <NA>
#> 68                            https://www.nj.gov/education/guide/   <NA>
#> 69                         https://www.nj.gov/education/stateaid/   <NA>
#> 70                         https://www.nj.gov/education/stateaid/   <NA>
#> 71                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 72                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 73                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 74                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 75                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 76                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 77                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 78                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 79                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 80                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 81                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 82                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 83                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 84                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 85                      https://www.nj.gov/education/spr/adddata/   <NA>
#> 86 https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 87 https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 88 https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 89 https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 90 https://www.nj.gov/education/specialed/monitor/ideapublicdata/   <NA>
#> 91                                                           <NA>   <NA>
#>    evidence checked_on
#> 1      <NA>       <NA>
#> 2      <NA>       <NA>
#> 3      <NA>       <NA>
#> 5      <NA>       <NA>
#> 6      <NA>       <NA>
#> 7      <NA>       <NA>
#> 8      <NA>       <NA>
#> 9      <NA>       <NA>
#> 11     <NA>       <NA>
#> 12     <NA>       <NA>
#> 13     <NA>       <NA>
#> 14     <NA>       <NA>
#> 15     <NA>       <NA>
#> 16     <NA>       <NA>
#> 17     <NA>       <NA>
#> 18     <NA>       <NA>
#> 19     <NA>       <NA>
#> 20     <NA>       <NA>
#> 21     <NA>       <NA>
#> 22     <NA>       <NA>
#> 23     <NA>       <NA>
#> 24     <NA>       <NA>
#> 25     <NA>       <NA>
#> 26     <NA>       <NA>
#> 27     <NA>       <NA>
#> 28     <NA>       <NA>
#> 29     <NA>       <NA>
#> 30     <NA>       <NA>
#> 31     <NA>       <NA>
#> 32     <NA>       <NA>
#> 33     <NA>       <NA>
#> 34     <NA>       <NA>
#> 35     <NA>       <NA>
#> 36     <NA>       <NA>
#> 37     <NA>       <NA>
#> 38     <NA>       <NA>
#> 39     <NA>       <NA>
#> 40     <NA>       <NA>
#> 41     <NA>       <NA>
#> 42     <NA>       <NA>
#> 43     <NA>       <NA>
#> 44     <NA>       <NA>
#> 45     <NA>       <NA>
#> 46     <NA>       <NA>
#> 47     <NA>       <NA>
#> 48     <NA>       <NA>
#> 49     <NA>       <NA>
#> 50     <NA>       <NA>
#> 51     <NA>       <NA>
#> 52     <NA>       <NA>
#> 53     <NA>       <NA>
#> 54     <NA>       <NA>
#> 55     <NA>       <NA>
#> 56     <NA>       <NA>
#> 57     <NA>       <NA>
#> 58     <NA>       <NA>
#> 59     <NA>       <NA>
#> 60     <NA>       <NA>
#> 61     <NA>       <NA>
#> 62     <NA>       <NA>
#> 63     <NA>       <NA>
#> 64     <NA>       <NA>
#> 65     <NA>       <NA>
#> 66     <NA>       <NA>
#> 67     <NA>       <NA>
#> 68     <NA>       <NA>
#> 69     <NA>       <NA>
#> 70     <NA>       <NA>
#> 71     <NA>       <NA>
#> 72     <NA>       <NA>
#> 73     <NA>       <NA>
#> 74     <NA>       <NA>
#> 75     <NA>       <NA>
#> 76     <NA>       <NA>
#> 77     <NA>       <NA>
#> 78     <NA>       <NA>
#> 79     <NA>       <NA>
#> 80     <NA>       <NA>
#> 81     <NA>       <NA>
#> 82     <NA>       <NA>
#> 83     <NA>       <NA>
#> 84     <NA>       <NA>
#> 85     <NA>       <NA>
#> 86     <NA>       <NA>
#> 87     <NA>       <NA>
#> 88     <NA>       <NA>
#> 89     <NA>       <NA>
#> 90     <NA>       <NA>
#> 91     <NA>       <NA>
get_data_registry(family = "enrollment", end_year = 2024)
#>    state     family end_year               source_id variant status mode
#> 36    NJ enrollment     2024 fall_enrollment_reports    <NA> served live
#>      fetcher n_source_files n_derived_files   bytes
#> 36 fetch_enr              1               0 1061242
#>                                                            source_url
#> 36 https://www.nj.gov/education/doedata/enr/enr24/enrollment_2324.zip
#>                             publisher publisher_type                   title
#> 36 New Jersey Department of Education      state_doe Fall Enrollment Reports
#>         year_basis                               landing_url reason evidence
#> 36 school_year_end https://www.nj.gov/education/doedata/enr/   <NA>     <NA>
#>    checked_on
#> 36       <NA>
```
