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


citywide_charter_aggs <- function(df) {
  # id hosts 
  
  # group by - host city
  
  # sum
  
  # give psuedo district names and codes
  
  # create appropriate boolean flag
  
  # column order and return

}


citywide_all_public_aggs <- function(df) {
  # id hosts 
  
  # group by - host city
  
  # sum
  
  # give psuedo district names and codes
  
  # create appropriate boolean flag
  
  # column order and return
  
}
