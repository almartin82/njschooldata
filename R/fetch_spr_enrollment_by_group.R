# ==============================================================================
# Enrollment by student group (SPR "EnrollmentTrendsByStudentGroup")
# ==============================================================================
#
# NJDOE has published this sheet in four layouts:
#
#   2016-17           one row per entity x group (`StudentGroup`, `Percent`),
#                     school file using short labels (econdis, disability, lep)
#   2017-18 - 2023-24 one column per group, numeric or text by year; English
#                     Learners renamed Multilingual Learners and Homeless
#                     Students renamed Students Experiencing Homelessness in
#                     2023-24; Non-Binary/Undesignated Gender added in 2019-20
#                     (district) / 2020-21 (school)
#   2024-25           one column per group, every cell text with a "%" sign,
#                     and five school years per entity in one sheet
#
# fetch_spr_enrollment_by_group() returns all of them in one long layout. No
# value is computed: `pct` is the published percent, `pct_published` the cell
# exactly as published.
# ==============================================================================

.spr_ebg_id_cols <- c("county_id", "county_name", "district_id",
                      "district_name", "school_id", "school_name")

.spr_ebg_flag_cols <- c("is_state", "is_county", "is_district", "is_school",
                        "is_charter", "is_charter_sector", "is_allpublic")

.spr_ebg_columns <- c("end_year", .spr_ebg_id_cols, "subgroup", "pct",
                      "pct_published", .spr_ebg_flag_cols)

# Published group label or column name -> package subgroup name. Each group
# keeps one name across NJDOE's renames; the renames relabel the same group.
.spr_ebg_subgroups <- c(
  female = "female",
  male = "male",
  non_binary_undesignated_gender = "non-binary/undesignated gender",
  "non-binary/undesignated gender" = "non-binary/undesignated gender",
  economically_disadvantaged_students = "economically disadvantaged",
  "economically disadvantaged students" = "economically disadvantaged",
  "economically disadvantaged" = "economically disadvantaged",
  econdis = "economically disadvantaged",
  students_with_disabilities = "students with disabilities",
  "students with disabilities" = "students with disabilities",
  "students with disability" = "students with disabilities",
  disability = "students with disabilities",
  english_learners = "limited english proficiency",
  multilingual_learners = "limited english proficiency",
  "english learners" = "limited english proficiency",
  "multilingual learners" = "limited english proficiency",
  "limited english proficiency" = "limited english proficiency",
  lep = "limited english proficiency",
  homeless_students = "homeless students",
  students_experiencing_homelessness = "homeless students",
  "homeless students" = "homeless students",
  "students experiencing homelessness" = "homeless students",
  students_in_foster_care = "students in foster care",
  "students in foster care" = "students in foster care",
  military_connected_students = "military-connected students",
  "military-connected students" = "military-connected students",
  migrant_students = "migrant students",
  "migrant students" = "migrant students"
)

.spr_ebg_subgroup_order <- unique(unname(.spr_ebg_subgroups))

.spr_ebg_map_subgroup <- function(x, end_year) {
  key <- tolower(trimws(as.character(x)))
  out <- unname(.spr_ebg_subgroups[key])
  unknown <- unique(x[is.na(out)])
  if (length(unknown)) {
    stop("EnrollmentTrendsByStudentGroup ", end_year,
         " has student groups this parser does not know: ",
         paste(unknown, collapse = ", "), call. = FALSE)
  }
  out
}

# The published cell as text, and its number when the cell is a single
# percent. A range, a bound or a suppression note ("<=5%", "20-30%",
# "Enrollment < 15 students") is kept as text and has no number.
.spr_ebg_published <- function(x) {
  if (is.numeric(x)) {
    # as.character() formats each cell on its own (format() would pad every
    # cell to the vector's common number of decimals).
    text <- as.character(x)
  } else {
    text <- trimws(as.character(x))
    text[!is.na(text) & !nzchar(text)] <- NA_character_
  }
  single <- !is.na(text) & grepl("^[0-9]+(\\.[0-9]+)?%?$", text)
  pct <- rep(NA_real_, length(text))
  pct[single] <- as.numeric(sub("%$", "", text[single]))
  pct[!is.na(pct) & (pct < 0 | pct > 100)] <- NA_real_
  list(pct = pct, text = text)
}

# Wide sheet (one column per group) -> long rows.
.spr_ebg_from_wide <- function(df, end_year) {
  value_cols <- setdiff(names(df), c(.spr_ebg_id_cols, .spr_ebg_flag_cols,
                                     "end_year", "school_year"))
  subgroup <- .spr_ebg_map_subgroup(value_cols, end_year)
  parts <- lapply(seq_along(value_cols), function(i) {
    cell <- .spr_ebg_published(df[[value_cols[i]]])
    out <- df[c(.spr_ebg_id_cols, .spr_ebg_flag_cols)]
    out$subgroup <- subgroup[i]
    out$pct <- cell$pct
    out$pct_published <- cell$text
    out
  })
  do.call(rbind, parts)
}

# Long sheet (2016-17) -> the same rows.
.spr_ebg_from_long <- function(df, end_year) {
  cell <- .spr_ebg_published(df$percent)
  out <- df[c(.spr_ebg_id_cols, .spr_ebg_flag_cols)]
  out$subgroup <- .spr_ebg_map_subgroup(df$subgroup, end_year)
  out$pct <- cell$pct
  out$pct_published <- cell$text
  out
}

#' Fetch enrollment share by student group from the School Performance Reports
#'
#' The percent of each school's (or district's) enrollment in each student
#' group, from the "Enrollment Trends by Student Group" sheet of the NJ School
#' Performance Reports, in one layout for every year 2016-17 through 2024-25.
#'
#' NJDOE changed this sheet's layout several times (one row per group in
#' 2016-17, one column per group afterward, text cells with percent signs in
#' 2024-25, five school years per sheet in 2024-25). This function returns one
#' row per entity x student group for the requested year only; earlier years
#' in a trend sheet are dropped, and come from their own year's file.
#'
#' Subgroup names are stable across NJDOE's relabels: English Learners and
#' Multilingual Learners are both \code{"limited english proficiency"};
#' Homeless Students and Students Experiencing Homelessness are both
#' \code{"homeless students"}. \code{"non-binary/undesignated gender"} has rows
#' only in years NJDOE published it (district file from 2019-20, school file
#' from 2020-21).
#'
#' @param end_year A school year end, 2017-2025 (2016-17 is 2017).
#' @param level \code{"school"} (default) or \code{"district"}. The district
#'   file also holds the state rows.
#' @return A data frame, columns in this order:
#'   \describe{
#'     \item{end_year}{integer}
#'     \item{county_id, county_name, district_id, district_name, school_id,
#'       school_name}{character; \code{school_id} is \code{"999"} on district
#'       and state rows}
#'     \item{subgroup}{character, the student group}
#'     \item{pct}{numeric, the published percent of enrollment (0-100).
#'       \code{NA} when NJDOE published a range, a bound or a suppression note
#'       instead of one number, or left the cell blank.}
#'     \item{pct_published}{character, the cell exactly as NJDOE published it
#'       (for example \code{"39.1"}, \code{"39.1\%"}, \code{"<=5\%"},
#'       \code{"20-30\%"})}
#'     \item{is_state, is_county, is_district, is_school, is_charter,
#'       is_charter_sector, is_allpublic}{logical entity flags}
#'   }
#' @export
#' @examples
#' \dontrun{
#' groups <- fetch_spr_enrollment_by_group(2024)
#' econ <- groups[groups$subgroup == "economically disadvantaged", ]
#' }
fetch_spr_enrollment_by_group <- function(end_year, level = "school") {
  level <- match.arg(level, c("school", "district"))
  if (length(end_year) != 1L || is.na(end_year) || !is_valid_year(end_year, "spr")) {
    stop("end_year must be one of ", paste(get_source_years("spr"), collapse = ", "),
         call. = FALSE)
  }
  end_year <- as.integer(end_year)
  raw <- fetch_spr_data("EnrollmentTrendsByStudentGroup", end_year,
                        level = level, clean_subgroups = FALSE)
  sources <- get_source_results(raw)
  raw <- filter_spr_to_year(raw, end_year)
  long <- if (all(c("subgroup", "percent") %in% names(raw))) {
    .spr_ebg_from_long(raw, end_year)
  } else {
    .spr_ebg_from_wide(raw, end_year)
  }
  long$end_year <- end_year
  long <- long[order(long$county_id, long$district_id, long$school_id,
                     match(long$subgroup, .spr_ebg_subgroup_order)), , drop = FALSE]
  long <- as.data.frame(long[.spr_ebg_columns], stringsAsFactors = FALSE)
  rownames(long) <- NULL
  attach_source_results(long, sources)
}
