#' Friendly District Names
#'
#' @param df data.frame that contains district_id and district_name
#' @return character vector of names, one per district id
#' @export

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


#' Given friendly names, returns ids
#'
#' @param district_names vector or list of friendly district names
#' @param df df used to generate the friendly names
#'
#' @return vector of district_ids
#' @export

district_name_to_id <- function(district_names, df) {
  df %>% 
    filter(district_name %in% district_names) %>%
    pull(district_id) %>%
    unique()
}


