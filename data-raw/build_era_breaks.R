era_breaks <- tibble::tibble(
  break_set = c(
    "njsla",
    "njsla",
    "njsla",
    "njsla",
    "njsla",
    "grad",
    "grad",
    "grad",
    "attendance",
    "attendance",
    "econ_disadv"
  ),
  break_year = c(
    2015L,
    2019L,
    2020L,
    2021L,
    2022L,
    2020L,
    2021L,
    2022L,
    2020L,
    2021L,
    2025L
  ),
  break_type = c(
    "scale_break",
    "definition_change",
    "covid_gap",
    "covid_gap",
    "definition_change",
    "covid_gap",
    "definition_change",
    "definition_change",
    "covid_gap",
    "covid_gap",
    "definition_change"
  ),
  label = c(
    "NJASK/HSPA to PARCC",
    "PARCC to NJSLA",
    "COVID assessment cancellation",
    "COVID assessment cancellation",
    "NJSLA resumption after COVID gaps",
    "Class of 2020 graduation assessment waiver",
    "Federal graduation rate reporting split",
    "Federal graduation requirement exclusion expands",
    "COVID attendance disruption",
    "COVID attendance disruption",
    "Expanded meal eligibility and CEP reporting"
  ),
  comparable_prior = c(
    FALSE,
    FALSE,
    NA,
    NA,
    FALSE,
    NA,
    FALSE,
    FALSE,
    NA,
    NA,
    FALSE
  ),
  notes = c(
    "NJDOE testing history states that in 2014-15 PARCC electronic assessments replaced NJASK in grades 3-8 and HSPA in high school; the assessment scale and administration changed, so prior NJASK/HSPA values are not comparable.",
    "NJDOE spring 2019 assessment-format guidance states that ELA/math assessments would no longer be called PARCC and would be called NJSLA-ELA and NJSLA-M, with length/time and policy changes; segment PARCC-era and NJSLA-era trends.",
    "NJDOE's March 24, 2020 statewide-assessment cancellation memo states that spring 2020 NJSLA, ACCESS, and DLM were cancelled after a federal waiver because COVID-related closures made testing infeasible.",
    "NJDOE's April 2021 assessment update states that there would be no spring 2021 NJSLA administration and that Start Strong fall 2021 would satisfy the 2020-21 federal statewide assessment requirement.",
    "NJDOE 2021-22 School Performance Reports resumed NJSLA reporting after the 2019-20 and 2020-21 cancellations and recommended caution comparing pandemic-impacted years; treat post-resumption trends as a new definition era.",
    "NJDOE 2019-20 reports note that Executive Order 117 waived graduation assessment requirements for class of 2020 students who had not met them as of March 18, 2020; COVID also removed reporting on ESSA target status.",
    "NJDOE's 2020-21 School Performance Reports release states that graduation assessment requirements were waived for classes of 2020 and 2021 and that, beginning in 2021, NJDOE reported state and federal graduation-rate versions after federal review.",
    "NJDOE's 2021-22 School Performance Reports release states that graduation assessment requirements were back in place in 2022 and the federal rate excluded students with disabilities who did not meet course, attendance, or assessment requirements.",
    "NJDOE 2021-22 reports state that chronic absenteeism data is not available for 2019-20 and recommend caution comparing pandemic-impacted attendance years.",
    "NJDOE 2021-22 reports recommend caution comparing 2021-22 chronic absenteeism rates with 2020-21 and pre-2019-20 rates because the pandemic impacted attendance rates over the last three years.",
    "NJDA/NJDOE SY2024-25 meals guidance expanded New Jersey Expanded Income Eligibility from 199% to 224% of the federal poverty level, and NJDOE ASSA guidance required CEP schools to determine low-income status using the 2024-25 School Meals and Summer EBT application or direct certification."
  )
)

allowed_break_types <- c("scale_break", "covid_gap", "definition_change")
if (!all(era_breaks$break_type %in% allowed_break_types)) {
  stop("era_breaks contains an unsupported break_type.", call. = FALSE)
}

dir.create("data", showWarnings = FALSE)
save(era_breaks, file = "data/era_breaks.rda", compress = "xz")
