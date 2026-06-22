# ==============================================================================
# Facilities Data - GIS companion
# ==============================================================================

#' Internal: shipped New Jersey facilities GIS layers
#' @keywords internal
facility_gis_layers <- function() {
  c("school_points")
}

#' Fetch New Jersey school facility geometry
#'
#' Spatial companion to [fetch_facilities()]. Returns NJGIN school points as an
#' `sf` object when `sf` is installed and `sf = TRUE`; otherwise returns a data
#' frame with latitude, longitude, and WKT.
#'
#' @param layer GIS layer. Currently `"school_points"`.
#' @param sf If TRUE, return an `sf` object when the `sf` package is installed.
#'   If FALSE, always return a data frame.
#' @param use_cache If TRUE (default), use cached source downloads when fresh.
#' @return An `sf` object or data frame with `latitude`, `longitude`, and `wkt`.
#' @export
#' @examples
#' \dontrun{
#' points <- fetch_facility_gis("school_points")
#' points_df <- fetch_facility_gis("school_points", sf = FALSE)
#' }
fetch_facility_gis <- function(layer = "school_points", sf = TRUE,
                               use_cache = TRUE) {
  valid <- facility_gis_layers()
  if (length(layer) != 1 || !layer %in% valid) {
    stop(
      "Invalid layer: ", as.character(layer)[1],
      "\nValid layers: ", paste(valid, collapse = ", "),
      call. = FALSE
    )
  }

  raw <- switch(
    layer,
    school_points = get_raw_facilities("njgin_school_points", use_cache = use_cache)
  )

  lon <- suppressWarnings(as.numeric(raw$.longitude))
  lat <- suppressWarnings(as.numeric(raw$.latitude))
  entity_id <- ifelse(
    !is.na(raw$OGIS_ID) & raw$OGIS_ID != "",
    as.character(raw$OGIS_ID),
    paste(raw$COUNTYCODE, raw$DIST_CODE, raw$SCHOOLCODE, sep = "-")
  )
  entity_name <- ifelse(
    !is.na(raw$SCHOOLNAME) & raw$SCHOOLNAME != "",
    as.character(raw$SCHOOLNAME),
    as.character(raw$SCHOOL)
  )

  df <- data.frame(
    entity_id = entity_id,
    entity_name = entity_name,
    county = as.character(raw$COUNTY),
    district_id = as.character(raw$DIST_CODE),
    district_name = as.character(raw$DIST_NAME),
    school_id = as.character(raw$SCHOOLCODE),
    school_type = as.character(raw$SCHOOLTYPE),
    street_address = as.character(raw$ADDRESS1),
    city = as.character(raw$CITY),
    state = as.character(raw$STATE),
    zip = as.character(raw$ZIP),
    latitude = lat,
    longitude = lon,
    source_agency = facilities_sources()$njgin_school_points$agency,
    source_url = facilities_sources()$njgin_school_points$url,
    stringsAsFactors = FALSE
  )
  df$wkt <- ifelse(
    is.na(df$longitude) | is.na(df$latitude),
    NA_character_,
    sprintf("POINT (%s %s)", df$longitude, df$latitude)
  )

  if (isTRUE(sf) && requireNamespace("sf", quietly = TRUE)) {
    keep <- !is.na(df$longitude) & !is.na(df$latitude)
    return(sf::st_as_sf(
      df[keep, , drop = FALSE],
      coords = c("longitude", "latitude"),
      crs = 4326,
      remove = FALSE
    ))
  }

  if (isTRUE(sf) && !requireNamespace("sf", quietly = TRUE)) {
    message(
      "Package 'sf' is not installed; returning a data frame with ",
      "latitude/longitude/wkt. Install sf for an sf object."
    )
  }
  df
}
