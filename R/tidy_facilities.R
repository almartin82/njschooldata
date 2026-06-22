# ==============================================================================
# Facilities Data - canonical schema assembly
# ==============================================================================

#' Canonical facilities long-schema columns
#'
#' @return Character vector of canonical column names.
#' @keywords internal
facilities_columns <- function() {
  c("category", "entity_level", "entity_id", "entity_name", "metric", "value",
    "unit", "source_agency", "source_type", "source_url", "vintage",
    "nces_dist", "nces_sch")
}

#' Full facilities category vocabulary
#'
#' Geometry is served by \code{\link{fetch_facility_gis}} and is not a category.
#'
#' @return Character vector of facilities categories.
#' @keywords internal
facilities_categories <- function() {
  c("inventory", "attributes", "capacity", "condition", "capital_needs",
    "projects", "finance", "environmental", "closures")
}

#' Shipped facilities categories for New Jersey
#'
#' @return Character vector of categories backed by verified public sources.
#' @keywords internal
facilities_available_categories <- function() {
  names(facilities_category_sources())
}

#' Attach NCES ids where facilities rows carry exact NJ CDS ids
#'
#' Federal identifiers are join keys only; unmatched rows stay NA.
#'
#' @param long Facilities long data before dropping internal id columns.
#' @return Facilities long data with \code{nces_dist} and \code{nces_sch}.
#' @keywords internal
attach_facilities_nces <- function(long) {
  long$nces_dist <- NA_character_
  long$nces_sch <- NA_character_

  xwalk_path <- system.file(
    "extdata", "crosswalk", "nj_nces_crosswalk.csv",
    package = "njschooldata"
  )
  if (!nzchar(xwalk_path)) {
    xwalk_path <- file.path("inst", "extdata", "crosswalk", "nj_nces_crosswalk.csv")
  }
  if (!file.exists(xwalk_path)) return(long)

  xwalk <- utils::read.csv(xwalk_path, colClasses = "character",
                           stringsAsFactors = FALSE)
  for (col in c(".county_id", ".district_id", ".school_id")) {
    if (!col %in% names(long)) long[[col]] <- NA_character_
  }

  dist_map <- xwalk[xwalk$entity_level == "District", , drop = FALSE]
  dist_key <- paste(dist_map$county_id, dist_map$district_id, sep = "-")
  long_key <- paste(long$.county_id, long$.district_id, sep = "-")
  dist_idx <- match(long_key, dist_key)
  can_have_dist <- long$entity_level %in% c("district", "school")
  long$nces_dist[can_have_dist] <- dist_map$nces_dist[dist_idx[can_have_dist]]

  school_map <- xwalk[xwalk$entity_level == "School", , drop = FALSE]
  school_key <- paste(school_map$county_id, school_map$district_id,
                      school_map$school_id, sep = "-")
  long_school_key <- paste(long$.county_id, long$.district_id, long$.school_id,
                           sep = "-")
  school_idx <- match(long_school_key, school_key)
  can_have_school <- long$entity_level == "school"
  long$nces_sch[can_have_school] <- school_map$nces_sch[school_idx[can_have_school]]

  long$nces_dist[long$nces_dist == ""] <- NA_character_
  long$nces_sch[long$nces_sch == ""] <- NA_character_
  long
}

#' Tidy processed facilities rows into the canonical long schema
#'
#' @param processed_list List of processed facilities long frames.
#' @return Data frame with \code{facilities_columns()}.
#' @keywords internal
tidy_facilities <- function(processed_list) {
  if (!length(processed_list)) {
    empty <- as.data.frame(
      stats::setNames(replicate(length(facilities_columns()), character(),
                                simplify = FALSE), facilities_columns()),
      stringsAsFactors = FALSE
    )
    return(empty)
  }

  long <- do.call(rbind, c(processed_list, list(make.row.names = FALSE)))
  if (is.null(long) || !nrow(long)) {
    empty <- as.data.frame(
      stats::setNames(replicate(length(facilities_columns()), character(),
                                simplify = FALSE), facilities_columns()),
      stringsAsFactors = FALSE
    )
    return(empty)
  }

  long <- attach_facilities_nces(long)
  internal <- intersect(c(".county_id", ".district_id", ".school_id"), names(long))
  long[internal] <- NULL
  long <- long[, facilities_columns(), drop = FALSE]
  rownames(long) <- NULL
  long
}
