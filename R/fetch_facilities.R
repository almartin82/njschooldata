# ==============================================================================
# Facilities Data - public fetchers
# ==============================================================================

#' Internal: map shipped New Jersey facilities categories to source families
#' @keywords internal
facilities_category_sources <- function() {
  list(
    inventory = c("njdoe_cds", "njgin_school_points"),
    attributes = c("njsda_active_projects"),
    capacity = c("njsda_active_projects"),
    projects = c("njsda_active_projects"),
    finance = c("njdoe_sda_allocation"),
    environmental = c("njdoe_lead_soa"),
    closures = c("njdoe_cds")
  )
}

#' Internal: process a raw facilities source into canonical rows
#' @keywords internal
process_facilities_source <- function(source, raw, src) {
  switch(
    source,
    njdoe_cds = process_njdoe_cds_facilities(raw, src),
    njgin_school_points = process_njgin_school_points(raw, src),
    njsda_active_projects = process_njsda_active_projects(raw, src),
    njdoe_sda_allocation = process_njdoe_sda_allocation(raw, src),
    njdoe_lead_soa = process_njdoe_lead_soa(raw, src),
    stop("No facilities processor for source: ", source, call. = FALSE)
  )
}

#' Fetch New Jersey school facilities data
#'
#' New Jersey facilities data is fragmented across state sources rather than a
#' single bulk API. This function dispatches by `category` and returns a
#' canonical long table with character-valued `value`, source provenance, and
#' true source vintages on every row.
#'
#' New Jersey currently ships honest partial coverage: `inventory`,
#' `attributes`, `capacity`, `projects`, `finance`, `environmental`, and
#' `closures`. The full controlled vocabulary also contains `condition` and
#' `capital_needs`, but no verified populated public statewide bulk source is
#' shipped for those categories yet, so they error with a coverage message
#' rather than returning placeholders.
#'
#' Geometry is served by [fetch_facility_gis()]. Inventory rows still include
#' latitude/longitude metrics from NJGIN where available.
#'
#' @param category Facilities category. Run [get_available_facilities()] for
#'   shipped New Jersey categories.
#' @param year Optional source-vintage filter. If no shipped vintage contains
#'   the requested year, the available rows are returned with a message.
#' @param tidy If TRUE (default), return the canonical long schema. Facilities
#'   has no separate wide form, so FALSE currently returns the same rows.
#' @param use_cache If TRUE (default), use cached source downloads when fresh.
#' @return Data frame with columns `category`, `entity_level`, `entity_id`,
#'   `entity_name`, `metric`, `value`, `unit`, `source_agency`, `source_type`,
#'   `source_url`, `vintage`, `nces_dist`, and `nces_sch`.
#' @export
#' @examples
#' \dontrun{
#' inv <- fetch_facilities("inventory")
#' grants <- fetch_facilities("finance")
#' lead <- fetch_facilities("environmental")
#'
#' library(dplyr)
#' grants |>
#'   mutate(allocation = as.numeric(value))
#' }
fetch_facilities <- function(category, year = NULL, tidy = TRUE,
                             use_cache = TRUE) {
  valid <- facilities_categories()
  if (missing(category) || length(category) != 1 || !category %in% valid) {
    stop(
      "Invalid category: ",
      if (missing(category)) "(missing)" else as.character(category)[1],
      "\nValid categories: ", paste(valid, collapse = ", "),
      call. = FALSE
    )
  }

  if (!category %in% facilities_available_categories()) {
    stop(
      "Facilities category '", category, "' is not available for New Jersey. ",
      "No verified populated public statewide source is shipped for this category.",
      call. = FALSE
    )
  }

  registry <- facilities_sources()
  sources <- facilities_category_sources()[[category]]
  processed <- list()
  for (source in sources) {
    raw <- get_raw_facilities(source, use_cache = use_cache)
    processed[[source]] <- process_facilities_source(source, raw, registry[[source]])
  }

  long <- tidy_facilities(processed)
  long <- long[long$category == category, , drop = FALSE]

  if (!is.null(year)) {
    yr <- as.character(year)
    filtered <- long[grepl(yr, long$vintage), , drop = FALSE]
    if (nrow(filtered)) {
      long <- filtered
    } else {
      message(
        "No New Jersey facilities vintage matched year ", yr,
        "; returning all available rows for category '", category, "'."
      )
    }
  }

  rownames(long) <- NULL
  long
}

#' Fetch New Jersey facilities data for multiple years
#'
#' Facilities sources shipped here are mostly latest-vintage snapshots. This
#' helper filters by requested year strings where the source vintage supports
#' it, otherwise returns the available source rows with a message.
#'
#' @param category See [fetch_facilities()].
#' @param years Vector of years.
#' @param tidy,use_cache See [fetch_facilities()].
#' @return Combined facilities long-schema data frame.
#' @export
#' @examples
#' \dontrun{
#' fetch_facilities_multi("finance", 2026)
#' fetch_facilities_multi("environmental", 2025)
#' fetch_facilities_multi("inventory", 2026)
#' }
fetch_facilities_multi <- function(category, years, tidy = TRUE,
                                   use_cache = TRUE) {
  if (missing(years) || length(years) == 0) {
    stop("years must contain at least one year", call. = FALSE)
  }
  out <- lapply(years, function(y) {
    fetch_facilities(category, year = y, tidy = tidy, use_cache = use_cache)
  })
  out <- unique(do.call(rbind, c(out, list(make.row.names = FALSE))))
  rownames(out) <- NULL
  out
}

#' What facilities categories are available for New Jersey
#'
#' Returns the shipped category-to-source mapping with source agency, type, URL,
#' and vintage. This is metadata-only and does not download full source files.
#'
#' @return Data frame with `category`, `source`, `source_agency`,
#'   `source_type`, `source_url`, and `vintage`.
#' @export
#' @examples
#' available <- get_available_facilities()
#' unique(available$category)
#' subset(available, category == "environmental")
get_available_facilities <- function() {
  registry <- facilities_sources()
  mapping <- facilities_category_sources()
  rows <- list()
  for (category in names(mapping)) {
    for (source in mapping[[category]]) {
      rows[[length(rows) + 1]] <- data.frame(
        category = category,
        source = source,
        source_agency = registry[[source]]$agency,
        source_type = registry[[source]]$source_type,
        source_url = registry[[source]]$url,
        vintage = registry[[source]]$vintage,
        stringsAsFactors = FALSE
      )
    }
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}
