#!/usr/bin/env Rscript

# Generate the Python/R compatibility contract from the authoritative R API.
# Run from the repository root after changing package formals, versions, or the
# source registry.

devtools::load_all(quiet = TRUE)

curated <- c(
  "fetch_enr", "fetch_parcc", "fetch_access", "fetch_grad_rate",
  "get_school_directory", "get_district_directory", "fetch_facilities",
  "fetch_facilities_multi", "fetch_facility_gis",
  "get_available_facilities", "fetch_finance", "fetch_finance_multi",
  "fetch_sped", "fetch_sped_placement", "fetch_sped_placement_multi",
  "fetch_ell", "fetch_ell_multi"
)

format_default <- function(value) {
  if (identical(value, quote(expr = ))) return("<required>")
  paste(deparse(value, width.cutoff = 500L), collapse = " ")
}

r_signatures <- setNames(lapply(curated, function(name) {
  fmls <- formals(get(name, envir = asNamespace("njschooldata")))
  list(
    parameters = names(fmls) %||% character(),
    defaults = setNames(lapply(fmls, format_default), names(fmls))
  )
}), curated)

registry <- njschooldata:::get_source_registry()
coverage <- lapply(registry, function(entry) {
  list(
    aliases = unname(entry$aliases),
    raw_years = unname(as.integer(entry$raw_years)),
    tidy_years = unname(as.integer(entry$tidy_years)),
    skipped_years = unname(as.integer(entry$skipped_years))
  )
})

r_version <- as.character(utils::packageDescription("njschooldata")$Version)
parts <- as.integer(strsplit(r_version, "\\.", fixed = FALSE)[[1]])
next_minor <- paste(parts[[1]], parts[[2]] + 1L, 0L, sep = ".")

contract <- list(
  python_package_version = r_version,
  r_package_min_version = r_version,
  r_package_max_version = next_minor,
  r_signatures = r_signatures,
  source_coverage = coverage
)

json <- jsonlite::toJSON(
  contract,
  auto_unbox = TRUE,
  pretty = TRUE,
  null = "null",
  na = "null"
)

generated <- c(
  '"""Generated from the R package. Do not edit by hand."""',
  "",
  "import json",
  "",
  "_CONTRACT = json.loads(r'''",
  json,
  "''')",
  "",
  'PYTHON_PACKAGE_VERSION = _CONTRACT["python_package_version"]',
  'R_PACKAGE_MIN_VERSION = _CONTRACT["r_package_min_version"]',
  'R_PACKAGE_MAX_VERSION = _CONTRACT["r_package_max_version"]',
  'R_SIGNATURES = _CONTRACT["r_signatures"]',
  'SOURCE_COVERAGE = _CONTRACT["source_coverage"]'
)
writeLines(generated, "python/src/njschooldata/_generated_contract.py")

year_range <- function(years) {
  if (!length(years)) return("current source")
  if (identical(years, seq.int(min(years), max(years)))) {
    return(paste0(min(years), "-", max(years)))
  }
  paste(years, collapse = ", ")
}

coverage_families <- c(
  enrollment = "Enrollment",
  parcc = "PARCC/NJSLA",
  access = "ACCESS for ELLs",
  grate_4yr = "Four-year graduation",
  grad_count = "Graduation counts",
  ell = "English Learner population",
  sped = "Special education classification",
  sped_placement = "Special education placement",
  tges = "TGES spending",
  state_aid = "State aid",
  finance = "Canonical finance"
)

coverage_rows <- c(
  "<!-- BEGIN GENERATED COVERAGE -->",
  "| Data family | Tidy years | Raw years | Deliberate gaps |",
  "|---|---:|---:|---|",
  vapply(names(coverage_families), function(family) {
    entry <- registry[[family]]
    gaps <- if (length(entry$skipped_years)) {
      paste(entry$skipped_years, collapse = ", ")
    } else {
      "None"
    }
    sprintf(
      "| %s | %s | %s | %s |",
      coverage_families[[family]], year_range(entry$tidy_years),
      year_range(entry$raw_years), gaps
    )
  }, character(1)),
  "<!-- END GENERATED COVERAGE -->"
)

readme_path <- "python/README.md"
readme <- readLines(readme_path, warn = FALSE)
begin <- match("<!-- BEGIN GENERATED COVERAGE -->", readme)
end <- match("<!-- END GENERATED COVERAGE -->", readme)
if (is.na(begin) || is.na(end) || end < begin) {
  stop("python/README.md is missing generated coverage markers.")
}
readme <- c(readme[seq_len(begin - 1L)], coverage_rows, readme[-seq_len(end)])
writeLines(readme, readme_path)
