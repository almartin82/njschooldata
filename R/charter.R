
#' Identify charter host districts
#'
#' @param df dataframe of NJ school data containing `district_id` column
#'
#' @return df with host district id and name for every matching record
#' @export

id_charter_hosts <- function(df) {
  ensure_that(
    df, 'district_id' %in% names(.) ~ 
      "supplied dataframe must contain a column called ''district_id'"
  )
  
  df_new <- df %>%
    left_join(charter_city %>% select(-district_name), by = 'district_id')

  ensure_that(
    df, nrow(.) == nrow(df_new) ~ 'joining to the charter hosts data set changed the size of your input dataframe.  this could be an issue with the `charter_city` dataframe included in this package.'
  )
  
  return(df_new)
}

foo <- function() {
  
  north_star <- ex_2018[grepl('North Star', ex_2018$district_name), ]
  id_charter_hosts(north_star) %>%
    head() %>%
    print.AsIs()
  
}