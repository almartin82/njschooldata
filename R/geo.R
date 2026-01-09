#' Enrich School Data with Lat / Long
#'
#' @param df dataframe to be enriched
#' @param use_cache if TRUE, will read from cache of school info / lat lng stored on TODO
#' @param api_key optional, personal google maps API key
#'
#' @return dataframe enriched with lat lng
#' @export

enrich_school_latlong <- function(df, use_cache=TRUE, api_key='') {

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
      address = paste0(address1, ', ', city, ', ', state, ' ', zip, ' USA')
      )
  
  
  # Load Newark address addendum from package data
  nwk_address_addendum <- NULL
  utils::data("nwk_address_addendum", package = "njschooldata", envir = environment())

  old_nwk_addresses <- nwk_address_addendum %>%
    dplyr::mutate(
      school_id = stringr::str_pad(school_id, 3, pad = '0')
    )

  # geocode
  if (use_cache) {
    geocoded_cached <- NULL
    utils::data("geocoded_cached", package = "njschooldata", envir = environment())
    geocoded <- geocoded_cached
  } else {
    if (!requireNamespace("placement", quietly = TRUE)) {
      stop("Package 'placement' is required for geocoding. Install with: remotes::install_github('DerekYves/placement')")
    }
    geocode_url <- utils::getExportedValue("placement", "geocode_url")
    geocoded <- geocode_url(
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
    ) %>%
    mutate(address = str_to_lower(address),
           address = str_replace(address, "-\\d{4}\\susa", " usa"))
  
  nj_sch <- nj_sch %>%
    bind_rows(old_nwk_addresses) %>%
    mutate(
      address = gsub("\\s+", ' ', address),
      address = str_to_lower(address),
      address = str_replace_all(address, "-\\d{4}\\susa", " usa"),
      address_2 = case_when(
        str_detect(address, "street") ~ str_replace(address, "street", "st"),
        str_detect(address, "avenue") ~ str_replace(address, "avenue", "ave"),
        str_detect(address, "boulevard") ~ str_replace(address, "boulevard", "blvd"),
        TRUE ~ address),
      address_3 = case_when(
        str_detect(address, "ave,") ~ str_replace(address, "ave,", "avenue,"),
        str_detect(address, "st,") ~ str_replace(address, "st,", "street,"),
        str_detect(address, "blvd,") ~ str_replace(address, "blvd,", "boulevard,"),
        TRUE ~ address1)
    ) %>%
    select(district_id, school_id, address, address_2, address_3) %>%
    left_join(geocoded_merge, by = 'address') %>%
    left_join(geocoded_merge, by = c('address_2' = 'address')) %>%
    left_join(geocoded_merge, by = c('address_3' = 'address')) %>%
    mutate(lat = coalesce(lat.x, lat.y, lat),
           lng = coalesce(lng.x, lng.y, lng)) %>%
    select(district_id, school_id, address, lat, lng) %>%
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
    if (!requireNamespace("geojsonio", quietly = TRUE)) {
      stop("Package 'geojsonio' is required for ward enrichment. Install it with: install.packages('geojsonio')")
    }
    if (!requireNamespace("sp", quietly = TRUE)) {
      stop("Package 'sp' is required for ward enrichment. Install it with: install.packages('sp')")
    }
    newark_wards <- geojsonio::geojson_read(
      "http://data.ci.newark.nj.us/dataset/ba8f41a3-584b-4021-b8c3-30a7d1ae8ac3/resource/5b9c86cd-b57b-4341-8c4c-ee975d9e1904/download/wards2012.geojson",
      what = "sp"
    )
    newark_wards$WARD_NAME <- as.character(newark_wards$WARD_NAME)
    sp::coordinates(df_supported) <- ~lng+lat
    sp::proj4string(df_supported) <- sp::proj4string(newark_wards)

    df_supported$ward <- sp::over(df_supported, newark_wards)$WARD_NAME
    df_supported <- tibble::as_tibble(df_supported)
  }
  # combine and return
  bind_rows(df_supported, df_unsupported)
}


#' Aggregates enrollment data by ward
#'
#'
#' @param df data frame containing enrollment data
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
     parcc_aggregate_calcs() %>%
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

#' Aggregates matriculation data by ward
#'
#'
#' @param df output of \code{enrich_matric_counts}
#'
#' @return A data frame of ward aggregations
#' @export
ward_matric_aggs <- function(df) {
  enriched_df <- df %>%
    enrich_school_latlong() %>%
    enrich_school_city_ward()
  
  ward_df <- enriched_df %>% 
    filter(!is.na(ward), 
           !is.na(enroll_any)) %>%
    group_by(
      end_year,
      county_id, county_name,
      district_id, district_name,
      ward,
      subgroup,
      is_16mo
    ) %>%
    matric_aggregate_calcs() %>%
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
    matric_column_order() %>%
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