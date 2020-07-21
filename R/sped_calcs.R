#' Aggregate multiple sped rows and produce summary statistics
#'
#' @param df grouped df of sped data
#'
#' @return df with aggregate stats for whatever grouping was provided
#' @export

sped_aggregate_calcs <- function(df) {
   
   df %>%
      summarize_at(
         vars(one_of("gened_num",
                     "sped_num",
                     "sped_num_no_speech",
                     "is_charter")), sum, na.rm = TRUE
      ) %>%
      rename(n_charter_rows = is_charter) %>%
      mutate(sped_rate = round(sped_num / gened_num * 100, 2) #, 
             ##### not totally sure why my version of dplyr 1.0.0 doesn't 
             ##### export across()
             #dplyr::across(one_of("sped_num_no_speech"),
             #       .fns = list(sped_rate_no_speech = round(. * 100, 2)))
      ) %>%
      mutate_at(
         vars(one_of("sped_num_no_speech")), 
         .funs = list(sped_rate_no_speech = ~ round(. / gened_num * 100, 2))
      ) %>%
      return()
}


#' Helper function to return aggregate sped columns in correct order
#'
#' @param df aggregate sped dataframe
#'
#' @return data.frame
#' @export
agg_sped_column_order <- function(df) {
   df %>%
      select(
         one_of(
            "end_year", "county_name", "district_id", "district_name",
            "gened_num", "sped_num", "sped_rate", "sped_num_no_speech",
            "sped_rate_no_speech"
         )
      )%>%
      return()
}