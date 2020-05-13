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
    filter(final_mask)
    
  df_unsupported <- df %>%
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



