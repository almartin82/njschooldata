# ==============================================================================
# NJ State Aid (K-12 District Details)
# ==============================================================================
#
# The NJ DOE Office of School Finance publishes a per-district breakdown of K-12
# state aid by category (equalization, special education, transportation,
# security, school choice, ...) alongside the Governor's Budget Message each year.
#
#   - Current year: a direct workbook at
#     /education/stateaid/{code}/FY{yy}_GBM_District_Details.xlsx
#   - Prior years: bundled in /education/stateaid/zippedfiles/{code}.zip, where the
#     district-details member's name drifts ("FY25 GBM District Details Rev.xlsx",
#     "District Details FY20 Revised.xlsx", "district.xlsx", ...).
#
# `{code}` is the two-year span (FY26 = school year 2025-26 = "2526"). The
# fetcher tries the direct URL first and falls back to the zip.
#
# This is the *aid* (state revenue subsidy) side of district finance, distinct
# from the *spending* side in fetch_tges(). Transportation aid in particular is a
# formula subsidy, not transportation cost; do not read it as expenditure.
# ==============================================================================


# standard, cross-year category names (labels drift year to year)
.state_aid_known_categories <- c(
  "equalization_aid", "educational_adequacy_aid", "school_choice_aid",
  "transportation_aid", "special_education_aid", "security_aid",
  "adjustment_aid", "under_adequacy_aid",
  "vocational_expansion_stabilization_aid", "military_impact_aid"
)


#' Normalize a raw NJ state-aid column label to a standard category name
#'
#' @description The published column labels drift across years ("Choice Aid" vs
#' "School Choice Aid"; "Special Education Categorical Aid" vs "Special Education
#' Aid"). This maps the recognized aid categories to a single cross-year name and
#' passes everything else (year totals, differences) through a snake-case clean,
#' so total/difference columns keep their year token and never collide.
#'
#' @param raw character vector of raw column labels
#'
#' @return character vector of normalized names
#' @keywords internal
normalize_state_aid_category <- function(raw) {
  # labels reach here already snake-cased by clean_names(), so treat underscores
  # as spaces too, otherwise space-based patterns ("special ed") never match.
  x <- tolower(gsub("[\r\n_]+", " ", raw))
  x <- trimws(gsub("\\s+", " ", x))
  dplyr::case_when(
    grepl("percent", x)                        ~ "aid_percent_difference",
    grepl("difference", x)                     ~ "k12_aid_difference",
    grepl("equalization", x)                   ~ "equalization_aid",
    grepl("under adequacy", x)                 ~ "under_adequacy_aid",
    grepl("adequacy", x)                       ~ "educational_adequacy_aid",
    grepl("choice", x)                         ~ "school_choice_aid",
    grepl("transportation", x)                 ~ "transportation_aid",
    grepl("special ed", x)                     ~ "special_education_aid",
    grepl("security", x)                       ~ "security_aid",
    grepl("adjustment", x)                     ~ "adjustment_aid",
    grepl("vocational", x)                     ~ "vocational_expansion_stabilization_aid",
    grepl("military", x)                       ~ "military_impact_aid",
    TRUE                                       ~ clean_name_vector(raw)
  )
}


# Parse one validated state-aid workbook. Transport and archive selection stay
# outside this format-specific parser.
.parse_state_aid_workbook <- function(xlsx_path, end_year) {
  # detect the header row (carries both "County" and "Dist"); default to row 5
  top <- suppressMessages(readxl::read_excel(
    xlsx_path, col_names = FALSE, n_max = 10
  ))
  hdr <- which(apply(top, 1, function(row) {
    values <- as.character(row)
    any(values == "County", na.rm = TRUE) &&
      any(values == "Dist", na.rm = TRUE)
  }))[1]
  if (is.na(hdr)) hdr <- 5L

  df <- suppressMessages(readxl::read_excel(xlsx_path, skip = hdr - 1L))
  df <- janitor::clean_names(df)
  df$report_year <- end_year
  df
}

.parse_state_aid_archive <- function(zip_path, end_year, source_url) {
  members <- utils::unzip(zip_path, list = TRUE)$Name
  basenames <- basename(members)
  is_details <- (
    (grepl("district", basenames, ignore.case = TRUE) &
       grepl("detail", basenames, ignore.case = TRUE)) |
      grepl("^district[.]xlsx$", basenames, ignore.case = TRUE)
  ) & !grepl(
    "county|preschool|prek|summary|adult|special|scenario|extraordinary|stabiliz|eligib",
    basenames, ignore.case = TRUE
  ) &
    # NJ DOE ships the district-details table twice, as a PDF and as a workbook
    # with the same stem ("FY25 GBM District Details Rev.pdf" alongside
    # ".xlsx"), and the PDF sorts first inside the archive. Without this the
    # first candidate is the PDF, .validate_source_file() rejects it as "XLSX
    # source is truncated or has no ZIP signature", and the whole year is
    # reported as a parse_error.
    grepl("[.]xls[xmb]?$", basenames, ignore.case = TRUE)
  candidate <- members[is_details]
  if (!length(candidate)) {
    stop(
      "Could not locate a district-details workbook in ", source_url,
      ". Members: ", paste(basenames, collapse = ", "), call. = FALSE
    )
  }

  extraction_dir <- tempfile("state-aid-")
  dir.create(extraction_dir)
  on.exit(unlink(extraction_dir, recursive = TRUE), add = TRUE)
  extracted <- utils::unzip(
    zip_path, files = candidate[1], exdir = extraction_dir,
    junkpaths = TRUE
  )
  if (length(extracted) != 1L || !file.exists(extracted)) {
    stop("State-aid archive member could not be extracted.", call. = FALSE)
  }
  .validate_source_file(extracted, "xlsx")
  .parse_state_aid_workbook(extracted, end_year)
}

get_raw_state_aid_result <- function(
    end_year, request_fn = .default_source_request) {
  end_year <- as.integer(end_year)
  valid_years <- get_source_years("state_aid", capability = "raw")
  if (is.na(end_year) || !end_year %in% valid_years) {
    stop("No NJ State Aid district-details parse is available for end_year ",
         end_year, ". Valid values are ", min(valid_years), " through ",
         max(valid_years), ".", call. = FALSE)
  }

  urls <- resolve_source_url("state_aid", end_year)
  direct <- download_source(
    urls[["direct"]], source_type = "xlsx", request_fn = request_fn
  )
  if (identical(direct$source_status, "actual")) {
    on.exit(unlink(direct$data), add = TRUE)
    parsed <- tryCatch(
      .parse_state_aid_workbook(direct$data, end_year), error = identity
    )
    if (inherits(parsed, "error")) {
      return(new_source_result(
        source_status = "parse_error", source_url = direct$source_url,
        retrieved_at = direct$retrieved_at, digest = direct$digest,
        error = conditionMessage(parsed)
      ))
    }
    return(new_source_result(
      data = parsed, source_status = "actual",
      source_url = direct$source_url, retrieved_at = direct$retrieved_at,
      digest = direct$digest
    ))
  }

  archive <- download_source(
    urls[["archive"]], source_type = "zip", request_fn = request_fn
  )
  if (!identical(archive$source_status, "actual")) {
    return(new_source_result(
      source_status = archive$source_status,
      source_url = archive$source_url,
      retrieved_at = archive$retrieved_at,
      digest = archive$digest,
      error = paste0(
        "Direct workbook candidate failed: ", direct$error,
        "; archive candidate failed: ", archive$error
      )
    ))
  }
  on.exit(unlink(archive$data), add = TRUE)
  parsed <- tryCatch(
    .parse_state_aid_archive(archive$data, end_year, archive$source_url),
    error = identity
  )
  if (inherits(parsed, "error")) {
    return(new_source_result(
      source_status = "parse_error", source_url = archive$source_url,
      retrieved_at = archive$retrieved_at, digest = archive$digest,
      error = conditionMessage(parsed)
    ))
  }
  new_source_result(
    data = parsed, source_status = "actual",
    source_url = archive$source_url, retrieved_at = archive$retrieved_at,
    digest = archive$digest,
    warning = paste0(
      "Archived ZIP fallback used after direct workbook candidate failed: ",
      direct$error
    )
  )
}

#' Get Raw NJ State Aid District Details
#'
#' @description Downloads one year of the NJ DOE K-12 State Aid "District Details"
#' workbook. Tries the current-year direct URL first, then falls back to the
#' archived per-year zip bundle and locates the district-details member by name.
#'
#' @param end_year school year (end of the academic year): the 2025-26 year
#'   (state FY2026) is \code{end_year = 2026}. Valid values are the registered
#'   2019-2027 sources; earlier years use a different unparsed layout.
#'
#' @return a wide data frame (one row per district), header detected at the
#'   first row carrying both "County" and "Dist"
#' @keywords internal
get_raw_state_aid <- function(end_year) {
  source_result_data(get_raw_state_aid_result(end_year))
}


#' Tidy NJ State Aid District Details
#'
#' @description Reshapes the wide district-details workbook to long: one row per
#' district per aid category. The recognized aid categories are normalized to
#' cross-year names; year totals and difference columns pass through (flagged
#' \code{is_aid_category = FALSE}).
#'
#' @param df a raw state-aid data frame from \code{get_raw_state_aid()}
#' @param end_year school year (end of the academic year)
#'
#' @return long, tidy data frame
#' @keywords internal
tidy_state_aid <- function(df, end_year) {
  end_year <- as.integer(end_year)

  # rename the three id columns (always County / Dist / District, in that order)
  if ("county"   %in% names(df)) names(df)[names(df) == "county"]   <- "county_name"
  if ("dist"     %in% names(df)) names(df)[names(df) == "dist"]     <- "district_id"
  if ("district" %in% names(df)) names(df)[names(df) == "district"] <- "district_name"
  # positional fallback if labels ever drift
  if (!"county_name" %in% names(df))   names(df)[1] <- "county_name"
  if (!"district_id" %in% names(df)) names(df)[2] <- "district_id"
  if (!"district_name" %in% names(df)) names(df)[3] <- "district_name"

  id_cols    <- c("county_name", "district_id", "district_name")
  value_cols <- setdiff(names(df), c(id_cols, "report_year"))

  # coerce every melted column to numeric up front: some years carry a character
  # "percent difference" column, which would otherwise block the long bind. Strip
  # currency/percent/grouping punctuation first so real numbers survive.
  df <- df %>%
    dplyr::mutate(dplyr::across(
      dplyr::all_of(value_cols),
      ~ suppressWarnings(as.numeric(gsub("[,$%()]", "", as.character(.x))))
    ))

  long <- tidyr::pivot_longer(
    df,
    cols      = dplyr::all_of(value_cols),
    names_to  = "aid_category_raw",
    values_to = "amount"
  )

  long$aid_category    <- normalize_state_aid_category(long$aid_category_raw)
  long$is_aid_category <- long$aid_category %in% .state_aid_known_categories

  dc <- as.character(long$district_id)
  has_code <- !is.na(dc) & grepl("[0-9]", dc)
  dc[has_code] <- pad_leading(dc[has_code], 4)
  long$district_id <- dc

  long$is_district <- grepl("^[0-9]{3,4}$", long$district_id)
  # the workbook ends in a grand-total row (blank/non-numeric code)
  long$is_state <- !long$is_district &
    (is.na(long$county_name) | grepl("total|state", long$district_name, ignore.case = TRUE))

  long$end_year <- end_year

  lead <- c("county_name", "district_id", "district_name", "end_year",
            "is_state", "is_district", "aid_category", "is_aid_category",
            "amount", "aid_category_raw")
  lead <- intersect(lead, names(long))
  long[, c(lead, setdiff(names(long), lead)), drop = FALSE]
}


#' Fetch NJ K-12 State Aid by District and Category
#'
#' @description One year of NJ DOE K-12 state aid, broken out per district by
#' category (equalization, educational adequacy, school choice, transportation,
#' special education, security, adjustment, vocational expansion stabilization,
#' military impact) plus the year totals. This is the state-aid (revenue subsidy)
#' counterpart to the spending data in \code{\link{fetch_tges}}.
#'
#' @details
#' Returned long, one row per district per category. \code{is_aid_category} marks
#' the individual aid categories (\code{TRUE}) versus the year totals and
#' difference columns (\code{FALSE}); filter to \code{is_aid_category} for the
#' clean categorical breakdown. Category names are normalized across years
#' (e.g. "Choice Aid" and "School Choice Aid" both become \code{school_choice_aid};
#' "Special Education Categorical Aid" becomes \code{special_education_aid}).
#'
#' Data come from the NJ DOE Office of School Finance "District Details" workbook
#' published with the Governor's Budget Message. These are \strong{appropriated /
#' proposed} aid figures, not audited expenditures. Note in particular that
#' \code{transportation_aid} is a formula subsidy and is typically far below a
#' district's actual transportation cost.
#'
#' Valid \code{end_year} values are registered centrally. Each year's workbook is
#' located by trying the current-year direct URL first, then the archived
#' per-year zip bundle.
#'
#' @param end_year school year (end of the academic year): the 2025-26 year
#'   (state FY2026) is \code{end_year = 2026}.
#'
#' @return A tibble with one row per district per aid category:
#'   \code{county_name}, \code{district_id}, \code{district_name},
#'   \code{end_year}, \code{is_state}, \code{is_district}, \code{aid_category},
#'   \code{is_aid_category}, \code{amount}, and the raw label \code{aid_category_raw}.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # All categories for one year
#' fetch_state_aid(2026) %>%
#'   filter(is_district, is_aid_category) %>%
#'   select(district_name, aid_category, amount)
#'
#' # Transportation aid, biggest recipients
#' fetch_state_aid(2026) %>%
#'   filter(is_district, aid_category == "transportation_aid") %>%
#'   arrange(desc(amount)) %>%
#'   select(district_name, amount)
#'
#' # One district's aid mix
#' fetch_state_aid(2026) %>%
#'   filter(district_id == "3570", is_aid_category) %>%
#'   select(aid_category, amount)
#' }
#'
#' @export
fetch_state_aid <- function(end_year) {
  result <- get_raw_state_aid_result(end_year)
  raw <- source_result_data(result)
  parsed <- tryCatch(tidy_state_aid(raw, end_year), error = identity)
  if (inherits(parsed, "error")) {
    result <- new_source_result(
      source_status = "parse_error", source_url = result$source_url,
      retrieved_at = result$retrieved_at, digest = result$digest,
      warning = result$warning, error = conditionMessage(parsed)
    )
    source_result_data(result)
  }
  attach_source_results(
    parsed,
    source_result_record(result, "state_aid", end_year)
  )
}


#' Fetch Multiple Years of NJ K-12 State Aid
#'
#' @param end_year_vector vector of school years (end of the academic year).
#'   Valid values come from the authoritative source registry.
#' @param allow_partial Return successful years when one request fails. The
#'   default is strict. In either mode, inspect \code{get_source_results()} for
#'   the status of every requested year.
#'
#' @return A single tibble, the per-year results of \code{\link{fetch_state_aid}}
#'   stacked (one row per district per category per year).
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Transportation aid trend for one district across years
#' fetch_many_state_aid(2022:2026) %>%
#'   filter(district_id == "3570", aid_category == "transportation_aid") %>%
#'   select(end_year, amount)
#' }
#'
#' @export
fetch_many_state_aid <- function(end_year_vector, allow_partial = FALSE) {
  captured <- lapply(end_year_vector, function(.y) {
    message(.y)
    capture_source_call(
      function() fetch_state_aid(.y), "state_aid", .y
    )
  })
  combine_source_captures(
    captured, allow_partial = allow_partial,
    context = "State-aid multi-year request"
  )
}
