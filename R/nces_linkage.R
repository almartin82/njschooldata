# ==============================================================================
# Federal NCES identifier linkage
# ==============================================================================
#
# Attaches the federal NCES 7-digit `LEAID` (`nces_dist`) and 12-digit `NCESSCH`
# (`nces_sch`) to NJ enrollment, keyed on the state's County-District-School
# (CDS) code. The mapping is a bundled, identifiers-only crosswalk
# (`inst/extdata/crosswalk/nj_nces_crosswalk.csv`); see that file's README and
# `data-raw/build_nces_crosswalk.R` for provenance. No enrollment or performance
# VALUES come from a federal source — only the join keys.
#
# ==============================================================================

#' Load the bundled NJ CDS -> NCES crosswalk
#'
#' Reads the identifiers-only crosswalk shipped in
#' \code{inst/extdata/crosswalk/nj_nces_crosswalk.csv}. All columns are returned
#' as character so the CDS codes keep their zero-padding.
#'
#' @return A data frame with columns \code{entity_level}, \code{county_id},
#'   \code{district_id}, \code{school_id}, \code{nces_dist}, \code{nces_sch}.
#' @keywords internal
load_nces_crosswalk <- function() {
  path <- system.file(
    "extdata", "crosswalk", "nj_nces_crosswalk.csv",
    package = "njschooldata"
  )
  if (!nzchar(path) || !file.exists(path)) {
    stop("NCES crosswalk not found in the installed package.", call. = FALSE)
  }
  utils::read.csv(path, colClasses = "character", stringsAsFactors = FALSE)
}


#' Attach federal NCES ids to an enrollment data frame
#'
#' Adds two columns to (wide or tidy) enrollment data:
#' \itemize{
#'   \item \code{nces_dist} — the 7-digit NCES \code{LEAID} for the district,
#'     attached to district rows (\code{school_id == "999"}) and school rows.
#'   \item \code{nces_sch} — the 12-digit NCES \code{NCESSCH} for the school,
#'     attached to school rows only (\code{NA} for district/state rows).
#' }
#'
#' The join is exact, on the NJ County-District-School (CDS) code. Entities not
#' present in the bundled crosswalk (new/closed/charter additions, state and
#' county aggregate rows) keep \code{NA} — an id is never fabricated or guessed.
#'
#' @param df An enrollment data frame carrying \code{county_id},
#'   \code{district_id}, and \code{school_id} (wide output of
#'   \code{\link{fetch_enr}} or tidy output of \code{\link{tidy_enr}}).
#' @return \code{df} with \code{nces_dist} and \code{nces_sch} columns added.
#' @export
#' @examples
#' \dontrun{
#' # wide enrollment with NCES ids
#' enr <- fetch_enr(2024)
#' dplyr::distinct(enr, district_id, district_name, nces_dist)
#'
#' # tidy enrollment also carries the ids
#' enr_tidy <- fetch_enr(2024, tidy = TRUE)
#' dplyr::filter(enr_tidy, is_school, !is.na(nces_sch))
#' }
attach_nces_ids <- function(df) {
  required <- c("county_id", "district_id", "school_id")
  if (!all(required %in% names(df))) {
    return(df)
  }

  xwalk <- load_nces_crosswalk()

  # Capture-and-drop any pre-existing id columns so a re-run never produces
  # .x/.y suffixes, then coalesce the incoming values back in.
  prior_dist <- if ("nces_dist" %in% names(df)) df[["nces_dist"]] else NULL
  prior_sch  <- if ("nces_sch" %in% names(df)) df[["nces_sch"]] else NULL
  df[["nces_dist"]] <- NULL
  df[["nces_sch"]] <- NULL

  # District-level map: (county_id, district_id) -> nces_dist. This LEAID is
  # attached to BOTH the district aggregate rows and that district's schools.
  dist_map <- xwalk[xwalk$entity_level == "District", , drop = FALSE]
  dist_map <- dist_map[!is.na(dist_map$nces_dist) & nchar(dist_map$nces_dist) == 7, ]
  dist_map <- unique(dist_map[, c("county_id", "district_id", "nces_dist")])

  # School-level map: (county_id, district_id, school_id) -> nces_sch.
  sch_map <- xwalk[xwalk$entity_level == "School", , drop = FALSE]
  sch_map <- sch_map[!is.na(sch_map$nces_sch) & nchar(sch_map$nces_sch) == 12, ]
  sch_map <- unique(sch_map[, c("county_id", "district_id", "school_id", "nces_sch")])

  df <- dplyr::left_join(df, dist_map, by = c("county_id", "district_id"))
  df <- dplyr::left_join(df, sch_map, by = c("county_id", "district_id", "school_id"))

  # nces_dist on district aggregate rows (school_id == "999") and school rows
  # is correct; on state/county aggregate rows it should stay NA.
  is_state_row  <- df$district_id == "9999"
  df$nces_dist[is_state_row] <- NA_character_

  if (!is.null(prior_dist)) {
    df$nces_dist <- dplyr::coalesce(df$nces_dist, prior_dist)
  }
  if (!is.null(prior_sch)) {
    df$nces_sch <- dplyr::coalesce(df$nces_sch, prior_sch)
  }

  df
}
