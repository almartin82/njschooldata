#' Get NJ District Directory Data
#'
#' @return dataframe of districts and associated metadata
#' @export

get_district_directory <- function() {

  dir_url = "https://homeroom4.doe.state.nj.us/public/districtpublicschools/download/"
  nj_dist <- readr::read_csv(dir_url, skip = 3) %>%
    janitor::clean_names() %>%
    dplyr::mutate(
      address = paste0(address1, ', ', city, ', ', state, ' ', zip)
    ) %>%
    dplyr::rename(
      county_id = county_code,
      district_id = district_code
    ) %>%
    dplyr::mutate(
      CDS_Code = paste0(county_id, district_id, '999')
    ) %>%
    # Ensure UTF-8 encoding for all character columns (fixes rpy2 conversion issues)
    dplyr::mutate(dplyr::across(dplyr::where(is.character), ~iconv(.x, to = "UTF-8", sub = "")))

  nj_dist
}


#' Get NJ School Directory Data
#'
#' @return dataframe of schools and associated metadata
#' @export

get_school_directory <- function() {

  dir_url = "https://homeroom4.doe.state.nj.us/public/publicschools/download/"
  nj_sch <- readr::read_csv(dir_url, skip = 3) %>%
    janitor::clean_names() %>%
    dplyr::mutate(
      address = paste0(address1, ', ', city, ', ', state, ' ', zip)
    ) %>%
    dplyr::rename(
      county_id = county_code,
      district_id = district_code,
      school_id = school_code
    ) %>%
    dplyr::mutate(
      CDS_Code = paste0(county_id, district_id, school_id)
    ) %>%
    # Ensure UTF-8 encoding for all character columns (fixes rpy2 conversion issues)
    dplyr::mutate(dplyr::across(dplyr::where(is.character), ~iconv(.x, to = "UTF-8", sub = "")))

  nj_sch
}
