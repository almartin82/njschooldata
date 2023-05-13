#' Get NJ District Directory Data
#'
#' @return dataframe of districts and associated metadata
#' @export

get_district_directory <- function() {

  dir_stem <- "https://homeroom5.doe.state.nj.us/directory/"
  nj_dist <- httr::GET(paste0(dir_stem, "districtDL.php")) %>%
    httr::content(as = "text") %>%
    readr::read_csv(skip = 3) %>%
    clean_names() %>%
    dplyr::mutate(
      across(.fns = kill_padformulas)
    ) %>%
    dplyr::mutate(
      address = paste0(address1, ', ', city, ', ', state, ' ', zip)
    ) %>%
    dplyr::rename(
      county_id = county_code,
      district_id = district_code
    ) %>%
    dplyr::mutate(
      CDS_Code = paste0(county_id, district_id, '999')
    )
  
  nj_dist
}


#' Get NJ School Directory Data
#'
#' @return dataframe of schools and associated metadata
#' @export

get_school_directory <- function() {
  
  dir_stem <- "https://homeroom5.doe.state.nj.us/directory/"
  nj_sch <- httr::GET(paste0(dir_stem, "schoolDL.php")) %>%
    httr::content(as = "text") %>%
    readr::read_csv(skip = 3) %>%
    clean_names() %>%
    mutate(
      across(.fns = kill_padformulas)
    ) %>%
    mutate(
      address = paste0(address1, ', ', city, ', ', state, ' ', zip)
    ) %>%
    rename(
      county_id = county_code,
      district_id = district_code,
      school_id = school_code
    ) %>%
    mutate(
      CDS_Code = paste0(county_id, district_id, school_id)
    )
  
  nj_sch
}
