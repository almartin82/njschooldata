#' Identify charter host districts
#'
#' @param df dataframe of NJ school data containing `district_id` column
#'
#' @return df with host district id and name for every matching record
#' @export

id_charter_hosts <- function(df) {
  ensure_that(
    df, 'district_id' %in% names(.) | 'district_code' %in% names(.) ~ 
      "supplied dataframe must contain 'district_id' or 'district_code'"
  )
  
  charter_city_slim <- charter_city %>% select(-district_name)
  
  if ('district_id' %in% names(df)) {
    df_new <- df %>% left_join(charter_city_slim, by = 'district_id')
  } else if ('district_code' %in% names(df)) {
    names(charter_city_slim)[1] <- 'district_code'
    df_new <- df %>% left_join(charter_city_slim, by = 'district_code')
  }

  ensure_that(
    df, nrow(.) == nrow(df_new) ~ 'joining to the charter hosts data set changed the size of your input dataframe.  this could be an issue with the `charter_city` dataframe included in this package.'
  )
  
  return(df_new)
}


#' Calculate Charter Sector Enrollment Aggregates
#'
#' @param df a tidied enrollment dataframe, eg output of `fetch_enr`
#'
#' @return dataframe with charter sector aggregates per host city
#' @export

charter_sector_enr_aggs <- function(df) {

  df <- enr_2018 %>% filter(county_id == '80' & !district_id=='9999')
  
  # id hosts 
  df <- id_charter_hosts(df)
  
  # charters are reported twice, one per school one per district
  # take the district level only, in the hopes that NJ will 
  # someday fix this and report charter campuses
  df <- df %>% filter(school_id == '999')
  
  # group by - host city and summarize
  df <- df %>% 
    ungroup() %>%
    group_by(
      end_year, 
      county_id, county_name,
      host_district_id, host_district_name,
      program_code, program_name, grade_level,
      subgroup
    ) %>%
    summarize(
      n_students = sum(n_students),
      n_schools = n()
    ) %>%
    ungroup()
  
  # calculate percent
  
  # give psuedo district names and codes
  sample_n(df, 5) %>% print.AsIs()
  
  # create appropriate boolean flag
  
  # column order and return

}


citywide_enr_aggs <- function(df) {
  # id hosts 
  
  # group by - host city
  
  # sum
  
  # give psuedo district names and codes
  
  # create appropriate boolean flag
  
  # column order and return
  
}
