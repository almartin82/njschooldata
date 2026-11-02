# Rebuild text-only SPR projections without evaluating formulas or filtering rows.
# Rscript data-raw/build_nj_spr.R workbook-2024.xlsx workbook-2025.xlsx [repo-root]
build_nj_spr <- function(workbook_2024, workbook_2025, root = ".") {
  manifest_path <- file.path(root, "inst/extdata/source-contract/contracts",
                             "new_jersey_shipped_sources/artifact-manifest.json")
  manifest <- jsonlite::read_json(manifest_path)
  ids <- c("DistrictCode", "DistrictName", "SchoolCode", "SchoolName")
  sheets <- list(
    `2024` = list(
      EnrollmentTrendsByStudentGroup = c("CountyCode", ids, "Students with Disabilities"),
      `6YrGraduationCohortProfile` = c(ids, "StudentGroup", "HighSchoolPersistance")),
    `2025` = list(
      EnrollmentTrendsByStudentGroup = c("CountyCode", ids, "SchoolYear", "Students with Disabilities"),
      EnrollmentTrendsbyGrade = c("CountyCode", "DistrictCode", "SchoolCode", "SchoolYear",
                                 "GradePK", "GradeKG", sprintf("Grade%02d", 1:12), "Total"),
      GraduationCohortProfile = c(ids, "StudentGroup", "CohortType", "Persisting_School"),
      HSPersistenceTargets = c(ids, "Indicator", "StudentGroup", "IndicatorPerformance")))
  artifacts <- manifest$artifacts
  extracts <- list()
  for (year in names(sheets)) {
    parent_id <- paste0("spr-school-", year)
    old <- Filter(function(a) identical(a$artifact_id, parent_id), artifacts)
    prior <- Filter(function(a) identical(a$lineage$parent_artifact_id, parent_id), artifacts)
    parent <- if (length(old)) old[[1L]] else prior[[1L]]$lineage$parent_workbook
    path <- if (year == "2024") workbook_2024 else workbook_2025
    stopifnot(file.info(path)$size == parent$byte_length,
              identical(digest::digest(file = path, algo = "sha256"), parent$sha256))
    for (sheet in names(sheets[[year]])) {
      x <- readxl::read_excel(path, sheet = sheet, skip = if (year == "2025") 3 else 0,
                              col_types = "text", na = "", trim_ws = FALSE)
      x <- x[sheets[[year]][[sheet]]]
      id <- paste(parent_id, sheet, sep = "-")
      relative <- paste0("inst/extdata/program-sources/", id, ".csv.gz")
      output <- file.path(root, relative)
      readr::write_csv(x, output, na = "")
      stopifnot(file.info(output)$size < 10000000)
      extracts[[length(extracts) + 1L]] <- list(
        artifact_id = id, source_identity = parent$source_identity, tier = "shipped",
        byte_length = unname(file.info(output)$size),
        sha256 = digest::digest(file = output, algo = "sha256"),
        selectors = list(family = "spr", key = year), storage = list(path = relative),
        lineage = list(kind = "derived", parent_artifact_id = parent_id,
          parent_source_identity = parent$source_identity,
          parent_workbook = list(source_identity = parent$source_identity,
                                 byte_length = parent$byte_length, sha256 = parent$sha256),
          recipe = "data-raw/build_nj_spr.R", recipe_version = "1", sheet = sheet,
          table_locator = paste0(sheet, "; all data rows; columns: ", paste(names(x), collapse = ", ")),
          skip = if (year == "2025") 3L else 0L, columns = names(x), row_count = nrow(x)))
      cat(id, nrow(x), "rows,", file.info(output)$size, "bytes\n")
    }
  }
  manifest$artifacts <- c(Filter(function(a) !grepl("^spr-school-", a$artifact_id), artifacts), extracts)
  jsonlite::write_json(manifest, manifest_path, pretty = TRUE, auto_unbox = TRUE)
  contract_path <- file.path(dirname(manifest_path), "contract.json")
  contract <- jsonlite::read_json(contract_path)
  contract$required_artifacts <- lapply(manifest$artifacts, function(a)
    list(artifact_id = a$artifact_id, selectors = a$selectors))
  jsonlite::write_json(contract, contract_path, pretty = TRUE, auto_unbox = TRUE)
  spec <- file.path(root, "data-raw/source-validation-spec/new_jersey_shipped_sources")
  file.copy(c(manifest_path, contract_path), spec, overwrite = TRUE)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (!length(args) %in% 2:3) stop("Expected workbook-2024, workbook-2025 and optional repo-root")
  do.call(build_nj_spr, as.list(args))
}
