# Share of students with IEPs, at the finest grain New Jersey publishes, for
# comparing one set of schools with another (see sped_all_vs_all() and
# sped_like_for_like()).
#
# Each basis uses one construct:
#
#   "lea_idea" (default). District rows from the IDEA classification files
#   (all grades) plus district rows by grade band from NJDOE's OPRA response
#   C255254 (counts by grade), with the same year's Fall Enrollment by grade as
#   the denominator. Counts, bundled, offline. 2023-2026.
#
#   "school_report". School, district and state rows from the School
#   Performance Reports "Students with Disabilities" percent of enrollment, one
#   decimal, no suppression. Live download, 2021-2025. A different construct
#   from IDEA (see the details of fetch_sped_share()).
#
#   "school_spr". Bundled school-only SPR rates for 2023-2025, read from
#   the 2024-25 release's historical trend rows. No count reconstruction.

.NJ_SPED_SHARE_BANDS <- list(
  elementary = c("K", sprintf("%02d", 1:5)),
  middle = sprintf("%02d", 6:8),
  high = sprintf("%02d", 9:12)
)

# Camden renaissance school operators. Each is its own LEA in county 07, not in
# the county-80 charter sector. The NJDOE Renaissance School Project annual
# reports page (https://www.nj.gov/education/chartsch/renaissance/reports,
# read 2026-10-31) lists exactly three operators for 2015-2025; the ids are the
# state district codes of those operators in the OPRA, IDEA and enrollment files.
.NJ_RENAISSANCE_LEA_IDS <- c("1799", "1801", "1802")

get_valid_sped_share_years <- function() {
  2023:2026
}

.nj_share_columns <- c(
  "end_year", "entity_level", "district_id", "school_id", "district_name",
  "school_name", "grade_band", "grade_low", "grade_high", "n_sped",
  "n_enrolled", "pct_sped", "pct_sped_lo", "pct_sped_hi", "is_charter",
  "construct", "count_date", "source_file"
)

# TRUE for the state's charter sector (county 80) and for the Camden
# renaissance operators; NA where the source published no county code and the
# district is not a renaissance operator; NA on state rows.
.nj_share_is_charter <- function(county_id, district_id, entity_level) {
  out <- is_charter_district(county_id) | district_id %in% .NJ_RENAISSANCE_LEA_IDS
  out[entity_level == "state"] <- NA
  out
}

.nj_share_frame <- function(n, ...) {
  out <- data.frame(
    end_year = rep(NA_integer_, max(n, 1L)), entity_level = NA_character_,
    district_id = NA_character_, school_id = NA_character_,
    district_name = NA_character_, school_name = NA_character_,
    grade_band = NA_character_, grade_low = NA_character_,
    grade_high = NA_character_, n_sped = NA_real_, n_enrolled = NA_real_,
    pct_sped = NA_real_, pct_sped_lo = NA_real_, pct_sped_hi = NA_real_,
    is_charter = NA, construct = NA_character_, count_date = NA_character_,
    source_file = NA_character_, stringsAsFactors = FALSE
  )[seq_len(n), , drop = FALSE]
  rownames(out) <- NULL
  out
}

# ---- lea_idea ---------------------------------------------------------------

# Enrollment by district and grade from the Fall Enrollment District sheet.
# Kindergarten is published as half-day and full-day rows and is summed. A
# grade with any unreported row is NA, never a partial sum.
.nj_share_lea_enrollment <- function(end_year) {
  e <- fetch_enr(end_year)
  d <- e[!is.na(e$district_id) & e$school_id == "999" &
           e$grade_level %in% c("PK", "K", sprintf("%02d", 1:12)), ,
         drop = FALSE]
  key <- paste(d$district_id, d$grade_level, sep = "|")
  total <- tapply(d$row_total, key, function(x) if (anyNA(x)) NA_real_ else sum(x))
  list(
    value = function(district_id, grades) {
      k <- paste(district_id, grades, sep = "|")
      v <- unname(total[k])
      if (anyNA(v)) NA_real_ else sum(v)
    },
    districts = unique(d$district_id)
  )
}

# One district's row for one grade band, from OPRA grade cells and enrollment.
# A cell NJDOE left blank is zero students: wherever no cell is suppressed, the
# grade cells sum to the IDEA child count exactly, including districts with a
# blank cell in an enrolled grade (all of them, 2023-2025). A suppressed cell
# (count of 1 to 4) makes the band's count NA with published-bound limits.
.nj_share_band_row <- function(cells, enrolled, grades) {
  hit <- cells[cells$grade_level %in% grades, , drop = FALSE]
  k_supp <- sum(hit$suppressed)
  known <- sum(hit$n_students[!hit$suppressed])
  out <- list(n_sped = NA_real_, lo = NA_real_, hi = NA_real_)
  if (k_supp == 0L) {
    out$n_sped <- known
  } else if (!is.na(enrolled) && enrolled > 0) {
    out$lo <- (known + k_supp) / enrolled * 100
    out$hi <- (known + 4 * k_supp) / enrolled * 100
  }
  out
}

.nj_share_lea_idea <- function(end_year) {
  opra <- fetch_sped_by_grade(end_year)
  enr <- .nj_share_lea_enrollment(end_year)
  opra_file <- .SPED_GRADE_OPRA_URL
  enr_file <- paste0("enrollment-", end_year, ".zip")
  construct <- "students with an IEP, October 15 child count"
  count_date <- if (end_year <= 2025L) "October 15" else NA_character_

  names_by_district <- opra[!duplicated(opra$district_id),
                            c("district_id", "county_id", "district_name")]
  band_rows <- list()
  for (i in seq_len(nrow(names_by_district))) {
    did <- names_by_district$district_id[i]
    cells <- opra[opra$district_id == did, , drop = FALSE]
    for (band in names(.NJ_SPED_SHARE_BANDS)) {
      grades <- .NJ_SPED_SHARE_BANDS[[band]]
      n_enr <- if (did %in% enr$districts) enr$value(did, grades) else NA_real_
      has_cell <- any(cells$grade_level %in% grades)
      # A band no student is enrolled in and no cell reports is not served.
      if (!has_cell && !is.na(n_enr) && n_enr == 0) next
      if (!has_cell && is.na(n_enr)) next
      b <- .nj_share_band_row(cells, n_enr, grades)
      # Fewer students enrolled than students with IEPs (sending districts
      # report students enrolled elsewhere): the enrollment is not this count's
      # denominator, so it is withheld, not clamped. Never a share above 100.
      if (!is.na(b$n_sped) && !is.na(n_enr) && b$n_sped > n_enr) n_enr <- NA_real_
      band_rows[[length(band_rows) + 1L]] <- data.frame(
        district_id = did, grade_band = band, n_sped = b$n_sped,
        n_enrolled = n_enr, pct_sped_lo = b$lo, pct_sped_hi = b$hi,
        stringsAsFactors = FALSE
      )
    }
  }
  bands <- do.call(rbind, band_rows)
  bands <- merge(bands, names_by_district, by = "district_id", sort = FALSE)
  bands_out <- .nj_share_frame(nrow(bands))
  bands_out$end_year <- as.integer(end_year)
  bands_out$entity_level <- "district"
  bands_out$district_id <- bands$district_id
  bands_out$district_name <- bands$district_name
  bands_out$grade_band <- bands$grade_band
  bands_out$n_sped <- bands$n_sped
  bands_out$n_enrolled <- bands$n_enrolled
  bands_out$pct_sped_lo <- bands$pct_sped_lo
  bands_out$pct_sped_hi <- bands$pct_sped_hi
  bands_out$is_charter <- .nj_share_is_charter(
    bands$county_id, bands$district_id, bands_out$entity_level
  )
  bands_out$construct <- construct
  bands_out$count_date <- count_date
  bands_out$source_file <- paste(opra_file, enr_file, sep = "; ")

  all_out <- .nj_share_frame(0L)
  if (end_year %in% 2023:2025) {
    s <- fetch_sped(end_year)
    s <- s[!is.na(s$district_id), , drop = FALSE]
    all_out <- .nj_share_frame(nrow(s))
    all_out$end_year <- as.integer(end_year)
    all_out$entity_level <- ifelse(s$is_state, "state", "district")
    all_out$district_id <- ifelse(s$is_state, NA_character_, s$district_id)
    all_out$district_name <- s$district_name
    all_out$grade_band <- "all"
    all_out$n_sped <- as.numeric(s$sped_num)
    all_out$n_enrolled <- as.numeric(s$gened_num)
    all_out$pct_sped <- as.numeric(s$sped_rate)
    # A published rate is rounded to two decimals in the source files; it is
    # the only figure when the count or the denominator is not published.
    rate_only <- !is.na(s$sped_rate) & (is.na(s$sped_num) | is.na(s$gened_num))
    all_out$pct_sped_lo <- ifelse(rate_only, s$sped_rate - 0.005, NA_real_)
    all_out$pct_sped_hi <- ifelse(rate_only, s$sped_rate + 0.005, NA_real_)
    all_out$is_charter <- .nj_share_is_charter(
      s$county_id, all_out$district_id, all_out$entity_level
    )
    all_out$construct <- construct
    all_out$count_date <- count_date
    all_out$source_file <- sped_classification_source(end_year)$url
  }
  out <- rbind(all_out, bands_out)
  out <- out[order(out$entity_level != "state", out$district_id,
                   match(out$grade_band, c("all", names(.NJ_SPED_SHARE_BANDS)))), ,
             drop = FALSE]
  rownames(out) <- NULL
  out[.nj_share_columns]
}

# ---- school_report ----------------------------------------------------------

.nj_share_pct <- function(x) {
  x <- gsub("%", "", trimws(as.character(x)), fixed = TRUE)
  v <- suppressWarnings(as.numeric(x))
  v[!is.na(v) & (v < 0 | v > 100)] <- NA_real_
  v
}

.nj_share_spr_year <- function(df, end_year) {
  if ("school_year" %in% names(df)) filter_spr_to_year(df, end_year) else df
}

# Lowest and highest grade with enrolled students, from the school's own
# enrollment by grade.
.nj_share_span <- function(enr_grades) {
  order <- c("PK", "K", sprintf("%02d", 1:12))
  cols <- c("grade_pk", "grade_kg", sprintf("grade_%02d", 1:12))
  m <- as.matrix(as.data.frame(lapply(enr_grades[cols], function(x)
    suppressWarnings(as.numeric(x)))))
  has <- !is.na(m) & m > 0
  low <- apply(has, 1, function(r) if (any(r)) order[which(r)[1]] else NA_character_)
  high <- apply(has, 1, function(r) if (any(r)) order[rev(which(r))[1]] else NA_character_)
  list(low = unname(low), high = unname(high))
}

# Assemble rows from the two SPR sheets of one level, already read.
.nj_share_spr_rows <- function(pct, grades, end_year, entity_level) {
  pct <- .nj_share_spr_year(pct, end_year)
  grades <- .nj_share_spr_year(grades, end_year)
  keys <- c("county_id", "district_id", "school_id")
  join <- function(df) do.call(paste, c(df[keys], sep = "|"))
  pos <- match(join(pct), join(grades))
  n <- nrow(pct)
  out <- .nj_share_frame(n)
  out$end_year <- as.integer(end_year)
  out$entity_level <- entity_level
  out$district_id <- pct$district_id
  out$district_name <- pct$district_name
  if (entity_level == "school") {
    out$school_id <- pct$school_id
    out$school_name <- pct$school_name
    span <- .nj_share_span(grades[pos, , drop = FALSE])
    out$grade_low <- span$low
    out$grade_high <- span$high
  }
  out$grade_band <- "all"
  out$n_enrolled <- suppressWarnings(as.numeric(grades$total[pos]))
  out$pct_sped <- .nj_share_pct(pct$students_with_disabilities)
  out$pct_sped_lo <- out$pct_sped - 0.05
  out$pct_sped_hi <- out$pct_sped + 0.05
  out$is_charter <- .nj_share_is_charter(pct$county_id, pct$district_id, entity_level)
  out$construct <- "students with disabilities, percent of enrollment"
  out$count_date <- NA_character_
  out$source_file <- NA_character_
  out
}

.nj_share_school_report <- function(end_year) {
  sheet_pct <- "EnrollmentTrendsByStudentGroup"
  sheet_grade <- "EnrollmentTrendsbyGrade"
  schools <- .nj_share_spr_rows(
    fetch_spr_data(sheet_pct, end_year, "school"),
    fetch_spr_data(sheet_grade, end_year, "school"), end_year, "school"
  )
  schools$source_file <- get_spr_url(end_year, "school")
  schools <- schools[schools$school_id != "999" & !is.na(schools$school_id), ,
                     drop = FALSE]
  dpct <- fetch_spr_data(sheet_pct, end_year, "district")
  dgr <- fetch_spr_data(sheet_grade, end_year, "district")
  rows <- .nj_share_spr_rows(dpct, dgr, end_year, "district")
  rows$source_file <- get_spr_url(end_year, "district")
  state <- as.logical(.nj_share_spr_year(dpct, end_year)$is_state)
  rows$entity_level[state] <- "state"
  rows$district_id[state] <- NA_character_
  rows$is_charter[state] <- NA
  out <- rbind(rows[state, , drop = FALSE], rows[!state, , drop = FALSE], schools)
  rownames(out) <- NULL
  out[.nj_share_columns]
}

# ---- exported ---------------------------------------------------------------

#' Fetch the share of students with IEPs, district rows by grade band or school rows
#'
#' Rows of the share of students with an IEP, at the finest grain New Jersey
#' publishes, in the shape \code{\link{sped_all_vs_all}} and
#' \code{\link{sped_like_for_like}} read. Every value is from a NJDOE file.
#'
#' Each basis uses its own construct and grain:
#'
#' \describe{
#'   \item{\code{"lea_idea"} (default, 2023-2026)}{District (LEA) rows. For
#'   2023-2025, an \code{all} row per district and the state from the IDEA
#'   classification files (count, enrollment, rate). For every year, rows for
#'   \code{elementary} (K-5), \code{middle} (6-8) and \code{high} (9-12) from
#'   NJDOE's response to OPRA request C255254 (see
#'   \code{\link{fetch_sped_by_grade}}), over the same year's Fall Enrollment by
#'   grade. Pre-K is left out of every band. A band with a suppressed grade cell
#'   (a count under 5) has \code{n_sped = NA} and \code{pct_sped_lo/hi} from the
#'   published bound of 1 to 4 for each suppressed cell. A cell NJDOE left blank
#'   is zero students: wherever nothing is suppressed, the OPRA grade cells sum to
#'   the IDEA child count for every district in 2023-2025. The band rows carry no
#'   \code{pct_sped}: NJDOE publishes counts by grade, and the helpers pool the
#'   counts. \strong{2025-26 is flagged}: known OPRA counts fall 8 percent from
#'   2024-25, there is no IDEA file yet, and the call warns.}
#'   \item{\code{"school_report"} (2021-2025, live)}{School rows, plus district
#'   and state rows, from the School Performance Reports: Students with
#'   Disabilities as a percent of enrollment, one decimal, with no suppression.
#'   \code{n_enrolled} is the same report's total enrollment, and
#'   \code{grade_low}/\code{grade_high} are the lowest and highest grades with
#'   students in that report. This is a different construct from the IDEA
#'   child count (in 2024-25 the statewide figure is 18.1 percent against 17.35
#'   percent for IDEA, and some schools differ by more); NJDOE does not explain
#'   the gap. Downloads the School Performance Reports workbooks, which are large.}
#'   \item{\code{"school_spr"} (2023-2025, bundled)}{School-only rates from
#'   the 2024-25 release's enrollment trends, preserving historical school-year
#'   labels, source text and rounding bounds. n_sped remains NA. The same
#'   report supplies enrollment and grade spans.}
#' }
#'
#' \code{is_charter} is TRUE for the state's charter sector (county code 80) and
#' for the three Camden renaissance operators in county 07 (1799, 1801, 1802)
#' listed by the NJDOE Renaissance School Project, and FALSE otherwise.
#'
#' @param end_year ending school year. \code{"lea_idea"}: 2023-2026.
#'   \code{"school_report"}: 2021-2025.
#' @param basis \code{"lea_idea"} (default) or \code{"school_report"}.
#'   Also accepts \code{"school_spr"}: school-only rates for 2023-2025 from
#'   the complete bundled 2024-25 EnrollmentTrendsByStudentGroup sheet.
#'   That basis keeps source_value and school_year, leaves n_sped NA, reads
#'   enrollment and grade spans from EnrollmentTrendsbyGrade, and preserves
#'   rounded or bounded rates in pct_sped_lo/hi.
#'   No count is recovered from a rounded share. The SPR guide defines this as
#'   students classified for special education divided by total enrollment.
#'   Enrollment is attributed to the school reporting enrollment; this differs
#'   from accountability's sending-school attribution for specialized receiving
#'   schools. School years 2023 and 2024 are historical rows in the 2025 release.
#'
#' @return A data frame with end_year, entity_level (state, district or school),
#'   district_id, school_id, district_name, school_name, grade_band (all,
#'   elementary, middle, high), grade_low, grade_high, n_sped, n_enrolled,
#'   pct_sped, pct_sped_lo, pct_sped_hi, is_charter, construct, count_date and
#'   source_file. Suppressed values are NA, never zero.
#' @seealso \code{\link{fetch_sped}}, \code{\link{fetch_sped_by_grade}}
#' @export
#'
#' @examples
#' # 1. District rows by grade band, with the IDEA all-grades row
#' share <- fetch_sped_share(2025)
#' head(share)
#'
#' # 2. Band counts for the district-run and charter sectors
#' library(dplyr)
#' share %>%
#'   filter(entity_level == "district", grade_band != "all") %>%
#'   group_by(is_charter, grade_band) %>%
#'   summarise(n_sped = sum(n_sped, na.rm = TRUE), n_enrolled = sum(n_enrolled, na.rm = TRUE))
#'
#' # 3. School rows from the bundled School Performance Reports
#' fetch_sped_share(2024, basis = "school_spr") %>%
#'   filter(entity_level == "school", is_charter)
fetch_sped_share <- function(end_year, basis = c("lea_idea", "school_report", "school_spr")) {
  basis <- match.arg(basis)
  if (basis == "school_spr") return(.nj_share_school_spr(end_year))
  if (length(end_year) != 1L || is.na(end_year)) {
    stop("end_year must be a single year.", call. = FALSE)
  }
  valid <- if (basis == "lea_idea") get_valid_sped_share_years() else 2021:2025
  if (!end_year %in% valid) {
    stop(end_year, " is not a valid end_year for basis '", basis,
         "'. Valid years are: ", paste(valid, collapse = ", "), ".", call. = FALSE)
  }
  if (basis == "lea_idea") .nj_share_lea_idea(end_year) else .nj_share_school_report(end_year)
}
