# ==============================================================================
# Restraint & Seclusion (DARS standalone workbooks) - school-level
# ==============================================================================
#
# School-level counts of physical/mechanical restraint and seclusion events,
# published by the NJ DOE in standalone Discipline & Restraint (DARS) Excel
# workbooks - separate from the violence/vandalism/HIB SPR data the package
# already pulls. NJ's Student Safety Data System (SSDS) groups these events into
# three categories: restraint (physical and/or mechanical), seclusion, and
# occasions where both a restraint and a seclusion occurred together.
#
# The DARS workbook is SCHOOL-LEVEL ONLY: there are no state/district/county
# aggregate rows (county codes run 01, 03, 05, ...; there is no "9999"/"State"
# row), and the per-school rows are crossed by student group (schoolwide, race,
# gender, economically disadvantaged, students with disabilities, and grade).
#
# Suppression: small cells are masked. "*" hides a value entirely; "<5" is a
# published RANGE for 1-4 students. BOTH become NA - never a guessed number, and
# never the literal 5 extracted from "<5".
#
# ==============================================================================


# Source workbooks (verified NJ DOE DARS downloads; static yearly snapshots).
.restraint_seclusion_urls <- c(
  "2023" = paste0(
    "https://www.nj.gov/education/vandv/annualreport/dars/",
    "2022_23RestraintAndSeclusionSchoolLevelDatabase.xlsx"
  ),
  "2024" = paste0(
    "https://www.nj.gov/education/vandv/annualreport/dars/",
    "2023_24RestraintAndSeclusionSchoolLevelDatabasePublic.xlsx"
  )
)

# The 20 value columns (count, percent pairs) in published sheet order. The
# DARS sheet ships them as "<Category> Count" / "<Category> Percent" pairs.
.restraint_seclusion_value_cols <- c(
  "any_restraint_seclusion_count", "any_restraint_seclusion_pct",
  "restraint_count", "restraint_pct",
  "restraint_physical_count", "restraint_physical_pct",
  "restraint_mechanical_count", "restraint_mechanical_pct",
  "restraint_both_phys_mech_count", "restraint_both_phys_mech_pct",
  "seclusion_count", "seclusion_pct",
  "both_restraint_seclusion_count", "both_restraint_seclusion_pct",
  "both_physical_restraint_count", "both_physical_restraint_pct",
  "both_mechanical_restraint_count", "both_mechanical_restraint_pct",
  "both_phys_mech_restraint_count", "both_phys_mech_restraint_pct"
)


# -----------------------------------------------------------------------------
# Suppression-safe numeric coercion
# -----------------------------------------------------------------------------

#' Coerce a masked DARS value to numeric, with "<5"/"*" -> NA
#'
#' The DARS workbooks mask small cells two ways: \code{"*"} hides a value
#' entirely, and \code{"<5"} (or \code{"<5.00"}, more generally \code{"<N"}) is a
#' published RANGE standing in for 1-4 students. Both must become \code{NA} - an
#' honest gap, never a guessed number. In particular this coercion must NEVER
#' turn \code{"<5"} into the literal \code{5}: any token beginning with
#' \code{"<"} (or equal to \code{"*"}) maps to \code{NA} BEFORE numeric parsing,
#' so no digit is ever extracted from a range string. A real published
#' \code{0} stays \code{0}.
#'
#' @param x A character (or already-numeric) vector from a DARS count/percent
#'   column.
#' @return A numeric vector with masked/suppressed cells as \code{NA}.
#' @keywords internal
rs_value_numeric <- function(x) {
  if (is.numeric(x)) return(x)
  x <- trimws(as.character(x))
  x <- gsub(",", "", x, fixed = TRUE)
  # Masking / suppression tokens -> NA, evaluated BEFORE numeric parsing so a
  # range like "<5" never yields the digit 5.
  x[x == ""] <- NA_character_
  x[x == "*"] <- NA_character_
  x[grepl("^<", x)] <- NA_character_   # "<5", "<5.00", "<N"
  suppressWarnings(as.numeric(x))
}


# -----------------------------------------------------------------------------
# Student-group / grade split
# -----------------------------------------------------------------------------

#' Split a DARS "Student Group" label into normalized subgroup + grade_level
#'
#' The DARS \code{Student Group} column mixes three kinds of label in one
#' column: the schoolwide total (\code{"Schoolwide"} in 2022-23,
#' \code{"School Total"} in 2023-24), demographic subgroups (race, gender,
#' economically disadvantaged, students with disabilities), and grade levels
#' (\code{"Grade Preschool"}, \code{"Grade Kindergarten"}, \code{"Grade 1"} ..
#' \code{"Grade 12"}). This helper splits each label into a project-standard
#' \code{subgroup} + \code{grade_level} pair so the two dimensions can be
#' filtered independently.
#'
#' Grade rows get \code{subgroup = "total population"} and a project-standard
#' grade label (\code{"PK"}, \code{"K"}, \code{"01"-"12"}); subgroup and
#' schoolwide rows get \code{grade_level = "TOTAL"}. The mapping is a
#' deterministic re-expression of the published labels, not an inference. (The
#' shared \code{spr_split_student_group_grade()} helper does not handle the exact
#' DARS labels - the hyphen in \code{"Black or African-American"}, the spelled-out
#' \code{"Grade Preschool"}/\code{"Grade Kindergarten"}, or the 2023-24
#' \code{"School Total"} total label - so DARS does the split locally.)
#'
#' @param label Character vector of raw \code{Student Group} labels.
#' @return A data frame with two columns: \code{subgroup} and \code{grade_level}.
#' @keywords internal
rs_split_student_group <- function(label) {
  raw <- as.character(label)
  is_grade <- !is.na(raw) & grepl("^Grade ", raw)
  grade_token <- ifelse(is_grade, sub("^Grade\\s+", "", raw), NA_character_)
  grade_norm <- dplyr::case_when(
    is.na(grade_token) ~ NA_character_,
    toupper(grade_token) %in% c("PRESCHOOL", "PK", "PRE-K", "PREK") ~ "PK",
    toupper(grade_token) %in% c("KINDERGARTEN", "K", "KG", "KF", "KH") ~ "K",
    suppressWarnings(!is.na(as.integer(grade_token))) ~
      sprintf("%02d", suppressWarnings(as.integer(grade_token))),
    TRUE ~ toupper(grade_token)
  )

  lc <- tolower(trimws(raw))
  subgroup_norm <- dplyr::case_when(
    is_grade ~ "total population",
    lc %in% c("schoolwide", "school total") ~ "total population",
    lc == "american indian or alaska native" ~ "american indian",
    lc == "asian" ~ "asian",
    lc == "black or african-american" ~ "black",
    lc == "hispanic" ~ "hispanic",
    lc == "pacific islander" ~ "pacific islander",
    lc == "two or more races" ~ "multiracial",
    lc == "white" ~ "white",
    lc == "female" ~ "female",
    lc == "male" ~ "male",
    lc == "non-binary/ undesignated gender" ~ "non-binary",
    lc == "economically disadvantaged" ~ "economically disadvantaged",
    lc == "students with disabilities" ~ "students with disabilities",
    TRUE ~ lc
  )

  data.frame(
    subgroup = subgroup_norm,
    grade_level = ifelse(is_grade, grade_norm, "TOTAL"),
    stringsAsFactors = FALSE
  )
}


# -----------------------------------------------------------------------------
# Raw download + parse
# -----------------------------------------------------------------------------

#' Download and read the raw DARS Restraint & Seclusion workbook
#'
#' Downloads the standalone NJ DOE DARS school-level Restraint & Seclusion Excel
#' workbook for \code{end_year}, validates it is a real \code{.xlsx} (ZIP magic
#' bytes; see \code{\link{is_valid_xlsx}}) so an HTTP error or bot page is never
#' parsed as data, and reads the \code{Restraints and Seclusions} sheet. That is
#' the second sheet (the first is \code{Introduction}); its real header is row 12
#' (\code{skip = 11} - row 11 is a masking-rule note that bleeds into the first
#' column).
#'
#' @param end_year 2023 (SY2022-23) or 2024 (SY2023-24). Other years error.
#' @return The raw 27-column data frame, exactly as published (count/percent
#'   columns still carry the \code{"*"} / \code{"<5"} masking tokens).
#' @keywords internal
get_raw_restraint_seclusion <- function(end_year) {
  if (!end_year %in% c(2023, 2024)) {
    stop(
      "restraint & seclusion data is available for end_year 2023 (SY2022-23) ",
      "and 2024 (SY2023-24) only.",
      call. = FALSE
    )
  }

  url <- .restraint_seclusion_urls[[as.character(end_year)]]
  dest <- tempfile(pattern = "dars_", fileext = ".xlsx")
  on.exit(unlink(dest), add = TRUE)
  downloader::download(url, destfile = dest, mode = "wb")

  if (!is_valid_xlsx(dest)) {
    stop(sprintf(
      paste0(
        "Downloaded restraint & seclusion workbook for %d is not a valid .xlsx ",
        "file -- the NJ DOE source may be unavailable or returned an error ",
        "page.\n  URL: %s"
      ),
      end_year, url
    ), call. = FALSE)
  }

  # The real header is row 12; skip the 11 preamble/notes rows.
  readxl::read_excel(
    path = dest,
    sheet = "Restraints and Seclusions",
    skip = 11,
    guess_max = 60000
  )
}


#' Tidy a raw DARS Restraint & Seclusion data frame
#'
#' Renames the seven identifier columns and the 20 count/percent columns to a
#' stable snake_case schema, cleans the CDS codes (leading zeros preserved),
#' drops the trailing sentinel row and the single blank \code{Student Group} row,
#' coerces every value column to numeric with masked cells (\code{"*"},
#' \code{"<5"}) mapped to \code{NA}, splits the student-group label into
#' \code{subgroup} + \code{grade_level}, and stamps the school-only entity flags.
#'
#' @param df A raw data frame from \code{\link{get_raw_restraint_seclusion}}.
#' @param end_year The school year end (added as a column).
#' @param with_status Logical. If \code{TRUE}, append \code{value_status}
#'   classified from the raw \code{any_restraint_seclusion_count} token before
#'   numeric coercion.
#' @return The tidy data frame in the documented output schema.
#' @keywords internal
tidy_restraint_seclusion <- function(df, end_year, with_status = FALSE) {
  if (ncol(df) != 27) {
    stop(sprintf(
      "Unexpected DARS layout for %d: %d columns (expected 27). The NJ DOE ",
      end_year, ncol(df)
    ), "source format may have changed.", call. = FALSE)
  }

  names(df) <- c(
    "county_id", "county_name", "district_id", "district_name",
    "school_id", "school_name", "student_group",
    .restraint_seclusion_value_cols
  )

  # CDS codes: clean Excel formula padding, keep as character (leading zeros).
  df$county_id <- kill_padformulas(as.character(df$county_id))
  df$district_id <- kill_padformulas(as.character(df$district_id))
  df$school_id <- kill_padformulas(as.character(df$school_id))

  # Drop the trailing "End of worksheet" sentinel, blank-id rows, and the single
  # row with a missing Student Group label.
  df <- df %>%
    dplyr::filter(
      !is.na(.data$county_id),
      !grepl("end of worksheet", .data$county_id, ignore.case = TRUE),
      !is.na(.data$student_group)
    )

  value_status <- NULL
  if (isTRUE(with_status)) {
    value_status <- rs_value_with_status(df$any_restraint_seclusion_count)$status
  }

  # Coerce the 20 value columns to numeric; masking tokens -> NA (never a guess).
  df[.restraint_seclusion_value_cols] <-
    lapply(df[.restraint_seclusion_value_cols], rs_value_numeric)

  # Split the Student Group label into normalized subgroup + grade_level, keeping
  # the raw label too.
  split_cols <- rs_split_student_group(df$student_group)
  df$subgroup <- split_cols$subgroup
  df$grade_level <- split_cols$grade_level

  df$end_year <- end_year

  # School-only source: every row is a school. There are NO state/district/county
  # aggregates - do not invent them.
  df <- df %>%
    dplyr::mutate(
      is_state = FALSE,
      is_county = FALSE,
      is_district = FALSE,
      is_school = TRUE,
      is_charter = .data$county_id == "80",
      is_charter_sector = FALSE,
      is_allpublic = FALSE
    )

  if (isTRUE(with_status)) {
    df$value_status <- value_status
  }

  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      student_group, subgroup, grade_level,
      dplyr::all_of(.restraint_seclusion_value_cols),
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic,
      dplyr::any_of("value_status")
    )
}


# -----------------------------------------------------------------------------
# fetch_restraint_seclusion()
# -----------------------------------------------------------------------------

#' Fetch Restraint & Seclusion Incidents (school-level)
#'
#' Downloads the NJ DOE standalone DARS (Discipline & Restraint) school-level
#' Restraint & Seclusion workbook. Each row reports, for one school and one
#' student group, counts (and percents) of restraint and seclusion events across
#' ten categories. Restraint and seclusion are among the highest-liability,
#' most legally sensitive metrics in a building and are concentrated in
#' special-education settings; this fetcher surfaces them in a cross-district
#' comparable form.
#'
#' @details
#' \strong{Source.} Standalone Excel workbooks under the NJ DOE annual-report
#' portal (\code{nj.gov/education/vandv/annualreport/dars/}) - a source distinct
#' from the violence/vandalism/HIB SPR data exposed by
#' \code{\link{fetch_violence_vandalism_hib}}. Covered years: \strong{end_year
#' 2023 (SY2022-23) and 2024 (SY2023-24)} only; other years error. The data sheet
#' is the second sheet (\code{Restraints and Seclusions}); its real header is
#' row 12.
#'
#' \strong{School-level only, no aggregates.} The workbook contains one row per
#' school per student group and has \strong{no} state, district, or county
#' aggregate rows - so \code{is_school} is \code{TRUE} on every row and
#' \code{is_state}/\code{is_county}/\code{is_district} are \code{FALSE}. The
#' \code{level} argument therefore accepts only \code{"school"}.
#'
#' \strong{SSDS three-category background.} NJ's Student Safety Data System groups
#' events into restraint (physical and/or mechanical), seclusion, and occasions
#' where both occurred together; the 20 value columns expand those categories
#' (e.g. \code{restraint_physical_count}, \code{seclusion_count},
#' \code{both_restraint_seclusion_count}) with a count and a percent each.
#'
#' \strong{Suppression -> NA (never a guessed number).} Small cells are masked:
#' \code{"*"} hides a value entirely, and \code{"<5"} is a published RANGE
#' standing in for 1-4 students. Both become \code{NA}; the coercion never
#' extracts the literal \code{5} from \code{"<5"}. A real published \code{0}
#' stays \code{0}.
#'
#' \strong{Student group.} The raw \code{Student Group} label
#' (\code{"Schoolwide"} in 2022-23, \code{"School Total"} in 2023-24, plus race,
#' gender, economically disadvantaged, students with disabilities, and grade
#' labels) is preserved as \code{student_group} and additionally split into
#' normalized \code{subgroup} + \code{grade_level}. Grade rows get
#' \code{subgroup = "total population"} and a grade label (\code{"PK"},
#' \code{"K"}, \code{"01"-"12"}); the rest get \code{grade_level = "TOTAL"}.
#'
#' @param end_year A school year: 2023 (SY2022-23) or 2024 (SY2023-24).
#' @param level Only \code{"school"} is supported (the DARS workbook is
#'   school-level only). Other values error.
#' @param with_status Logical, default \code{FALSE}. If \code{TRUE}, appends
#'   \code{value_status}, classified from the raw
#'   \code{any_restraint_seclusion_count} token before numeric coercion.
#' @param with_denominator Logical, default \code{FALSE}. If \code{TRUE},
#'   appends \code{n_students} from the matching total-enrollment row in
#'   \code{\link{fetch_enr}} on \code{end_year} and CDS identifiers. Unmatched
#'   rows remain \code{NA}.
#' @param with_subgroup_std Logical, default \code{FALSE}. If \code{TRUE}, adds
#'   \code{subgroup_std} immediately after \code{subgroup}.
#'
#' @return Data frame with \code{end_year}, the entity identifiers
#'   (\code{county_id}/\code{county_name}/\code{district_id}/\code{district_name}/
#'   \code{school_id}/\code{school_name}), the raw \code{student_group} plus
#'   normalized \code{subgroup} and \code{grade_level}, the 20 numeric
#'   count/percent columns, and the standard aggregation flags
#'   (\code{is_state}, \code{is_county}, \code{is_district}, \code{is_school},
#'   \code{is_charter}, \code{is_charter_sector}, \code{is_allpublic}).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # School-level restraint & seclusion (latest year)
#' rs <- fetch_restraint_seclusion(2024)
#'
#' # Schoolwide totals: schools with the most restraint occasions
#' library(dplyr)
#' fetch_restraint_seclusion(2024) %>%
#'   filter(subgroup == "total population", grade_level == "TOTAL") %>%
#'   slice_max(restraint_count, n = 10) %>%
#'   select(district_name, school_name, restraint_count, seclusion_count)
#'
#' # Students-with-disabilities share of restraint events, Newark (district 3570)
#' fetch_restraint_seclusion(2023) %>%
#'   filter(district_id == "3570",
#'          subgroup %in% c("total population", "students with disabilities"),
#'          grade_level == "TOTAL") %>%
#'   select(school_name, subgroup, restraint_count)
#' }
fetch_restraint_seclusion <- function(end_year, level = "school",
                                      with_status = FALSE,
                                      with_denominator = FALSE,
                                      with_subgroup_std = FALSE) {
  if (!identical(level, "school")) {
    stop(
      "fetch_restraint_seclusion() is school-level only: the DARS Restraint & ",
      "Seclusion workbook contains only per-school rows and has no ",
      "district/state aggregate.",
      call. = FALSE
    )
  }
  if (!end_year %in% c(2023, 2024)) {
    stop(
      "restraint & seclusion data is available for end_year 2023 (SY2022-23) ",
      "and 2024 (SY2023-24) only.",
      call. = FALSE
    )
  }

  # Parsed-result session cache (the workbook is ~5 MB and holds ~46k rows).
  cache_key <- make_cache_key("fetch_restraint_seclusion", end_year, level)
  cached <- if (isTRUE(with_status)) NULL else cache_get(cache_key)
  if (!is.null(cached)) {
    out <- cached
  } else {
    raw <- get_raw_restraint_seclusion(end_year)
    out <- tidy_restraint_seclusion(raw, end_year, with_status = with_status)

    if (!isTRUE(with_status)) {
      cache_set(cache_key, out)
    }
  }

  if (isTRUE(with_subgroup_std)) {
    out <- add_subgroup_std(out)
  }

  if (isTRUE(with_denominator)) {
    out <- attach_discipline_enrollment_denominator(out)
  }

  out
}
