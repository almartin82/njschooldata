# ==============================================================================
# Directory Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading school and district directory
# data from the NJ Department of Education Homeroom website.
#
# Data sources: current Homeroom CSV endpoints registered in source_registry.R.
#
# ==============================================================================

# -----------------------------------------------------------------------------
# Raw Data Download Functions
# -----------------------------------------------------------------------------

#' Download raw school directory data from NJ DOE
#'
#' Downloads the CSV file from NJ DOE Homeroom and reads it into a data frame.
#' The CSV includes 3 header rows that need to be skipped.
#'
#' @return Data frame with raw school directory data
#' @keywords internal
.directory_source_result <- function(level,
                                     request_fn = .default_source_request) {
  level <- match.arg(level, c("school", "district"))
  url <- resolve_source_url("directory", level = level)
  transport <- download_source(url, source_type = "csv", request_fn = request_fn)
  if (!identical(transport$source_status, "actual")) return(transport)
  on.exit(unlink(transport$data), add = TRUE)
  parsed <- tryCatch(
    readr::read_csv(
      transport$data,
      skip = 3,
      col_types = readr::cols(.default = readr::col_character()),
      show_col_types = FALSE
    ),
    error = identity
  )
  if (inherits(parsed, "error")) {
    return(new_source_result(
      source_status = "parse_error", source_url = transport$source_url,
      retrieved_at = transport$retrieved_at, digest = transport$digest,
      error = conditionMessage(parsed)
    ))
  }
  cleaned_names <- janitor::make_clean_names(names(parsed))
  required <- c("county_code", "district_code")
  if (level == "school") required <- c(required, "school_code")
  missing <- setdiff(required, cleaned_names)
  if (!nrow(parsed) || length(missing)) {
    detail <- if (length(missing)) {
      paste0("missing columns: ", paste(missing, collapse = ", "))
    } else {
      "no data rows"
    }
    return(new_source_result(
      source_status = "parse_error", source_url = transport$source_url,
      retrieved_at = transport$retrieved_at, digest = transport$digest,
      error = paste0("Directory CSV failed its structural contract (", detail, ").")
    ))
  }
  new_source_result(
    data = parsed, source_status = "actual",
    source_url = transport$source_url,
    retrieved_at = transport$retrieved_at, digest = transport$digest
  )
}

get_raw_school_directory <- function() {
  source_result_data(.directory_source_result("school"))
}


#' Download raw district directory data from NJ DOE
#'
#' Downloads the CSV file from NJ DOE Homeroom and reads it into a data frame.
#' The CSV includes 3 header rows that need to be skipped.
#'
#' @return Data frame with raw district directory data
#' @keywords internal
get_raw_district_directory <- function() {
  source_result_data(.directory_source_result("district"))
}


# -----------------------------------------------------------------------------
# Processing Functions
# -----------------------------------------------------------------------------

#' Process raw school directory data into standardized format
#'
#' Cleans column names, removes Excel formula padding, and standardizes
#' the schema.
#'
#' @param raw Data frame from \code{get_raw_school_directory()}
#' @return Processed data frame with standardized column names
#' @keywords internal
process_school_directory <- function(raw) {
  df <- raw %>%
    janitor::clean_names()

  # Fix encoding issues before string operations
  char_cols <- names(df)[vapply(df, is.character, logical(1))]
  for (col in char_cols) {
    df[[col]] <- iconv(df[[col]], from = "", to = "UTF-8", sub = "")
  }

  # Remove Excel formula padding (="01" -> "01")
  for (col in char_cols) {
    df[[col]] <- kill_padformulas(df[[col]])
  }

  # Trim whitespace from all character columns
  for (col in char_cols) {
    df[[col]] <- trimws(df[[col]])
  }

  # Build grade range from individual grade columns
  grade_cols <- c(
    "pre_k", "kindergarten",
    paste0("grade_", 1:12),
    "post_grad", "adult_ed"
  )
  grade_labels <- c(
    "PK", "K",
    sprintf("%02d", 1:12),
    "Post-Grad", "Adult Ed"
  )

  # Only use grade columns that exist
  existing_grade_cols <- grade_cols[grade_cols %in% names(df)]
  existing_grade_labels <- grade_labels[grade_cols %in% names(df)]

  df$grades_served <- apply(
    df[, existing_grade_cols, drop = FALSE], 1,
    function(row) {
      offered <- which(!is.na(row) & row != "" & row != "0")
      if (length(offered) == 0) return(NA_character_)
      paste(existing_grade_labels[offered], collapse = ", ")
    }
  )

  df %>%
    dplyr::transmute(
      county_id = county_code,
      county_name = county_name,
      district_id = district_code,
      district_name = district_name,
      school_id = school_code,
      school_name = school_name,
      entity_type = "school",
      principal_title = princ_title,
      principal_first_name = princ_first_name,
      principal_last_name = princ_last_name,
      principal_name = dplyr::if_else(
        !is.na(princ_first_name) & !is.na(princ_last_name),
        paste(princ_first_name, princ_last_name),
        NA_character_
      ),
      principal_role = princ_title_2,
      principal_email = princ_email,
      address = address1,
      address2 = address2,
      city = city,
      state = state,
      zip = zip,
      mailing_address = mailing_address1,
      mailing_address2 = mailing_address2,
      mailing_city = mailing_city,
      mailing_state = mailing_state,
      mailing_zip = mailing_zip,
      phone = phone,
      hib_name = dplyr::if_else(
        !is.na(hib_first_nname) & !is.na(hib_last_name),
        paste(hib_first_nname, hib_last_name),
        NA_character_
      ),
      hib_role = hib_title2,
      homeless_liaison_name = dplyr::if_else(
        !is.na(homeless_liaison_first_name) & !is.na(homeless_liaison_last_name),
        paste(homeless_liaison_first_name, homeless_liaison_last_name),
        NA_character_
      ),
      homeless_liaison_role = homeless_liaison_title2,
      grades_served = grades_served,
      nces_id = nces_code,
      is_charter = county_id == "80",
      is_school = TRUE,
      is_district = FALSE,
      cds_code = paste0(county_id, district_id, school_id)
    )
}


#' Process raw district directory data into standardized format
#'
#' Cleans column names, removes Excel formula padding, and standardizes
#' the schema.
#'
#' @param raw Data frame from \code{get_raw_district_directory()}
#' @return Processed data frame with standardized column names
#' @keywords internal
process_district_directory <- function(raw) {
  df <- raw %>%
    janitor::clean_names()

  # Fix encoding issues before string operations
  char_cols <- names(df)[vapply(df, is.character, logical(1))]
  for (col in char_cols) {
    df[[col]] <- iconv(df[[col]], from = "", to = "UTF-8", sub = "")
  }

  # Remove Excel formula padding (="01" -> "01")
  for (col in char_cols) {
    df[[col]] <- kill_padformulas(df[[col]])
  }

  # Trim whitespace from all character columns
  for (col in char_cols) {
    df[[col]] <- trimws(df[[col]])
  }

  df %>%
    dplyr::transmute(
      county_id = county_code,
      county_name = county_name,
      district_id = district_code,
      district_name = district_name,
      school_id = NA_character_,
      school_name = NA_character_,
      entity_type = "district",
      superintendent_title = supt_title,
      superintendent_first_name = supt_first_name,
      superintendent_last_name = supt_last_name,
      superintendent_name = dplyr::if_else(
        !is.na(supt_first_name) & !is.na(supt_last_name),
        paste(supt_first_name, supt_last_name),
        NA_character_
      ),
      superintendent_role = supt_title_2,
      superintendent_email = supt_e_mail,
      ba_name = dplyr::if_else(
        !is.na(ba_first_name) & !is.na(ba_last_name),
        paste(ba_first_name, ba_last_name),
        NA_character_
      ),
      ba_email = ba_email,
      ba_role = ba_title2,
      address = address1,
      address2 = address2,
      city = city,
      state = state,
      zip = zip,
      mailing_address = mailing_address1,
      mailing_address2 = mailing_address2,
      mailing_address3 = mailing_address3,
      mailing_city = mailing_city,
      mailing_state = mailing_state,
      mailing_zip = mailing_zip,
      phone = phone,
      website = website,
      hib_name = dplyr::if_else(
        !is.na(hib_first_name) & !is.na(hib_last_name),
        paste(hib_first_name, hib_last_name),
        NA_character_
      ),
      hib_role = hib_title2,
      testing_coordinator_name = dplyr::if_else(
        !is.na(state_testing_coor_first_name) & !is.na(state_testing_coor_last_name),
        paste(state_testing_coor_first_name, state_testing_coor_last_name),
        NA_character_
      ),
      safety_specialist_name = dplyr::if_else(
        !is.na(school_safety_specialist_first_name) & !is.na(school_safety_specialist_last_name),
        paste(school_safety_specialist_first_name, school_safety_specialist_last_name),
        NA_character_
      ),
      charter_school_code = chrt_sch_code,
      nces_id = nces_id,
      is_charter = county_id == "80",
      is_school = FALSE,
      is_district = TRUE,
      cds_code = paste0(county_id, district_id, "999")
    )
}


# -----------------------------------------------------------------------------
# directory-contract/v1 surface
# -----------------------------------------------------------------------------
#
# fetch_directory() returns the current official New Jersey education directory
# as the canonical triple list(entities, roles, meta), per directory-contract/v1.
# There is no level argument, no cache switch, and no tidy toggle: the function
# represents "the directory as published right now".
#
# Sources (official NJDOE Homeroom, https://homeroom6.doe.nj.gov/directory/):
#   - Public School Districts download: superintendents, business
#     administrators, and special-education coordinators per district.
#   - Public Schools download (includes grade levels): principals per school.
# Both files include charter schools.
#
# Native identifiers: New Jersey's County-District-School (CDS) code.
#   - district_id = 2-digit county code + 4-digit district code (6 chars).
#   - school_id   = district_id + 3-digit school code (9 chars), on school rows.
# Verbatim, leading zeros preserved.

DIRECTORY_DISTRICT_URL <-
  "https://homeroom4.doe.nj.gov/public/districtpublicschools/download/"
DIRECTORY_SCHOOL_URL <-
  "https://homeroom4.doe.nj.gov/public/publicschools/download/"

DIRECTORY_ID_SCHEME <- paste0(
  "NJ County-District-School (CDS) code: district_id = 2-digit county code + ",
  "4-digit district code (6 characters); school_id = district_id + 3-digit ",
  "school code (9 characters), on school rows only. Verbatim, leading zeros ",
  "preserved."
)

#' Classified error condition for directory failures
#' @keywords internal
#' @noRd
dc_stop <- function(message, class) {
  stop(structure(
    class = c(class, "error", "condition"),
    list(message = message, call = NULL)
  ))
}

#' Fetch the current New Jersey education directory (directory-contract/v1)
#'
#' Downloads the current official New Jersey directory from the NJDOE Homeroom
#' public download endpoints and returns the canonical triple
#' \code{list(entities, roles, meta)} defined by directory-contract/v1.
#' Districts (including single-site charter LEAs) are keyed by the county +
#' district CDS code; schools by the county + district + school CDS code.
#' District superintendents, business administrators, and special-education
#' coordinators are attached as district-grain \code{roles}; school principals
#' as school-grain \code{roles}. Source-declared vacancies are rows with
#' \code{person_name} \code{NA} and the verbatim \code{title_raw} preserved.
#'
#' The New Jersey source publishes SPLIT first/last name fields; \code{first_name}
#' and \code{last_name} come directly from those source columns and
#' \code{person_name} is assembled from them (see \code{R/directory_contract.R}).
#'
#' @return A named list with components:
#'   \describe{
#'     \item{entities}{One row per organization (district / school),
#'       canonically sorted.}
#'     \item{roles}{One row per organization-role assignment (long),
#'       canonically sorted.}
#'     \item{meta}{Self-describing metadata: schema version, sources, id scheme,
#'       coverage, counts, and quality.}
#'   }
#' @export
#' @examples
#' \dontrun{
#' dir <- fetch_directory()
#' dir$entities
#' dir$roles
#' dir$meta$counts
#' }
fetch_directory <- function() {
  retrieved_at <- dc_iso8601()

  district_raw <- tryCatch(
    download_nj_directory(DIRECTORY_DISTRICT_URL, "district"),
    error = function(e) e
  )
  school_raw <- tryCatch(
    download_nj_directory(DIRECTORY_SCHOOL_URL, "school"),
    error = function(e) e
  )

  district_ok <- !inherits(district_raw, "error")
  school_ok <- !inherits(school_raw, "error")

  if (!district_ok && !school_ok) {
    return(directory_source_unavailable(retrieved_at))
  }

  entities_d <- if (district_ok) {
    build_directory_entities_district(district_raw)
  } else {
    empty_directory_entities()
  }
  entities_s <- if (school_ok) {
    build_directory_entities_school(school_raw)
  } else {
    empty_directory_entities()
  }
  entities <- dplyr::bind_rows(entities_d, entities_s)

  roles_d <- if (district_ok) {
    build_directory_roles_district(district_raw, entities_d)
  } else {
    empty_directory_roles()
  }
  roles_s <- if (school_ok) {
    build_directory_roles_school(school_raw, entities_s)
  } else {
    empty_directory_roles()
  }
  roles <- dplyr::bind_rows(roles_d, roles_s)

  # De-duplicate on the canonical keys (defensive; the source is single-row
  # per organization and per organization-slot).
  entities <- entities[!duplicated(paste(
    entities$entity_type, entities$district_id, entities$school_id, sep = "\r"
  )), , drop = FALSE]
  roles <- roles[!duplicated(paste(
    roles$district_id, roles$school_id, roles$role, roles$person_name,
    sep = "\r"
  )), , drop = FALSE]

  entities <- dc_sort_entities(entities)
  roles <- dc_sort_roles(roles)

  source_status <- if (district_ok && school_ok) "ok" else "partial"

  sources <- list(
    list(
      name = "NJDOE Homeroom Public School Districts download",
      url = DIRECTORY_DISTRICT_URL,
      retrieved_at = if (district_ok) retrieved_at else NA_character_,
      status = if (district_ok) "ok" else "failed"
    ),
    list(
      name = "NJDOE Homeroom Public Schools download (includes grade levels)",
      url = DIRECTORY_SCHOOL_URL,
      retrieved_at = if (school_ok) retrieved_at else NA_character_,
      status = if (school_ok) "ok" else "failed"
    )
  )

  coverage <- list(
    district_roles = c(
      "superintendent", "assistant_superintendent", "business_administrator",
      "special_education_director", "other"
    ),
    school_roles = c("principal", "other"),
    org_only = FALSE,
    principal_only = FALSE,
    notes = paste0(
      "District personnel are the superintendent (however titled: ",
      "Superintendent, Chief School Administrator, Lead of Charter School), ",
      "the business administrator, and the special-education coordinator, each ",
      "from its own NJDOE Homeroom source column. School personnel are the ",
      "principal. Verbatim titles are preserved in title_raw; the visible role ",
      "map (R/directory_role_map.R) supplies role. Source-declared vacancies ",
      "are person_name NA with title_raw retained. The Homeroom files also ",
      "list HIB coordinators, state testing coordinators, PARCC IT contacts, ",
      "school safety specialists, and homeless liaisons; those contacts are ",
      "outside this contract's leadership vocabulary and are not surfaced as ",
      "roles. Nonpublic schools (a separate Homeroom download) are not included."
    )
  )

  meta <- dc_build_meta(
    entities = entities,
    roles = roles,
    state = "nj",
    sources = sources,
    id_scheme = DIRECTORY_ID_SCHEME,
    coverage = coverage,
    source_status = source_status,
    retrieved_at = retrieved_at
  )

  list(entities = entities, roles = roles, meta = meta)
}


# -----------------------------------------------------------------------------
# Source download (self-contained; the directory endpoints are not part of the
# registered source-transport allowlist)
# -----------------------------------------------------------------------------

#' Download and clean an NJDOE Homeroom directory CSV
#'
#' Downloads the CSV (three descriptive header rows precede the column header),
#' reads it as all-character, then applies the standard NJ cleaning: UTF-8
#' re-encode, strip Excel formula padding (\code{="01"} -> \code{01}), and trim.
#' Errors (transport failure, HTTP error, or a response that is not the expected
#' CSV) are raised and become source_status "partial"/"source_unavailable".
#' @keywords internal
#' @noRd
download_nj_directory <- function(url, label) {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  response <- httr::GET(
    url,
    httr::write_disk(tmp, overwrite = TRUE),
    httr::timeout(120),
    httr::user_agent(paste0("njschooldata/", utils::packageVersion("njschooldata")))
  )
  if (httr::http_error(response)) {
    dc_stop(
      paste0("NJDOE ", label, " directory download failed: HTTP ",
             httr::status_code(response)),
      "directory_parse_error"
    )
  }

  parsed <- tryCatch(
    suppressWarnings(readr::read_csv(
      tmp, skip = 3,
      col_types = readr::cols(.default = readr::col_character()),
      show_col_types = FALSE
    )),
    error = function(e) e
  )
  if (inherits(parsed, "error") || !is.data.frame(parsed) || nrow(parsed) == 0L) {
    dc_stop(
      paste0("NJDOE ", label, " directory response was not a parseable CSV"),
      "directory_parse_error"
    )
  }

  df <- janitor::clean_names(parsed)
  required <- c("county_code", "district_code")
  if (label == "school") required <- c(required, "school_code")
  missing <- setdiff(required, names(df))
  if (length(missing) > 0L) {
    dc_stop(
      paste0("NJDOE ", label, " directory is missing required columns: ",
             paste(missing, collapse = ", ")),
      "directory_parse_error"
    )
  }

  char_cols <- names(df)[vapply(df, is.character, logical(1))]
  for (col in char_cols) {
    df[[col]] <- iconv(df[[col]], from = "", to = "UTF-8", sub = "")
    df[[col]] <- kill_padformulas(df[[col]])
    df[[col]] <- dc_blank_to_na(df[[col]])
  }
  df
}


# -----------------------------------------------------------------------------
# Entities
# -----------------------------------------------------------------------------

#' Empty entities frame with the canonical column types
#' @keywords internal
#' @noRd
empty_directory_entities <- function() {
  dplyr::tibble(
    state = character(0), entity_type = character(0),
    entity_subtype = character(0), district_id = character(0),
    school_id = character(0), district_name = character(0),
    school_name = character(0), nces_district_id = character(0),
    nces_school_id = character(0), parent_district_id = character(0),
    county_name = character(0), grades_served = character(0),
    address = character(0), city = character(0), zip = character(0),
    phone = character(0), website = character(0), status = character(0),
    is_charter = logical(0)
  )
}

#' Combine NJDOE address lines
#' @keywords internal
#' @noRd
directory_address <- function(df) {
  a1 <- if ("address1" %in% names(df)) df$address1 else rep(NA_character_, nrow(df))
  a2 <- if ("address2" %in% names(df)) df$address2 else rep(NA_character_, nrow(df))
  out <- ifelse(is.na(a2), a1, ifelse(is.na(a1), a2, paste(a1, a2)))
  dc_blank_to_na(out)
}

#' Build the canonical district entities frame
#' @keywords internal
#' @noRd
build_directory_entities_district <- function(d) {
  county <- d$county_code
  district <- d$district_code
  if (any(is.na(county)) || any(is.na(district))) {
    dc_stop("district source has a missing county or district code",
            "directory_integrity_error")
  }
  district_id <- paste0(county, district)
  is_charter <- county == "80"

  dplyr::tibble(
    state = "nj",
    entity_type = "district",
    entity_subtype = ifelse(is_charter, "charter", NA_character_),
    district_id = district_id,
    school_id = NA_character_,
    district_name = d$district_name,
    school_name = NA_character_,
    nces_district_id = if ("nces_id" %in% names(d)) d$nces_id else NA_character_,
    nces_school_id = NA_character_,
    parent_district_id = NA_character_,
    county_name = if ("county_name" %in% names(d)) d$county_name else NA_character_,
    grades_served = NA_character_,
    address = directory_address(d),
    city = if ("city" %in% names(d)) d$city else NA_character_,
    zip = if ("zip" %in% names(d)) d$zip else NA_character_,
    phone = if ("phone" %in% names(d)) d$phone else NA_character_,
    website = if ("website" %in% names(d)) d$website else NA_character_,
    status = "active",
    is_charter = is_charter
  )
}

#' Build a "PK, K, 01..12, Post-Grad, Adult Ed" grade span from grade columns
#' @keywords internal
#' @noRd
directory_grades_served <- function(s) {
  grade_cols <- c("pre_k", "kindergarten", paste0("grade_", 1:12),
                  "post_grad", "adult_ed")
  grade_labels <- c("PK", "K", sprintf("%02d", 1:12), "Post-Grad", "Adult Ed")
  present <- grade_cols %in% names(s)
  cols <- grade_cols[present]
  labels <- grade_labels[present]
  if (length(cols) == 0L) return(rep(NA_character_, nrow(s)))
  mat <- as.data.frame(s[, cols, drop = FALSE])
  vapply(seq_len(nrow(mat)), function(i) {
    row <- mat[i, , drop = TRUE]
    offered <- which(!is.na(row) & row != "0")
    if (length(offered) == 0L) return(NA_character_)
    paste(labels[offered], collapse = ", ")
  }, character(1))
}

#' Build the canonical school entities frame
#' @keywords internal
#' @noRd
build_directory_entities_school <- function(s) {
  county <- s$county_code
  district <- s$district_code
  school <- s$school_code
  if (any(is.na(county)) || any(is.na(district)) || any(is.na(school))) {
    dc_stop("school source has a missing county, district, or school code",
            "directory_integrity_error")
  }
  district_id <- paste0(county, district)
  school_id <- paste0(county, district, school)
  if (!all(startsWith(school_id, district_id))) {
    dc_stop("school_id composite disagrees with its county+district parts",
            "directory_integrity_error")
  }
  is_charter <- county == "80"

  ent <- dplyr::tibble(
    state = "nj",
    entity_type = "school",
    entity_subtype = ifelse(is_charter, "charter", NA_character_),
    district_id = district_id,
    school_id = school_id,
    district_name = s$district_name,
    school_name = s$school_name,
    nces_district_id = NA_character_,
    nces_school_id = if ("nces_code" %in% names(s)) s$nces_code else NA_character_,
    parent_district_id = NA_character_,
    county_name = if ("county_name" %in% names(s)) s$county_name else NA_character_,
    grades_served = directory_grades_served(s),
    address = directory_address(s),
    city = if ("city" %in% names(s)) s$city else NA_character_,
    zip = if ("zip" %in% names(s)) s$zip else NA_character_,
    phone = if ("phone" %in% names(s)) s$phone else NA_character_,
    website = NA_character_,
    status = "active",
    is_charter = is_charter
  )

  bad <- is.na(ent$school_name)
  if (any(bad)) {
    dc_stop(
      paste("school entities missing school_name for school_id:",
            paste(ent$school_id[bad], collapse = ", ")),
      "directory_parse_error"
    )
  }
  ent
}


# -----------------------------------------------------------------------------
# Roles
# -----------------------------------------------------------------------------

#' Empty roles frame with the canonical column types
#' @keywords internal
#' @noRd
empty_directory_roles <- function() {
  dplyr::tibble(
    state = character(0), district_id = character(0),
    school_id = character(0), entity_type = character(0),
    role = character(0), title_raw = character(0),
    person_name = character(0), first_name = character(0),
    last_name = character(0), email = character(0), phone = character(0)
  )
}

#' Assemble one district-grain role slot into long roles rows
#'
#' A role row is emitted only where the slot's verbatim title2 is present
#' (title_raw is required on every roles row). person_name is NA when both name
#' parts are absent -- a source-declared vacancy with the title retained.
#' @keywords internal
#' @noRd
build_directory_role_slot <- function(df, entities, slot,
                                       title_col, first_col, last_col,
                                       email_col = NULL) {
  if (!title_col %in% names(df)) return(empty_directory_roles())
  title_raw <- df[[title_col]]
  keep <- !is.na(title_raw)
  if (!any(keep)) return(empty_directory_roles())

  county <- df$county_code[keep]
  district <- df$district_code[keep]
  district_id <- paste0(county, district)
  title_raw <- title_raw[keep]
  first <- if (first_col %in% names(df)) df[[first_col]][keep] else NA_character_
  last <- if (last_col %in% names(df)) df[[last_col]][keep] else NA_character_
  email <- if (!is.null(email_col) && email_col %in% names(df)) {
    df[[email_col]][keep]
  } else {
    rep(NA_character_, sum(keep))
  }

  dplyr::tibble(
    state = "nj",
    district_id = district_id,
    school_id = NA_character_,
    entity_type = "district",
    role = nj_map_role(title_raw, slot),
    title_raw = title_raw,
    person_name = dc_assemble_person_name(first, last),
    first_name = dc_blank_to_na(first),
    last_name = dc_blank_to_na(last),
    email = dc_blank_to_na(email),
    phone = NA_character_
  )
}

#' Build the district-grain roles frame (superintendent, business
#' administrator, special-education coordinator)
#'
#' Every role row references an existing district entity; a personnel row whose
#' district is absent from the entity panel is an integrity error, never dropped
#' or synthesized.
#' @keywords internal
#' @noRd
build_directory_roles_district <- function(d, entities) {
  roles <- dplyr::bind_rows(
    build_directory_role_slot(d, entities, "district_chief",
      "supt_title_2", "supt_first_name", "supt_last_name", "supt_e_mail"),
    build_directory_role_slot(d, entities, "business",
      "ba_title2", "ba_first_name", "ba_last_name", "ba_email"),
    build_directory_role_slot(d, entities, "special_ed",
      "sec_title2", "sec_first_name", "sec_last_name")
  )
  district_ids <- entities$district_id[entities$entity_type == "district"]
  orphan <- setdiff(roles$district_id, district_ids)
  if (length(orphan) > 0L) {
    dc_stop(
      paste("district personnel reference districts absent from the panel:",
            paste(orphan, collapse = ", ")),
      "directory_integrity_error"
    )
  }
  roles
}

#' Build the school-grain roles frame (principal)
#' @keywords internal
#' @noRd
build_directory_roles_school <- function(s, entities) {
  if (!"princ_title_2" %in% names(s)) return(empty_directory_roles())
  title_raw <- s$princ_title_2
  keep <- !is.na(title_raw)
  if (!any(keep)) return(empty_directory_roles())

  district_id <- paste0(s$county_code[keep], s$district_code[keep])
  school_id <- paste0(s$county_code[keep], s$district_code[keep], s$school_code[keep])
  title_raw <- title_raw[keep]
  first <- s$princ_first_name[keep]
  last <- s$princ_last_name[keep]
  email <- if ("princ_email" %in% names(s)) s$princ_email[keep] else NA_character_

  roles <- dplyr::tibble(
    state = "nj",
    district_id = district_id,
    school_id = school_id,
    entity_type = "school",
    role = nj_map_role(title_raw, "principal"),
    title_raw = title_raw,
    person_name = dc_assemble_person_name(first, last),
    first_name = dc_blank_to_na(first),
    last_name = dc_blank_to_na(last),
    email = dc_blank_to_na(email),
    phone = NA_character_
  )

  school_ids <- entities$school_id[entities$entity_type == "school"]
  orphan <- setdiff(roles$school_id, school_ids)
  if (length(orphan) > 0L) {
    dc_stop(
      paste("principal personnel reference schools absent from the panel:",
            paste(orphan, collapse = ", ")),
      "directory_integrity_error"
    )
  }
  roles
}


#' Build the conforming declared-miss result when upstream is unreachable
#' @keywords internal
#' @noRd
directory_source_unavailable <- function(retrieved_at) {
  entities <- empty_directory_entities()
  roles <- empty_directory_roles()
  sources <- list(
    list(
      name = "NJDOE Homeroom Public School Districts download",
      url = DIRECTORY_DISTRICT_URL,
      retrieved_at = NA_character_, status = "failed"
    ),
    list(
      name = "NJDOE Homeroom Public Schools download (includes grade levels)",
      url = DIRECTORY_SCHOOL_URL,
      retrieved_at = NA_character_, status = "failed"
    )
  )
  coverage <- list(
    district_roles = c(
      "superintendent", "assistant_superintendent", "business_administrator",
      "special_education_director", "other"
    ),
    school_roles = c("principal", "other"),
    org_only = FALSE, principal_only = FALSE,
    notes = "Upstream NJDOE Homeroom directory downloads were unreachable at fetch time."
  )
  meta <- dc_build_meta(
    entities = entities, roles = roles, state = "nj", sources = sources,
    id_scheme = DIRECTORY_ID_SCHEME, coverage = coverage,
    source_status = "source_unavailable", retrieved_at = retrieved_at
  )
  list(entities = entities, roles = roles, meta = meta)
}
