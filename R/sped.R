#' Valid years for SPED data
#'
#' @return vector of valid end years for SPED data
#' @keywords internal
get_valid_sped_years <- function() {
 # As of 2024, NJ DOE restructured their website.
 # Historical data (2003-2019) URLs no longer work.
 # Only current data is available at new URL structure.
 c(2024, 2025)
}


#' Build SPED data URL
#'
#' @param end_year ending school year
#' @return URL string for the SPED data file
#' @keywords internal
build_sped_url <- function(end_year) {
  base <- "https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/"

  # 2025 (SY2024-25): NJ DOE switched to the consolidated IDEA-618 public
  # reporting naming convention. The classification-rate workbook lives in
  # the 2025_618data/ folder and carries BOTH a "District Rates" sheet (the
  # district-level total classification rate, same shape as earlier years)
  # and a "State Rates" sheet (counts + classification rate by IDEA
  # disability category). See get_raw_sped() for sheet dispatch.
  if (end_year >= 2025L) {
    return(paste0(
      base, end_year, "_618data/",
      end_year, "IDEA618PublicReporting_ClassificationRates.xlsx"
    ))
  }

  # Pre-2025 URL structure (2024 verified live): academic year format,
  # eg 2023-2024 data = "2324", in the prior-year-labeled folder.
  year_suffix <- paste0(
    substr(as.character(end_year - 1), 3, 4),
    substr(as.character(end_year), 3, 4)
  )

  paste0(
    base, end_year - 1, "_618data/DistrictWide_ClassificationRate_",
    year_suffix, "_public.xlsx"
  )
}


#' read Special ed excel files from the NJ state website
#'
#' @inheritParams get_raw_enr
#' @param level one of \code{"district"} (default; district-level total
#'   classification rate, all supported years) or \code{"state"} (state-level
#'   counts + classification rate by IDEA disability category, 2025+ only --
#'   NJ DOE did not publish the by-disability state table in the older
#'   single-sheet workbooks).
#'
#' @return a dataframe with special ed counts, etc.
#' @keywords internal
get_raw_sped <- function(end_year, level = "district") {
  valid_years <- get_valid_sped_years()

  if (!end_year %in% valid_years) {
    stop(paste0(
      end_year, " is not a valid end_year for SPED data. ",
      "Valid years are: ", paste(valid_years, collapse = ", "), ". ",
      "Historical data (2003-2019) is no longer available from NJ DOE. ",
      "Data prior to 2014 requires an OPRA request."
    ))
  }
  if (!level %in% c("district", "state")) {
    stop("level must be one of 'district' or 'state'.", call. = FALSE)
  }
  if (level == "state" && end_year < 2025L) {
    stop(paste0(
      "State-level SPED counts by disability category are only available ",
      "for end_year >= 2025 (NJ DOE introduced the 'State Rates' table in ",
      "the 2025 consolidated IDEA-618 workbook). For by-disability counts ",
      "in earlier years use fetch_sped_placement(level = 'state')."
    ), call. = FALSE)
  }

  sped_url <- build_sped_url(end_year)

  # Check URL accessibility before attempting download
  if (!check_url_accessible(sped_url)) {
    stop(paste0("SPED data URL is not accessible: ", sped_url))
  }

  tf <- tempfile(fileext = ".xlsx")
  utils::download.file(sped_url, tf, mode = 'wb', quiet = TRUE)

  if (end_year >= 2025L) {
    # 2025+ consolidated workbook: two sheets, each with the column-header
    # row at row 5 (skip = 4). "District Rates" parses through the standard
    # clean_sped_names()/clean_sped_df() pipeline; "State Rates" is a
    # by-disability table handled by tidy_sped_state_disability().
    sheet <- if (level == "state") "State Rates" else "District Rates"
    sped <- readxl::read_excel(
      tf, sheet = sheet, skip = 4, na = c('-', '*', 'N', 'S')
    )
  } else {
    # Pre-2025 single-sheet workbook has 3 header rows.
    sped <- readxl::read_excel(
      tf, skip = 3, na = c('-', '*', 'N', 'S')
    )
  }

  sped$end_year <- end_year

  return(sped)
}


#' Map NJ county names to 2-digit county ID codes
#'
#' @description Maps New Jersey county names to their standard 2-digit
#' numeric codes (01-21). NJ counties are numbered alphabetically.
#'
#' @param county_name Character vector of county names (case-insensitive).
#'
#' @return Character vector of 2-digit zero-padded county codes.
#'   Returns \code{NA_character_} for unrecognized names.
#'
#' @examples
#' county_name_to_id("ESSEX")
#' county_name_to_id(c("essex", "Hudson", "BERGEN"))
#'
#' @export
county_name_to_id <- function(county_name) {
  nj_counties <- c(
    "ATLANTIC" = "01", "BERGEN" = "02", "BURLINGTON" = "03", "CAMDEN" = "04",
    "CAPE MAY" = "05", "CUMBERLAND" = "06", "ESSEX" = "07", "GLOUCESTER" = "08",
    "HUDSON" = "09", "HUNTERDON" = "10", "MERCER" = "11", "MIDDLESEX" = "12",
    "MONMOUTH" = "13", "MORRIS" = "14", "OCEAN" = "15", "PASSAIC" = "16",
    "SALEM" = "17", "SOMERSET" = "18", "SUSSEX" = "19", "UNION" = "20",
    "WARREN" = "21"
  )
  unname(nj_counties[toupper(county_name)])
}


clean_sped_names <- function(df) {

  #data
  clean <- list(
    #preserve these
    "end_year" = "end_year",

    #disability category (2025+ State Rates sheet)
    "Disability Category" = "disability_category",

    #county ids
    "County" = "county_id",
    "COUNTY" = "county_id",
    "County Code" = "county_id",

    #district ids
    "District" = "district_id",
    "DISTRICT" = "district_id",
    "SUB_DIST" = "district_id",
    "District Code" = "district_id",

    #county name
    "county_name" = "county_name",
    "County Name" = "county_name",
    "COUNTYNAME" = "county_name",

    #district name
    "District Name" = "district_name",
    "DISTRICTNAME" = "district_name",
    "Districts                                 State Agency                            Charter School" = "district_name",

    #special ed count
    "Number Classified" = "sped_num",
    "Special Education Student Count" = "sped_num",
    "Special Ed Student Count" = "sped_num",
    "3-21 Clsfd" = "sped_num",
    "Special Ed. Enrollment" = "sped_num",
    "SPECED" = "sped_num",
    "3-21 Count" = "sped_num",
    "Count of Student with IEPs" = "sped_num",

    #special ed count no speech
    "Number Classified Without Speech" = "sped_num_no_speech",

    #gened count
    "Enrollment*" = "gened_num",
    "Gened" = "gened_num",
    "Enrollment" = "gened_num",
    "General Ed. Enrollment" = "gened_num",
    "GENED" = "gened_num",
    "LEA" = "gened_num",
    "All Students Count" = "gened_num",
    "Total Enrollment" = "gened_num",

    #special ed classification rate
    "Percent Classified" = "sped_rate",
    "Classification Rate" = "sped_rate",
    "Clsfd Rate" = "sped_rate",
    "CLASSIFICATION RATE" = "sped_rate",
    "District Classification Rate" = "sped_rate",

    #special ed classification rate no speech
    "Percent Classified Without Speech" = "sped_rate_no_speech"
  )

  names(df) <- map_chr(names(df), ~clean_name(.x, clean))

  return(df)

}


#' Clean SPED data
#'
#' @description Cleans and standardizes SPED data from NJ DOE.
#' @param df raw data frame with cleaned names, output of get_raw_sped with clean_sped_names applied.
#' @param end_year academic year, ending year - eg 2023-2024 is 2024.
#'
#' @return cleaned data frame
#' @export

clean_sped_df <- function(df, end_year) {

  # Coerce value columns to numeric. The 2025 "District Rates" sheet reads
  # the count/rate columns as character (a trailing "end of worksheet"
  # sentinel row forces text); pre-2025 sheets already parse as numeric, so
  # this is a no-op for those years.
  num_cols <- intersect(
    c("gened_num", "sped_num", "sped_rate",
      "sped_num_no_speech", "sped_rate_no_speech"),
    names(df)
  )
  for (nc in num_cols) {
    df[[nc]] <- suppressWarnings(as.numeric(df[[nc]]))
  }

  # Remove rows with missing enrollment data (footer / sentinel rows)
  df <- df %>% dplyr::filter(!is.na(gened_num))

  # Derive county_id from county_name when missing (historic data)
  if (!"county_id" %in% names(df) && "county_name" %in% names(df)) {
    df$county_id <- county_name_to_id(df$county_name)
  }

  # Return df with proper column order
  # Use any_of() to handle columns that may not exist in all years
  df %>%
    dplyr::select(
      dplyr::any_of(c(
        'end_year', 'county_id', 'county_name',
        'district_id', 'district_name',
        'gened_num', 'sped_num',
        'sped_rate',
        'sped_num_no_speech',
        'sped_rate_no_speech'
      ))
    )

}


#' Standardize NJ disability-category labels to cross-state snake_case
#'
#' Thin wrapper around \code{\link{standardize_sped_placement_subgroups}} that
#' additionally maps the "Statewide Total" rollup row to
#' \code{"all_disabilities"} (the cross-state convention for the all-students
#' disability rollup).
#'
#' @param x character vector of NJ disability-category labels
#' @return character vector of standardized \code{disability_category} values
#' @keywords internal
standardize_sped_disability_category <- function(x) {
  out <- standardize_sped_placement_subgroups(x)
  out[x %in% c("Statewide Total", "Total", "Statewide total")] <-
    "all_disabilities"
  out
}


#' Tidy the 2025+ "State Rates" by-disability sheet
#'
#' Reshapes the state-level child-count-by-disability table (NJ DOE IDEA 618
#' "State Rates" sheet) into a tidy frame with one row per disability
#' category. Counts are the Dec-1 child count of students with IEPs; the
#' published classification rate is stored as a 0-100 percent (the source
#' reports it as a decimal). The "Statewide Total" rollup row maps to
#' \code{disability_category == "all_disabilities"}.
#'
#' @param df cleaned data frame: output of get_raw_sped(level = "state")
#'   passed through clean_sped_names()
#' @param end_year ending school year
#' @return tidy tibble: end_year, is_state, disability_category, n_students,
#'   sped_rate, suppressed
#' @keywords internal
tidy_sped_state_disability <- function(df, end_year) {
  # clean_sped_names() maps the workbook's "Disability Category" header to
  # itself if unmapped; resolve the label column robustly.
  dis_col <- intersect(
    c("Disability Category", "disability_category"), names(df)
  )[1]
  if (is.na(dis_col)) {
    stop(
      "Could not find the Disability Category column in the State Rates sheet.",
      call. = FALSE
    )
  }

  raw_label <- df[[dis_col]]
  # Drop the "end of worksheet" sentinel and any blank label rows.
  keep <- !is.na(raw_label) &
    !grepl("^end of worksheet$", raw_label, ignore.case = TRUE)
  df <- df[keep, , drop = FALSE]
  raw_label <- raw_label[keep]

  n_students <- suppressWarnings(as.numeric(df[["sped_num"]]))
  # Source reports the classification rate as a decimal (0.0227 = 2.27%);
  # store on the same 0-100 scale used by the district output.
  sped_rate <- round(suppressWarnings(as.numeric(df[["sped_rate"]])) * 100, 2)

  tibble::tibble(
    end_year = end_year,
    is_state = TRUE,
    disability_category = standardize_sped_disability_category(raw_label),
    n_students = n_students,
    sped_rate = sped_rate,
    suppressed = is.na(n_students)
  )
}


#' Fetch Special Education Classification Data
#'
#' @description Fetches NJ DOE special education classification data (IDEA
#'   Section 618 public reporting). With \code{level = "district"} (default)
#'   returns the district-level total classification rate (the count of
#'   students with IEPs and the general-education enrollment denominator per
#'   district). With \code{level = "state"} returns the statewide count of
#'   students with IEPs by IDEA disability category (2025+ only).
#'
#'   Historical district data (2003-2019) is no longer accessible via URL and
#'   requires an OPRA request. For by-disability counts and educational
#'   placement (LRE) across 2020-2025, see \code{\link{fetch_sped_placement}}.
#'
#' @param end_year ending school year (e.g., 2025 for the 2024-2025 school
#'   year). Valid years: 2024, 2025.
#' @param level one of \code{"district"} (default) or \code{"state"}. The
#'   \code{"state"} by-disability table is only published for 2025+.
#'
#' @return For \code{level = "district"}: a data frame with columns end_year,
#'   county_id, county_name, district_id, district_name, gened_num, sped_num,
#'   sped_rate. For \code{level = "state"}: a tibble with columns end_year,
#'   is_state, disability_category, n_students, sped_rate, suppressed.
#'
#' @seealso \code{\link{fetch_sped_placement}} for IDEA 618 educational
#'   environment / placement data and multi-year by-disability counts.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # 1. District-level classification rates (default)
#' fetch_sped(2025)
#'
#' # 2. Filter to the highest-classification districts
#' library(dplyr)
#' fetch_sped(2025) %>%
#'   filter(gened_num > 1000) %>%
#'   arrange(desc(sped_rate)) %>%
#'   select(district_name, gened_num, sped_num, sped_rate)
#'
#' # 3. Statewide child count by disability category (2025+)
#' fetch_sped(2025, level = "state") %>%
#'   arrange(desc(n_students))
#' }
fetch_sped <- function(end_year, level = "district") {
  if (!level %in% c("district", "state")) {
    stop("level must be one of 'district' or 'state'.", call. = FALSE)
  }

  if (level == "state") {
    return(
      get_raw_sped(end_year, level = "state") %>%
        clean_sped_names() %>%
        tidy_sped_state_disability(end_year)
    )
  }

  get_raw_sped(end_year, level = "district") %>%
    clean_sped_names() %>%
    clean_sped_df(., end_year)
}