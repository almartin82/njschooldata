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
#> 59               absence     2017                  fetch_absence
#> 60               absence     2018                  fetch_absence
#> 61               absence     2019                  fetch_absence
#> 62               absence     2021                  fetch_absence
#> 63               absence     2022                  fetch_absence
#> 64               absence     2023                  fetch_absence
#> 65               absence     2024                  fetch_absence
#> 66               absence     2025                  fetch_absence
#> 29            assessment     2015                    fetch_parcc
#> 30            assessment     2016                    fetch_parcc
#> 31            assessment     2017                    fetch_parcc
#> 32            assessment     2018                    fetch_parcc
#> 33            assessment     2019                    fetch_parcc
#> 34            assessment     2022                    fetch_parcc
#> 35            assessment     2023                    fetch_parcc
#> 36            assessment     2024                    fetch_parcc
#> 37            assessment     2025                    fetch_parcc
#> 38            assessment     2026                    fetch_parcc
#> 158    assessment_access     2022                   fetch_access
#> 159    assessment_access     2023                   fetch_access
#> 160    assessment_access     2024                   fetch_access
#> 161    assessment_access     2025                   fetch_access
#> 39      assessment_njgpa     2022                    fetch_njgpa
#> 40      assessment_njgpa     2023                    fetch_njgpa
#> 41      assessment_njgpa     2024                    fetch_njgpa
#> 42      assessment_njgpa     2025                    fetch_njgpa
#> 43      assessment_njgpa     2026                    fetch_njgpa
#> 102                  ell     2006                      fetch_ell
#> 103                  ell     2007                      fetch_ell
#> 104                  ell     2008                      fetch_ell
#> 105                  ell     2009                      fetch_ell
#> 106                  ell     2010                      fetch_ell
#> 107                  ell     2011                      fetch_ell
#> 108                  ell     2012                      fetch_ell
#> 109                  ell     2013                      fetch_ell
#> 110                  ell     2014                      fetch_ell
#> 111                  ell     2015                      fetch_ell
#> 112                  ell     2016                      fetch_ell
#> 113                  ell     2017                      fetch_ell
#> 114                  ell     2018                      fetch_ell
#> 115                  ell     2019                      fetch_ell
#> 116                  ell     2020                      fetch_ell
#> 117                  ell     2021                      fetch_ell
#> 118                  ell     2022                      fetch_ell
#> 119                  ell     2023                      fetch_ell
#> 120                  ell     2024                      fetch_ell
#> 121                  ell     2025                      fetch_ell
#> 122                  ell     2026                      fetch_ell
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
#> 171 essa_chronic_absence     2017 fetch_essa_chronic_absenteeism
#> 172 essa_chronic_absence     2018 fetch_essa_chronic_absenteeism
#> 173 essa_chronic_absence     2019 fetch_essa_chronic_absenteeism
#> 174 essa_chronic_absence     2022 fetch_essa_chronic_absenteeism
#> 175 essa_chronic_absence     2023 fetch_essa_chronic_absenteeism
#> 176 essa_chronic_absence     2024 fetch_essa_chronic_absenteeism
#> 67               finance     2001                  fetch_finance
#> 68               finance     2002                  fetch_finance
#> 69               finance     2003                  fetch_finance
#> 70               finance     2004                  fetch_finance
#> 71               finance     2005                  fetch_finance
#> 72               finance     2006                  fetch_finance
#> 73               finance     2007                  fetch_finance
#> 74               finance     2008                  fetch_finance
#> 75               finance     2009                  fetch_finance
#> 76               finance     2010                  fetch_finance
#> 77               finance     2011                  fetch_finance
#> 78               finance     2012                  fetch_finance
#> 79               finance     2013                  fetch_finance
#> 80               finance     2014                  fetch_finance
#> 81               finance     2015                  fetch_finance
#> 82               finance     2016                  fetch_finance
#> 83               finance     2017                  fetch_finance
#> 84               finance     2018                  fetch_finance
#> 85               finance     2019                  fetch_finance
#> 86               finance     2020                  fetch_finance
#> 87               finance     2021                  fetch_finance
#> 88               finance     2022                  fetch_finance
#> 89               finance     2023                  fetch_finance
#> 90               finance     2024                  fetch_finance
#> 91               finance     2025                  fetch_finance
#> 92               finance     2026                  fetch_finance
#> 44            graduation     2011                fetch_grad_rate
#> 45            graduation     2012                fetch_grad_rate
#> 46            graduation     2013                fetch_grad_rate
#> 47            graduation     2014                fetch_grad_rate
#> 48            graduation     2015                fetch_grad_rate
#> 49            graduation     2016                fetch_grad_rate
#> 50            graduation     2017                fetch_grad_rate
#> 51            graduation     2018                fetch_grad_rate
#> 52            graduation     2019                fetch_grad_rate
#> 53            graduation     2020                fetch_grad_rate
#> 54            graduation     2021                fetch_grad_rate
#> 55            graduation     2022                fetch_grad_rate
#> 56            graduation     2023                fetch_grad_rate
#> 57            graduation     2024                fetch_grad_rate
#> 58            graduation     2025                fetch_grad_rate
#> 153       graduation_6yr     2021            fetch_6yr_grad_rate
#> 154       graduation_6yr     2022            fetch_6yr_grad_rate
#> 155       graduation_6yr     2023            fetch_6yr_grad_rate
#> 156       graduation_6yr     2024            fetch_6yr_grad_rate
#> 157       graduation_6yr     2025            fetch_6yr_grad_rate
#> 139     graduation_count     2012               fetch_grad_count
#> 140     graduation_count     2013               fetch_grad_count
#> 141     graduation_count     2014               fetch_grad_count
#> 142     graduation_count     2015               fetch_grad_count
#> 143     graduation_count     2016               fetch_grad_count
#> 144     graduation_count     2017               fetch_grad_count
#> 145     graduation_count     2018               fetch_grad_count
#> 146     graduation_count     2019               fetch_grad_count
#> 147     graduation_count     2020               fetch_grad_count
#> 148     graduation_count     2021               fetch_grad_count
#> 149     graduation_count     2022               fetch_grad_count
#> 150     graduation_count     2023               fetch_grad_count
#> 151     graduation_count     2024               fetch_grad_count
#> 152     graduation_count     2025               fetch_grad_count
#> 123                 sped     2015                     fetch_sped
#> 124                 sped     2016                     fetch_sped
#> 125                 sped     2017                     fetch_sped
#> 126                 sped     2018                     fetch_sped
#> 127                 sped     2019                     fetch_sped
#> 128                 sped     2020                     fetch_sped
#> 129                 sped     2021                     fetch_sped
#> 130                 sped     2022                     fetch_sped
#> 131                 sped     2023                     fetch_sped
#> 132                 sped     2024                     fetch_sped
#> 133                 sped     2025                     fetch_sped
#> 134        sped_by_grade     2022            fetch_sped_by_grade
#> 135        sped_by_grade     2023            fetch_sped_by_grade
#> 136        sped_by_grade     2024            fetch_sped_by_grade
#> 137        sped_by_grade     2025            fetch_sped_by_grade
#> 138        sped_by_grade     2026            fetch_sped_by_grade
#> 99      sped_environment     2023         fetch_sped_environment
#> 100     sped_environment     2024         fetch_sped_environment
#> 101     sped_environment     2025         fetch_sped_environment
#> 93            sped_share     2023               fetch_sped_share
#> 94            sped_share     2024               fetch_sped_share
#> 95            sped_share     2025               fetch_sped_share
#> 96            sped_share     2026               fetch_sped_share
#> 97             stability     2024                fetch_stability
#> 98             stability     2025                fetch_stability
#> 162            state_aid     2019                fetch_state_aid
#> 163            state_aid     2020                fetch_state_aid
#> 164            state_aid     2021                fetch_state_aid
#> 165            state_aid     2022                fetch_state_aid
#> 166            state_aid     2023                fetch_state_aid
#> 167            state_aid     2024                fetch_state_aid
#> 168            state_aid     2025                fetch_state_aid
#> 169            state_aid     2026                fetch_state_aid
#> 170            state_aid     2027                fetch_state_aid
coverage <- get_available_years()
subset(coverage, end_year == max(end_year))
#>          type end_year         fetcher
#> 170 state_aid     2027 fetch_state_aid
```
