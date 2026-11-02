# Frozen NJDOE sources retrieved 2026-11-01. The SPR source is labeled
# School Year 2024-25 (released May 21, 2026). It includes 2020-21 to 2024-25
# enrollment trends and 2024-25 accountability based on 2023-24 cohort data.
# https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
# https://www.nj.gov/education/spr/resources/doc/SPR_ReferenceGuide.pdf
# Text projections retain every source row, without entity filtering.

.nj_landing_artifact <- function(id) {
  manifest <- system.file("extdata", "source-contract", "contracts",
                          "new_jersey_shipped_sources", "artifact-manifest.json",
                          package = "njschooldata")
  artifacts <- jsonlite::read_json(manifest)$artifacts
  hit <- Filter(function(a) identical(a$artifact_id, id), artifacts)
  if (length(hit) != 1L) stop("Missing or ambiguous bundled artifact: ", id,
                             call. = FALSE)
  a <- hit[[1L]]
  path <- system.file(sub("^inst/", "", a$storage$path), package = "njschooldata")
  if (!nzchar(path) || !file.exists(path) ||
      file.info(path)$size != a$byte_length ||
      !identical(.source_digest(path), a$sha256)) {
    stop("Bundled artifact length or SHA-256 mismatch: ", id, call. = FALSE)
  }
  list(path = path, url = a$source_identity$url)
}

.nj_landing_year <- function(end_year, years, family) {
  if (!is.numeric(end_year) || length(end_year) != 1L || is.na(end_year) ||
      !end_year %in% years) {
    stop(family, ": published bundled end_year values are ",
         paste(years, collapse = ", "), ". See inst/registry/gaps.csv.", call. = FALSE)
  }
}

.nj_landing_spr_extract <- function(sheet, end_year) {
  .nj_landing_artifact("spr-reference-guide")
  a <- .nj_landing_artifact(paste0("spr-school-", end_year, "-", sheet))
  x <- readr::read_csv(a$path, col_types = readr::cols(.default = "c"),
                        na = "", trim_ws = FALSE, show_col_types = FALSE,
                        progress = FALSE, name_repair = "minimal")
  # readxl's original text reader trims surrounding whitespace. The extract
  # itself preserves it, along with published suppression and rounding text.
  x[] <- lapply(x, trimws)
  attr(x, "source_file") <- a$url
  x
}

.nj_landing_spr <- function(sheet) {
  x <- .nj_landing_spr_extract(sheet, 2025L)
  source <- attr(x, "source_file")
  x <- x[!is.na(x$DistrictCode) & !is.na(x$SchoolCode), , drop = FALSE]
  attr(x, "source_file") <- source
  x
}

# Keep rates and intervals separate. Non-numeric text is never a point estimate.
.nj_landing_percent <- function(x) {
  raw <- trimws(sub("%$", "", x))
  point <- !is.na(raw) & grepl("^[0-9]+(\\.[0-9]+)?$", raw)
  value <- rep(NA_real_, length(x))
  value[point] <- as.numeric(raw[point])
  value[value > 100 | value < 0] <- NA_real_
  digits <- ifelse(grepl("\\.", raw), nchar(sub("^.*\\.", "", raw)), 0L)
  half <- 0.5 * 10^(-digits)
  lo <- pmax(0, value - half)
  hi <- pmin(100, value + half)
  range <- !is.na(raw) & grepl("^[0-9]+(\\.[0-9]+)?-[0-9]+(\\.[0-9]+)?$", raw)
  lo[range] <- as.numeric(sub("-.*$", "", raw[range]))
  hi[range] <- as.numeric(sub("^.*-", "", raw[range]))
  upper <- !is.na(raw) & grepl("^<=?[0-9]+(\\.[0-9]+)?$", raw)
  lo[upper] <- 0
  hi[upper] <- as.numeric(sub("^<=?", "", raw[upper]))
  bad <- !is.na(lo) & (lo < 0 | hi > 100 | lo > hi)
  lo[bad] <- hi[bad] <- NA_real_
  list(value = value, lo = lo, hi = hi)
}

.nj_share_school_spr <- function(end_year) {
  .nj_landing_year(end_year, 2023:2025, "school_spr")
  x <- .nj_landing_spr("EnrollmentTrendsByStudentGroup")
  source <- attr(x, "source_file")
  label <- sprintf("%d-%02d", end_year - 1L, end_year %% 100L)
  x <- x[x$SchoolYear == label, , drop = FALSE]
  grades <- .nj_landing_spr("EnrollmentTrendsbyGrade")
  grades <- grades[grades$SchoolYear == label, , drop = FALSE]
  key <- function(d) paste(d$CountyCode, d$DistrictCode, d$SchoolCode, sep = "|")
  if (anyDuplicated(key(grades))) stop("Duplicate SPR enrollment keys.")
  grades <- grades[match(key(x), key(grades)), , drop = FALSE]
  rates <- .nj_landing_percent(x[["Students with Disabilities"]])
  out <- .nj_share_frame(nrow(x))
  out$end_year <- as.integer(end_year)
  out$entity_level <- "school"
  out$district_id <- x$DistrictCode
  out$district_name <- x$DistrictName
  out$school_id <- x$SchoolCode
  out$school_name <- x$SchoolName
  out$grade_band <- "all"
  grade_cols <- c("GradePK", "GradeKG", sprintf("Grade%02d", 1:12))
  grade_labels <- c("PK", "K", sprintf("%02d", 1:12))
  enrolled <- as.matrix(as.data.frame(lapply(grades[grade_cols], as.numeric)))
  span <- function(r, first) {
    present <- which(!is.na(r) & r > 0)
    if (!length(present)) return(NA_character_)
    grade_labels[if (first) present[1L] else tail(present, 1L)]
  }
  out$grade_low <- apply(enrolled, 1, span, first = TRUE)
  out$grade_high <- apply(enrolled, 1, span, first = FALSE)
  out$n_enrolled <- suppressWarnings(as.numeric(grades$Total))
  out$pct_sped <- rates$value
  out$pct_sped_lo <- rates$lo
  out$pct_sped_hi <- rates$hi
  out$is_charter <- is_charter_district(x$CountyCode)
  out$construct <- "students with disabilities, percent of enrollment"
  out$count_date <- paste("End-of-year enrollment", label)
  out$source_file <- source
  out$source_value <- x[["Students with Disabilities"]]
  out$school_year <- x$SchoolYear
  out
}
