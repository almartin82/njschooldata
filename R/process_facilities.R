# ==============================================================================
# Facilities Data - source processors
# ==============================================================================
#
# Source-shaped raw rows are melted into the canonical long facilities schema.
# Missing source cells are dropped, never filled or inferred.
# ==============================================================================

#' Internal empty facilities long frame before NCES attachment
#' @keywords internal
facilities_empty_long <- function() {
  data.frame(
    category = character(),
    entity_level = character(),
    entity_id = character(),
    entity_name = character(),
    metric = character(),
    value = character(),
    unit = character(),
    source_agency = character(),
    source_type = character(),
    source_url = character(),
    vintage = character(),
    .county_id = character(),
    .district_id = character(),
    .school_id = character(),
    stringsAsFactors = FALSE
  )
}

#' Internal vectorized regex capture
#' @keywords internal
facilities_capture_vec <- function(x, pattern, group = 1L) {
  vapply(as.character(x), facilities_capture, character(1), pattern = pattern,
         group = group, USE.NAMES = FALSE)
}

#' Internal: source-aware melt helper
#' @keywords internal
facilities_melt <- function(df, entity_id_col, entity_name_col, entity_level,
                            src, spec, county_id_col = NA_character_,
                            district_id_col = NA_character_,
                            school_id_col = NA_character_) {
  if (!nrow(df)) return(facilities_empty_long())

  ids <- as.character(df[[entity_id_col]])
  names <- if (!is.na(entity_name_col) && entity_name_col %in% names(df)) {
    as.character(df[[entity_name_col]])
  } else {
    rep(NA_character_, nrow(df))
  }
  source_urls <- if (".source_url" %in% names(df)) {
    as.character(df$.source_url)
  } else {
    rep(src$url, nrow(df))
  }
  vintages <- if (".vintage" %in% names(df)) {
    as.character(df$.vintage)
  } else {
    rep(src$vintage, nrow(df))
  }
  county_ids <- if (!is.na(county_id_col) && county_id_col %in% names(df)) {
    as.character(df[[county_id_col]])
  } else {
    rep(NA_character_, nrow(df))
  }
  district_ids <- if (!is.na(district_id_col) && district_id_col %in% names(df)) {
    as.character(df[[district_id_col]])
  } else {
    rep(NA_character_, nrow(df))
  }
  school_ids <- if (!is.na(school_id_col) && school_id_col %in% names(df)) {
    as.character(df[[school_id_col]])
  } else {
    rep(NA_character_, nrow(df))
  }

  out <- list()
  for (s in spec) {
    if (!s$col %in% names(df)) next
    value <- trimws(as.character(df[[s$col]]))
    value[value %in% c("", "NA", "N/A", "n/a", "NULL", "null", "-")] <- NA_character_
    keep <- !is.na(value)
    if (!any(keep)) next

    out[[length(out) + 1]] <- data.frame(
      category = s$category,
      entity_level = entity_level,
      entity_id = ids[keep],
      entity_name = names[keep],
      metric = s$metric,
      value = value[keep],
      unit = if (is.null(s$unit)) NA_character_ else s$unit,
      source_agency = src$agency,
      source_type = src$source_type,
      source_url = source_urls[keep],
      vintage = vintages[keep],
      .county_id = county_ids[keep],
      .district_id = district_ids[keep],
      .school_id = school_ids[keep],
      stringsAsFactors = FALSE
    )
  }

  if (!length(out)) return(facilities_empty_long())
  do.call(rbind, out)
}

#' Process NJDOE CDS workbook to inventory and closure lifecycle rows
#' @keywords internal
process_njdoe_cds_facilities <- function(raw, src) {
  cds <- raw$cds
  cds <- cds[!is.na(cds$CountyCode) & !is.na(cds$DistrictCode) &
               !is.na(cds$SchoolCode) & cds$SchoolCode != "000", , drop = FALSE]
  cds$entity_id <- paste(cds$CountyCode, cds$DistrictCode, cds$SchoolCode, sep = "-")

  inventory <- facilities_melt(
    cds,
    entity_id_col = "entity_id",
    entity_name_col = "SchoolName",
    entity_level = "school",
    src = src,
    spec = list(
      list(col = "SchoolCategory", category = "inventory",
           metric = "school_category", unit = NA),
      list(col = "CountyName", category = "inventory",
           metric = "county_name", unit = NA),
      list(col = "DistrictName", category = "inventory",
           metric = "district_name", unit = NA),
      list(col = "PreschoolExpansionAid", category = "inventory",
           metric = "preschool_expansion_aid", unit = NA)
    ),
    county_id_col = "CountyCode",
    district_id_col = "DistrictCode",
    school_id_col = "SchoolCode"
  )

  updates <- raw$updates
  updates <- updates[!is.na(updates$`County Code`) &
                       !is.na(updates$`District Code`) &
                       !is.na(updates$`School Code`) &
                       toupper(updates$`Action Taken`) == "DELETED", , drop = FALSE]
  closures <- facilities_empty_long()
  if (nrow(updates)) {
    updates$entity_id <- paste(
      updates$`County Code`, updates$`District Code`, updates$`School Code`,
      sep = "-"
    )
    closures <- facilities_melt(
      updates,
      entity_id_col = "entity_id",
      entity_name_col = "School Name",
      entity_level = "school",
      src = src,
      spec = list(
        list(col = "Action Taken", category = "closures",
             metric = "cds_action", unit = NA),
        list(col = "Date", category = "closures",
             metric = "cds_action_date", unit = NA),
        list(col = "District Name", category = "closures",
             metric = "district_name", unit = NA),
        list(col = "County Name", category = "closures",
             metric = "county_name", unit = NA)
      ),
      county_id_col = "County Code",
      district_id_col = "District Code",
      school_id_col = "School Code"
    )
  }

  rbind(inventory, closures)
}

#' Process NJGIN school points to inventory rows
#' @keywords internal
process_njgin_school_points <- function(raw, src) {
  raw$entity_id <- ifelse(
    !is.na(raw$OGIS_ID) & raw$OGIS_ID != "",
    as.character(raw$OGIS_ID),
    paste(raw$COUNTYCODE, raw$DIST_CODE, raw$SCHOOLCODE, sep = "-")
  )
  raw$entity_name <- ifelse(
    !is.na(raw$SCHOOLNAME) & raw$SCHOOLNAME != "",
    as.character(raw$SCHOOLNAME),
    as.character(raw$SCHOOL)
  )

  facilities_melt(
    raw,
    entity_id_col = "entity_id",
    entity_name_col = "entity_name",
    entity_level = "school",
    src = src,
    spec = list(
      list(col = "SCHOOLTYPE", category = "inventory",
           metric = "school_type", unit = NA),
      list(col = "ADDRESS1", category = "inventory",
           metric = "street_address", unit = NA),
      list(col = "CITY", category = "inventory",
           metric = "city", unit = NA),
      list(col = "ZIP", category = "inventory",
           metric = "zip", unit = NA),
      list(col = "PHONE", category = "inventory",
           metric = "phone", unit = NA),
      list(col = "SOURCE", category = "inventory",
           metric = "point_source", unit = NA),
      list(col = "LOC_QUAL", category = "inventory",
           metric = "location_quality", unit = NA),
      list(col = "OGIS_ID", category = "inventory",
           metric = "ogis_id", unit = NA),
      list(col = "GNIS_ID", category = "inventory",
           metric = "gnis_id", unit = NA),
      list(col = ".latitude", category = "inventory",
           metric = "latitude", unit = "deg"),
      list(col = ".longitude", category = "inventory",
           metric = "longitude", unit = "deg")
    ),
    county_id_col = "COUNTYCODE",
    district_id_col = "DIST_CODE",
    school_id_col = "SCHOOLCODE"
  )
}

#' Process NJSDA active project detail pages
#' @keywords internal
process_njsda_active_projects <- function(raw, src) {
  facilities_melt(
    raw,
    entity_id_col = "project_id",
    entity_name_col = "project_name",
    entity_level = "project",
    src = src,
    spec = list(
      list(col = "project_scope", category = "projects",
           metric = "project_scope", unit = NA),
      list(col = "current_status", category = "projects",
           metric = "current_status", unit = NA),
      list(col = "status_date", category = "projects",
           metric = "status_date", unit = NA),
      list(col = "total_estimated_project_cost", category = "projects",
           metric = "total_estimated_project_cost", unit = "usd"),
      list(col = "added_capacity", category = "capacity",
           metric = "added_capacity", unit = "seats"),
      list(col = "grade_span", category = "capacity",
           metric = "grade_span", unit = NA),
      list(col = "new_construction_sq_ft", category = "attributes",
           metric = "new_construction_sq_ft", unit = "sq_ft"),
      list(col = "renovation_sq_ft", category = "attributes",
           metric = "renovation_sq_ft", unit = "sq_ft"),
      list(col = "year_constructed", category = "attributes",
           metric = "year_constructed", unit = "year")
    )
  )
}

#' Process NJDOE SDA district allocation workbook
#' @keywords internal
process_njdoe_sda_allocation <- function(raw, src) {
  raw$entity_id <- ifelse(
    !is.na(raw$county_id),
    paste(raw$county_id, raw$`District ID`, sep = "-"),
    raw$`District ID`
  )
  raw$entity_name <- ifelse(
    !is.na(raw$cds_district_name),
    raw$cds_district_name,
    raw$`District Name`
  )

  facilities_melt(
    raw,
    entity_id_col = "entity_id",
    entity_name_col = "entity_name",
    entity_level = "district",
    src = src,
    spec = list(
      list(col = "SDA Grant Allocation", category = "finance",
           metric = "sda_grant_allocation", unit = "usd")
    ),
    county_id_col = "county_id",
    district_id_col = "District ID"
  )
}

#' Process NJDOE lead Statement of Assurance workbook
#' @keywords internal
process_njdoe_lead_soa <- function(raw, src) {
  raw$entity_level <- ifelse(raw$.sheet == "District", "district", "school")
  raw$entity_id <- ifelse(
    raw$entity_level == "district" & !is.na(raw$county_id) & !is.na(raw$.district_id),
    paste(raw$county_id, raw$.district_id, sep = "-"),
    paste(raw$County, raw$.entity_name, sep = "|")
  )
  raw$entity_name <- raw$.entity_name
  for (count_col in c("# of Outlets Tested", "# Exceeded")) {
    count <- suppressWarnings(as.numeric(raw[[count_col]]))
    raw[[count_col]][!is.na(count) & count < 0] <- NA_character_
  }

  out <- list()
  for (level in unique(raw$entity_level)) {
    sub <- raw[raw$entity_level == level, , drop = FALSE]
    out[[length(out) + 1]] <- facilities_melt(
      sub,
      entity_id_col = "entity_id",
      entity_name_col = "entity_name",
      entity_level = level,
      src = src,
      spec = list(
        list(col = "Testing Complete", category = "environmental",
             metric = "testing_complete", unit = NA),
        list(col = "# of Outlets Tested", category = "environmental",
             metric = "n_outlets_tested", unit = "outlets"),
        list(col = "# Exceeded", category = "environmental",
             metric = "n_outlets_exceeded", unit = "outlets"),
        list(col = "Exceeded", category = "environmental",
             metric = "exceeded_action_level", unit = NA),
        list(col = "Submission Date", category = "environmental",
             metric = "soa_submission_date", unit = "excel_date"),
        list(col = "District Website of Test Results", category = "environmental",
             metric = "test_results_url", unit = NA),
        list(col = "School Website of Test Results", category = "environmental",
             metric = "test_results_url", unit = NA),
        list(col = "Exempt", category = "environmental",
             metric = "exempt", unit = NA)
      ),
      county_id_col = "county_id",
      district_id_col = ".district_id"
    )
  }

  do.call(rbind, out)
}
