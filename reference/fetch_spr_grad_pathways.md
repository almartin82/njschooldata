# Fetch Graduation Pathways

Downloads the `GraduationPathways` sheet from the redesigned 2024-25
School Performance Reports. For each entity and subject (ELA and Math),
it reports the percentage of graduates who satisfied the
graduation-assessment requirement through each available pathway.

## Usage

``` r
fetch_spr_grad_pathways(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2018-2022, 2024, or 2025). Year is the end of the
  academic year - e.g. the 2020-21 school year is `end_year` 2021.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, school_year, subject, the four
pathway percentage columns, and the aggregation flags.

## Details

Pathways (columns, each a percentage on a 0-100 scale):

- `statewide_assessment` – met via the statewide NJSLA/NJGPA assessment.

- `substitute_competency_test` – met via an approved substitute
  competency test (e.g. SAT, ACT, PSAT, ASVAB).

- `portfolio_appeals` – met via the portfolio appeals process.

- `alternate_requirements_in_iep` – met via alternate requirements
  specified in the student's IEP.

Percentages are returned numeric (suppressed cells become `NA`).

**Supported years:** 2018-2022, 2024, and 2025. The `GraduationPathways`
sheet is present in those SPR databases (it is **absent** from the
SY2016-17 and SY2022-23 databases, which therefore error). Before the
2024-25 redesign the columns were named slightly differently
(`ELA/Math`, `PARCCAssessment`/`StatewideAssessment`,
`SubstituteCompetency`, `PortfolioAppealsProcess`, `AlternateReqIEP`);
this function harmonizes them to the redesigned names and uppercases the
subject label. The COVID-era executive-order waiver column present in
the 2020 and 2021 sheets is not part of the four-pathway schema and is
dropped.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level graduation pathways
gp <- fetch_spr_grad_pathways(2025)

# The same pathway mix back to SY2017-18
gp_2018 <- fetch_spr_grad_pathways(2018)

# Statewide ELA pathway mix
library(dplyr)
fetch_spr_grad_pathways(2025, level = "district") %>%
  filter(is_state, subject == "ELA") %>%
  select(statewide_assessment, substitute_competency_test,
         portfolio_appeals, alternate_requirements_in_iep)

# Schools leaning hardest on portfolio appeals for Math
fetch_spr_grad_pathways(2025) %>%
  filter(is_school, subject == "Math") %>%
  slice_max(portfolio_appeals, n = 10) %>%
  select(district_name, school_name, portfolio_appeals)
} # }
```
