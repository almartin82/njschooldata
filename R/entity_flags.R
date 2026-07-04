#' Assign standard entity-level flags
#'
#' Derives standard aggregation flags from \code{county_id}, \code{district_id},
#' and \code{school_id} columns.
#'
#' @param df Data frame with CDS identifier columns.
#' @param district_school_ids School identifiers that represent district-level
#'   aggregate rows.
#' @param recognize_state_label Whether \code{county_id == "STATE"} should be
#'   treated as the statewide row, case-insensitively.
#' @param charter_county_id County identifier used for charter rows.
#' @param na_school_is_district Whether rows with missing \code{school_id} and
#'   non-missing \code{district_id} should be treated as district rows.
#' @return \code{df} with standard entity flags added.
#' @export
assign_entity_flags <- function(df,
                                district_school_ids = c("888", "997", "999"),
                                recognize_state_label = TRUE,
                                charter_county_id = "80",
                                na_school_is_district = FALSE) {
  required_cols <- c("county_id", "district_id", "school_id")
  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) {
    stop(
      "assign_entity_flags() requires columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  county_id <- df[["county_id"]]
  district_id <- df[["district_id"]]
  school_id <- df[["school_id"]]

  is_state <- district_id == "9999" & county_id == "99"
  if (isTRUE(recognize_state_label)) {
    is_state <- is_state | toupper(county_id) == "STATE"
  }

  is_county <- (district_id == "9999" & county_id != "99") & !is_state

  district_from_school <- school_id %in% district_school_ids
  if (isTRUE(na_school_is_district)) {
    district_from_school <- district_from_school |
      (is.na(school_id) & !is.na(district_id))
  }
  is_district <- district_from_school & !is_state

  is_school <- !(school_id %in% district_school_ids) & !is_state
  if (isTRUE(na_school_is_district)) {
    is_school <- !is.na(school_id) &
      !(school_id %in% district_school_ids) & !is_state
  }

  df[["is_state"]] <- is_state
  df[["is_county"]] <- is_county
  df[["is_district"]] <- is_district
  df[["is_school"]] <- is_school
  df[["is_charter"]] <- county_id == charter_county_id
  df[["is_charter_sector"]] <- FALSE
  df[["is_allpublic"]] <- FALSE

  df
}
