#' Friendly District Names
#'
#' @param df data.frame that contains district_id and district_name
#' @return character vector of names, one per district id
#' @keywords internal
friendly_district_names <- function(df) {
  
  # group by district id, tag by most recent year in df, take first
  df_first <- df %>% 
    group_by(district_id) %>% 
    arrange(-end_year) %>%
    mutate(count = row_number()) %>%
    ungroup() %>%
    filter(count == 1)
  
  # count unique districts per district_name
  name_count <- df_first %>%
    group_by(district_name) %>%
    summarize(
      n = n()
    )
  
  # if n > 1 put in county
  df_first <- df_first %>%
    left_join(name_count, by='district_name') %>%
    mutate(
      district_name = ifelse(
        n > 1, 
        paste0(district_name, ' (', county_name, ')'),
        district_name
      )
    )
  
  df_first$district_name %>%
    sort()
}


#' Given friendly district names, returns ids
#'
#' @param district_names vector or list of friendly district names
#' @param df df used to generate the friendly names
#'
#' @return vector of district_ids
#' @keywords internal
district_name_to_id <- function(district_names, df) {
  out <- df %>% 
    filter(district_name %in% district_names) %>%
    pull(district_id) %>%
    unique()
  # TODO: what about the collisions?
  
  out
}


#' Friendly School Names
#'
#' @param df data.frame that contains school_id and school_name
#' @return character vector of names, one per school id
#' @keywords internal
friendly_school_names <- function(df) {
  # group by district id, tag by most recent year in df, take first
  df_first <- df %>% 
    group_by(district_id, school_id) %>% 
    arrange(-end_year) %>%
    mutate(count = row_number()) %>%
    ungroup() %>%
    filter(count == 1)
  
  # count unique districts per district_name
  name_count <- df_first %>%
    group_by(school_name) %>%
    summarize(
      n = n()
    )
  
  # if n > 1 put in district
  df_first <- df_first %>%
    left_join(name_count, by='school_name') %>%
    mutate(
      school_name = ifelse(
        n > 1, 
        paste0(school_name, ' (', district_name, ')'),
        school_name
      )
    )
  
  df_first$school_name %>% sort()
}


#' Given friendly school names, returns ids
#'
#' @param school_names vector or list of friendly school names
#' @param df df used to generate the friendly names
#'
#' @return vector of school_ids
#' @keywords internal
school_name_to_id <- function(school_names, df) {
  out <- df %>% 
    filter(school_name %in% school_names) %>%
    pull(school_id) %>%
    unique()
  
  out
}



#' District Names to IDs
#'
#' @param district_names vector of names
#' @param lookup_df dataframe with district_id and district_name
#'
#' @return list of districtids matching the names
#' @keywords internal
id_selected_districtids <- function(district_names, lookup_df) {
  selected_districtids <- district_name_to_id(district_names, lookup_df)
  
  # charter aggs are a special case
  if (grepl('Charters', district_names) %>% any()) {
    #get the district ids
    selected_ids <- district_name_to_id(district_names, lookup_df)
    
    # strip the 'C'
    hosts <- gsub('C', '', selected_ids)
    
    # find the relevant charters via the hosts
    target_charters <- charter_city %>% 
      filter(host_district_id %in% hosts)
    
    relevant_charters <- lookup_df %>%
      dplyr::filter(
        is_school &
          district_id %in% target_charters$district_id
      )
    
    selected_districtids <- c(selected_districtids, unique(relevant_charters$district_id))
  }
  
  return(selected_districtids)
}