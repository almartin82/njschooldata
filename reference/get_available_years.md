# Get available end years under default selectors

Reports years served by a type's fetcher with \`source = "live"\` or
\`source = "package"\`, and all other selectors at their defaults.
Coverage is computed offline from the declarations the fetchers enforce.
Years requiring non-default selectors or private stores are excluded.

## Usage

``` r
get_available_years(type = NULL)
```

## Arguments

- type:

  A single fetch family name, such as \`"enrollment"\`, or \`NULL\` for
  all declared types.

## Value

With \`type\`, a sorted, unique integer vector of school year ends. With
\`NULL\`, a data frame with columns \`type\`, \`end_year\`, and
\`fetcher\`, ordered by type and year. Gaps in coverage remain visible.

## Details

Enrollment, absence, graduation, finance, sped, sped_by_grade,
sped_share, ell, graduation_count, graduation_6yr, assessment_access,
state_aid and essa_chronic_absence coverage is declared. Absence
excludes 2020, when chronic absenteeism was not published. Assessment
requires explicit grade/course and subject selectors and remains
undeclared. Other known fetch families raise an error containing
"coverage not yet declared".

## Examples

``` r
get_available_years("enrollment")
#>  [1] 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013
#> [16] 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025 2026
get_available_years()
#>                     type end_year                        fetcher
#> 44               absence     2017                  fetch_absence
#> 45               absence     2018                  fetch_absence
#> 46               absence     2019                  fetch_absence
#> 47               absence     2021                  fetch_absence
#> 48               absence     2022                  fetch_absence
#> 49               absence     2023                  fetch_absence
#> 50               absence     2024                  fetch_absence
#> 51               absence     2025                  fetch_absence
#> 143    assessment_access     2022                   fetch_access
#> 144    assessment_access     2023                   fetch_access
#> 145    assessment_access     2024                   fetch_access
#> 146    assessment_access     2025                   fetch_access
#> 87                   ell     2006                      fetch_ell
#> 88                   ell     2007                      fetch_ell
#> 89                   ell     2008                      fetch_ell
#> 90                   ell     2009                      fetch_ell
#> 91                   ell     2010                      fetch_ell
#> 92                   ell     2011                      fetch_ell
#> 93                   ell     2012                      fetch_ell
#> 94                   ell     2013                      fetch_ell
#> 95                   ell     2014                      fetch_ell
#> 96                   ell     2015                      fetch_ell
#> 97                   ell     2016                      fetch_ell
#> 98                   ell     2017                      fetch_ell
#> 99                   ell     2018                      fetch_ell
#> 100                  ell     2019                      fetch_ell
#> 101                  ell     2020                      fetch_ell
#> 102                  ell     2021                      fetch_ell
#> 103                  ell     2022                      fetch_ell
#> 104                  ell     2023                      fetch_ell
#> 105                  ell     2024                      fetch_ell
#> 106                  ell     2025                      fetch_ell
#> 107                  ell     2026                      fetch_ell
#> 1             enrollment     1999                      fetch_enr
#> 2             enrollment     2000                      fetch_enr
#> 3             enrollment     2001                      fetch_enr
#> 4             enrollment     2002                      fetch_enr
#> 5             enrollment     2003                      fetch_enr
#> 6             enrollment     2004                      fetch_enr
#> 7             enrollment     2005                      fetch_enr
#> 8             enrollment     2006                      fetch_enr
#> 9             enrollment     2007                      fetch_enr
#> 10            enrollment     2008                      fetch_enr
#> 11            enrollment     2009                      fetch_enr
#> 12            enrollment     2010                      fetch_enr
#> 13            enrollment     2011                      fetch_enr
#> 14            enrollment     2012                      fetch_enr
#> 15            enrollment     2013                      fetch_enr
#> 16            enrollment     2014                      fetch_enr
#> 17            enrollment     2015                      fetch_enr
#> 18            enrollment     2016                      fetch_enr
#> 19            enrollment     2017                      fetch_enr
#> 20            enrollment     2018                      fetch_enr
#> 21            enrollment     2019                      fetch_enr
#> 22            enrollment     2020                      fetch_enr
#> 23            enrollment     2021                      fetch_enr
#> 24            enrollment     2022                      fetch_enr
#> 25            enrollment     2023                      fetch_enr
#> 26            enrollment     2024                      fetch_enr
#> 27            enrollment     2025                      fetch_enr
#> 28            enrollment     2026                      fetch_enr
#> 156 essa_chronic_absence     2017 fetch_essa_chronic_absenteeism
#> 157 essa_chronic_absence     2018 fetch_essa_chronic_absenteeism
#> 158 essa_chronic_absence     2019 fetch_essa_chronic_absenteeism
#> 159 essa_chronic_absence     2022 fetch_essa_chronic_absenteeism
#> 160 essa_chronic_absence     2023 fetch_essa_chronic_absenteeism
#> 161 essa_chronic_absence     2024 fetch_essa_chronic_absenteeism
#> 52               finance     2001                  fetch_finance
#> 53               finance     2002                  fetch_finance
#> 54               finance     2003                  fetch_finance
#> 55               finance     2004                  fetch_finance
#> 56               finance     2005                  fetch_finance
#> 57               finance     2006                  fetch_finance
#> 58               finance     2007                  fetch_finance
#> 59               finance     2008                  fetch_finance
#> 60               finance     2009                  fetch_finance
#> 61               finance     2010                  fetch_finance
#> 62               finance     2011                  fetch_finance
#> 63               finance     2012                  fetch_finance
#> 64               finance     2013                  fetch_finance
#> 65               finance     2014                  fetch_finance
#> 66               finance     2015                  fetch_finance
#> 67               finance     2016                  fetch_finance
#> 68               finance     2017                  fetch_finance
#> 69               finance     2018                  fetch_finance
#> 70               finance     2019                  fetch_finance
#> 71               finance     2020                  fetch_finance
#> 72               finance     2021                  fetch_finance
#> 73               finance     2022                  fetch_finance
#> 74               finance     2023                  fetch_finance
#> 75               finance     2024                  fetch_finance
#> 76               finance     2025                  fetch_finance
#> 77               finance     2026                  fetch_finance
#> 29            graduation     2011                fetch_grad_rate
#> 30            graduation     2012                fetch_grad_rate
#> 31            graduation     2013                fetch_grad_rate
#> 32            graduation     2014                fetch_grad_rate
#> 33            graduation     2015                fetch_grad_rate
#> 34            graduation     2016                fetch_grad_rate
#> 35            graduation     2017                fetch_grad_rate
#> 36            graduation     2018                fetch_grad_rate
#> 37            graduation     2019                fetch_grad_rate
#> 38            graduation     2020                fetch_grad_rate
#> 39            graduation     2021                fetch_grad_rate
#> 40            graduation     2022                fetch_grad_rate
#> 41            graduation     2023                fetch_grad_rate
#> 42            graduation     2024                fetch_grad_rate
#> 43            graduation     2025                fetch_grad_rate
#> 138       graduation_6yr     2021            fetch_6yr_grad_rate
#> 139       graduation_6yr     2022            fetch_6yr_grad_rate
#> 140       graduation_6yr     2023            fetch_6yr_grad_rate
#> 141       graduation_6yr     2024            fetch_6yr_grad_rate
#> 142       graduation_6yr     2025            fetch_6yr_grad_rate
#> 124     graduation_count     2012               fetch_grad_count
#> 125     graduation_count     2013               fetch_grad_count
#> 126     graduation_count     2014               fetch_grad_count
#> 127     graduation_count     2015               fetch_grad_count
#> 128     graduation_count     2016               fetch_grad_count
#> 129     graduation_count     2017               fetch_grad_count
#> 130     graduation_count     2018               fetch_grad_count
#> 131     graduation_count     2019               fetch_grad_count
#> 132     graduation_count     2020               fetch_grad_count
#> 133     graduation_count     2021               fetch_grad_count
#> 134     graduation_count     2022               fetch_grad_count
#> 135     graduation_count     2023               fetch_grad_count
#> 136     graduation_count     2024               fetch_grad_count
#> 137     graduation_count     2025               fetch_grad_count
#> 108                 sped     2015                     fetch_sped
#> 109                 sped     2016                     fetch_sped
#> 110                 sped     2017                     fetch_sped
#> 111                 sped     2018                     fetch_sped
#> 112                 sped     2019                     fetch_sped
#> 113                 sped     2020                     fetch_sped
#> 114                 sped     2021                     fetch_sped
#> 115                 sped     2022                     fetch_sped
#> 116                 sped     2023                     fetch_sped
#> 117                 sped     2024                     fetch_sped
#> 118                 sped     2025                     fetch_sped
#> 119        sped_by_grade     2022            fetch_sped_by_grade
#> 120        sped_by_grade     2023            fetch_sped_by_grade
#> 121        sped_by_grade     2024            fetch_sped_by_grade
#> 122        sped_by_grade     2025            fetch_sped_by_grade
#> 123        sped_by_grade     2026            fetch_sped_by_grade
#> 84      sped_environment     2023         fetch_sped_environment
#> 85      sped_environment     2024         fetch_sped_environment
#> 86      sped_environment     2025         fetch_sped_environment
#> 78            sped_share     2023               fetch_sped_share
#> 79            sped_share     2024               fetch_sped_share
#> 80            sped_share     2025               fetch_sped_share
#> 81            sped_share     2026               fetch_sped_share
#> 82             stability     2024                fetch_stability
#> 83             stability     2025                fetch_stability
#> 147            state_aid     2019                fetch_state_aid
#> 148            state_aid     2020                fetch_state_aid
#> 149            state_aid     2021                fetch_state_aid
#> 150            state_aid     2022                fetch_state_aid
#> 151            state_aid     2023                fetch_state_aid
#> 152            state_aid     2024                fetch_state_aid
#> 153            state_aid     2025                fetch_state_aid
#> 154            state_aid     2026                fetch_state_aid
#> 155            state_aid     2027                fetch_state_aid
coverage <- get_available_years()
subset(coverage, end_year == max(end_year))
#>          type end_year         fetcher
#> 155 state_aid     2027 fetch_state_aid
```
