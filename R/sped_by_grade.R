# Students with an active IEP by district and grade, from NJDOE's response to
# OPRA request C255254 (2026-07-08). NJDOE publishes no equivalent file.

.SPED_GRADE_OPRA_URL <- "opra://njdoe/C255254/Districtlevel_C255254_Suppressed.xlsx"
.SPED_GRADE_LEVELS <- c(
  PK = "PK", KG = "K", Grade_1 = "01", Grade_2 = "02", Grade_3 = "03",
  Grade_4 = "04", Grade_5 = "05", Grade_6 = "06", Grade_7 = "07",
  Grade_8 = "08", Grade_9 = "09", Grade_10 = "10", Grade_11 = "11",
  Grade_12 = "12", `No Grade Count` = "NO_GRADE"
)

get_valid_sped_by_grade_years <- function() {
  2022:2026
}

#' Get raw OPRA IEP counts by district and grade
#'
#' @param end_year ending school year, 2022 through 2026.
#'
#' @return one row per district in the year, every cell as character, exactly
#'   as NJDOE released it.
#' @keywords internal
get_raw_sped_by_grade <- function(end_year) {
  if (length(end_year) != 1L || !end_year %in% get_valid_sped_by_grade_years()) {
    stop(paste0(
      end_year, " is not a valid end_year for IEP counts by grade. ",
      "Valid years are: ",
      paste(get_valid_sped_by_grade_years(), collapse = ", "), "."
    ), call. = FALSE)
  }

  source_result <- .package_source(.SPED_GRADE_OPRA_URL, "xlsx")
  if (is.null(source_result)) {
    stop("IEP-by-grade source is missing from the package.", call. = FALSE)
  }
  on.exit(source_result$release(), add = TRUE)

  raw <- readxl::read_excel(
    source_result_data(source_result), sheet = 1, na = "", col_types = "text"
  )
  missing_cols <- setdiff(
    c("County Code", "County Name", "District Code", "District Name",
      "School Year", names(.SPED_GRADE_LEVELS)),
    names(raw)
  )
  if (length(missing_cols)) {
    stop("IEP-by-grade source is missing columns: ",
         paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  label <- sprintf("%d-%02d", end_year - 1L, end_year %% 100L)
  raw <- raw[raw[["School Year"]] == label, , drop = FALSE]
  attach_source_results(
    raw,
    source_result_record(source_result, "sped_by_grade", end_year, "district")
  )
}

#' Fetch students with an active IEP by district and grade
#'
#' Counts of students with an active IEP for every public school district and
#' charter school, by grade, from NJDOE's response to OPRA request C255254. The
#' workbook is bundled in the package and verified by SHA-256 on every read.
#'
#' NJDOE suppressed counts under 5. A suppressed cell returns
#' \code{n_students = NA} with \code{suppressed = TRUE}, never zero. A grade
#' NJDOE left blank for a district has no row. The file has no statewide row and
#' no denominators, and this function adds neither.
#'
#' \strong{2025-26 looks incomplete.} Statewide known counts fall 8\% from
#' 2024-25, grades 9-12 fall about 15\%, and some large districts have no known
#' counts. NJDOE has not explained this, so \code{end_year = 2026} warns. The
#' values are returned as released.
#'
#' @param end_year ending school year, 2022 through 2026 (2023-24 is 2024).
#'
#' @return a tibble with end_year, county_id, county_name, district_id,
#'   district_name, grade_level (PK, K, 01-12, NO_GRADE), n_students and
#'   suppressed, plus the standard entity flags.
#'
#' @seealso \code{\link{fetch_sped}} for published classification rates.
#' @export
#'
#' @examples
#' # 1. Every district and grade for one year
#' fetch_sped_by_grade(2025)
#'
#' # 2. One district, by grade
#' library(dplyr)
#' fetch_sped_by_grade(2025) %>%
#'   filter(district_name == "Newark Public School District") %>%
#'   select(grade_level, n_students, suppressed)
#'
#' # 3. Charter schools only, across years
#' lapply(2022:2025, fetch_sped_by_grade) %>%
#'   bind_rows() %>%
#'   filter(is_charter, grade_level == "K")
fetch_sped_by_grade <- function(end_year) {
  raw <- get_raw_sped_by_grade(end_year)
  if (end_year == 2026L) {
    warning(
      "2025-26 IEP counts look incomplete: statewide known counts fall 8% ",
      "from 2024-25. Values are returned as NJDOE released them.",
      call. = FALSE
    )
  }

  grade_cols <- names(.SPED_GRADE_LEVELS)
  long <- tidyr::pivot_longer(
    raw, dplyr::all_of(grade_cols),
    names_to = "grade_col", values_to = "value"
  )
  long <- long[!is.na(long$value), , drop = FALSE]

  value <- trimws(long$value)
  suppressed <- value == "*"
  unexpected <- !suppressed & !grepl("^[0-9]+$", value)
  if (any(unexpected)) {
    stop("Unexpected IEP count values: ",
         paste(unique(value[unexpected]), collapse = ", "), call. = FALSE)
  }

  out <- tibble::tibble(
    end_year = as.integer(end_year),
    county_id = long[["County Code"]],
    county_name = long[["County Name"]],
    district_id = long[["District Code"]],
    district_name = long[["District Name"]],
    grade_level = unname(.SPED_GRADE_LEVELS[long$grade_col]),
    n_students = ifelse(suppressed, NA_real_, suppressWarnings(as.numeric(value))),
    suppressed = suppressed
  )
  out <- append_sped_entity_flags(out, is_district = TRUE)
  attach_source_results(out, get_source_results(raw))
}
