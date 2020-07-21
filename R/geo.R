#' Enrich School Data with Lat / Long
#'
#' @param df dataframe to be enriched
#' @param use_cache if TRUE, will read from cache of school info / lat lng stored on TODO
#' @param api_key optional, personal google maps API key
#'
#' @return dataframe enriched with lat lng
#' @export

enrich_school_latlong <- function(df, use_cache=TRUE, api_key='') {

  kill_padformulas <- function(x) {
    gsub('="', '', x, fixed=TRUE) %>%
      gsub('"', "", ., fixed=TRUE)
  }

  # download and clean
  nj_sch <- httr::GET('https://homeroom5.doe.state.nj.us/directory/schoolDL.php') %>%
    httr::content(as="text") %>%
    readr::read_csv(skip=3) %>%
    rename(
      district_id = `District Code`,
      school_id = `School Code`
    ) %>%
    clean_names() %>%
    select(
      district_id,
      school_id,
      address1,
      city,
      state,
      zip
    ) %>%
    mutate(
      district_id = kill_padformulas(district_id),
      school_id = kill_padformulas(school_id),
      zip = kill_padformulas(zip),
      address = paste0(address1, ', ', city, ', ', state, ' ', zip, ' USA'),
      address = gsub("\\s+", ' ', address)
    )

  # geocode
  if (use_cache) {
    data("geocoded_cached")
  } else {
    geocoded <- placement::geocode_url(
      nj_sch$address,
      auth='standard_api',
      privkey=api_key,
      clean=TRUE,
      verbose=TRUE
    )
  }

  geocoded_merge <- geocoded %>%
    select(locations, lat, lng) %>%
    rename(
      address = locations
    )
  nj_sch <- nj_sch %>%
    select(district_id, school_id, address) %>%
    left_join(geocoded_merge, by = 'address') %>%
    unique()

  # join on district and school and return
  df %>% left_join(nj_sch, by = c('district_id', 'school_id'))
}


#' Enrich School Data with City Ward
#'
#' @param df any dataframe with a district_id
#'
#' @return df enriched with ward, if geographic data is 'registered' for a given district
#' @export

enrich_school_city_ward <- function(df) {
  supported_geos <- c('3570')

  # say what fraction of the rows are supported
  supported <- df$district_id %in% supported_geos
  pct_supported <- supported %>%
    mean() %>%
    multiply_by(100) %>%
    round(1)

  message(
    paste0('ward information available for ', pct_supported,
           '% (', sum(supported), '/', length(supported),
           ') rows in this data set.')
  )
  # split into supported / unsupported
  geo_mask <- df$district_id %in% supported_geos
  latlong_mask <- !is.na(df$lat) & !is.na(df$lng)
  final_mask <- geo_mask & latlong_mask

  df_supported <- df %>%
     ungroup() %>%
     filter(final_mask)

  df_unsupported <- df %>%
     ungroup() %>%
     filter(!final_mask)

  # add specific geos here
  # newark (3570)
  if ('3570' %in% df$district_id) {
    newark_wards <- geojsonio::geojson_read(
      "http://data.ci.newark.nj.us/dataset/ba8f41a3-584b-4021-b8c3-30a7d1ae8ac3/resource/5b9c86cd-b57b-4341-8c4c-ee975d9e1904/download/wards2012.geojson",
      what = "sp"
    )
    newark_wards$WARD_NAME <- as.character(newark_wards$WARD_NAME)
    sp::coordinates(df_supported) <- ~lng+lat
    sp::proj4string(df_supported) <- sp::proj4string(newark_wards)

    df_supported$ward <- sp::over(df_supported, newark_wards)$WARD_NAME
    df_supported <- as_tibble(df_supported)
  }
  # combine and return
  bind_rows(df_supported, df_unsupported)
}


#' Aggregates enrollment data by ward
#'
#'
#' @param list_of_dfs output of \code{fetch_enr}
#'
#' @return A data frame of ward aggregations
#' @export

ward_enr_aggs <- function(df) {

  # enrich
  df <- enrich_school_latlong(df) %>%
    enrich_school_city_ward()

  df <- df %>%
    filter(!is.na(ward)) %>%
    group_by(
      end_year,
      county_id, county_name,
      district_id, district_name,
      ward,
      program_code, program_name, grade_level,
      subgroup
    ) %>%
    summarize(
      n_students = sum(n_students, na.rm = TRUE),
      n_schools = n()
    ) %>%
    ungroup()

  df <- df %>%
    mutate(
      CDS_Code = NA_character_,
      district_id = paste0(district_id, ' ', ward),
      district_name = paste0(district_name, ' ', ward),
      school_id = '999W',
      school_name = 'Ward Total',
      is_state = FALSE,
      is_county = FALSE,
      is_citywide = FALSE,
      is_district = FALSE,
      is_charter_sector = FALSE,
      is_allpublic = FALSE,
      is_school = FALSE,
      is_subprogram = !program_code == '55'
    ) %>%
    select(-ward)

  # calculate percent
  df <- agg_enr_pct_total(df)

  # column order and return
  agg_enr_column_order(df)
}

#' Aggregates assessment data by ward
#'
#'
#' @param list_of_dfs output of \code{fetch_all_parcc} or \code{fetch_parcc}
#'
#' @return A data frame of ward aggregations
#' @export

ward_parcc_aggs <- function(list_of_dfs) {

   df <- list_of_dfs %>%
      bind_rows() %>% # convert to df
      enrich_school_latlong() %>%
      enrich_school_city_ward()

   df <- df %>%
      filter(!is.na(ward)) %>%
      group_by(
         testing_year,
         assess_name, test_name,
         county_id, county_name,
         district_id, district_name,
         ward,
         grade,
         subgroup, subgroup_type
      ) %>%
     parcc_aggregate_calcs %>%
     ungroup()

   df <- df %>%
      mutate(
         district_id = paste0(district_id, ' ', ward),
         district_name = paste0(district_name, ' ', ward),
         school_id = '999W',
         school_name = 'Ward Total',
         is_state = FALSE,
         is_county = FALSE,
         is_citywide = FALSE,
         is_district = FALSE,
         is_charter_sector = FALSE,
         is_allpublic = FALSE,
         is_charter = FALSE,
         is_school = FALSE,
         is_dfg = (county_id == 'DFG')
      ) %>%
      select(-ward)

   return(df)
}

#' Aggregates assessment data by ward
#'
#'
#' @param list_of_dfs output of \code{fetch_all_parcc}, \code{fetch_parcc},
#' \code{calculate_agg_parcc_prof}
#'
#' @return A data frame of ward aggregations
#'
#'
#' @export
ward_parcc_aggs <- function(list_of_dfs) {
   
   df <- list_of_dfs %>%
      bind_rows() %>% # convert to df
      enrich_school_latlong() %>%
      enrich_school_city_ward()
   
   df <- df %>%
      filter(!is.na(ward) #,
             #subgroup == "special_education",
             #grade == 3,
             #test_name == "ela",
             #testing_year == 2018,
             #!is.na(number_of_valid_scale_scores)
             ) %>%
      group_by(
         testing_year,
         assess_name, test_name,
         county_id, county_name,
         district_id, district_name,
         ward,
         grade,
         subgroup, subgroup_type
      ) %>%
      summarize( # this should be replaced with parcc_aggregate_calcs()
         n_schools = n(), 
         number_enrolled = sum(number_enrolled, na.rm = T),
         number_not_tested = sum(number_not_tested, na.rm = T),
         scale_score_mean = sum(scale_score_mean * number_of_valid_scale_scores, na.rm = T) /
                            sum(number_of_valid_scale_scores, na.rm = T),
         number_of_valid_scale_scores = sum(number_of_valid_scale_scores, na.rm = T),
         num_l1 = sum(num_l1, na.rm = T),
         num_l2 = sum(num_l2, na.rm = T),
         num_l3 = sum(num_l3, na.rm = T),
         num_l4 = sum(num_l4, na.rm = T),
         num_l5 = sum(num_l5, na.rm = T),
         pct_l1 = 100 * num_l1 / sum(num_l1, num_l2, num_l3, num_l4, num_l5),
         pct_l2 = 100 * num_l2 / sum(num_l1, num_l2, num_l3, num_l4, num_l5),
         pct_l3 = 100 * num_l3 / sum(num_l1, num_l2, num_l3, num_l4, num_l5),
         pct_l4 = 100 * num_l4 / sum(num_l1, num_l2, num_l3, num_l4, num_l5),
         pct_l5 = 100 * num_l5 / sum(num_l1, num_l2, num_l3, num_l4, num_l5),
         proficient_above = pct_l4 + pct_l5
       ) %>%
      ungroup()
   
   df <- df %>%
      mutate(
         district_id = paste0(district_id, ' ', ward),
         district_name = paste0(district_name, ' ', ward),
         school_id = '999W',
         school_name = 'Ward Total',
         number_of_valid_scale_scores = if_else(is.na(scale_score_mean), NA_real_, 
                                                number_of_valid_scale_scores),
         num_l1 = if_else(is.na(scale_score_mean), NA_real_, num_l1),
         num_l2 = if_else(is.na(scale_score_mean), NA_real_, num_l2),
         num_l3 = if_else(is.na(scale_score_mean), NA_real_, num_l3),
         num_l4 = if_else(is.na(scale_score_mean), NA_real_, num_l4),
         num_l5 = if_else(is.na(scale_score_mean), NA_real_, num_l5),
         is_state = FALSE,
         is_county = FALSE,
         is_citywide = FALSE,
         is_district = FALSE,
         is_charter_sector = FALSE,
         is_allpublic = FALSE,
         is_charter = FALSE,
         is_school = FALSE,
         is_dfg = (county_id == 'DFG')
      ) %>%
      select(-ward)
   
   return(df)
}



#' Aggregates grad rate data by ward
#'
#'
#' @param df output of \code{fetch_grad_rate}
#'
#' @return A data frame of ward aggregations
#'
#'
#' @export
ward_grate_aggs <- function(df) {
  enriched_df <- df %>%
    enrich_school_latlong() %>%
    enrich_school_city_ward()
  
  ward_df <- enriched_df %>% 
    filter(!is.na(ward)) %>%
    group_by(
      end_year,
      county_id, county_name,
      district_id, district_name,
      ward,
      subgroup, 
      methodology
    ) %>%
    grate_aggregate_calcs() %>%
    ungroup()
  
  ward_df %>%
    mutate(
      district_id = paste0(district_id, ' ', ward),
      district_name = paste0(district_name, ' ', ward),
      school_id = '999W',
      school_name = 'Ward Total',
      is_state = FALSE,
      is_county = FALSE,
      is_district = FALSE,
      is_charter = FALSE,
      is_school = FALSE,      
      is_charter_sector = FALSE,
      is_allpublic = FALSE
    ) %>%
    grate_column_order() %>%
    return()
}



#' Aggregates grad counts data by ward
#'
#'
#' @param df output of \code{fetch_grad_count}
#'
#' @return A data frame of ward aggregations
#'
#'
#' @export
ward_gcount_aggs <- function(df) {
  enriched_df <- df %>%
    enrich_school_latlong() %>%
    enrich_school_city_ward()
  
  ward_df <- enriched_df %>% 
    filter(!is.na(ward)) %>%
    group_by(
      end_year,
      county_id, county_name,
      district_id, district_name,
      ward,
      subgroup
    ) %>%
    gcount_aggregate_calcs() %>%
    ungroup()
  
  ward_df %>%
    mutate(
      district_id = paste0(district_id, ' ', ward),
      district_name = paste0(district_name, ' ', ward),
      school_id = '999W',
      school_name = 'Ward Total',
      is_state = FALSE,
      is_county = FALSE,
      is_district = FALSE,
      is_charter = FALSE,
      is_school = FALSE,      
      is_charter_sector = FALSE,
      is_allpublic = FALSE
    ) %>%
    gcount_column_order() %>%
    return()
}
