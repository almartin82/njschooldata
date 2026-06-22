# ==============================================================================
# Facilities Data - raw source fetchers
# ==============================================================================
#
# Each source returns minimally processed, source-shaped rows. Source processors
# map them into the canonical long facilities schema.
# ==============================================================================

#' Facilities source registry
#'
#' Live source URLs, agency labels, source types, and honest source vintages for
#' New Jersey facilities data.
#'
#' @return Named list of source descriptors.
#' @keywords internal
facilities_sources <- function() {
  list(
    njdoe_cds = list(
      url = "https://www.nj.gov/education/sleds/keydocs/docs/County_District_School_Code_List.xlsx",
      agency = "NJDOE",
      source_type = "xlsx",
      vintage = "CDS list current as of 2026-06-15"
    ),
    njgin_school_points = list(
      url = paste0(
        "https://services2.arcgis.com/XVOqAjTOJ5P6ngMu/arcgis/rest/services/",
        "School_Point_Locations_of_NJ/FeatureServer/0/query"
      ),
      agency = "NJGIN",
      source_type = "arcgis",
      vintage = "NJGIN school points modified 2023-05-10"
    ),
    njsda_active_projects = list(
      url = "https://www.njsda.gov/Projects/CapitalProgram",
      agency = "NJSDA",
      source_type = "html",
      vintage = "NJSDA active capital portfolio, accessed 2026-06-22"
    ),
    njdoe_sda_allocation = list(
      url = "https://www.nj.gov/education/facilities/docs/SDA/DistrictAllocationTable.xlsx",
      agency = "NJDOE",
      source_type = "xlsx",
      vintage = "FY2026 SDA Emergent/Capital Maintenance allocation"
    ),
    njdoe_lead_soa = list(
      url = "https://www.nj.gov/education/lead/docs/24-25SOA_SubmissionsLeadDW102825.xlsx",
      agency = "NJDOE",
      source_type = "xlsx",
      vintage = "2024-2025 Lead SOA submissions, file dated 2025-10-28"
    )
  )
}

#' Internal facilities cache directory
#' @keywords internal
facilities_cache_dir <- function() {
  path <- file.path(tools::R_user_dir("njschooldata", "cache"), "facilities")
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

#' Fetch raw New Jersey facilities source data
#'
#' Low-level fetcher for source transparency. Most users should call
#' \code{\link{fetch_facilities}} or \code{\link{fetch_facility_gis}}.
#'
#' @param source One of the names in \code{facilities_sources()}.
#' @param use_cache If TRUE, reuse a local source cache when it is less than
#'   30 days old.
#' @return A source-shaped data frame or list of data frames.
#' @export
#' @examples
#' \dontrun{
#' cds <- get_raw_facilities("njdoe_cds")
#' points <- get_raw_facilities("njgin_school_points")
#' grants <- get_raw_facilities("njdoe_sda_allocation")
#' }
get_raw_facilities <- function(source, use_cache = TRUE) {
  registry <- facilities_sources()
  if (!source %in% names(registry)) {
    stop(
      "Invalid facilities source: ", source, "\nValid sources: ",
      paste(names(registry), collapse = ", "),
      call. = FALSE
    )
  }

  cache_file <- file.path(facilities_cache_dir(), paste0(source, ".rds"))
  if (isTRUE(use_cache) && file.exists(cache_file)) {
    age_days <- as.numeric(difftime(Sys.time(), file.info(cache_file)$mtime,
                                    units = "days"))
    if (!is.na(age_days) && age_days < 30) {
      return(readRDS(cache_file))
    }
  }

  src <- registry[[source]]
  raw <- switch(
    source,
    njdoe_cds = get_raw_njdoe_cds(src),
    njgin_school_points = get_raw_facilities_arcgis(src),
    njsda_active_projects = get_raw_njsda_active_projects(src),
    njdoe_sda_allocation = get_raw_njdoe_sda_allocation(src),
    njdoe_lead_soa = get_raw_njdoe_lead_soa(src),
    stop("No raw facilities fetcher for source: ", source, call. = FALSE)
  )

  if (isTRUE(use_cache)) {
    saveRDS(raw, cache_file)
  }
  raw
}

#' Internal: download an XLSX and validate ZIP magic bytes
#' @keywords internal
facilities_download_xlsx <- function(url) {
  dest <- tempfile(fileext = ".xlsx")
  utils::download.file(url, dest, mode = "wb", quiet = TRUE)
  magic <- readBin(dest, what = "raw", n = 4)
  if (!identical(as.integer(magic), as.integer(charToRaw("PK\003\004")))) {
    stop("Downloaded file is not a valid XLSX: ", url, call. = FALSE)
  }
  dest
}

#' Internal: fetch and read the NJDOE CDS workbook
#' @keywords internal
get_raw_njdoe_cds <- function(src) {
  path <- facilities_download_xlsx(src$url)
  on.exit(unlink(path), add = TRUE)

  cds <- readxl::read_excel(path, sheet = "CDS Codes", skip = 1,
                            col_types = "text")
  updates <- readxl::read_excel(path, sheet = "Updates", skip = 1,
                                col_types = "text")

  list(cds = as.data.frame(cds, stringsAsFactors = FALSE),
       updates = as.data.frame(updates, stringsAsFactors = FALSE))
}

#' Internal: page an ArcGIS query endpoint
#' @keywords internal
get_raw_facilities_arcgis <- function(src) {
  all_rows <- list()
  offset <- 0L
  page <- 2000L

  repeat {
    resp <- httr::GET(
      src$url,
      query = list(
        where = "1=1",
        outFields = "*",
        returnGeometry = "true",
        outSR = "4326",
        resultOffset = offset,
        resultRecordCount = page,
        f = "json"
      ),
      httr::timeout(60)
    )
    httr::stop_for_status(resp)
    parsed <- jsonlite::fromJSON(
      httr::content(resp, as = "text", encoding = "UTF-8"),
      simplifyDataFrame = TRUE
    )

    features <- parsed$features
    if (is.null(features) || length(features) == 0 ||
        (is.data.frame(features) && nrow(features) == 0)) {
      break
    }

    attrs <- features$attributes
    if (!is.null(features$geometry)) {
      attrs$.longitude <- features$geometry$x
      attrs$.latitude <- features$geometry$y
    }
    all_rows[[length(all_rows) + 1]] <- attrs

    n_got <- nrow(attrs)
    if (!isTRUE(parsed$exceededTransferLimit) && n_got < page) break
    offset <- offset + n_got
    if (offset > 500000L) stop("ArcGIS paging safety limit exceeded", call. = FALSE)
  }

  if (!length(all_rows)) {
    stop("ArcGIS source returned no school points: ", src$url, call. = FALSE)
  }
  do.call(rbind, all_rows)
}

#' Internal: fetch a URL as text with a browser user agent
#' @keywords internal
facilities_get_text <- function(url) {
  resp <- httr::GET(
    url,
    httr::user_agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"),
    httr::timeout(60)
  )
  httr::stop_for_status(resp)
  httr::content(resp, as = "text", encoding = "UTF-8")
}

#' Internal: very small HTML-to-text helper
#' @keywords internal
facilities_html_text <- function(html) {
  html <- gsub("(?is)<script.*?</script>", " ", html, perl = TRUE)
  html <- gsub("(?is)<style.*?</style>", " ", html, perl = TRUE)
  txt <- gsub("(?is)<[^>]+>", " ", html, perl = TRUE)
  txt <- gsub("&nbsp;", " ", txt, fixed = TRUE)
  txt <- gsub("&amp;", "&", txt, fixed = TRUE)
  txt <- gsub("&ndash;|&#8211;", "-", txt, perl = TRUE)
  txt <- gsub("&mdash;|&#8212;", "-", txt, perl = TRUE)
  txt <- gsub("&quot;", "\"", txt, fixed = TRUE)
  txt <- gsub("&#39;", "'", txt, fixed = TRUE)
  trimws(gsub("\\s+", " ", txt))
}

#' Internal: first regex capture or NA
#' @keywords internal
facilities_capture <- function(text, pattern, group = 1L) {
  m <- regexec(pattern, text, perl = TRUE, ignore.case = TRUE)
  hit <- regmatches(text, m)[[1]]
  if (length(hit) <= group) return(NA_character_)
  trimws(hit[group + 1L])
}

#' Internal: convert strings like 87.2 Million to whole-dollar text
#' @keywords internal
facilities_million_to_usd <- function(x) {
  if (is.na(x) || x == "") return(NA_character_)
  n <- suppressWarnings(as.numeric(gsub(",", "", x)))
  if (is.na(n)) return(NA_character_)
  format(round(n * 1000000), scientific = FALSE, trim = TRUE)
}

#' Internal: remove commas from a number-like string
#' @keywords internal
facilities_number_string <- function(x) {
  if (is.na(x) || x == "") return(NA_character_)
  gsub(",", "", x)
}

#' Internal: extract active NJSDA project detail pages
#' @keywords internal
get_raw_njsda_active_projects <- function(src) {
  html <- facilities_get_text(src$url)
  link_matches <- regmatches(
    html,
    gregexpr("<a[^>]+href=\"[^\"]*ProjectSchoolDetails[^\"]*\"[^>]*>[^<]+",
             html, perl = TRUE, ignore.case = TRUE)
  )[[1]]
  if (!length(link_matches) || identical(link_matches, character(0))) {
    stop("NJSDA Capital Program page exposed no active project links", call. = FALSE)
  }

  hrefs <- sub(".*href=\"([^\"]+)\".*", "\\1", link_matches, perl = TRUE)
  labels <- facilities_html_text(sub(".*>([^<]+)$", "\\1", link_matches, perl = TRUE))
  hrefs <- unique(hrefs)

  rows <- list()
  for (i in seq_along(hrefs)) {
    href <- hrefs[[i]]
    url <- if (grepl("^https?://", href)) href else paste0("https://www.njsda.gov", href)
    url <- gsub(" ", "%20", url, fixed = TRUE)
    label <- labels[[min(i, length(labels))]]

    row <- tryCatch({
      page <- facilities_get_text(url)
      text <- facilities_html_text(page)
      project_id <- utils::URLdecode(facilities_capture(url, "vProjectID=([^&]+)"))
      district <- utils::URLdecode(facilities_capture(url, "vSchoolDistrict=([^&]+)"))

      cost_millions <- facilities_capture(
        text, "Total Estimated Project Costs\\s*\\$([0-9,.]+)\\s*Million"
      )

      data.frame(
        project_id = project_id,
        district_name = district,
        project_name = label,
        project_scope = facilities_capture(text, "(The project scope includes[^.]+\\.)"),
        added_capacity = facilities_number_string(facilities_capture(
          text, "additional capacity to educate ([0-9,]+) students"
        )),
        grade_span = facilities_capture(text, "students in grades ([^.]+?)\\."),
        new_construction_sq_ft = facilities_number_string(facilities_capture(
          text, "approximately ([0-9,]+) (?:of )?new construction"
        )),
        renovation_sq_ft = facilities_number_string(facilities_capture(
          text, "approximately ([0-9,]+) square feet of program driven renovations"
        )),
        current_status = facilities_capture(
          text, "CURRENT STATUS - As of [^:]+:\\s*([^.]+\\.)"
        ),
        status_date = facilities_capture(text, "CURRENT STATUS - As of ([^:]+):"),
        total_estimated_project_cost = facilities_million_to_usd(cost_millions),
        year_constructed = facilities_capture(text, "was constructed in ([0-9]{4})"),
        .source_url = url,
        .vintage = ifelse(
          is.na(facilities_capture(text, "CURRENT STATUS - As of ([^:]+):")),
          src$vintage,
          paste0("NJSDA active project status as of ",
                 facilities_capture(text, "CURRENT STATUS - As of ([^:]+):"))
        ),
        stringsAsFactors = FALSE
      )
    }, error = function(e) {
      warning("Skipping NJSDA active project page ", url, ": ",
              conditionMessage(e), call. = FALSE)
      NULL
    })

    if (!is.null(row)) rows[[length(rows) + 1]] <- row
  }

  if (!length(rows)) stop("No NJSDA active project pages could be parsed", call. = FALSE)
  do.call(rbind, rows)
}

#' Internal: district lookup from the live CDS workbook
#' @keywords internal
facilities_cds_district_lookup <- function() {
  cds <- get_raw_njdoe_cds(facilities_sources()$njdoe_cds)$cds
  cds <- cds[!is.na(cds$CountyCode) & !is.na(cds$DistrictCode) &
               cds$SchoolCode == "000", , drop = FALSE]
  unique(cds[, c("CountyCode", "CountyName", "DistrictCode", "DistrictName")])
}

#' Internal: read NJDOE SDA district allocation workbook
#' @keywords internal
get_raw_njdoe_sda_allocation <- function(src) {
  path <- facilities_download_xlsx(src$url)
  on.exit(unlink(path), add = TRUE)
  x <- readxl::read_excel(path, sheet = 1, skip = 4, col_types = "text")
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  x <- x[!is.na(x$County) & !is.na(x$`District ID`) &
           !is.na(x$`SDA Grant Allocation`), , drop = FALSE]
  x$`District ID` <- sprintf("%04s", x$`District ID`)
  x$`District ID` <- gsub(" ", "0", x$`District ID`, fixed = TRUE)

  lookup <- facilities_cds_district_lookup()
  names(lookup) <- c("county_id", "county_name", "district_id", "cds_district_name")
  x$.county_upper <- toupper(x$County)
  x <- dplyr::left_join(
    x,
    lookup,
    by = c(".county_upper" = "county_name", "District ID" = "district_id")
  )
  x
}

#' Internal: read NJDOE lead SOA workbook, excluding early childcare rows
#' @keywords internal
get_raw_njdoe_lead_soa <- function(src) {
  path <- facilities_download_xlsx(src$url)
  on.exit(unlink(path), add = TRUE)

  sheets <- intersect(
    readxl::excel_sheets(path),
    c("District", "Charter or Renaissance", "APSSD and Receiving Schools")
  )
  rows <- list()
  lookup <- facilities_cds_district_lookup()
  names(lookup) <- c("county_id", "county_name", "district_id", "cds_district_name")

  for (sheet in sheets) {
    x <- readxl::read_excel(path, sheet = sheet, skip = 1, col_types = "text")
    x <- as.data.frame(x, stringsAsFactors = FALSE)
    x$.sheet <- sheet
    name_col <- if ("District" %in% names(x)) "District" else "School"
    x$.entity_name <- x[[name_col]]
    x$.district_id <- facilities_capture_vec(x$.entity_name, "\\(([0-9]{4})\\)")
    x <- dplyr::left_join(
      x,
      lookup,
      by = c("County" = "county_name", ".district_id" = "district_id")
    )
    rows[[length(rows) + 1]] <- x
  }

  dplyr::bind_rows(rows)
}
