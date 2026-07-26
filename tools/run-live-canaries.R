#!/usr/bin/env Rscript

if (!identical(tolower(Sys.getenv("NJSCHOOLDATA_LIVE_TESTS")), "true")) {
  stop("Live canaries require NJSCHOOLDATA_LIVE_TESTS=true.", call. = FALSE)
}

suppressPackageStartupMessages(library(njschooldata))

canaries <- list(
  enrollment_current = function() njschooldata:::get_raw_enr_result(2026),
  enrollment_historical = function() njschooldata:::get_raw_enr_result(2020),
  assessment_current = function() njschooldata:::get_raw_sla_result(2025, 4, "ela"),
  assessment_historical = function() njschooldata:::get_raw_parcc_result(2018, 4, "ela"),
  graduation_current = function() njschooldata:::get_raw_grad_file_result(2025, "4 year"),
  graduation_historical = function() njschooldata:::get_raw_grad_file_result(2012, "4 year"),
  spr_current = function() njschooldata:::spr_cached_workbook_result(2025, "district"),
  finance_spending = function() njschooldata:::get_raw_tges_result(2025),
  finance_revenue = function() njschooldata:::get_finance_revenue_result(2026)
)

contract_check <- function(name, result) {
  data <- njschooldata:::source_result_data(result)
  if (grepl("enrollment", name) && (!is.data.frame(data) || nrow(data) == 0)) {
    stop("Enrollment parser returned no rows.")
  }
  if (grepl("assessment", name) &&
      !all(c("County Code", "District Code", "Subgroup") %in% names(data))) {
    stop("Assessment parser returned an unexpected schema.")
  }
  if (grepl("graduation", name) && (!is.data.frame(data) || nrow(data) == 0)) {
    stop("Graduation parser returned no rows.")
  }
  if (name == "spr_current" &&
      !"ChronicAbsenteeismStudentGroup" %in% readxl::excel_sheets(data)) {
    stop("SPR workbook is valid but the representative sheet is absent.")
  }
  if (name == "finance_spending" && !length(data)) {
    stop("TGES parser returned no tables.")
  }
  if (name == "finance_revenue" && (!is.data.frame(data) || nrow(data) == 0)) {
    stop("State-aid parser returned no expected revenue rows.")
  }
  TRUE
}

records <- lapply(names(canaries), function(name) {
  result <- tryCatch(canaries[[name]](), error = identity)
  if (inherits(result, "error")) {
    classification <- if (inherits(result, "njsd_source_unavailable")) {
      "SOURCE_OUTAGE"
    } else {
      "PARSER_OR_CONTRACT_REGRESSION"
    }
    return(data.frame(
      canary = name, source_status = NA_character_, source_url = NA_character_,
      classification = classification, error = conditionMessage(result)
    ))
  }

  contract_error <- NA_character_
  classification <- if (result$source_status == "source_unavailable") {
    "SOURCE_OUTAGE"
  } else if (result$source_status != "actual") {
    "PARSER_OR_CONTRACT_REGRESSION"
  } else {
    check <- tryCatch(contract_check(name, result), error = identity)
    if (inherits(check, "error")) {
      contract_error <- conditionMessage(check)
      "PARSER_OR_CONTRACT_REGRESSION"
    } else {
      "PASS"
    }
  }
  error <- if (classification == "PASS") {
    NA_character_
  } else if (!is.na(contract_error)) {
    contract_error
  } else if (!is.na(result$error)) {
    result$error
  } else {
    paste("Unexpected source status:", result$source_status)
  }
  data.frame(
    canary = name,
    source_status = result$source_status,
    source_url = result$source_url,
    classification = classification,
    error = error
  )
})

report <- do.call(rbind, records)
jsonlite::write_json(
  report, "live-canary-report.json", pretty = TRUE, dataframe = "rows",
  na = "null"
)
print(report, row.names = FALSE)

if (any(report$classification == "SOURCE_OUTAGE")) {
  message("SOURCE_OUTAGE: one or more NJ DOE artifacts could not be retrieved.")
}
if (any(report$classification == "PARSER_OR_CONTRACT_REGRESSION")) {
  message("PARSER_OR_CONTRACT_REGRESSION: a retrieved artifact failed validation or contract checks.")
}
if (any(report$classification != "PASS")) quit(status = 1L)
