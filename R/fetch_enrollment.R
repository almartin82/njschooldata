# ==============================================================================
# Enrollment Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading enrollment data from the
# NJ Department of Education website.
#
# ==============================================================================

#' Read an NJ DOE enrollment percentage column as published
#'
#' NJ DOE publishes some fall-enrollment percentages as a censoring token
#' instead of a value - most visibly `">95"`, used from the 2019-20 file
#' onward wherever a share exceeds 95 percent. A censored cell is UNKNOWN, not
#' a number, so every non-numeric token becomes `NA` and stays `NA`. This
#' mirrors the suppression handling already applied to graduation data in
#' [process_grate()].
#'
#' Substituting a midpoint (or any other stand-in) for the token would invent
#' the percentage, and because these populations are published only as
#' percentages, the count derived by multiplying it by total enrollment would
#' be an invented headcount presented as an NJ DOE figure.
#'
#' @param x A percentage column exactly as published.
#' @return A numeric vector, `NA` wherever NJ DOE censored or omitted the value.
#' @keywords internal
enr_pct_published_value <- function(x) {
  token <- trimws(as.character(x))
  token <- sub("%$", "", token)

  # A published percentage is a bare number and nothing else. Anything that is
  # not (">95", "*", "N", "", ...) is the source declining to report a value.
  published <- grepl("^[0-9]*\\.?[0-9]+$", token)
  token[!published] <- NA_character_

  as.numeric(token)
}

.normalize_enr_headers <- function(data) {
  data %>%
    dplyr::rename_with(
      ~ dplyr::case_when(
        . == "Pre -K Halfday" ~ "Pre-K Halfday",
        . == "Pre-K FullDay" ~ "Pre-K Fullday",
        . %in% c("Pre-K\r\n Full day", "Pre-K\n Full day") ~ "Pre-K Fullday",
        . == "Pre-K Half Day" ~ "Pre-K Halfday",
        . == "Eight Grade" ~ "Eighth Grade",
        . == "Reduced_Lunch" ~ "Reduced Lunch",
        . == "% Reduced_Lunch" ~ "%Reduced Lunch",
        # 2024+ renamed English Learners to Multilingual Learners
        . == "Multilingual Learners" ~ "English Learners",
        . == "%Multilingual Learners" ~ "%English Learners",
        # 2024+ renamed Hawaiian Native
        . == "Hawaiian Native" ~ "Pacific Islander",
        . == "%Hawaiian Native" ~ "%Pacific Islander",
        TRUE ~ .
      )
    )
}

.enr_grade_count_names <- function(end_year = NULL) {
  grade_names <- c(
    "Pre-K Halfday", "Pre-K Fullday",
    "Kindergarten Halfday", "Kindergarten Fullday",
    "First Grade", "Second Grade", "Third Grade", "Fourth Grade",
    "Fifth Grade", "Sixth Grade", "Seventh Grade", "Eighth Grade",
    "Ninth Grade", "Tenth Grade", "Eleventh Grade", "Twelfth Grade"
  )
  # Retained 2020-2026 District headers show every listed
  # count column in every year. `Ungraded` is present through 2023 and absent
  # in 2024-2026. The 2022-2023 spelling `Eight Grade` is normalized before
  # this check; percentage companions are interleaved from 2024 onward.
  if (is.null(end_year) || as.integer(end_year)[1] <= 2023L) {
    c(grade_names, "Ungraded")
  } else {
    grade_names
  }
}

.enr_schema_error <- function(missing, unexpected, end_year) {
  details <- character()
  if (length(missing)) {
    details <- c(
      details,
      paste0("missing expected grade columns: ", paste(missing, collapse = ", "))
    )
  }
  if (length(unexpected)) {
    details <- c(
      details,
      paste0(
        "unrecognised column(s) inside grade block: ",
        paste(unexpected, collapse = ", ")
      )
    )
  }
  condition <- structure(
    list(
      message = paste0(
        "Enrollment grade schema for ", end_year, " has ",
        paste(details, collapse = "; "), "."
      ),
      call = NULL,
      missing_columns = missing,
      unexpected_columns = unexpected,
      end_year = end_year
    ),
    class = c(
      "njsd_enrollment_schema_error", "njsd_parse_error", "error", "condition"
    )
  )
  stop(condition)
}

.enr_grade_count_columns <- function(column_names, end_year = NULL) {
  grade_names <- .enr_grade_count_names(end_year)
  missing <- setdiff(grade_names, column_names)
  recognized <- intersect(grade_names, column_names)
  unexpected <- character()

  if (length(recognized)) {
    positions <- match(recognized, column_names)
    block <- column_names[seq.int(min(positions), max(positions))]
    unexpected <- setdiff(
      block,
      c(grade_names, block[grepl("^%", block)])
    )
  }

  if (length(missing) || length(unexpected)) {
    .enr_schema_error(missing, unexpected, end_year %||% "unknown")
  }

  recognized
}

.enr_source_vintage <- function(end_year) {
  paste0(end_year - 1L, "-", sprintf("%02d", end_year %% 100L))
}

.enr_raw_cache_path <- function(end_year, digest) {
  file.path(
    njsd_cache_root(), "enrollment-sources",
    paste0("enrollment-", end_year, "-", digest, ".zip")
  )
}

.retain_enr_source <- function(result, end_year) {
  raw_dir <- file.path(njsd_cache_root(), "enrollment-sources")
  dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
  raw_path <- .enr_raw_cache_path(end_year, result$digest)

  if (!file.exists(raw_path) ||
      !identical(.source_digest(raw_path), result$digest)) {
    if (file.exists(raw_path)) unlink(raw_path)
    moved <- file.rename(result$data, raw_path)
    if (!moved && !file.copy(result$data, raw_path, overwrite = FALSE) &&
        !file.exists(raw_path)) {
      stop("Validated enrollment source could not be retained.", call. = FALSE)
    }
  }

  if (!identical(.source_digest(raw_path), result$digest)) {
    stop("Retained enrollment source digest differs from the download.", call. = FALSE)
  }
  .release_source_result(result)
  normalizePath(raw_path, mustWork = TRUE)
}

.enr_cached_source_is_valid <- function(data, end_year) {
  records <- get_source_results(data)
  if (!nrow(records)) return(FALSE)

  digest <- as.character(records$digest[[1]])
  if (length(digest) != 1L || is.na(digest) ||
      !grepl("^[0-9a-f]{64}$", digest)) {
    return(FALSE)
  }

  raw_path <- .enr_raw_cache_path(end_year, digest)
  if (!file.exists(raw_path)) return(FALSE)

  isTRUE(tryCatch(
    identical(.source_digest(raw_path), digest),
    error = function(error) FALSE
  ))
}

.attach_enr_contract <- function(data, end_year, source_result = NULL) {
  records <- get_source_results(data)
  if (inherits(source_result, "njsd_source_result")) {
    raw_path <- source_result$raw_path
    raw_sha256 <- source_result$digest
    source_url <- source_result$source_url
    source_mode <- source_result$source_mode
  } else {
    if (!nrow(records)) {
      stop("Enrollment data has no source provenance record.", call. = FALSE)
    }
    record <- records[1, , drop = FALSE]
    raw_sha256 <- record$digest[[1]]
    raw_path <- .enr_raw_cache_path(end_year, raw_sha256)
    source_url <- record$source_url[[1]]
    source_mode <- "live"
  }

  raw_sha256 <- as.character(raw_sha256)[1]
  if (!file.exists(raw_path) ||
      !isTRUE(tryCatch(
        identical(.source_digest(raw_path), raw_sha256),
        error = function(error) FALSE
      ))) {
    stop("Enrollment source bytes are missing or do not match their digest.",
         call. = FALSE)
  }

  raw_path <- normalizePath(raw_path, mustWork = TRUE)
  attr(data, "raw_path") <- raw_path
  attr(data, "raw_sha256") <- raw_sha256
  attr(data, "source_url") <- as.character(source_url)[1]
  attr(data, "source_mode") <- as.character(source_mode %||% "live")[1]
  attr(data, "source_vintage") <- .enr_source_vintage(end_year)
  attr(data, "official_source") <- TRUE
  data
}


#' Parse a validated zipped fall enrollment artifact
#'
#' @param tname Path to a validated NJ DOE enrollment ZIP.
#' @param end_year A school year. Year is the end of the academic year - eg
#'   2006-07 school year is year '2007'.
#' @return Data frame with raw enrollment data
#' @keywords internal
.parse_enr_archive <- function(tname, end_year) {
  tdir <- tempfile(pattern = "enr-unpack-")
  dir.create(tdir)
  on.exit(unlink(tdir, recursive = TRUE), add = TRUE)
  utils::unzip(tname, exdir = tdir)

  # Read file
  enr_files <- utils::unzip(tname, list = TRUE)

  if (grepl(".xls", tolower(enr_files$Name[1]))) {
    this_file <- file.path(tdir, enr_files$Name[1])

    to_skip <- dplyr::case_when(
      end_year == 2018 ~ 1,
      end_year >= 2019 ~ 2,
      TRUE ~ 0
    )

    if (end_year < 2020) {
      enr <- readxl::read_excel(this_file, skip = to_skip)

      # Starting in the 2020 school year the format changes significantly
      # Three distinct worksheets to combine
    } else if (end_year >= 2020) {

      # In 2020 they leave a stray space in this sheet name
      enr_state <- readxl::read_excel(
        this_file, sheet = ifelse(end_year == 2020, "State ", "State"), skip = 2
      )
      enr_dist <- readxl::read_excel(this_file, sheet = "District", skip = 2)
      enr_sch <- readxl::read_excel(this_file, sheet = "School", skip = 2)

      # Normalize observed spelling/header aliases before combining sheets.
      enr_state <- enr_state %>% .normalize_enr_headers()
      enr_dist <- enr_dist %>% .normalize_enr_headers()
      enr_sch <- enr_sch %>% .normalize_enr_headers()

      # .normalize_enr_headers() only corrects column *names*. On the State worksheet the
      # grade labels live in row *values* of the `Grade` column, where NJ DOE
      # ships "Eight Grade" (sic). Left uncorrected this fails to map to grade
      # level "08", so state-level 8th grade enrollment silently lands in an
      # NA-grade row. District/School sheets are unaffected (grades are columns
      # there and already corrected above). See issue: state grade-8 dropout.
      if ("Grade" %in% names(enr_state)) {
        enr_state <- enr_state %>%
          dplyr::mutate(
            Grade = dplyr::if_else(Grade == "Eight Grade", "Eighth Grade", Grade)
          )
      }

      # Set some constants
      enr_dist <- enr_dist %>%
        dplyr::mutate(
          `School Code` = "999",
          `School Name` = "District Total"
        )

      # Combine state, dist, sch df by binding dist and sch and then
      # pivoting grade level columns long
      enr_dist_sch <- dplyr::bind_rows(enr_dist, enr_sch)

      # Percentage columns are used to derive counts when the corresponding
      # count is not published. A companion "<field> Value Source" column
      # records the result per row so it can survive into `fetch_enr()`'s wide
      # output and `tidy_enr()`'s long pivot (see get_enr_column_order() and
      # tidy_enr()): "derived_from_pct" where the arithmetic produced a real
      # number, "published_pct_only" where it did not, and "published" where
      # the workbook also carries the count column. English Learners uses the
      # published count when the workbook provides it.
      #
      # NJ DOE censors a percentage above 95 as the token ">95" rather than a
      # value. A censored cell is UNKNOWN. It stays NA, and the count derived
      # from it is therefore NA too. Never substitute a midpoint for the token:
      # the percentage would be invented, and the headcount produced by
      # multiplying it by enrollment would be an invented headcount published
      # as though NJ DOE had reported it.
      pct_cols <- c(
        "%Free Lunch", "%Reduced Lunch", "%English Learners",
        "%Migrant", "%Military", "%Homeless"
      )

      for (pct_col in pct_cols) {
        if (!pct_col %in% names(enr_dist_sch)) next
        count_col <- sub("^%", "", pct_col)
        # Title Case, matching count_col, so clean_enr_names() maps it the
        # same way as its sibling raw columns (eg "Free Lunch Value Source").
        source_col <- paste0(count_col, " Value Source")

        if (count_col == "English Learners" && count_col %in% names(enr_dist_sch)) {
          enr_dist_sch[[source_col]] <- "published"
        } else {
          enr_dist_sch[[count_col]] <-
            enr_pct_published_value(enr_dist_sch[[pct_col]]) / 100 *
            enr_dist_sch[["Total Enrollment"]]
          enr_dist_sch[[source_col]] <- ifelse(
            is.na(enr_dist_sch[[count_col]]), "published_pct_only", "derived_from_pct"
          )
        }
      }

      # Select only the named enrollment count columns. Percentage columns are
      # interleaved with these columns in recent NJ DOE workbooks.
      all_cols <- names(enr_dist_sch)
      grade_cols <- .enr_grade_count_columns(all_cols, end_year)

      enr <- enr_dist_sch %>%
        dplyr::select(
          `County Code`:`District Name`, `School Code`, `School Name`,
          dplyr::all_of(grade_cols)
        ) %>%
        tidyr::pivot_longer(
          cols = dplyr::all_of(grade_cols),
          names_to = "Grade",
          values_to = "Total Enrollment"
        ) %>%
        dplyr::bind_rows(
          enr_dist_sch %>%
            dplyr::select(-dplyr::all_of(grade_cols)) %>%
            dplyr::mutate(Grade = "All Grades")
        ) %>%
        dplyr::bind_rows(
          enr_state %>%
            dplyr::rename(
              "Total Enrollment" = "Total",
              "Native American" = "American Indian"
            )
        )
    }
  } else if (grepl(".csv", tolower(enr_files$Name[1]))) {
    enr <- readr::read_csv(
      file = file.path(tdir, enr_files$Name[1]),
      na = c("     . ", ".", ""),
      show_col_types = FALSE
    )
  }

  enr$end_year <- end_year

  # Specific fixes
  # 2010 pre-k disabled issue
  if (end_year == 2010) {
    mask <- enr$PROGRAM_CODE == "32" & enr$PROGRAM_NAME == "Half Day Preschool Dis"
    enr[mask, "PROGRAM_CODE"] <- "33"
  }

  # 2013 marin issue
  if (end_year == 2013) {
    mask <- enr$`SCHOOL NAME` == "LUIS MUNOZ MARIN ELEM SCH" & enr$`DISTRICT NAME` == "NEWARK"
    enr[mask, "DISTRICT NAME"] <- "THE NEWARK PUBLIC SCHOOLS"
  }

  return(enr)
}

#' Retrieve and parse one enrollment source
#'
#' @param end_year School-year end year.
#' @param request_fn Injectable transport request function used by offline tests.
#' @return An `njsd_source_result` containing raw enrollment data.
#' @keywords internal
.download_enrollment_source <- function(
    end_year, request_fn = .default_source_request) {
  validate_end_year(end_year, "enrollment")
  candidates <- resolve_source_url("enrollment", end_year = end_year)
  failures <- list()

  for (candidate in candidates) {
    transport <- download_source(
      candidate,
      source_type = "zip",
      request_fn = request_fn
    )
    if (!identical(transport$source_status, "actual")) {
      failures[[length(failures) + 1L]] <- transport
      if (identical(transport$source_status, "parse_error")) return(transport)
      next
    }
    return(transport)
  }

  errors <- vapply(failures, function(result) result$error, character(1))
  new_source_result(
    source_status = "source_unavailable",
    source_url = candidates[1],
    retrieved_at = if (length(failures)) failures[[length(failures)]]$retrieved_at else NULL,
    error = paste(unique(errors[!is.na(errors)]), collapse = "; ")
  )
}

get_raw_enr_result <- function(end_year, request_fn = .default_source_request) {
  transport <- .download_enrollment_source(end_year, request_fn)
  if (!identical(transport$source_status, "actual")) return(transport)

  on.exit(.release_source_result(transport), add = TRUE)
  parsed <- tryCatch(
    .parse_enr_archive(transport$data, end_year),
    error = identity
  )
  if (inherits(parsed, "error")) {
    return(new_source_result(
      source_status = "parse_error",
      source_url = transport$source_url,
      retrieved_at = transport$retrieved_at,
      digest = transport$digest,
      error = conditionMessage(parsed)
    ))
  }
  raw_path <- .retain_enr_source(transport, end_year)
  result <- new_source_result(
    data = parsed,
    source_status = "actual",
    source_url = transport$source_url,
    retrieved_at = transport$retrieved_at,
    digest = transport$digest
  )
  result$raw_path <- raw_path
  result$source_mode <- "live"
  result$source_vintage <- .enr_source_vintage(end_year)
  result$official_source <- TRUE
  result
}

#' Read a zipped Excel fall enrollment file from the NJ state website
#'
#' @param end_year A school-year end year. Valid values are 1999-2026.
#' @return Data frame with raw enrollment data.
#' @keywords internal
get_raw_enr <- function(end_year) {
  source_result_data(get_raw_enr_result(end_year))
}


#' Gets and processes a NJ enrollment file
#'
#' `fetch_enr` is a wrapper around `get_raw_enr` and `process_enr` that
#' downloads and cleans enrollment data for a given year.
#'
#' @param end_year A school year. Year is the end of the academic year - eg 2006-07
#' school year is year '2007'. Valid values are 1999-2026.
#' @param tidy If TRUE, takes the unwieldy wide data and normalizes into a
#' long, tidy data frame with limited headers - constants (school/district name and code),
#' subgroup (all the enrollment file subgroups), program/grade and measure (row_total, free lunch, etc).
#' @param use_cache If TRUE, uses the session cache to avoid re-downloading data.
#' See \code{\link{njsd_cache_info}} for cache details.
#' @return Data frame with processed enrollment data. From 2020+ files,
#' `free_lunch`/`reduced_lunch`/`migrant`/`homeless` are computed as
#' `pct / 100 * row_total` from NJ DOE's published percentage and this
#' entity/year's own published total enrollment (never rounded to a whole
#' student). For English Learners, a published count is preserved when the
#' workbook provides one; otherwise the published percentage is used in the
#' same calculation. `tidy = TRUE` output carries a `value_source` column
#' (`"published"`, `"derived_from_pct"`, or `"published_pct_only"`; see
#' \code{\link{tidy_enr}}) and `tidy = FALSE` wide output carries the same
#' provenance per field as `<field>_value_source` (eg `lep_value_source`).
#' Pre-2020 files publish these fields as real counts directly (`"published"`).
#' @export
#' @examples
#' \dontrun{
#' # Get 2023 enrollment data
#' enr_2023 <- fetch_enr(2023)
#'
#' # Get tidy (long format) enrollment data
#' enr_tidy <- fetch_enr(2023, tidy = TRUE)
#'
#' # Use caching for faster repeat calls
#' enr_cached <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
#' }
fetch_enr <- function(end_year, tidy = FALSE, use_cache = FALSE) {
  if (use_cache) {
    key <- make_cache_key("fetch_enr", end_year = end_year, tidy = tidy)
    cached <- cache_get(key)
    if (!is.null(cached)) {
      if (.enr_cached_source_is_valid(cached, end_year)) {
        message("Using cached enrollment data.")
        return(.attach_enr_contract(cached, end_year))
      }
      message("Cached enrollment data has no matching retained source; refetching.")
    }
  }

  source_result <- get_raw_enr_result(end_year)
  enr_data <- source_result_data(source_result) %>%
    process_enr() %>%
    # Attach federal NCES ids (LEAID / NCESSCH) on the wide frame so they carry
    # through to tidy as well. Identifiers only — no federal data values.
    attach_nces_ids()

  if (tidy) {
    enr_data <- tidy_enr(enr_data) %>%
      id_enr_aggs()
  }

  enr_data <- attach_source_results(
    enr_data,
    source_result_record(source_result, "enrollment", end_year, "enrollment")
  )

  if (use_cache) {
    cache_set(key, enr_data)
  }

  .attach_enr_contract(enr_data, end_year, source_result)
}
