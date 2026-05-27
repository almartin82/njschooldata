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


# the two-digit-each year span code: end_year 2026 (FY26 / SY2025-26) -> "2526"
state_aid_year_code <- function(end_year) {
  end_year <- as.integer(end_year)
  sprintf("%02d%02d", (end_year - 1L) %% 100L, end_year %% 100L)
}


# cheap real-.xlsx check: a valid workbook is a ZIP, so it starts with "PK"
.is_xlsx_file <- function(path) {
  if (!file.exists(path) || file.size(path) < 100) return(FALSE)
  con <- file(path, "rb")
  on.exit(close(con))
  magic <- readBin(con, what = "raw", n = 2L)
  length(magic) == 2L && magic[1] == as.raw(0x50) && magic[2] == as.raw(0x4b)
}


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


#' Get Raw NJ State Aid District Details
#'
#' @description Downloads one year of the NJ DOE K-12 State Aid "District Details"
#' workbook. Tries the current-year direct URL first, then falls back to the
#' archived per-year zip bundle and locates the district-details member by name.
#'
#' @param end_year school year (end of the academic year): the 2025-26 year
#'   (state FY2026) is \code{end_year = 2026}. Valid values are 2019 and later;
#'   earlier years use a different layout that this fetcher does not yet parse.
#'
#' @return a wide data frame (one row per district), header detected at the
#'   first row carrying both "County" and "Dist"
#' @keywords internal
get_raw_state_aid <- function(end_year) {
  end_year <- as.integer(end_year)
  if (is.na(end_year) || end_year < 2019) {
    stop("No NJ State Aid district-details parse is available for end_year ",
         end_year, ". Valid values are 2019 and later (earlier years use a ",
         "different layout).", call. = FALSE)
  }

  code <- state_aid_year_code(end_year)
  yy   <- end_year %% 100L
  base <- "https://www.nj.gov/education/stateaid"
  direct_url <- sprintf("%s/%s/FY%02d_GBM_District_Details.xlsx", base, code, yy)

  xlsx_path <- NULL

  # 1) current-year direct workbook
  tmp <- tempfile(fileext = ".xlsx")
  got_direct <- tryCatch({
    downloader::download(direct_url, dest = tmp, mode = "wb", quiet = TRUE)
    .is_xlsx_file(tmp)
  }, error = function(e) FALSE)

  if (isTRUE(got_direct)) {
    xlsx_path <- tmp
  } else {
    # 2) archived per-year zip bundle
    zip_url <- sprintf("%s/zippedfiles/%s.zip", base, code)
    ztmp <- tempfile(fileext = ".zip")
    downloader::download(zip_url, dest = ztmp, mode = "wb", quiet = TRUE)
    exdir <- tempfile()
    dir.create(exdir)
    utils::unzip(ztmp, exdir = exdir)

    fs <- list.files(exdir, recursive = TRUE, full.names = TRUE, pattern = "[.]xlsx$")
    b  <- basename(fs)
    is_dd <- (
      (grepl("district", b, ignore.case = TRUE) & grepl("detail", b, ignore.case = TRUE)) |
        grepl("^district[.]xlsx$", b, ignore.case = TRUE)
    ) & !grepl("county|preschool|prek|summary|adult|special|scenario|extraordinary|stabiliz|eligib",
               b, ignore.case = TRUE)
    cand <- fs[is_dd]
    if (!length(cand)) {
      stop("Could not locate a district-details workbook in ", zip_url,
           ". Members: ", paste(b, collapse = ", "), call. = FALSE)
    }
    xlsx_path <- cand[1]
  }

  # detect the header row (carries both "County" and "Dist"); default to row 5
  top <- suppressMessages(readxl::read_excel(xlsx_path, col_names = FALSE, n_max = 10))
  hdr <- which(apply(top, 1, function(r) {
    rc <- as.character(r)
    any(rc == "County", na.rm = TRUE) && any(rc == "Dist", na.rm = TRUE)
  }))[1]
  if (is.na(hdr)) hdr <- 5L

  df <- suppressMessages(readxl::read_excel(xlsx_path, skip = hdr - 1L))
  df <- janitor::clean_names(df)
  df$report_year <- end_year
  df
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
#' Valid \code{end_year} values are 2019 and later. Each year's workbook is
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
  get_raw_state_aid(end_year) %>%
    tidy_state_aid(end_year)
}


#' Fetch Multiple Years of NJ K-12 State Aid
#'
#' @param end_year_vector vector of school years (end of the academic year).
#'   Valid values are 2019 and later.
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
fetch_many_state_aid <- function(end_year_vector) {
  purrr::map_dfr(end_year_vector, function(.y) {
    message(.y)
    fetch_state_aid(.y)
  })
}
