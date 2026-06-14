# ==============================================================================
# English Learner (EL) Population Data — raw extraction
# ==============================================================================
#
# Source: NJ DOE Fall Enrollment files (nj.gov/education/doedata/enr/).
# Every NJ enrollment workbook reports an English Learner / Multilingual Learner
# headcount alongside total enrollment. This module pulls the REAL published
# EL headcount — it deliberately does NOT reuse the derived EL value that
# `get_raw_enr()` computes for 2020+ (that pipeline overwrites the published
# count with `pct * total` for its demographic-share workflow).
#
# Data-integrity notes (verified against the published files, 2026-06):
#   * 2006-2019: a real `LEP` count column at state/district/school level.
#   * 2020-2022: a real statewide count on the State worksheet ("All Grades"
#     row), but district/school worksheets publish ONLY `%English Learners`
#     (no count). For those entity-years the count is left NA and the published
#     percent is carried through — the count is NEVER derived from the percent.
#   * 2023+: a real count at every level (column renamed "English Learners" ->
#     "Multilingual Learners" in the 2023-24 file).
#   * NJ does not suppress EL counts; fractional values (e.g. 0.5) are real
#     shared-time / vocational FTE, preserved exactly as published.
# ==============================================================================

#' Build the NJ DOE Fall Enrollment workbook URL for a year
#'
#' @param end_year ending academic year
#' @return character URL of the enrollment zip (first capitalization that
#'   resolves)
#' @keywords internal
ell_enr_zip_url <- function(end_year) {
  yy <- substr(end_year, 3, 4)
  prev_yy <- substr(end_year - 1, 3, 4)
  base_url <- paste0(
    "https://www.nj.gov/education/doedata/enr/enr", yy, "/"
  )
  candidates <- paste0(
    base_url, c("enrollment_", "Enrollment_"), prev_yy, yy, ".zip"
  )
  for (candidate in candidates) {
    if (check_url_accessible(candidate)) {
      return(candidate)
    }
  }
  candidates[1]
}

#' Download and unzip the NJ enrollment workbook, return the .xlsx path
#'
#' @param end_year ending academic year (>= 2020, the multi-sheet xlsx era)
#' @return character path to the unzipped .xlsx
#' @keywords internal
ell_download_xlsx <- function(end_year) {
  url <- ell_enr_zip_url(end_year)
  tname <- tempfile(pattern = "ell_enr", tmpdir = tempdir(), fileext = ".zip")
  tdir <- tempfile(pattern = "ell_dir")
  dir.create(tdir)
  downloader::download(url, dest = tname, mode = "wb")
  utils::unzip(tname, exdir = tdir)
  files <- list.files(tdir, pattern = "\\.xlsx?$", full.names = TRUE)
  if (length(files) == 0) {
    stop("No Excel file found in enrollment archive for ", end_year)
  }
  files[1]
}

#' Locate the EL count and EL percent columns on a raw enrollment sheet
#'
#' Handles the "English Learners" -> "Multilingual Learners" rename and the
#' "%X" / "% X" percent-column spacing drift.
#'
#' @param nm character vector of column names
#' @return list(count = <name or NA>, pct = <name or NA>)
#' @keywords internal
ell_locate_cols <- function(nm) {
  is_el <- grepl("english learner|multilingual learner", nm, ignore.case = TRUE)
  is_pct <- grepl("%", nm)
  count_col <- nm[is_el & !is_pct]
  pct_col <- nm[is_el & is_pct]
  list(
    count = if (length(count_col) > 0) count_col[1] else NA_character_,
    pct = if (length(pct_col) > 0) pct_col[1] else NA_character_
  )
}

#' Read EL headcount + percent from the District / School worksheets
#'
#' @param xlsx path to the enrollment workbook
#' @param end_year ending academic year
#' @return data.frame: cds_code, el_count, el_pct (one row per entity; count is
#'   NA where the worksheet publishes only a percent)
#' @keywords internal
ell_read_modern_entities <- function(xlsx, end_year) {
  read_level <- function(sheet, has_school) {
    df <- as.data.frame(
      readxl::read_excel(xlsx, sheet = sheet, skip = 2),
      check.names = FALSE
    )
    names(df) <- trimws(names(df))
    cols <- ell_locate_cols(names(df))

    county <- stringr::str_pad(as.character(df[["County Code"]]), 2, "left", "0")
    district <- stringr::str_pad(as.character(df[["District Code"]]), 4, "left", "0")
    school <- if (has_school) {
      stringr::str_pad(as.character(df[["School Code"]]), 3, "left", "0")
    } else {
      rep("999", nrow(df))
    }

    el_count <- if (!is.na(cols$count)) {
      suppressWarnings(as.numeric(df[[cols$count]]))
    } else {
      rep(NA_real_, nrow(df))
    }
    el_pct <- if (!is.na(cols$pct)) {
      suppressWarnings(as.numeric(df[[cols$pct]]))
    } else {
      rep(NA_real_, nrow(df))
    }

    out <- data.frame(
      cds_code = paste0(county, district, school),
      el_count = el_count,
      el_pct = el_pct,
      stringsAsFactors = FALSE
    )
    out[!is.na(out$cds_code) & !grepl("NA", out$cds_code), ]
  }

  dist <- read_level("District", has_school = FALSE)
  sch <- read_level("School", has_school = TRUE)
  rbind(dist, sch)
}

#' Read the statewide EL headcount + percent from the State worksheet
#'
#' The State worksheet lists EL by grade; the "All Grades" row is the published
#' statewide total. Available as a real count for every year 2020+.
#'
#' @param xlsx path to the enrollment workbook
#' @param end_year ending academic year
#' @return list(el_count, el_pct)
#' @keywords internal
ell_read_modern_state <- function(xlsx, end_year) {
  # NJ DOE shipped the 2019-20 State sheet with a trailing space in its name.
  sheets <- readxl::excel_sheets(xlsx)
  state_sheet <- sheets[trimws(sheets) == "State"][1]
  df <- as.data.frame(
    readxl::read_excel(xlsx, sheet = state_sheet, skip = 2),
    check.names = FALSE
  )
  names(df) <- trimws(names(df))
  grade_col <- names(df)[grepl("grade", names(df), ignore.case = TRUE)][1]
  cols <- ell_locate_cols(names(df))

  total_row <- which(tolower(trimws(df[[grade_col]])) == "all grades")
  if (length(total_row) == 0) {
    # Fall back to summing the per-grade rows (drops sentinel/total artifacts).
    if (!is.na(cols$count)) {
      vals <- suppressWarnings(as.numeric(df[[cols$count]]))
      return(list(el_count = sum(vals, na.rm = TRUE), el_pct = NA_real_))
    }
    return(list(el_count = NA_real_, el_pct = NA_real_))
  }
  total_row <- total_row[1]
  list(
    el_count = if (!is.na(cols$count)) {
      suppressWarnings(as.numeric(df[[cols$count]][total_row]))
    } else {
      NA_real_
    },
    el_pct = if (!is.na(cols$pct)) {
      suppressWarnings(as.numeric(df[[cols$pct]][total_row]))
    } else {
      NA_real_
    }
  )
}

#' Get raw English Learner population data for one year
#'
#' Returns one row per entity (state, district, school) carrying the published
#' EL headcount and total enrollment. The entity scaffold (ids, names, CDS code,
#' NCES ids, total enrollment) is taken from `fetch_enr()`; the EL headcount is
#' read directly from the published source so 2020+ years keep the real count
#' rather than the derived value `get_raw_enr()` computes.
#'
#' @param end_year ending academic year. Valid values: 2006-2026.
#' @return data.frame with entity identifiers, `total_enrollment`, `el_count`
#'   (NA where only a percent is published), and `el_pct`.
#' @keywords internal
get_raw_ell <- function(end_year) {
  if (!end_year %in% ELL_VALID_YEARS) {
    stop(
      "EL population data is only available for ",
      min(ELL_VALID_YEARS), "-", max(ELL_VALID_YEARS),
      " (requested ", end_year, ")."
    )
  }

  # Entity scaffold: the all-students total row per entity (program code 55)
  # carries real ids, names, CDS code, NCES ids, and total enrollment.
  enr <- fetch_enr(end_year)
  scaffold <- enr %>%
    dplyr::filter(.data$program_code == "55") %>%
    dplyr::select(
      dplyr::any_of(c(
        "end_year", "cds_code",
        "county_id", "county_name",
        "district_id", "district_name",
        "school_id", "school_name",
        "nces_dist", "nces_sch"
      )),
      total_enrollment = "row_total",
      lep_enr = dplyr::any_of("lep")
    )

  if (end_year <= 2019) {
    # The enrollment `lep` column IS the published headcount for these years.
    scaffold$el_count <- scaffold$lep_enr
    scaffold$el_pct <- NA_real_
  } else {
    xlsx <- ell_download_xlsx(end_year)
    ent_el <- ell_read_modern_entities(xlsx, end_year)
    st_el <- ell_read_modern_state(xlsx, end_year)

    # de-dup the entity EL table on cds (defensive against repeated rows)
    ent_el <- ent_el[!duplicated(ent_el$cds_code), ]

    scaffold <- scaffold %>%
      dplyr::left_join(ent_el, by = "cds_code")

    # state total comes from the State worksheet "All Grades" row
    is_state_row <- scaffold$district_id == "9999" & scaffold$county_id == "99"
    scaffold$el_count[is_state_row] <- st_el$el_count
    scaffold$el_pct[is_state_row] <- st_el$el_pct
  }

  scaffold$lep_enr <- NULL
  scaffold$end_year <- end_year
  scaffold
}
