# Fetch the share of students with IEPs, district rows by grade band or school rows

Rows of the share of students with an IEP, at the finest grain New
Jersey publishes, in the shape
[`sped_all_vs_all`](https://almartin82.github.io/njschooldata/reference/sped_all_vs_all.md)
and
[`sped_like_for_like`](https://almartin82.github.io/njschooldata/reference/sped_like_for_like.md)
read. Every value is from a NJDOE file.

## Usage

``` r
fetch_sped_share(
  end_year,
  basis = c("lea_idea", "school_report", "school_spr")
)
```

## Arguments

- end_year:

  ending school year. `"lea_idea"`: 2023-2026. `"school_report"`:
  2021-2025.

- basis:

  `"lea_idea"` (default) or `"school_report"`. Also accepts
  `"school_spr"`: school-only rates for 2023-2025 from the complete
  bundled 2024-25 EnrollmentTrendsByStudentGroup sheet. That basis keeps
  source_value and school_year, leaves n_sped NA, reads enrollment and
  grade spans from EnrollmentTrendsbyGrade, and preserves rounded or
  bounded rates in pct_sped_lo/hi. No count is recovered from a rounded
  share. The SPR guide defines this as students classified for special
  education divided by total enrollment. Enrollment is attributed to the
  school reporting enrollment; this differs from accountability's
  sending-school attribution for specialized receiving schools. School
  years 2023 and 2024 are historical rows in the 2025 release.

## Value

A data frame with end_year, entity_level (state, district or school),
district_id, school_id, district_name, school_name, grade_band (all,
elementary, middle, high), grade_low, grade_high, n_sped, n_enrolled,
pct_sped, pct_sped_lo, pct_sped_hi, is_charter, construct, count_date
and source_file. Suppressed values are NA, never zero.

## Details

Each basis uses its own construct and grain:

- `"lea_idea"` (default, 2023-2026):

  District (LEA) rows. For 2023-2025, an `all` row per district and the
  state from the IDEA classification files (count, enrollment, rate).
  For every year, rows for `elementary` (K-5), `middle` (6-8) and `high`
  (9-12) from NJDOE's response to OPRA request C255254 (see
  [`fetch_sped_by_grade`](https://almartin82.github.io/njschooldata/reference/fetch_sped_by_grade.md)),
  over the same year's Fall Enrollment by grade. Pre-K is left out of
  every band. A band with a suppressed grade cell (a count under 5) has
  `n_sped = NA` and `pct_sped_lo/hi` from the published bound of 1 to 4
  for each suppressed cell. A cell NJDOE left blank is zero students:
  wherever nothing is suppressed, the OPRA grade cells sum to the IDEA
  child count for every district in 2023-2025. The band rows carry no
  `pct_sped`: NJDOE publishes counts by grade, and the helpers pool the
  counts. **2025-26 is flagged**: known OPRA counts fall 8 percent from
  2024-25, there is no IDEA file yet, and the call warns.

- `"school_report"` (2021-2025, live):

  School rows, plus district and state rows, from the School Performance
  Reports: Students with Disabilities as a percent of enrollment, one
  decimal, with no suppression. `n_enrolled` is the same report's total
  enrollment, and `grade_low`/`grade_high` are the lowest and highest
  grades with students in that report. This is a different construct
  from the IDEA child count (in 2024-25 the statewide figure is 18.1
  percent against 17.35 percent for IDEA, and some schools differ by
  more); NJDOE does not explain the gap. Downloads the School
  Performance Reports workbooks, which are large.

- `"school_spr"` (2023-2025, bundled):

  School-only rates from the 2024-25 release's enrollment trends,
  preserving historical school-year labels, source text and rounding
  bounds. n_sped remains NA. The same report supplies enrollment and
  grade spans.

`is_charter` is TRUE for the state's charter sector (county code 80) and
for the three Camden renaissance operators in county 07 (1799, 1801,
1802) listed by the NJDOE Renaissance School Project, and FALSE
otherwise.

## See also

[`fetch_sped`](https://almartin82.github.io/njschooldata/reference/fetch_sped.md),
[`fetch_sped_by_grade`](https://almartin82.github.io/njschooldata/reference/fetch_sped_by_grade.md)

## Examples

``` r
# 1. District rows by grade band, with the IDEA all-grades row
share <- fetch_sped_share(2025)
#> Unknown column name: Column1
#> Unknown column name: Column2
head(share)
#>   end_year entity_level district_id school_id
#> 1     2025        state        <NA>      <NA>
#> 2     2025     district        0010      <NA>
#> 3     2025     district        0010      <NA>
#> 4     2025     district        0010      <NA>
#> 5     2025     district        0020      <NA>
#> 6     2025     district        0020      <NA>
#>                         district_name school_name grade_band grade_low
#> 1                     Statewide Total        <NA>        all      <NA>
#> 2     Absecon Public Schools District        <NA>        all      <NA>
#> 3     Absecon Public Schools District        <NA> elementary      <NA>
#> 4     Absecon Public Schools District        <NA>     middle      <NA>
#> 5 Alexandria Township School District        <NA>        all      <NA>
#> 6 Alexandria Township School District        <NA> elementary      <NA>
#>   grade_high n_sped n_enrolled pct_sped pct_sped_lo pct_sped_hi is_charter
#> 1       <NA> 242001    1394970 17.34812          NA          NA         NA
#> 2       <NA>    165        915 18.03000          NA          NA      FALSE
#> 3       <NA>     93        474       NA          NA          NA      FALSE
#> 4       <NA>     54        304       NA          NA          NA      FALSE
#> 5       <NA>     88        422 20.85000          NA          NA      FALSE
#> 6       <NA>     NA        256       NA    19.53125    20.70312      FALSE
#>                                      construct count_date
#> 1 students with an IEP, October 15 child count October 15
#> 2 students with an IEP, October 15 child count October 15
#> 3 students with an IEP, October 15 child count October 15
#> 4 students with an IEP, October 15 child count October 15
#> 5 students with an IEP, October 15 child count October 15
#> 6 students with an IEP, October 15 child count October 15
#>                                                                                                                           source_file
#> 1 https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2025_618data/2025IDEA618PublicReporting_ClassificationRates.xlsx
#> 2 https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2025_618data/2025IDEA618PublicReporting_ClassificationRates.xlsx
#> 3                                                     opra://njdoe/C255254/Districtlevel_C255254_Suppressed.xlsx; enrollment-2025.zip
#> 4                                                     opra://njdoe/C255254/Districtlevel_C255254_Suppressed.xlsx; enrollment-2025.zip
#> 5 https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2025_618data/2025IDEA618PublicReporting_ClassificationRates.xlsx
#> 6                                                     opra://njdoe/C255254/Districtlevel_C255254_Suppressed.xlsx; enrollment-2025.zip

# 2. Band counts for the district-run and charter sectors
library(dplyr)
share %>%
  filter(entity_level == "district", grade_band != "all") %>%
  group_by(is_charter, grade_band) %>%
  summarise(n_sped = sum(n_sped, na.rm = TRUE), n_enrolled = sum(n_enrolled, na.rm = TRUE))
#> `summarise()` has regrouped the output.
#> ℹ Summaries were computed grouped by is_charter and grade_band.
#> ℹ Output is grouped by is_charter.
#> ℹ Use `summarise(.groups = "drop_last")` to silence this message.
#> ℹ Use `summarise(.by = c(is_charter, grade_band))` for per-operation grouping
#>   (`?dplyr::dplyr_by`) instead.
#> # A tibble: 6 × 4
#> # Groups:   is_charter [2]
#>   is_charter grade_band n_sped n_enrolled
#>   <lgl>      <chr>       <dbl>      <dbl>
#> 1 FALSE      elementary  89068    533221 
#> 2 FALSE      high        70872    404992 
#> 3 FALSE      middle      51142    280688 
#> 4 TRUE       elementary   1747     36371 
#> 5 TRUE       high         1668     14256.
#> 6 TRUE       middle       2068     19254 

# 3. School rows from the bundled School Performance Reports
fetch_sped_share(2024, basis = "school_spr") %>%
  filter(entity_level == "school", is_charter)
#>    end_year entity_level district_id school_id
#> 1      2024       school        6010       910
#> 2      2024       school        6013       900
#> 3      2024       school        6017       932
#> 4      2024       school        6018       900
#> 5      2024       school        6020       985
#> 6      2024       school        6021       905
#> 7      2024       school        6022       990
#> 8      2024       school        6025       907
#> 9      2024       school        6026       908
#> 10     2024       school        6028       910
#> 11     2024       school        6029       911
#> 12     2024       school        6030       912
#> 13     2024       school        6032       901
#> 14     2024       school        6033       902
#> 15     2024       school        6036       921
#> 16     2024       school        6041       916
#> 17     2024       school        6053       917
#> 18     2024       school        6058       939
#> 19     2024       school        6060       942
#> 20     2024       school        6064       946
#> 21     2024       school        6069       952
#> 22     2024       school        6076       961
#> 23     2024       school        6079       964
#> 24     2024       school        6080       966
#> 25     2024       school        6081       967
#> 26     2024       school        6082       963
#> 27     2024       school        6086       972
#> 28     2024       school        6089       976
#> 29     2024       school        6093       981
#> 30     2024       school        6094       968
#> 31     2024       school        6096       982
#> 32     2024       school        6099       986
#> 33     2024       school        6100       991
#> 34     2024       school        6101       992
#> 35     2024       school        6102       993
#> 36     2024       school        6103       994
#> 37     2024       school        6104       995
#> 38     2024       school        6105       996
#> 39     2024       school        6106       997
#> 40     2024       school        6107       998
#> 41     2024       school        6109       953
#> 42     2024       school        6183       914
#> 43     2024       school        6230       915
#> 44     2024       school        6320       920
#> 45     2024       school        6410       920
#> 46     2024       school        6420       925
#> 47     2024       school        6430       930
#> 48     2024       school        6635       930
#> 49     2024       school        6665       930
#> 50     2024       school        6720       930
#> 51     2024       school        6740       950
#> 52     2024       school        6810       940
#> 53     2024       school        6910       940
#> 54     2024       school        6915       950
#> 55     2024       school        7021       986
#> 56     2024       school        7109       931
#> 57     2024       school        7115       960
#> 58     2024       school        7210       940
#> 59     2024       school        7290       957
#> 60     2024       school        7320       960
#> 61     2024       school        7325       965
#> 62     2024       school        7410       940
#> 63     2024       school        7500       900
#> 64     2024       school        7503       970
#> 65     2024       school        7540       930
#> 66     2024       school        7600       960
#> 67     2024       school        7720       915
#> 68     2024       school        7727       900
#> 69     2024       school        7730       970
#> 70     2024       school        7735       975
#> 71     2024       school        7830       980
#> 72     2024       school        7850       960
#> 73     2024       school        7890       920
#> 74     2024       school        7891       904
#> 75     2024       school        7892       909
#> 76     2024       school        7893       918
#> 77     2024       school        7895       920
#> 78     2024       school        7896       923
#> 79     2024       school        7897       923
#> 80     2024       school        7898       924
#> 81     2024       school        7899       925
#> 82     2024       school        8010       980
#> 83     2024       school        8050       990
#> 84     2024       school        8060       990
#> 85     2024       school        8140       990
#>                                                  district_name
#> 1                                  Academy Charter High School
#> 2                       Bergen Arts and Science Charter School
#> 3                            Foundation Academy Charter School
#> 4                   Central Jersey College Prep Charter School
#> 5                        Pride Academy Charter School District
#> 6                         Community Charter School of Paterson
#> 7                           Burch Charter School of Excellence
#> 8               Paul Robeson Charter School for the Humanities
#> 9                       Riverbank Charter School of Excellence
#> 10                              Vineland Public Charter School
#> 11                   Newark Educators Community Charter School
#> 12        The Ethical Community Charter School School District
#> 13                 Academy for Urban Leadership Charter School
#> 14                  Barack Obama Green Charter School District
#> 15                        Hoboken Dual Language Charter School
#> 16               Hatikvah International Academy Charter School
#> 17                            Great Oaks Legacy Charter School
#> 18                          Roseville Community Charter School
#> 19                           Atlantic Community Charter School
#> 20                     Dr Lena Edwards Academic Charter School
#> 21                    Millville Public Charter School District
#> 22                Benjamin Banneker Preparatory Charter School
#> 23               John P Holland Charter School School District
#> 24                     Passaic Arts and Science Charter School
#> 25                    Thomas Edison EnergySmart Charter School
#> 26                                   BelovED Community Charter
#> 27                               Hope Community Charter School
#> 28                              Compass Academy Charter School
#> 29                           Jersey City Global Charter School
#> 30                             Philip's Academy Charter School
#> 31                    Paterson Arts and Science Charter School
#> 32                               Link Community Charter School
#> 33                             Bridgeton Public Charter School
#> 34                      College Achieve Central Charter School
#> 35                           Cresthaven Academy Charter School
#> 36                          Empowerment Academy Charter School
#> 37                            Principle Academy Charter School
#> 38                      Hudson Arts and Science Charter School
#> 39                 Philip's Academy Charter School of Paterson
#> 40                             Camden's Promise Charter School
#> 41                                         LEAD Charter School
#> 42                       Trenton STEM-to-Civics Charter School
#> 43                 Classical Academy Charter School of Clifton
#> 44                                    Discovery Charter School
#> 45                        East Orange Community Charter School
#> 46                                      Elysian Charter School
#> 47                   Englewood on the Palisades Charter School
#> 48                            Greater Brunswick Charter School
#> 49                                         Gray Charter School
#> 50                             Hoboken Charter School District
#> 51                                 Hope Academy Charter School
#> 52                     International Charter School of Trenton
#> 53                        Jersey City Community Charter School
#> 54                      Jersey City Golden Door Charter School
#> 55                              Gateway Academy Charter School
#> 56                      LEAP Academy University Charter School
#> 57                       The Learning Community Charter School
#> 58                             Marion P. Thomas Charter School
#> 59                       New Horizons Community Charter School
#> 60                           North Star Academy Charter School
#> 61                                 TEAM Academy Charter School
#> 62             Chartertech High School for the Performing Arts
#> 63                             Pace Charter School of Hamilton
#> 64          Paterson Charter School for Science and Technology
#> 65                                    Princeton Charter School
#> 66              The Queen City Academy Charter School District
#> 67                                     Red Bank Charter School
#> 68                             Ridge and Valley Charter School
#> 69                         Robert Treat Academy Charter School
#> 70                      Maria L. Varisco-Rogers Charter School
#> 71                              Soaring Heights Charter School
#> 72                     Sussex County Technology Charter School
#> 73                            Teaneck Community Charter School
#> 74 College Achieve Greater Asbury Park Charter School District
#> 75                     College Achieve Paterson Charter School
#> 76                                Ocean Academy Charter School
#> 77                 Achievers Early College Prep Charter School
#> 78                        Middlesex County STEM Charter School
#> 79                      Creativity CoLaboratory Charter School
#> 80                      Kindle Education Public Charter School
#> 81                         Paterson Preparatory Charter School
#> 82    Union County TEAMS Charter School-High School/College LA
#> 83                                        Unity Charter School
#> 84                      University Academy Charter High School
#> 85                                  The Village Charter School
#>                                                    school_name grade_band
#> 1                                  Academy Charter High School        all
#> 2                      Bergen Arts and Sciences Charter School        all
#> 3                            Foundation Academy Charter School        all
#> 4                   Central Jersey College Prep Charter School        all
#> 5                                 Pride Academy Charter School        all
#> 6                         Community Charter School of Paterson        all
#> 7                           Burch Charter School of Excellence        all
#> 8               Paul Robeson Charter School for the Humanities        all
#> 9                       Riverbank Charter School of Excellence        all
#> 10                              Vineland Public Charter School        all
#> 11                   Newark Educators Community Charter School        all
#> 12                        The Ethical Community Charter School        all
#> 13                 Academy for Urban Leadership Charter School        all
#> 14                           Barack Obama Green Charter School        all
#> 15                        Hoboken Dual Language Charter School        all
#> 16               Hatikvah International Academy Charter School        all
#> 17                            Great Oaks Legacy Charter School        all
#> 18                          Roseville Community Charter School        all
#> 19                           Atlantic Community Charter School        all
#> 20                     Dr Lena Edwards Academic Charter School        all
#> 21                             Millville Public Charter School        all
#> 22                Benjamin Banneker Preparatory Charter School        all
#> 23                              John P. Holland Charter School        all
#> 24                     Passaic Arts and Science Charter School        all
#> 25                    Thomas Edison EnergySmart Charter School        all
#> 26                            BelovED Community Charter School        all
#> 27                               Hope Community Charter School        all
#> 28                              Compass Academy Charter School        all
#> 29                           Jersey City Global Charter School        all
#> 30                             Philip's Academy Charter School        all
#> 31                    Paterson Arts and Science Charter School        all
#> 32                               Link Community Charter School        all
#> 33                             Bridgeton Public Charter School        all
#> 34                      College Achieve Central Charter School        all
#> 35                           Cresthaven Academy Charter School        all
#> 36                          Empowerment Academy Charter School        all
#> 37                            Principle Academy Charter School        all
#> 38                      Hudson Arts and Science Charter School        all
#> 39                 Philip's Academy Charter School of Paterson        all
#> 40                             Camden's Promise Charter School        all
#> 41                                         LEAD Charter School        all
#> 42                       Trenton STEM-to-Civics Charter School        all
#> 43                 Classical Academy Charter School of Clifton        all
#> 44                                    Discovery Charter School        all
#> 45                        East Orange Community Charter School        all
#> 46                           Elysian Charter School of Hoboken        all
#> 47                   Englewood on the Palisades Charter School        all
#> 48                            Greater Brunswick Charter School        all
#> 49                                     The Gray Charter School        all
#> 50                                      Hoboken Charter School        all
#> 51                                 Hope Academy Charter School        all
#> 52                                 International CS of Trenton        all
#> 53                        Jersey City Community Charter School        all
#> 54                      Jersey City Golden Door Charter School        all
#> 55                              Gateway Academy Charter School        all
#> 56                      Leap Academy University Charter School        all
#> 57                           Learning Community Charter School        all
#> 58                             Marion P. Thomas Charter School        all
#> 59                       New Horizons Community Charter School        all
#> 60                           North Star Academy Charter School        all
#> 61                                 TEAM Academy Charter School        all
#> 62             Chartertech High School for the Performing Arts        all
#> 63                             Pace Charter School of Hamilton        all
#> 64          Paterson Charter School for Science and Technology        all
#> 65                                    Princeton Charter School        all
#> 66                       The Queen City Academy Charter School        all
#> 67                                     Red Bank Charter School        all
#> 68                             Ridge and Valley Charter School        all
#> 69                         Robert Treat Academy Charter School        all
#> 70                         Maria Varisco Rogers Charter School        all
#> 71                              Soaring Heights Charter School        all
#> 72                     Sussex County Technology Charter School        all
#> 73                            Teaneck Community Charter school        all
#> 74 College Achieve Greater Asbury Park Charter School District        all
#> 75                     College Achieve Paterson Charter School        all
#> 76                                Ocean Academy Charter School        all
#> 77                 Achievers Early College Prep Charter School        all
#> 78                        Middlesex County STEM Charter School        all
#> 79                      Creativity CoLaboratory Charter School        all
#> 80                      Kindle Education Public Charter School        all
#> 81                         Paterson Preparatory Charter School        all
#> 82                           Union County TEAMS Charter School        all
#> 83                                        Unity Charter School        all
#> 84                      University Academy Charter High School        all
#> 85                                  The Village Charter School        all
#>    grade_low grade_high n_sped n_enrolled pct_sped pct_sped_lo pct_sped_hi
#> 1         09         12     NA        173     18.0       17.95       18.05
#> 2          K         12     NA       1266     11.1       11.05       11.15
#> 3          K         12     NA       1079     10.4       10.35       10.45
#> 4          K         12     NA       1318      9.3        9.25        9.35
#> 5         05         08     NA        296     15.2       15.15       15.25
#> 6          K         08     NA        875      9.3        9.25        9.35
#> 7          K         05     NA        310      2.9        2.85        2.95
#> 8         03         08     NA        434     10.8       10.75       10.85
#> 9          K         03     NA        151      6.0        5.95        6.05
#> 10        PK         08     NA        411     10.2       10.15       10.25
#> 11        PK         04     NA        154     12.3       12.25       12.35
#> 12         K         08     NA        342     11.1       11.05       11.15
#> 13        07         12     NA        334      5.1        5.05        5.15
#> 14        06         12     NA        314      8.9        8.85        8.95
#> 15         K         08     NA        428      9.3        9.25        9.35
#> 16         K         08     NA        635     11.2       11.15       11.25
#> 17        PK         12     NA       2122     15.0       14.95       15.05
#> 18         K         04     NA        280     13.9       13.85       13.95
#> 19         K         08     NA        317     18.0       17.95       18.05
#> 20         K         08     NA        372     23.1       23.05       23.15
#> 21         K         08     NA        325     11.4       11.35       11.45
#> 22         K         08     NA        360     11.9       11.85       11.95
#> 23        PK         08     NA        730     12.3       12.25       12.35
#> 24         K         12     NA       2032     11.5       11.45       11.55
#> 25         K         12     NA        611      5.1        5.05        5.15
#> 26         K         12     NA       1534      8.9        8.85        8.95
#> 27         K         08     NA        124     17.7       17.65       17.75
#> 28        PK         05     NA        177     16.9       16.85       16.95
#> 29         K         08     NA        412      5.8        5.75        5.85
#> 30        PK         08     NA        667      7.3        7.25        7.35
#> 31         K         12     NA       1184     12.7       12.65       12.75
#> 32         K         08     NA        359     11.4       11.35       11.45
#> 33         K         04     NA        125      4.8        4.75        4.85
#> 34         K         12     NA       1397      8.2        8.15        8.25
#> 35         K         07     NA        599      9.8        9.75        9.85
#> 36         K         09     NA       1150     12.2       12.15       12.25
#> 37         K         06     NA        448     16.3       16.25       16.35
#> 38         K         08     NA        825     14.9       14.85       14.95
#> 39         K         07     NA        600     15.7       15.65       15.75
#> 40        PK         12     NA       2378     10.8       10.75       10.85
#> 41        09         12     NA        287     16.4       16.35       16.45
#> 42        06         12     NA        567     12.0       11.95       12.05
#> 43        05         08     NA        158      6.3        6.25        6.35
#> 44        04         08     NA        106     12.3       12.25       12.35
#> 45         K         04     NA        427      8.7        8.65        8.75
#> 46         K         08     NA        293     13.0       12.95       13.05
#> 47         K         08     NA        313     12.1       12.05       12.15
#> 48         K         08     NA        397     21.2       21.15       21.25
#> 49         K         08     NA        325      7.4        7.35        7.45
#> 50         K         12     NA        299     17.1       17.05       17.15
#> 51         K         08     NA        292     18.2       18.15       18.25
#> 52         K         05     NA        108      9.3        9.25        9.35
#> 53         K         08     NA        560     12.9       12.85       12.95
#> 54        PK         08     NA        647      7.1        7.05        7.15
#> 55         K         12     NA        750     13.9       13.85       13.95
#> 56         K         12     NA       1566      8.2        8.15        8.25
#> 57        PK         08     NA        638     10.5       10.45       10.55
#> 58        PK         12     NA       1373     11.1       11.05       11.15
#> 59         K         08     NA        340      4.7        4.65        4.75
#> 60         K         12     NA       6404      9.2        9.15        9.25
#> 61         K         12     NA       6241     13.7       13.65       13.75
#> 62        09         12     NA        291     30.9       30.85       30.95
#> 63         K         08     NA        453      5.1        5.05        5.15
#> 64         K         12     NA       1656     12.7       12.65       12.75
#> 65         K         08     NA        424      7.8        7.75        7.85
#> 66         K         11     NA        424      7.3        7.25        7.35
#> 67        PK         08     NA        184     13.0       12.95       13.05
#> 68         K         08     NA        134     23.9       23.85       23.95
#> 69         K         08     NA        698     11.0       10.95       11.05
#> 70         K         08     NA        582     13.7       13.65       13.75
#> 71         K         08     NA        273      4.8        4.75        4.85
#> 72        06         08     NA        222     20.7       20.65       20.75
#> 73         K         08     NA        369     13.0       12.95       13.05
#> 74         K         12     NA        560     14.1       14.05       14.15
#> 75         K         12     NA       1474      3.8        3.75        3.85
#> 76         K         08     NA        485     20.4       20.35       20.45
#> 77        06         10     NA        441      7.5        7.45        7.55
#> 78         K         07     NA        551     11.8       11.75       11.85
#> 79        05         08     NA        190     11.1       11.05       11.15
#> 80        06         06     NA         63     19.0       18.95       19.05
#> 81         K         05     NA        196      9.2        9.15        9.25
#> 82         K         12     NA        314      6.4        6.35        6.45
#> 83         K         08     NA        245     15.9       15.85       15.95
#> 84        09         12     NA        421     18.3       18.25       18.35
#> 85         K         08     NA        361      9.4        9.35        9.45
#>    is_charter                                         construct
#> 1        TRUE students with disabilities, percent of enrollment
#> 2        TRUE students with disabilities, percent of enrollment
#> 3        TRUE students with disabilities, percent of enrollment
#> 4        TRUE students with disabilities, percent of enrollment
#> 5        TRUE students with disabilities, percent of enrollment
#> 6        TRUE students with disabilities, percent of enrollment
#> 7        TRUE students with disabilities, percent of enrollment
#> 8        TRUE students with disabilities, percent of enrollment
#> 9        TRUE students with disabilities, percent of enrollment
#> 10       TRUE students with disabilities, percent of enrollment
#> 11       TRUE students with disabilities, percent of enrollment
#> 12       TRUE students with disabilities, percent of enrollment
#> 13       TRUE students with disabilities, percent of enrollment
#> 14       TRUE students with disabilities, percent of enrollment
#> 15       TRUE students with disabilities, percent of enrollment
#> 16       TRUE students with disabilities, percent of enrollment
#> 17       TRUE students with disabilities, percent of enrollment
#> 18       TRUE students with disabilities, percent of enrollment
#> 19       TRUE students with disabilities, percent of enrollment
#> 20       TRUE students with disabilities, percent of enrollment
#> 21       TRUE students with disabilities, percent of enrollment
#> 22       TRUE students with disabilities, percent of enrollment
#> 23       TRUE students with disabilities, percent of enrollment
#> 24       TRUE students with disabilities, percent of enrollment
#> 25       TRUE students with disabilities, percent of enrollment
#> 26       TRUE students with disabilities, percent of enrollment
#> 27       TRUE students with disabilities, percent of enrollment
#> 28       TRUE students with disabilities, percent of enrollment
#> 29       TRUE students with disabilities, percent of enrollment
#> 30       TRUE students with disabilities, percent of enrollment
#> 31       TRUE students with disabilities, percent of enrollment
#> 32       TRUE students with disabilities, percent of enrollment
#> 33       TRUE students with disabilities, percent of enrollment
#> 34       TRUE students with disabilities, percent of enrollment
#> 35       TRUE students with disabilities, percent of enrollment
#> 36       TRUE students with disabilities, percent of enrollment
#> 37       TRUE students with disabilities, percent of enrollment
#> 38       TRUE students with disabilities, percent of enrollment
#> 39       TRUE students with disabilities, percent of enrollment
#> 40       TRUE students with disabilities, percent of enrollment
#> 41       TRUE students with disabilities, percent of enrollment
#> 42       TRUE students with disabilities, percent of enrollment
#> 43       TRUE students with disabilities, percent of enrollment
#> 44       TRUE students with disabilities, percent of enrollment
#> 45       TRUE students with disabilities, percent of enrollment
#> 46       TRUE students with disabilities, percent of enrollment
#> 47       TRUE students with disabilities, percent of enrollment
#> 48       TRUE students with disabilities, percent of enrollment
#> 49       TRUE students with disabilities, percent of enrollment
#> 50       TRUE students with disabilities, percent of enrollment
#> 51       TRUE students with disabilities, percent of enrollment
#> 52       TRUE students with disabilities, percent of enrollment
#> 53       TRUE students with disabilities, percent of enrollment
#> 54       TRUE students with disabilities, percent of enrollment
#> 55       TRUE students with disabilities, percent of enrollment
#> 56       TRUE students with disabilities, percent of enrollment
#> 57       TRUE students with disabilities, percent of enrollment
#> 58       TRUE students with disabilities, percent of enrollment
#> 59       TRUE students with disabilities, percent of enrollment
#> 60       TRUE students with disabilities, percent of enrollment
#> 61       TRUE students with disabilities, percent of enrollment
#> 62       TRUE students with disabilities, percent of enrollment
#> 63       TRUE students with disabilities, percent of enrollment
#> 64       TRUE students with disabilities, percent of enrollment
#> 65       TRUE students with disabilities, percent of enrollment
#> 66       TRUE students with disabilities, percent of enrollment
#> 67       TRUE students with disabilities, percent of enrollment
#> 68       TRUE students with disabilities, percent of enrollment
#> 69       TRUE students with disabilities, percent of enrollment
#> 70       TRUE students with disabilities, percent of enrollment
#> 71       TRUE students with disabilities, percent of enrollment
#> 72       TRUE students with disabilities, percent of enrollment
#> 73       TRUE students with disabilities, percent of enrollment
#> 74       TRUE students with disabilities, percent of enrollment
#> 75       TRUE students with disabilities, percent of enrollment
#> 76       TRUE students with disabilities, percent of enrollment
#> 77       TRUE students with disabilities, percent of enrollment
#> 78       TRUE students with disabilities, percent of enrollment
#> 79       TRUE students with disabilities, percent of enrollment
#> 80       TRUE students with disabilities, percent of enrollment
#> 81       TRUE students with disabilities, percent of enrollment
#> 82       TRUE students with disabilities, percent of enrollment
#> 83       TRUE students with disabilities, percent of enrollment
#> 84       TRUE students with disabilities, percent of enrollment
#> 85       TRUE students with disabilities, percent of enrollment
#>                        count_date
#> 1  End-of-year enrollment 2023-24
#> 2  End-of-year enrollment 2023-24
#> 3  End-of-year enrollment 2023-24
#> 4  End-of-year enrollment 2023-24
#> 5  End-of-year enrollment 2023-24
#> 6  End-of-year enrollment 2023-24
#> 7  End-of-year enrollment 2023-24
#> 8  End-of-year enrollment 2023-24
#> 9  End-of-year enrollment 2023-24
#> 10 End-of-year enrollment 2023-24
#> 11 End-of-year enrollment 2023-24
#> 12 End-of-year enrollment 2023-24
#> 13 End-of-year enrollment 2023-24
#> 14 End-of-year enrollment 2023-24
#> 15 End-of-year enrollment 2023-24
#> 16 End-of-year enrollment 2023-24
#> 17 End-of-year enrollment 2023-24
#> 18 End-of-year enrollment 2023-24
#> 19 End-of-year enrollment 2023-24
#> 20 End-of-year enrollment 2023-24
#> 21 End-of-year enrollment 2023-24
#> 22 End-of-year enrollment 2023-24
#> 23 End-of-year enrollment 2023-24
#> 24 End-of-year enrollment 2023-24
#> 25 End-of-year enrollment 2023-24
#> 26 End-of-year enrollment 2023-24
#> 27 End-of-year enrollment 2023-24
#> 28 End-of-year enrollment 2023-24
#> 29 End-of-year enrollment 2023-24
#> 30 End-of-year enrollment 2023-24
#> 31 End-of-year enrollment 2023-24
#> 32 End-of-year enrollment 2023-24
#> 33 End-of-year enrollment 2023-24
#> 34 End-of-year enrollment 2023-24
#> 35 End-of-year enrollment 2023-24
#> 36 End-of-year enrollment 2023-24
#> 37 End-of-year enrollment 2023-24
#> 38 End-of-year enrollment 2023-24
#> 39 End-of-year enrollment 2023-24
#> 40 End-of-year enrollment 2023-24
#> 41 End-of-year enrollment 2023-24
#> 42 End-of-year enrollment 2023-24
#> 43 End-of-year enrollment 2023-24
#> 44 End-of-year enrollment 2023-24
#> 45 End-of-year enrollment 2023-24
#> 46 End-of-year enrollment 2023-24
#> 47 End-of-year enrollment 2023-24
#> 48 End-of-year enrollment 2023-24
#> 49 End-of-year enrollment 2023-24
#> 50 End-of-year enrollment 2023-24
#> 51 End-of-year enrollment 2023-24
#> 52 End-of-year enrollment 2023-24
#> 53 End-of-year enrollment 2023-24
#> 54 End-of-year enrollment 2023-24
#> 55 End-of-year enrollment 2023-24
#> 56 End-of-year enrollment 2023-24
#> 57 End-of-year enrollment 2023-24
#> 58 End-of-year enrollment 2023-24
#> 59 End-of-year enrollment 2023-24
#> 60 End-of-year enrollment 2023-24
#> 61 End-of-year enrollment 2023-24
#> 62 End-of-year enrollment 2023-24
#> 63 End-of-year enrollment 2023-24
#> 64 End-of-year enrollment 2023-24
#> 65 End-of-year enrollment 2023-24
#> 66 End-of-year enrollment 2023-24
#> 67 End-of-year enrollment 2023-24
#> 68 End-of-year enrollment 2023-24
#> 69 End-of-year enrollment 2023-24
#> 70 End-of-year enrollment 2023-24
#> 71 End-of-year enrollment 2023-24
#> 72 End-of-year enrollment 2023-24
#> 73 End-of-year enrollment 2023-24
#> 74 End-of-year enrollment 2023-24
#> 75 End-of-year enrollment 2023-24
#> 76 End-of-year enrollment 2023-24
#> 77 End-of-year enrollment 2023-24
#> 78 End-of-year enrollment 2023-24
#> 79 End-of-year enrollment 2023-24
#> 80 End-of-year enrollment 2023-24
#> 81 End-of-year enrollment 2023-24
#> 82 End-of-year enrollment 2023-24
#> 83 End-of-year enrollment 2023-24
#> 84 End-of-year enrollment 2023-24
#> 85 End-of-year enrollment 2023-24
#>                                                                                        source_file
#> 1  https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 2  https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 3  https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 4  https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 5  https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 6  https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 7  https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 8  https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 9  https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 10 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 11 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 12 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 13 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 14 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 15 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 16 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 17 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 18 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 19 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 20 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 21 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 22 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 23 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 24 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 25 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 26 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 27 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 28 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 29 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 30 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 31 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 32 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 33 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 34 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 35 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 36 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 37 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 38 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 39 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 40 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 41 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 42 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 43 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 44 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 45 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 46 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 47 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 48 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 49 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 50 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 51 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 52 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 53 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 54 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 55 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 56 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 57 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 58 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 59 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 60 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 61 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 62 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 63 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 64 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 65 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 66 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 67 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 68 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 69 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 70 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 71 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 72 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 73 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 74 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 75 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 76 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 77 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 78 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 79 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 80 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 81 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 82 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 83 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 84 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#> 85 https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
#>    source_value school_year
#> 1         18.0%     2023-24
#> 2         11.1%     2023-24
#> 3         10.4%     2023-24
#> 4          9.3%     2023-24
#> 5         15.2%     2023-24
#> 6          9.3%     2023-24
#> 7          2.9%     2023-24
#> 8         10.8%     2023-24
#> 9          6.0%     2023-24
#> 10        10.2%     2023-24
#> 11        12.3%     2023-24
#> 12        11.1%     2023-24
#> 13         5.1%     2023-24
#> 14         8.9%     2023-24
#> 15         9.3%     2023-24
#> 16        11.2%     2023-24
#> 17        15.0%     2023-24
#> 18        13.9%     2023-24
#> 19        18.0%     2023-24
#> 20        23.1%     2023-24
#> 21        11.4%     2023-24
#> 22        11.9%     2023-24
#> 23        12.3%     2023-24
#> 24        11.5%     2023-24
#> 25         5.1%     2023-24
#> 26         8.9%     2023-24
#> 27        17.7%     2023-24
#> 28        16.9%     2023-24
#> 29         5.8%     2023-24
#> 30         7.3%     2023-24
#> 31        12.7%     2023-24
#> 32        11.4%     2023-24
#> 33         4.8%     2023-24
#> 34         8.2%     2023-24
#> 35         9.8%     2023-24
#> 36        12.2%     2023-24
#> 37        16.3%     2023-24
#> 38        14.9%     2023-24
#> 39        15.7%     2023-24
#> 40        10.8%     2023-24
#> 41        16.4%     2023-24
#> 42        12.0%     2023-24
#> 43         6.3%     2023-24
#> 44        12.3%     2023-24
#> 45         8.7%     2023-24
#> 46        13.0%     2023-24
#> 47        12.1%     2023-24
#> 48        21.2%     2023-24
#> 49         7.4%     2023-24
#> 50        17.1%     2023-24
#> 51        18.2%     2023-24
#> 52         9.3%     2023-24
#> 53        12.9%     2023-24
#> 54         7.1%     2023-24
#> 55        13.9%     2023-24
#> 56         8.2%     2023-24
#> 57        10.5%     2023-24
#> 58        11.1%     2023-24
#> 59         4.7%     2023-24
#> 60         9.2%     2023-24
#> 61        13.7%     2023-24
#> 62        30.9%     2023-24
#> 63         5.1%     2023-24
#> 64        12.7%     2023-24
#> 65         7.8%     2023-24
#> 66         7.3%     2023-24
#> 67        13.0%     2023-24
#> 68        23.9%     2023-24
#> 69        11.0%     2023-24
#> 70        13.7%     2023-24
#> 71         4.8%     2023-24
#> 72        20.7%     2023-24
#> 73        13.0%     2023-24
#> 74        14.1%     2023-24
#> 75         3.8%     2023-24
#> 76        20.4%     2023-24
#> 77         7.5%     2023-24
#> 78        11.8%     2023-24
#> 79        11.1%     2023-24
#> 80        19.0%     2023-24
#> 81         9.2%     2023-24
#> 82         6.4%     2023-24
#> 83        15.9%     2023-24
#> 84        18.3%     2023-24
#> 85         9.4%     2023-24
```
