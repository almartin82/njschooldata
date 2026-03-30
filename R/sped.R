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
  # New URL structure (2024+)
  # Uses academic year format: 2023-2024 data = "2324"
  year_suffix <- paste0(
    substr(as.character(end_year - 1), 3, 4),
    substr(as.character(end_year), 3, 4)
  )

  paste0(
    "https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/",
    end_year - 1, "_618data/DistrictWide_ClassificationRate_",
    year_suffix, "_public.xlsx"
  )
}


#' read Special ed excel files from the NJ state website
#'
#' @inheritParams get_raw_enr
#'
#' @return a dataframe with special ed counts, etc.
#' @keywords internal
get_raw_sped <- function(end_year) {
  valid_years <- get_valid_sped_years()

  if (!end_year %in% valid_years) {
    stop(paste0(
      end_year, " is not a valid end_year for SPED data. ",
      "Valid years are: ", paste(valid_years, collapse = ", "), ". ",
      "Historical data (2003-2019) is no longer available from NJ DOE. ",
      "Data prior to 2014 requires an OPRA request."
    ))
  }

  sped_url <- build_sped_url(end_year)

  # Check URL accessibility before attempting download
  if (!check_url_accessible(sped_url)) {
    stop(paste0("SPED data URL is not accessible: ", sped_url))
  }

  # New format (2024+) has 3 header rows
  rows_to_skip <- 3

  tf <- tempfile(fileext = ".xlsx")
  utils::download.file(sped_url, tf, mode = 'wb', quiet = TRUE)

  sped <- readxl::read_excel(
    tf,
    skip = rows_to_skip,
    na = c('-', '*', 'N', 'S')
  )

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

    #special ed classification rate
    "Percent Classified" = "sped_rate",
    "Classification Rate" = "sped_rate",
    "Clsfd Rate" = "sped_rate",
    "CLASSIFICATION RATE" = "sped_rate",

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

  # Remove rows with missing enrollment data (footer rows)
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


#' Fetch Special Education Classification Data
#'
#' @description Fetches special education classification rate data from NJ DOE.
#' As of 2024, only current data is available. Historical data (2003-2019) is no
#' longer accessible via URL and requires an OPRA request.
#'
#' @param end_year ending school year (e.g., 2024 for 2023-2024 school year).
#'   Valid years: 2024+
#'
#' @return cleaned sped dataframe with columns: end_year, county_id, county_name,
#'   district_id, district_name, gened_num, sped_num, sped_rate
#' @export

fetch_sped <- function(end_year) {
  get_raw_sped(end_year) %>%
    clean_sped_names() %>%
    clean_sped_df(., end_year)
}