#' Enrich School Data with Lat / Long
#'
#' @param df dataframe to be enriched 
#' @param use_cache if TRUE, will read from cache of school info / lat lng stored on TODO
#' @param api_key optional, personal google maps API key
#'
#' @return
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
      address = paste0(address1, ', ', city, ', ', state, ' ', zip, ' USA')
    )
  
  # geocode
  if (use_cache) {
    geocoded <- geocoded_cached
  } else {
    geocoded <- placement::geocode_url(
      nj_sch$address, 
      auth='standard_api', 
      privkey=api_key, 
      clean=TRUE, 
      verbose=TRUE
    )
  }
  
  nj_sch$lat <- geocoded$lat
  nj_sch$lng <- geocoded$lng
  
  # join on district and school and return
  df %>% left_join(by = c('district_id', 'school_id'))
}


#' Title
#'
#' @param df 
#'
#' @return
#' @export

enrich_school_city_ward <- function(df) {
  supported_geos <- c('3570')
  
  # say what fraction of the rows are supported
  
  # split into supported / unsupported
  
  # newark (3570)
  if ('3570' %in% df$district_id) {
    newark_wards <- geojsonio::geojson_read(
      "http://data.ci.newark.nj.us/dataset/ba8f41a3-584b-4021-b8c3-30a7d1ae8ac3/resource/5b9c86cd-b57b-4341-8c4c-ee975d9e1904/download/wards2012.geojson",
      what = "sp"
    )
  }
  
  sp::coordinates(df) <- ~lng+lat
  sp::proj4string(df) <- sp::proj4string(newark_wards)
  
  rgeos::gWithin(countyDF, basinDF, byid = TRUE)
  

  
  # combine and return
}


#' Title
#'
#' @param df 
#'
#' @return
#' @export

enrich_school_city_neighborhood <- function(df) {
  
}

woo <- function() {
  
  
  tmp_schooldl = tempfile(fileext = '.xls')
  httr::GET(
    'https://homeroom5.doe.state.nj.us/directory/schoolDL.php', 
    write_disk(tmp_schooldl)
  )
  nj_sch <- readxl::read_excel(tmp_schooldl, skip=3)
  
  
  foo <- get_one_rc_database(2018)
  names(foo)

  
  foo06 <- get_one_rc_database(2006)
  names(foo06)
  
  kill_padformulas <- function(df, col) {
    df[, col] <- gsub('="', '', df[, col], fixed=TRUE)
    df[, col] <- gsub('"', "", df[, col], fixed=TRUE)
    df
  }
  
  
}
