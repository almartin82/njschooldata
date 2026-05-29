# ==============================================================================
# Special Education Placement / Educational Environment (IDEA Section 618)
# ==============================================================================
#
# Fetcher for the NJ DOE "Student Count and Educational Environment" data
# published under IDEA Section 618 public reporting. This is the placement
# (Least Restrictive Environment / LRE) dataset that complements the existing
# fetch_sped() classification-rate fetcher.
#
# Closes #46. v1 (end_year 2025 only) shipped in PR #278 (commit 4710b754).
# v2 (#278 follow-up, 0.9.13) extends coverage to end_years 2020-2024.
#
# ------------------------------------------------------------------------------
# URL conventions discovered for 2020-2025 (implementation discovery, 2026-05)
# ------------------------------------------------------------------------------
# NJ DOE labels its IDEA 618 directories by school-year START year, while this
# package keys on END year. The mapping is:
#
#   | end_year | NJ "label" | base URL                                                  |
#   |----------|------------|-----------------------------------------------------------|
#   | 2020     | 2019       | docs/2019.zip                          (zip of xlsx + pdf) |
#   | 2021     | 2020       | docs/2020.zip                          (zip of xlsx + pdf) |
#   | 2022     | 2021       | docs/2022%20data/                      (loose xlsx files)  |
#   | 2023     | 2022       | docs/2022public618data/                (loose xlsx files)  |
#   | 2024     | 2023       | docs/2023_618data/                     (loose xlsx files)  |
#   | 2025     | 2024       | docs/2025_618data/                     (consolidated)      |
#
# Each pre-2025 year publishes 4 single-subgroup workbooks for ages 5-21
# district-level placement (race, gender, disability, LEP), plus 4 district
# 3-5 count-only files (no environment dimension). State-level placement
# coverage varies by year (see availability matrix below). The 2025 workbook
# consolidates all of this into one ~3 MB xlsx with state + district sheets.
#
# Availability matrix (X = Excel placement, C = Excel count-only, P = PDF only):
#
#   | end_year | 5-21 district | 5-21 state | 3-5 district | 3-5 state |
#   |----------|---------------|------------|--------------|-----------|
#   | 2020     | X (4 files)   | P          | C (4 files)  | P         |
#   | 2021     | X (4 files)   | P          | C (4 files)  | P         |
#   | 2022     | X (4 files)   | P          | C (4 files)  | P         |
#   | 2023     | X (4 files)   | P          | C (4 files)  | X         |
#   | 2024     | X (4 files)   | X          | C (4 files)  | X         |
#   | 2025     | X (1 file)    | X          | X (1 file)   | X         |
#
# Per-year structural quirks worth noting:
#
#   - 2020 (5-21 disability): uses 2-letter abbreviation codes ("AUT", "EMN",
#     "ID", "MD", "OHI", "SLD", "SLI", "VI", "HI", "OI", "DD", "TBI", "DB")
#     instead of full disability names. We expand to canonical full names
#     before standardizing.
#   - 2020 / 2021: the "District" column is labeled "District" rather than
#     "District Code". 2022+ all use "District Code".
#   - 2020 / 2021: the 3-5 disability files include a "Pre-School Disabled"
#     column not present in later years. 2022+ replace it with "Developmental
#     Delay".
#   - The 2020 LEP file misspells "Non-English Learner" as "Non-Englishh
#     Learner" (double h). We accept either spelling when standardizing.
#   - The 2024 5-21 gender file calls the third LRE column "Separate Settings"
#     instead of "Separate School". We accept either spelling.
#   - The 2024 5-21 LEP file has "County  Code" with a double space.
#   - Header-row position (the `skip` argument to readxl::read_excel) varies
#     by (year, subgroup) file. See enumerate_sped_placement_files() for the
#     full map.
#   - 2021 5-21 state placement is published only as a PDF (in 2020.zip).
#     Per design, fetch_sped_placement(2021, age_group = "5-21") errors with
#     a clear message pointing at the PDF source instead of attempting a
#     partial-year answer.
#
# Discovery details captured here so future maintainers don't have to re-walk
# the IDEA Public Data landing page from scratch.
# ==============================================================================


# -----------------------------------------------------------------------------
# Year + URL configuration
# -----------------------------------------------------------------------------

#' Valid years for SPED placement / educational-environment data
#'
#' Returns the integer end_year values currently wired up for
#' \code{\link{fetch_sped_placement}}.
#'
#' One narrow gap exists inside this range:
#' \code{fetch_sped_placement(2021, age_group = "5-21")} errors with a clear
#' message because NJ DOE published that one slice only as a PDF. Every other
#' (end_year, age_group, level) combination across 2020-2025 returns data.
#'
#' @return integer vector of supported end years
#' @keywords internal
get_valid_sped_placement_years <- function() {
  2020L:2025L
}


# Year -> base URL on nj.gov. Pre-2022 years ship as zip archives; 2022+ are
# loose .xlsx files. 2025 uses a single consolidated workbook.
sped_placement_base_url <- function(end_year) {
  base <- "https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/"
  switch(
    as.character(end_year),
    "2020" = paste0(base, "2019.zip"),
    "2021" = paste0(base, "2020.zip"),
    "2022" = paste0(base, "2022%20data/"),
    "2023" = paste0(base, "2022public618data/"),
    "2024" = paste0(base, "2023_618data/"),
    "2025" = paste0(base, "2025_618data/"),
    stop(sprintf("No base URL configured for end_year %s.", end_year))
  )
}


#' Build the IDEA 618 placement workbook URL (2025 only)
#'
#' Retained for backwards compatibility with the v1 (PR #278) API. For
#' end_years 2020-2024 use \code{\link{enumerate_sped_placement_files}}, which
#' returns a tibble of (subgroup_dim, age_group, level, url, skip) rows.
#'
#' @param end_year ending school year (2025)
#' @return character URL
#' @keywords internal
build_sped_placement_url <- function(end_year) {
  if (end_year != 2025L) {
    stop(
      "build_sped_placement_url() only covers end_year 2025. ",
      "Use enumerate_sped_placement_files() for 2020-2024.",
      call. = FALSE
    )
  }
  paste0(
    "https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/",
    "2025_618data/",
    "2025IDEA618PublicReporting_StudentCountandEducationalEnvironment.xlsx"
  )
}


# -----------------------------------------------------------------------------
# Per-year file enumerator (replaces single-URL builder for 2020-2024)
# -----------------------------------------------------------------------------

# For end_years 2020-2024, this lookup map specifies, per subgroup dimension
# and age group, the file basename inside the year's base URL plus the
# `skip` value needed for readxl::read_excel(). The map is constructed once
# at package load.
#
# `path` is appended to `sped_placement_base_url(end_year)` to build the full
# URL. For zip-archive years (2020, 2021), `zip_member` is the path inside
# the archive; the cached-workbook helper extracts the member to disk.
.sped_placement_file_map <- list(
  # ---------------------------------------------------------------------
  # end_year 2020 (SY2019-20) -- 2019.zip
  # ---------------------------------------------------------------------
  "2020" = list(
    `5-21_district_disability` = list(
      zip_member = "2019/5-21DisabilitybyEdEnvironment.xlsx", skip = 5
    ),
    `5-21_district_race` = list(
      zip_member = "2019/5-21RaceVsEducationalEnvironment.xlsx", skip = 5
    ),
    `5-21_district_gender` = list(
      zip_member = "2019/5-21GenderVsEducationalEnvironment.xlsx", skip = 5
    ),
    `5-21_district_lep` = list(
      zip_member = "2019/5-21LEPbyEducationalEnvironment.xlsx", skip = 5
    ),
    `3-5_district_disability` = list(
      zip_member = "2019/3-5StudentCountByDisability_District.xlsx", skip = 5
    ),
    `3-5_district_race` = list(
      zip_member = "2019/3-5StudentCountbyRace_District.xlsx", skip = 5
    ),
    `3-5_district_gender` = list(
      zip_member = "2019/3-5StudentCountByGender_District.xlsx", skip = 5
    ),
    `3-5_district_lep` = list(
      zip_member = "2019/3-5StudentcountbyLEP_District.xlsx", skip = 5
    )
  ),
  # ---------------------------------------------------------------------
  # end_year 2021 (SY2020-21) -- 2020.zip
  # ---------------------------------------------------------------------
  "2021" = list(
    `5-21_district_disability` = list(
      zip_member = "2020/5_21DisabilityVsEducationalEnvironment.xlsx", skip = 6
    ),
    `5-21_district_race` = list(
      zip_member = "2020/5_21RaceVsEducationalEnvironment.xlsx", skip = 5
    ),
    `5-21_district_gender` = list(
      zip_member = "2020/5_21GenderVsEducationalEnvironment.xlsx", skip = 5
    ),
    `5-21_district_lep` = list(
      zip_member = "2020/5_21LEPVsEducationalEnvironment.xlsx", skip = 5
    ),
    `3-5_district_disability` = list(
      zip_member = "2020/3_5StudentCountbyDisability_District.xlsx", skip = 5
    ),
    `3-5_district_race` = list(
      zip_member = "2020/3_5StudentCountbyRace_District.xlsx", skip = 5
    ),
    `3-5_district_gender` = list(
      zip_member = "2020/3_5StudentCountbyGender_District.xlsx", skip = 5
    ),
    `3-5_district_lep` = list(
      zip_member = "2020/3_5StudentCountbyLEP_District.xlsx", skip = 5
    )
  ),
  # ---------------------------------------------------------------------
  # end_year 2022 (SY2021-22) -- docs/2022%20data/
  # ---------------------------------------------------------------------
  "2022" = list(
    `5-21_district_disability` = list(
      path = "5_21DisabilityVsEducationalEnvironment.xlsx", skip = 6
    ),
    `5-21_district_race` = list(
      path = "5_21RaceVsEducationalEnvironment.xlsx", skip = 6
    ),
    `5-21_district_gender` = list(
      path = "5_21GenderVsEducationalEnvironment.xlsx", skip = 6
    ),
    `5-21_district_lep` = list(
      path = "5_21LEPVsEducationalEnvironment.xlsx", skip = 6
    ),
    `3-5_district_disability` = list(
      path = "3_5StudentCountbyDisability_District.xlsx", skip = 5
    ),
    `3-5_district_race` = list(
      path = "3_5StudentCountbyRace_District.xlsx", skip = 5
    ),
    `3-5_district_gender` = list(
      path = "3_5StudentCountbyGender_District.xlsx", skip = 5
    ),
    `3-5_district_lep` = list(
      path = "3_5StudentCountbyLEP_District.xlsx", skip = 5
    )
  ),
  # ---------------------------------------------------------------------
  # end_year 2023 (SY2022-23) -- docs/2022public618data/
  # ---------------------------------------------------------------------
  "2023" = list(
    `5-21_district_disability` = list(
      path = "Placement_Disability_5_21_2223.xlsx", skip = 6
    ),
    `5-21_district_race` = list(
      path = "Placement_Race_5_21_2223.xlsx", skip = 6
    ),
    `5-21_district_gender` = list(
      path = "Placement_Gender_5_21_2223.xlsx", skip = 6
    ),
    `5-21_district_lep` = list(
      path = "Placement_LEP_5_21_2223.xlsx", skip = 6
    ),
    `3-5_district_disability` = list(
      path = "SpecedCount_Disablity3to5_SchoolYear22.23.xlsx", skip = 5
    ),
    `3-5_district_race` = list(
      path = "SpecedCount_Race3to5_SchoolYear_22.23.xlsx", skip = 5
    ),
    `3-5_district_gender` = list(
      path = "SpecedCount_Gender3to5%20-SchoolYear22.23.xlsx", skip = 5
    ),
    `3-5_district_lep` = list(
      path = "SpecedCount_LEP3to5_SchoolYear22.23.xlsx", skip = 5
    ),
    `3-5_state_placement` = list(
      path = "StateWideExcel_PlacementData_3-5Age_2223.xlsx", skip = 0
    )
  ),
  # ---------------------------------------------------------------------
  # end_year 2024 (SY2023-24) -- docs/2023_618data/
  # ---------------------------------------------------------------------
  "2024" = list(
    `5-21_district_disability` = list(
      path = "age%205-21_Districts%20data%20by%20Disablityand%20placement.xlsx",
      skip = 5
    ),
    `5-21_district_race` = list(
      path = "age%205-21_Districts%20data%20by%20Race%20and%20placement.xlsx",
      skip = 5
    ),
    `5-21_district_gender` = list(
      path = "age%205-21_Districts%20data%20by%20Gender%20and%20placement.xlsx",
      skip = 5
    ),
    `5-21_district_lep` = list(
      path = "age%205-21_Districts%20data%20by%20LEP%20Status%20and%20placement.xlsx",
      skip = 5
    ),
    `3-5_district_disability` = list(
      path = "studentcount_Disablity_3-5_2324_District.xlsx", skip = 5
    ),
    `3-5_district_race` = list(
      path = "studentcount_Race_3-5_2324_District.xlsx", skip = 5
    ),
    `3-5_district_gender` = list(
      path = "studentcount_Gender_3-5_2324_District.xlsx", skip = 5
    ),
    `3-5_district_lep` = list(
      path = "studentcount_LEP_3-5_2324_District.xlsx", skip = 5
    ),
    `5-21_state_placement` = list(
      path = "placement_StateWide_5-21_2324.xlsx", skip = 0
    ),
    `3-5_state_placement` = list(
      path = "placement_StateWide_3-5_Age_2324.xlsx", skip = 0
    )
  )
)


#' Enumerate the per-year SPED placement files for an end_year
#'
#' For end_years 2020-2024, returns a tibble describing every workbook
#' published for the year, including its url, expected sheet structure, and
#' the readxl skip value. For end_year 2025, returns a single-row tibble
#' pointing at the consolidated workbook.
#'
#' @param end_year ending school year
#' @return tibble with columns: end_year, subgroup_dim, age_group, level,
#'   url, zip_member (NA for non-zip years), skip
#' @keywords internal
enumerate_sped_placement_files <- function(end_year) {
  end_year <- as.integer(end_year)
  if (end_year == 2025L) {
    return(tibble::tibble(
      end_year = 2025L,
      subgroup_dim = "consolidated",
      age_group = NA_character_,
      level = NA_character_,
      url = build_sped_placement_url(2025L),
      zip_member = NA_character_,
      skip = 4L,
      file_label = "consolidated"
    ))
  }

  yr_key <- as.character(end_year)
  if (!yr_key %in% names(.sped_placement_file_map)) {
    stop(sprintf(
      "No file map configured for end_year %d.", end_year
    ), call. = FALSE)
  }
  m <- .sped_placement_file_map[[yr_key]]
  base <- sped_placement_base_url(end_year)
  is_zip <- grepl("\\.zip$", base)

  rows <- lapply(names(m), function(k) {
    spec <- m[[k]]
    # Parse the label: "<age>_<level>_<dim>" or "<age>_<level>_placement"
    parts <- strsplit(k, "_", fixed = TRUE)[[1]]
    age_group <- parts[[1]]
    level <- parts[[2]]
    dim <- parts[[3]]
    tibble::tibble(
      end_year = end_year,
      subgroup_dim = dim,
      age_group = age_group,
      level = level,
      url = if (is_zip) base else paste0(base, spec$path),
      zip_member = if (is_zip) spec$zip_member else NA_character_,
      skip = as.integer(spec$skip),
      file_label = k
    )
  })
  do.call(rbind, rows)
}


# -----------------------------------------------------------------------------
# Workbook cache (on-disk, like SPR)
# -----------------------------------------------------------------------------

#' Directory holding cached SPED placement workbooks
#'
#' @return absolute path to the cache directory (created lazily on use)
#' @keywords internal
sped_placement_cache_dir <- function() {
  base <- getOption(
    "njschooldata.cache_dir",
    tools::R_user_dir("njschooldata", which = "cache")
  )
  file.path(base, "sped-placement")
}


#' Download (and disk-cache) one IDEA 618 placement workbook
#'
#' Validates the download as a real .xlsx before caching, so an HTTP error or
#' bot-protection page is never written to the cache or parsed as data. For
#' zip-archive years (2020, 2021), downloads the zip once, extracts the
#' requested member, and caches the member as a standalone .xlsx.
#'
#' @param end_year ending school year
#' @param file_label per-file slug for cache differentiation (eg
#'   "5-21_district_race", "consolidated"). Defaults to "consolidated" so
#'   v1 callers continue to work.
#' @param url full HTTP URL of the workbook (or the parent zip)
#' @param zip_member if the URL is a .zip, path inside the archive to extract
#' @return path to a local, validated .xlsx file
#' @keywords internal
sped_placement_cached_workbook <- function(end_year,
                                           file_label = "consolidated",
                                           url = NULL,
                                           zip_member = NULL) {
  if (is.null(url)) {
    # Backwards-compatible 2025 path
    url <- build_sped_placement_url(end_year)
  }

  use_cache <- isTRUE(getOption("njschooldata.workbook_cache", TRUE)) &&
    njsd_cache_enabled()

  # Sanitize the file_label for the on-disk filename (URL-encoded paths,
  # spaces, etc.). Anything outside [A-Za-z0-9._-] becomes "_".
  safe_label <- gsub("[^A-Za-z0-9._-]", "_", file_label)

  if (use_cache) {
    cache_dir <- sped_placement_cache_dir()
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
    dest <- file.path(
      cache_dir,
      sprintf("SPED_Placement_%d_%s.xlsx", end_year, safe_label)
    )
    if (is_valid_xlsx(dest)) {
      return(dest)
    }
    dl_dir <- cache_dir
  } else {
    dest <- tempfile(pattern = "sped_placement_", fileext = ".xlsx")
    dl_dir <- dirname(dest)
  }

  is_zip <- grepl("\\.zip$", url)
  if (is_zip) {
    # Download the zip into a temp file, extract the requested member, then
    # treat the extracted member as the downloaded workbook.
    zip_tmp <- tempfile(
      pattern = "sped_placement_zip_", tmpdir = dl_dir, fileext = ".zip"
    )
    on.exit(unlink(zip_tmp), add = TRUE)
    downloader::download(url, destfile = zip_tmp, mode = "wb")
    if (!file.exists(zip_tmp) || file.size(zip_tmp) < 1024) {
      stop(sprintf(
        "Downloaded SPED placement archive for %d is empty or missing.\n  URL: %s",
        end_year, url
      ), call. = FALSE)
    }
    if (is.null(zip_member)) {
      stop(sprintf(
        "Internal error: zip URL provided without zip_member for end_year %d.",
        end_year
      ), call. = FALSE)
    }
    extract_dir <- tempfile(pattern = "sped_zip_extract_", tmpdir = dl_dir)
    dir.create(extract_dir, recursive = TRUE, showWarnings = FALSE)
    on.exit(unlink(extract_dir, recursive = TRUE), add = TRUE)
    available <- utils::unzip(zip_tmp, list = TRUE)$Name
    if (!zip_member %in% available) {
      stop(sprintf(
        paste0(
          "Expected file '%s' not found inside SPED placement archive for ",
          "end_year %d. Available members:\n  %s\n  URL: %s"
        ),
        zip_member, end_year,
        paste(head(available, 30), collapse = "\n  "),
        url
      ), call. = FALSE)
    }
    extracted <- utils::unzip(
      zip_tmp, files = zip_member, exdir = extract_dir, junkpaths = TRUE
    )
    tmp <- extracted[[1]]
  } else {
    tmp <- tempfile(
      pattern = "sped_placement_dl_", tmpdir = dl_dir, fileext = ".xlsx"
    )
    on.exit(unlink(tmp), add = TRUE)
    downloader::download(url, destfile = tmp, mode = "wb")
  }

  if (!is_valid_xlsx(tmp)) {
    stop(sprintf(
      paste0(
        "Downloaded SPED placement workbook for %d (%s) is not a valid ",
        ".xlsx file -- the NJ DOE source may be unavailable or returned ",
        "an error page.\n  URL: %s"
      ),
      end_year, file_label, url
    ), call. = FALSE)
  }

  if (!file.rename(tmp, dest)) {
    file.copy(tmp, dest, overwrite = TRUE)
  }
  dest
}


# -----------------------------------------------------------------------------
# 2025 sheet name dispatch (legacy path)
# -----------------------------------------------------------------------------

# The 2025 workbook has the following sheets we care about for placement:
#   "5-21 District by Ed Environ"  -- school-age, district + charter
#   "3-5 District Counts"          -- preschool, district + charter (totals
#                                    only, no environment dimension)
#   "5-21 State by Ed Environ"     -- school-age, statewide (stacked tables)
#   "3-5 State by Ed Environ"      -- preschool, statewide (stacked tables)

#' Map (age_group, level) to the workbook sheet name (2025 only)
#'
#' @param age_group "5-21" or "3-5"
#' @param level "district" or "state"
#' @return character sheet name
#' @keywords internal
sped_placement_sheet <- function(age_group, level) {
  if (!age_group %in% c("5-21", "3-5")) {
    stop(
      "age_group must be one of '5-21' or '3-5'.",
      call. = FALSE
    )
  }
  if (!level %in% c("district", "state")) {
    stop(
      "level must be one of 'district' or 'state'.",
      call. = FALSE
    )
  }

  if (level == "district") {
    if (age_group == "5-21") {
      "5-21 District by Ed Environ"
    } else {
      "3-5 District Counts"
    }
  } else {
    if (age_group == "5-21") {
      "5-21 State by Ed Environ"
    } else {
      "3-5 State by Ed Environ"
    }
  }
}


# -----------------------------------------------------------------------------
# 2021/5-21 short-circuit (user-mandated, plan section 4)
# -----------------------------------------------------------------------------

# NJ DOE only published 2021 Ages 5-21 placement state-level data as a PDF.
# Per the v2 design decision, fetch_sped_placement(2021, age_group = "5-21")
# errors with a clear message pointing at the PDF source. This short-circuit
# runs before any download is attempted.
sped_placement_21_5_21_error <- function() {
  stop(
    "NJ DOE published 2021 Ages 5-21 placement data only as a PDF, not as ",
    "a structured download. Source page: https://www.nj.gov/education/",
    "specialed/monitor/ideapublicdata/. For programmatic access, file an ",
    "OPRA request. See njschooldata issue tracker for status.",
    call. = FALSE
  )
}


# -----------------------------------------------------------------------------
# Pre-2025 PDF-only short-circuits (state level)
# -----------------------------------------------------------------------------

# State-level placement data for 5-21 was PDF-only across 2020-2023, and
# 3-5 state placement was PDF-only across 2020-2022. We surface the same
# honest error in each of those cases.
sped_placement_state_pdf_error <- function(end_year, age_group) {
  stop(sprintf(
    paste0(
      "NJ DOE published end_year %d state-level Ages %s placement data ",
      "only as a PDF, not as a structured download. Source page: ",
      "https://www.nj.gov/education/specialed/monitor/ideapublicdata/. ",
      "District-level data for the same year is available via ",
      "fetch_sped_placement(%d, age_group = \"%s\", level = \"district\")."
    ),
    end_year, age_group, end_year, age_group
  ), call. = FALSE)
}


# -----------------------------------------------------------------------------
# Raw reader
# -----------------------------------------------------------------------------

#' Read one raw sheet from the SPED placement workbook
#'
#' For end_year 2025, returns the raw tibble for a single sheet
#' (district 5-21, district 3-5, state 5-21, or state 3-5).
#'
#' For end_years 2020-2024, returns a named list of raw tibbles -- one per
#' single-subgroup workbook (race, gender, disability, lep) needed for the
#' requested (age_group, level) slice. State-level 5-21 across 2020-2023 and
#' state-level 3-5 across 2020-2022 are PDF-only and error out.
#'
#' @param end_year ending school year (2020-2025)
#' @param age_group "5-21" or "3-5"
#' @param level "district" or "state"
#'
#' @return tibble (2025) or named list of tibbles (2020-2024). Each tibble
#'   carries an \code{end_year} column appended for downstream joining.
#' @export
#'
#' @examples
#' \dontrun{
#' # Raw district-level school-age placement (2025: one tibble)
#' raw <- get_raw_sped_placement(2025, age_group = "5-21", level = "district")
#'
#' # 2024 district 5-21: returns list("race" = ..., "gender" = ..., ...)
#' raw_2024 <- get_raw_sped_placement(2024, age_group = "5-21",
#'                                    level = "district")
#'
#' # Raw preschool statewide (2025)
#' raw_state_3_5 <- get_raw_sped_placement(2025, age_group = "3-5",
#'                                         level = "state")
#' }
get_raw_sped_placement <- function(end_year,
                                   age_group = "5-21",
                                   level = "district") {
  valid_years <- get_valid_sped_placement_years()
  if (!end_year %in% valid_years) {
    stop(
      sprintf(
        paste0(
          "%d is not a valid end_year for SPED placement data. ",
          "Valid years are: %s."
        ),
        end_year, paste(valid_years, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  if (!age_group %in% c("5-21", "3-5")) {
    stop("age_group must be one of '5-21' or '3-5'.", call. = FALSE)
  }
  if (!level %in% c("district", "state")) {
    stop("level must be one of 'district' or 'state'.", call. = FALSE)
  }

  # 2021 Ages 5-21 short-circuit (regardless of level)
  if (end_year == 2021L && age_group == "5-21") {
    sped_placement_21_5_21_error()
  }
  # Pre-2025 PDF-only state combinations
  if (level == "state") {
    if (age_group == "5-21" && end_year %in% c(2020L, 2022L, 2023L)) {
      sped_placement_state_pdf_error(end_year, age_group)
    }
    if (age_group == "3-5" && end_year %in% c(2020L, 2021L, 2022L)) {
      sped_placement_state_pdf_error(end_year, age_group)
    }
  }

  # Check the parsed-sheet session cache first.
  cache_key <- make_cache_key(
    "get_raw_sped_placement",
    end_year = end_year, age_group = age_group, level = level
  )
  cached <- cache_get(cache_key)
  if (!is.null(cached)) {
    return(cached)
  }

  if (end_year == 2025L) {
    sheet <- sped_placement_sheet(age_group, level)
    wb <- sped_placement_cached_workbook(end_year)
    df <- readxl::read_excel(
      path = wb,
      sheet = sheet,
      skip = 4,
      col_types = "text"
    )
    df$end_year <- end_year
    cache_set(cache_key, df)
    return(df)
  }

  # 2020-2024 path: one workbook per (subgroup_dim, age_group, level)
  files <- enumerate_sped_placement_files(end_year)
  files <- files[files$age_group == age_group & files$level == level, ]
  if (nrow(files) == 0) {
    stop(sprintf(
      "Internal error: no files registered for end_year %d, age_group %s, level %s.",
      end_year, age_group, level
    ), call. = FALSE)
  }

  results <- vector("list", nrow(files))
  for (i in seq_len(nrow(files))) {
    row <- files[i, ]
    wb <- sped_placement_cached_workbook(
      end_year = end_year,
      file_label = row$file_label,
      url = row$url,
      zip_member = if (is.na(row$zip_member)) NULL else row$zip_member
    )
    sheets <- readxl::excel_sheets(wb)
    # Read the first sheet -- NJ DOE puts the data table on sheet 1 in every
    # observed file. Auxiliary "SQL Statement" sheets are ignored.
    #
    # For state-level placement files we use col_names = FALSE because the
    # workbooks have multiple decorative header rows ahead of the actual
    # column-header row, and the column headers themselves embed `%` chars
    # that defeat regex-based count/pct disambiguation. The parser indexes
    # data positionally.
    if (row$level == "state") {
      df <- suppressMessages(readxl::read_excel(
        path = wb,
        sheet = sheets[[1]],
        skip = row$skip,
        col_types = "text",
        col_names = FALSE,
        .name_repair = "minimal"
      ))
    } else {
      df <- readxl::read_excel(
        path = wb,
        sheet = sheets[[1]],
        skip = row$skip,
        col_types = "text"
      )
    }
    df$end_year <- end_year
    df$subgroup_dim <- row$subgroup_dim
    df$age_group <- row$age_group
    df$source_file <- basename(row$url)
    results[[i]] <- df
  }
  names(results) <- files$subgroup_dim

  cache_set(cache_key, results)
  results
}


# -----------------------------------------------------------------------------
# Tidy / reshape helpers (shared)
# -----------------------------------------------------------------------------

# School-age (5-21) educational-environment categories. Stored as a named
# vector mapping the canonical short code -> the prefix used in the workbook
# column headers. For the 2025 consolidated workbook the same prefix is shared
# by the Count and Percent columns. For 2020-2024 single-subgroup workbooks
# the categories appear as bare column names (no Count / Percent suffix).
sped_placement_categories_5_21 <- c(
  gen_ed_80_plus =
    "In General Education for 80% or More of the Day",
  gen_ed_40_79 =
    "In General Education for 40-79% of the Day",
  gen_ed_less_40 =
    "In General Education for Less Than 40% of the Day",
  separate_school =
    "Separate School",
  residential_facility =
    "Residential Facility",
  homebound_hospital =
    "Home Bound or Hospital",
  correction_facility =
    "Correction Facility",
  parentally_placed_nonpublic =
    "Parentally Placed in Private School (\"Nonpublic\") and Receiving Services"
)

# Preschool (3-5) educational-environment categories.
sped_placement_categories_3_5 <- c(
  ec_program_10plus_hrs =
    "In a General Early Childhood Program Lasting 10+ Hours/Week",
  services_other_loc_attended_ec_10plus_hrs =
    paste0(
      "Services in Another Location, but Attended a General Early ",
      "Childhood Program Lasting 10+ Hours/Week"
    ),
  ec_program_less_10_hrs =
    "In a General Early Childhood Program Lasting Less Than 10 Hours/Week",
  services_other_loc_attended_ec_less_10_hrs =
    paste0(
      "Services in Another Location, but Attended a General Early ",
      "Childhood Program Lasting Less Than 10 Hours/Week"
    ),
  separate_class = "Separate Class",
  separate_school = "Separate School",
  residential_facility = "Residential Facility",
  home = "Home",
  service_provider_location = "Service Provider Location"
)

# For pre-2025 single-subgroup district 5-21 workbooks, the environment
# columns are bare (no Count/Percent suffix). Map canonical short code ->
# list of possible column names seen in the workbooks. The first hit wins.
sped_placement_5_21_pre2025_envcols <- list(
  gen_ed_80_plus = "Inside The Regular Class 80% or More of Day",
  gen_ed_40_79 = paste0(
    "Inside The Regular Class No More Than 79% of Day ",
    "But No Less Than 40% of Day"
  ),
  gen_ed_less_40 = "Inside Regular Class For Less Than 40% of Day",
  separate_school = c("Separate School", "Separate Settings"),
  residential_facility = "Residential Facility",
  homebound_hospital = "HomeBound/Hospital",
  correction_facility = c("Correctional Facility", "Correction Facility")
)

# Disability-code -> full-name expansion for the 2020/2021 5-21 disability
# files, which use 2-letter abbreviation codes instead of full names. The
# right-hand side is the full name as it appears in 2022+ files; the
# standardizer then maps these to snake_case.
sped_placement_disability_code_expansion <- c(
  AUT = "Autism",
  EMN = "Emotional Disturbance",
  ID  = "Intellectual Disability",
  MD  = "Multiple Disabilities",
  OHI = "Other Health Impairment",
  SLD = "Specific Learning Disability",
  SLI = "Speech or Language Impairment",
  VI  = "Visual Impairment",
  HI  = "Hearing impairment",
  OI  = "Orthopedic Impairment",
  DD  = "Developmental Delay",
  TBI = "Traumatic Brain Injury",
  DB  = "Deaf-Blindness",
  # 2019.zip also uses "MR" (Mental Retardation, the pre-IDEA-2008 name for
  # Intellectual Disability)
  MR  = "Intellectual Disability"
)


#' Standardize student-group labels to cross-state conventions
#'
#' Maps the verbose NJ student-group labels in the District by Ed Environ
#' sheet (eg "Black or African American", "Multilingual Learner") to the
#' lowercase snake_case names the rest of njschooldata/the 50-state project
#' uses (eg "black", "lep"). Covers labels seen in 2020-2025 inputs,
#' including a few year-specific variants (eg "Non-Englishh Learner" with
#' the typo present in 2020, "Two or More" without "Races" in 2020/2021).
#'
#' @param x character vector of NJ-formatted student group labels
#' @return character vector of standardized subgroup names
#' @keywords internal
standardize_sped_placement_subgroups <- function(x) {
  dplyr::case_when(
    x == "Districtwide" ~ "total",
    # Race/ethnicity
    x == "American Indian or Alaska Native" ~ "native_american",
    x == "Asian" ~ "asian",
    x == "Black or African American" ~ "black",
    x == "Black" ~ "black",
    x == "Hispanic" ~ "hispanic",
    x == "Hispanic/Latino" ~ "hispanic",
    x == "Native Hawaiian or Pacific Islander" ~ "pacific_islander",
    x == "Native Hawaiian or Other Pacific Islander" ~ "pacific_islander",
    x == "Two or More Races" ~ "multiracial",
    x == "Two or more races" ~ "multiracial",
    x == "Two or More" ~ "multiracial",
    x == "White" ~ "white",
    # Gender
    x == "Female" ~ "female",
    x == "Male" ~ "male",
    x == "Non-Binary/Undesignated" ~ "non_binary",
    # ML / EL status
    x == "Multilingual Learner" ~ "lep",
    x == "Non-Multilingual Learner" ~ "non_lep",
    x == "English Learner" ~ "lep",
    x == "English_Learner" ~ "lep",
    x == "Non-English Learner" ~ "non_lep",
    x == "Non-Englishh Learner" ~ "non_lep", # 2020 typo
    # Disability categories -- keep snake_case for cross-state consistency
    x == "Auditory Impairment" ~ "auditory_impairment",
    x == "Autism" ~ "autism",
    x == "Deaf-Blindness" ~ "deaf_blindness",
    x == "Deaf Blindness" ~ "deaf_blindness",
    x == "Deaf- Blindness" ~ "deaf_blindness",
    x == "Developmental Delay" ~ "developmental_delay",
    x == "Emotional Disturbance" ~ "emotional_disturbance",
    x == "Emotional Regulation Impairment" ~ "emotional_regulation_impairment",
    x == "Hearing Impairment" ~ "hearing_impairment",
    x == "Hearing impairment" ~ "hearing_impairment",
    x == "Intellectual Disability" ~ "intellectual_disability",
    x == "Multiple Disabilities" ~ "multiple_disabilities",
    x == "Orthopedic Impairment" ~ "orthopedic_impairment",
    x == "Other Health Impairment" ~ "other_health_impairment",
    x == "Pre-School Disabled" ~ "preschool_disability",
    x == "Preschool Child with a Disability" ~ "preschool_disability",
    x == "Specific Learning Disability" ~ "specific_learning_disability",
    x == "Speech or Language Impairment" ~ "speech_language_impairment",
    x == "Traumatic Brain Injury" ~ "traumatic_brain_injury",
    x == "Visual Impairment" ~ "visual_impairment",
    TRUE ~ x
  )
}


#' Parse a percent value from the workbook
#'
#' The workbook mixes two percent formats across sheets:
#'   - State sheets store percents as decimals (eg 0.4514 = 45.14%) in 2025
#'   - District sheets store percents as whole percents (eg 67.3 = 67.3%)
#'   - Pre-2025 district 5-21 files store COUNTS only (no percent column)
#' Both are kept on the same 0-100 scale in tidy output. Suppression flags
#' ("*") become NA.
#'
#' @param x character vector
#' @param scale_to_pct numeric multiplier applied after parsing (100 for
#'   decimal sheets, 1 for already-pct sheets)
#' @return numeric vector on the 0-100 scale (NA for suppressed)
#' @keywords internal
parse_placement_pct <- function(x, scale_to_pct = 1) {
  x <- gsub("[*N]", NA, x)
  suppressWarnings(as.numeric(x)) * scale_to_pct
}


#' Parse a count value from the workbook (suppression-aware)
#' @keywords internal
parse_placement_count <- function(x) {
  x <- gsub("[*N]", NA, x)
  suppressWarnings(as.numeric(x))
}


# -----------------------------------------------------------------------------
# 2025 tidy functions (legacy path, unchanged)
# -----------------------------------------------------------------------------

#' Tidy the District by Ed Environ sheet (school-age, 5-21) -- 2025
#' @keywords internal
tidy_sped_placement_district_5_21 <- function(df) {
  df <- df[!is.na(df$`County Code`) &
    df$`County Code` != "end of worksheet", ]

  long_list <- lapply(
    seq_along(sped_placement_categories_5_21),
    function(i) {
      cat_short <- names(sped_placement_categories_5_21)[i]
      cat_prefix <- sped_placement_categories_5_21[[i]]
      count_col <- paste0(cat_prefix, " Count")
      pct_col <- paste0(cat_prefix, " Percent")
      data.frame(
        end_year = df$end_year,
        county_id = df$`County Code`,
        county_name = df$`County Name`,
        district_id = df$`District Code`,
        district_name = df$`District Name`,
        subgroup_raw = df$`Student Group`,
        environment = cat_short,
        count = parse_placement_count(df[[count_col]]),
        percent = parse_placement_pct(df[[pct_col]], scale_to_pct = 1),
        stringsAsFactors = FALSE
      )
    }
  )
  out <- do.call(rbind, long_list)

  totals <- data.frame(
    end_year = df$end_year,
    county_id = df$`County Code`,
    district_id = df$`District Code`,
    subgroup_raw = df$`Student Group`,
    subgroup_total =
      parse_placement_count(df$`Districtwide Total`),
    stringsAsFactors = FALSE
  )
  out <- merge(
    out, totals,
    by = c("end_year", "county_id", "district_id", "subgroup_raw"),
    all.x = TRUE
  )

  out$subgroup <- standardize_sped_placement_subgroups(out$subgroup_raw)
  out$subgroup_raw <- NULL

  out$is_state <- FALSE
  out$is_district <- TRUE
  out$is_charter <- out$county_id == "80"

  out <- out[, c(
    "end_year", "county_id", "county_name",
    "district_id", "district_name",
    "subgroup", "environment",
    "count", "percent", "subgroup_total",
    "is_state", "is_district", "is_charter"
  )]
  rownames(out) <- NULL
  tibble::as_tibble(out)
}


#' Identify the next-table-divider row inside a stacked State sheet (2025)
#' @keywords internal
split_state_ed_environ_tables <- function(df) {
  col1 <- df[[1]]
  divider_idx <- grep(
    "^Counts and Percents", col1
  )

  starts <- c(1, divider_idx + 2)
  ends <- c(divider_idx - 1, nrow(df))

  cat_names <- c(
    "age",
    sub(".*by Educational Environment and (.*)$", "\\1",
      col1[divider_idx])
  )
  cat_names <- gsub(" Category| Group| Status", "", cat_names)
  cat_names <- tolower(gsub("[^A-Za-z]+", "_", cat_names))
  cat_names <- gsub("_$", "", cat_names)

  out <- lapply(seq_along(starts), function(i) {
    chunk <- df[starts[i]:ends[i], , drop = FALSE]
    chunk <- chunk[!is.na(chunk[[1]]), ]
    chunk <- chunk[!grepl("^end of worksheet$",
                          chunk[[1]], ignore.case = TRUE), ]
    chunk <- chunk[!grepl("^Counts and Percents",
                          chunk[[1]]), ]
    chunk
  })
  names(out) <- cat_names
  out
}


#' Tidy the State by Ed Environ sheet (5-21 or 3-5) -- 2025
#' @keywords internal
tidy_sped_placement_state <- function(df, age_group) {
  categories <- if (age_group == "5-21") {
    sped_placement_categories_5_21
  } else {
    sped_placement_categories_3_5
  }

  tables <- split_state_ed_environ_tables(df)

  long_per_table <- lapply(names(tables), function(dim_name) {
    chunk <- tables[[dim_name]]
    if (nrow(chunk) == 0) return(NULL)

    long_list <- lapply(
      seq_along(categories),
      function(i) {
        cat_short <- names(categories)[i]
        cat_prefix <- categories[[i]]
        count_col <- paste0(cat_prefix, " Count")
        pct_col <- paste0(cat_prefix, " Percent")
        if (!all(c(count_col, pct_col) %in% names(chunk))) return(NULL)
        data.frame(
          end_year = chunk$end_year,
          dimension = dim_name,
          subgroup_raw = chunk[[1]],
          environment = cat_short,
          count = parse_placement_count(chunk[[count_col]]),
          percent = parse_placement_pct(chunk[[pct_col]], scale_to_pct = 100),
          stringsAsFactors = FALSE
        )
      }
    )
    do.call(rbind, long_list)
  })
  long <- do.call(rbind, long_per_table)
  if (is.null(long) || nrow(long) == 0) {
    return(tibble::tibble())
  }

  totals_per_table <- lapply(names(tables), function(dim_name) {
    chunk <- tables[[dim_name]]
    if (nrow(chunk) == 0 ||
        !"Statewide Total" %in% names(chunk)) {
      return(NULL)
    }
    data.frame(
      end_year = chunk$end_year,
      dimension = dim_name,
      subgroup_raw = chunk[[1]],
      subgroup_total = parse_placement_count(chunk$`Statewide Total`),
      stringsAsFactors = FALSE
    )
  })
  totals <- do.call(rbind, totals_per_table)
  long <- merge(
    long, totals,
    by = c("end_year", "dimension", "subgroup_raw"),
    all.x = TRUE
  )

  long$subgroup <- ifelse(
    long$dimension == "age",
    gsub(
      "Age (\\d+).*", "age_\\1",
      ifelse(
        grepl("^Statewide Total$", long$subgroup_raw),
        "total",
        long$subgroup_raw
      )
    ),
    standardize_sped_placement_subgroups(long$subgroup_raw)
  )
  long$subgroup[long$subgroup_raw == "Statewide Total"] <- "total"
  long$subgroup_raw <- NULL

  long$county_id <- NA_character_
  long$county_name <- NA_character_
  long$district_id <- NA_character_
  long$district_name <- "New Jersey"
  long$is_state <- TRUE
  long$is_district <- FALSE
  long$is_charter <- FALSE

  long <- long[, c(
    "end_year", "county_id", "county_name",
    "district_id", "district_name",
    "dimension", "subgroup", "environment",
    "count", "percent", "subgroup_total",
    "is_state", "is_district", "is_charter"
  )]
  rownames(long) <- NULL
  tibble::as_tibble(long)
}


#' Tidy the 3-5 District Counts sheet -- 2025
#' @keywords internal
tidy_sped_placement_district_3_5 <- function(df) {
  sg_col <- intersect(c("Student Group", "Student  Group"), names(df))[1]
  if (is.na(sg_col)) {
    stop("Could not find Student Group column in 3-5 District Counts sheet.",
         call. = FALSE)
  }

  df <- df[!is.na(df$`County Code`) &
    df$`County Code` != "end of worksheet", ]

  out <- data.frame(
    end_year = df$end_year,
    county_id = df$`County Code`,
    county_name = df$`County Name`,
    district_id = df$`District Code`,
    district_name = df$`District Name`,
    subgroup_raw = df[[sg_col]],
    environment = "districtwide",
    count = parse_placement_count(df$`Districtwide Total`),
    percent = parse_placement_pct(df$`Districtwide Percent`,
                                  scale_to_pct = 1),
    subgroup_total = parse_placement_count(df$`Districtwide Total`),
    stringsAsFactors = FALSE
  )
  out$subgroup <- standardize_sped_placement_subgroups(out$subgroup_raw)
  out$subgroup_raw <- NULL

  out$is_state <- FALSE
  out$is_district <- TRUE
  out$is_charter <- out$county_id == "80"

  out <- out[, c(
    "end_year", "county_id", "county_name",
    "district_id", "district_name",
    "subgroup", "environment",
    "count", "percent", "subgroup_total",
    "is_state", "is_district", "is_charter"
  )]
  rownames(out) <- NULL
  tibble::as_tibble(out)
}


# -----------------------------------------------------------------------------
# Pre-2025 (2020-2024) tidy functions
# -----------------------------------------------------------------------------

# Helper: pick the first column name from a candidate list that exists in df.
# Returns NA_character_ if none match. Used to handle inter-year naming
# variants (eg "District" vs "District Code", "Separate School" vs
# "Separate Settings").
pick_col <- function(df, candidates) {
  hit <- intersect(candidates, names(df))
  if (length(hit) == 0) NA_character_ else hit[[1]]
}


#' Tidy one pre-2025 5-21 district subgroup workbook
#'
#' Handles one of the four single-subgroup workbooks (race, gender,
#' disability, lep) published for end_years 2020-2024. Counts only (no
#' percent column was published in these files); percent is therefore NA.
#'
#' @param df raw tibble from \code{get_raw_sped_placement(...)} for the
#'   subgroup dimension
#' @param subgroup_dim "race" / "gender" / "disability" / "lep"
#' @return tidy tibble in the canonical schema
#' @keywords internal
tidy_pre2025_district_5_21_one <- function(df, subgroup_dim) {
  # Resolve flexible column names. Cross 2020-2024 we see:
  #   county_id:    "County Code" (2022+) | "County" (2020, 2021) | "County  Code" (2024 LEP, double space)
  #   district_id:  "District Code" (2022+) | "District" (2020, 2021)
  county_id_col <- pick_col(df, c("County Code", "County  Code", "County"))
  county_name_col <- pick_col(df, c("County Name"))
  district_id_col <- pick_col(df, c("District Code", "District"))
  district_name_col <- pick_col(df, c("District Name"))
  subgroup_col_lookup <- list(
    race = c("Race"),
    gender = c("Gender"),
    disability = c("Disability Category"),
    lep = c("LEP Status", "English Learner")
  )
  subgroup_col <- pick_col(df, subgroup_col_lookup[[subgroup_dim]])

  required <- c(
    county_id = county_id_col, county_name = county_name_col,
    district_id = district_id_col, district_name = district_name_col,
    subgroup = subgroup_col
  )
  if (any(is.na(required))) {
    missing_nm <- names(required)[is.na(required)]
    stop(sprintf(
      paste0(
        "tidy_pre2025_district_5_21_one(%s): missing expected column(s): %s.\n",
        "Available columns:\n  %s"
      ),
      subgroup_dim,
      paste(missing_nm, collapse = ", "),
      paste(names(df), collapse = "\n  ")
    ), call. = FALSE)
  }

  # Drop sentinel rows (NJ DOE marks end of data with a single cell row
  # whose first cell is "End Of Sheet" / "End of the Year" / similar).
  is_sentinel <- is.na(df[[county_id_col]]) |
    grepl("^end", df[[county_id_col]], ignore.case = TRUE)
  df <- df[!is_sentinel, , drop = FALSE]

  # Build per-environment long format. For each canonical short code, look
  # up the column name in the workbook (fall back through known variants).
  long_list <- lapply(
    names(sped_placement_5_21_pre2025_envcols),
    function(short) {
      candidates <- sped_placement_5_21_pre2025_envcols[[short]]
      col <- pick_col(df, candidates)
      if (is.na(col)) {
        # Some 2024 gender files use "Separate Settings" instead of
        # "Separate School"; the pick_col list already includes both.
        # If we still didn't find it, return NULL (no rows for this env).
        return(NULL)
      }
      data.frame(
        end_year = df$end_year,
        county_id = df[[county_id_col]],
        county_name = df[[county_name_col]],
        district_id = df[[district_id_col]],
        district_name = df[[district_name_col]],
        subgroup_raw = df[[subgroup_col]],
        environment = short,
        count = parse_placement_count(df[[col]]),
        percent = NA_real_,
        stringsAsFactors = FALSE
      )
    }
  )
  long <- do.call(rbind, long_list)

  if (is.null(long) || nrow(long) == 0) {
    return(tibble::tibble())
  }

  # 2020 5-21 disability uses 2-letter abbreviation codes -- expand them.
  if (subgroup_dim == "disability") {
    expansion <- sped_placement_disability_code_expansion
    long$subgroup_raw <- ifelse(
      long$subgroup_raw %in% names(expansion),
      expansion[long$subgroup_raw],
      long$subgroup_raw
    )
  }

  long$subgroup <- standardize_sped_placement_subgroups(long$subgroup_raw)
  long$subgroup_raw <- NULL

  long$is_state <- FALSE
  long$is_district <- TRUE
  long$is_charter <- long$county_id == "80"

  # Subgroup total = sum of environment counts within (district x subgroup).
  # Since pre-2025 files don't ship a districtwide total column for these
  # files, we derive it as the visible-count sum. Suppressed cells (NA)
  # mean the true total may be higher, but this matches the rule used
  # elsewhere in the package.
  totals <- stats::aggregate(
    long$count,
    by = list(
      end_year = long$end_year,
      county_id = long$county_id,
      district_id = long$district_id,
      subgroup = long$subgroup
    ),
    FUN = function(z) sum(z, na.rm = TRUE)
  )
  names(totals)[ncol(totals)] <- "subgroup_total"
  long <- merge(
    long, totals,
    by = c("end_year", "county_id", "district_id", "subgroup"),
    all.x = TRUE
  )

  long <- long[, c(
    "end_year", "county_id", "county_name",
    "district_id", "district_name",
    "subgroup", "environment",
    "count", "percent", "subgroup_total",
    "is_state", "is_district", "is_charter"
  )]
  rownames(long) <- NULL
  tibble::as_tibble(long)
}


#' Tidy one pre-2025 3-5 district subgroup workbook
#'
#' The 3-5 district files are count-only (no environment dimension). For
#' each (district x subgroup) pair we emit one row with
#' \code{environment = "districtwide"}, matching the 2025 3-5 District Counts
#' behavior so the schema is uniform across years.
#'
#' @param df raw tibble for the subgroup_dim
#' @param subgroup_dim "race" / "gender" / "disability" / "lep"
#' @return tidy tibble
#' @keywords internal
tidy_pre2025_district_3_5_one <- function(df, subgroup_dim) {
  county_id_col <- pick_col(df, c("County Code", "County  Code", "County"))
  county_name_col <- pick_col(df, c("County Name"))
  district_id_col <- pick_col(df, c("District Code", "District"))
  district_name_col <- pick_col(df, c("District Name"))

  required <- c(
    county_id = county_id_col, county_name = county_name_col,
    district_id = district_id_col, district_name = district_name_col
  )
  if (any(is.na(required))) {
    missing_nm <- names(required)[is.na(required)]
    stop(sprintf(
      paste0(
        "tidy_pre2025_district_3_5_one(%s): missing expected column(s): %s.\n",
        "Available columns:\n  %s"
      ),
      subgroup_dim,
      paste(missing_nm, collapse = ", "),
      paste(names(df), collapse = "\n  ")
    ), call. = FALSE)
  }

  # Drop sentinel rows.
  is_sentinel <- is.na(df[[county_id_col]]) |
    grepl("^end", df[[county_id_col]], ignore.case = TRUE)
  df <- df[!is_sentinel, , drop = FALSE]

  meta_cols <- c(
    county_id_col, county_name_col,
    district_id_col, district_name_col,
    "end_year", "subgroup_dim", "age_group", "source_file"
  )
  # Subgroup-bearing column for disability is the wide-format columns
  # themselves (one column per disability). For race/gender/LEP, there is
  # ONE row per (district x subgroup_value) so a "Race" / "Gender" /
  # "LEP Status" column carries the subgroup label.
  if (subgroup_dim == "disability") {
    # Pivot the disability columns into long form. Every non-meta column
    # is a disability label.
    dis_cols <- setdiff(names(df), meta_cols)
    rows <- lapply(dis_cols, function(dc) {
      data.frame(
        end_year = df$end_year,
        county_id = df[[county_id_col]],
        county_name = df[[county_name_col]],
        district_id = df[[district_id_col]],
        district_name = df[[district_name_col]],
        subgroup_raw = dc,
        environment = "districtwide",
        count = parse_placement_count(df[[dc]]),
        percent = NA_real_,
        stringsAsFactors = FALSE
      )
    })
    long <- do.call(rbind, rows)
  } else {
    subgroup_col_lookup <- list(
      race = c("Race"),
      gender = c("Gender"),
      lep = c("LEP Status", "English Learner")
    )
    subgroup_col <- pick_col(df, subgroup_col_lookup[[subgroup_dim]])
    # Count columns for race/gender/LEP 3-5 vary: 2020-2021 publish counts
    # spread across multiple disability-related columns and lack a "Total"
    # column. For these files we sum across all numeric (non-meta /
    # non-subgroup) columns to get the per-(district x subgroup) total.
    if (is.na(subgroup_col)) {
      # Fall back: single value per district. Sum across all data cols.
      data_cols <- setdiff(names(df), meta_cols)
      if (length(data_cols) == 0) {
        return(tibble::tibble())
      }
      counts <- rowSums(
        sapply(data_cols, function(dc) parse_placement_count(df[[dc]])),
        na.rm = TRUE
      )
      long <- data.frame(
        end_year = df$end_year,
        county_id = df[[county_id_col]],
        county_name = df[[county_name_col]],
        district_id = df[[district_id_col]],
        district_name = df[[district_name_col]],
        subgroup_raw = "Districtwide",
        environment = "districtwide",
        count = counts,
        percent = NA_real_,
        stringsAsFactors = FALSE
      )
    } else {
      data_cols <- setdiff(names(df), c(meta_cols, subgroup_col))
      counts <- rowSums(
        sapply(data_cols, function(dc) parse_placement_count(df[[dc]])),
        na.rm = TRUE
      )
      long <- data.frame(
        end_year = df$end_year,
        county_id = df[[county_id_col]],
        county_name = df[[county_name_col]],
        district_id = df[[district_id_col]],
        district_name = df[[district_name_col]],
        subgroup_raw = df[[subgroup_col]],
        environment = "districtwide",
        count = counts,
        percent = NA_real_,
        stringsAsFactors = FALSE
      )
    }
  }

  if (is.null(long) || nrow(long) == 0) {
    return(tibble::tibble())
  }

  long$subgroup <- standardize_sped_placement_subgroups(long$subgroup_raw)
  long$subgroup_raw <- NULL

  long$is_state <- FALSE
  long$is_district <- TRUE
  long$is_charter <- long$county_id == "80"

  # For 3-5 count-only, the per-row count IS the subgroup_total.
  long$subgroup_total <- long$count

  long <- long[, c(
    "end_year", "county_id", "county_name",
    "district_id", "district_name",
    "subgroup", "environment",
    "count", "percent", "subgroup_total",
    "is_state", "is_district", "is_charter"
  )]
  rownames(long) <- NULL
  tibble::as_tibble(long)
}


# Map the subgroup_dim of a raw pre-2025 5-21 district file to the
# `dimension` value used in the existing 2025 state output schema. (The
# district output doesn't have a `dimension` column, but this mapping is
# kept here for completeness if it's added later.)
sped_placement_dim_to_dimension <- c(
  race = "racial_ethnic",
  gender = "gender",
  disability = "disability",
  lep = "multilingual_learner"
)


#' Tidy a pre-2025 state placement workbook (5-21 or 3-5)
#'
#' For end_years where state placement is published as a standalone xlsx
#' (2023 3-5, 2024 5-21, 2024 3-5), parses the single-sheet workbook into
#' the canonical state-level tidy schema. The sheet structure has stacked
#' tables separated by section-header rows whose first cell labels the
#' dimension ("Race", "Gender", "Special Education Classification" /
#' "Disablity Category" / "Disability Category", "LEP Status" / "LEP").
#'
#' @param df raw tibble (sheet read with skip = 0, col_types = "text")
#' @param end_year for tagging
#' @param age_group "5-21" or "3-5"
#' @return tidy tibble matching the 2025 state output schema
#' @keywords internal
tidy_pre2025_state <- function(df, end_year, age_group) {
  # Find the section-header rows: rows whose first column matches one of
  # the known dimension labels.
  col1 <- df[[1]]
  dimension_labels <- list(
    racial_ethnic = c("Race"),
    gender = c("Gender"),
    disability = c(
      "Special Education Classification",
      "Disablity Category", # NJ typo in some 3-5 sheets
      "Disability Category"
    ),
    multilingual_learner = c("LEP Status", "LEP", "Lep Status")
  )
  header_idx <- integer(0)
  header_dim <- character(0)
  for (dim_key in names(dimension_labels)) {
    candidates <- dimension_labels[[dim_key]]
    hits <- which(col1 %in% candidates)
    if (length(hits) > 0) {
      header_idx <- c(header_idx, hits[[1]])
      header_dim <- c(header_dim, dim_key)
    }
  }
  ord <- order(header_idx)
  header_idx <- header_idx[ord]
  header_dim <- header_dim[ord]

  if (length(header_idx) == 0) {
    stop(sprintf(
      "tidy_pre2025_state(%d, %s): no dimension-header rows found.",
      end_year, age_group
    ), call. = FALSE)
  }

  # Each section runs from the row AFTER its header up to the row BEFORE
  # the next header (or end of sheet).
  starts <- header_idx + 1L
  ends <- c(header_idx[-1] - 1L, nrow(df))

  if (age_group == "5-21") {
    # 5-21 state sheets are wide -- one row per subgroup_raw value, with
    # 7 environment (count, pct) column pairs plus a final (Total, Total%)
    # pair. The column NAMES embed `%` characters in the count headers
    # ("Inside the Regular Class 80% Or More of day"), so regex-based
    # count/pct disambiguation is unreliable. Instead we index positionally
    # off the first non-meta column.
    #
    # The 2024 5-21 statewide placement workbook has these data columns
    # (after the "Measure" label in column 1):
    #   c2,c3  = gen_ed_80_plus       (count, pct)
    #   c4,c5  = gen_ed_40_79         (count, pct)
    #   c6,c7  = gen_ed_less_40       (count, pct)
    #   c8,c9  = separate_school      (count, pct)
    #   c10,c11 = residential_facility (count, pct)
    #   c12,c13 = homebound_hospital   (count, pct)
    #   c14,c15 = correction_facility  (count, pct)
    #   c16,c17 = Total, TOTAL %
    #
    # Layout has been stable across the SPR-era 5-21 state placement files.
    env_codes_5_21 <- c(
      "gen_ed_80_plus", "gen_ed_40_79", "gen_ed_less_40",
      "separate_school", "residential_facility",
      "homebound_hospital", "correction_facility"
    )
    env_count_cols_5_21 <- as.integer(c(2, 4, 6, 8, 10, 12, 14))
    env_pct_cols_5_21 <- as.integer(c(3, 5, 7, 9, 11, 13, 15))
    total_col_5_21 <- 16L
    total_pct_col_5_21 <- 17L

    # Sanity-check: the file must have at least 17 columns.
    if (ncol(df) < total_pct_col_5_21) {
      stop(sprintf(
        paste0(
          "tidy_pre2025_state(%d, 5-21): expected at least %d columns, ",
          "got %d. Layout may have changed."
        ),
        end_year, total_pct_col_5_21, ncol(df)
      ), call. = FALSE)
    }
  }

  long_per_section <- lapply(seq_along(header_idx), function(i) {
    dim_key <- header_dim[[i]]
    chunk <- df[starts[[i]]:ends[[i]], , drop = FALSE]
    # Drop blank rows.
    chunk <- chunk[!is.na(chunk[[1]]), , drop = FALSE]
    # Drop "End of the Sheet" sentinel rows.
    chunk <- chunk[!grepl("^end", chunk[[1]], ignore.case = TRUE),
                   , drop = FALSE]
    if (nrow(chunk) == 0) return(NULL)

    if (age_group == "5-21") {
      # One row per subgroup value, columns per env count + percent.
      rows_per_env <- lapply(seq_along(env_codes_5_21), function(j) {
        short <- env_codes_5_21[[j]]
        ci <- env_count_cols_5_21[[j]]
        pi <- env_pct_cols_5_21[[j]]
        data.frame(
          end_year = end_year,
          dimension = dim_key,
          subgroup_raw = chunk[[1]],
          environment = short,
          count = parse_placement_count(chunk[[ci]]),
          percent = parse_placement_pct(chunk[[pi]], scale_to_pct = 1),
          stringsAsFactors = FALSE
        )
      })
      env_long <- do.call(rbind, rows_per_env)
      # Subgroup total: use the chunk's "Total" column for the per-row total.
      totals <- data.frame(
        end_year = end_year,
        dimension = dim_key,
        subgroup_raw = chunk[[1]],
        subgroup_total = parse_placement_count(chunk[[total_col_5_21]]),
        stringsAsFactors = FALSE
      )
      merge(
        env_long, totals,
        by = c("end_year", "dimension", "subgroup_raw"),
        all.x = TRUE
      )
    } else {
      # 3-5 state placement: column headers above the first section have
      # 4 prose "Receiving Majority Of Special Education And Related
      # Services..." columns flanked by sub-headers. The data columns are
      # the 4 environment groups with count+pct interleaved per env, then
      # a Total + Total% pair at the end. The first row of each section
      # is itself a header row carrying the env labels, so we strip it.
      # Actually we want to extract: cols 2, 4, 6, 8 = counts for
      # ec_program_10plus_hrs, services_other_loc_attended_ec_10plus_hrs,
      # ec_program_less_10_hrs, services_other_loc_attended_ec_less_10_hrs.
      # Cols 3, 5, 7, 9 are corresponding percents. Col 10 = Total, 11 = Total%.
      # See observed 2024 layout: row 6 (Race header) followed by 7-14
      # data rows including a "Total" sentinel row.
      env_short_codes_3_5 <- c(
        ec_program_10plus_hrs = c(2, 3),
        services_other_loc_attended_ec_10plus_hrs = c(4, 5),
        ec_program_less_10_hrs = c(6, 7),
        services_other_loc_attended_ec_less_10_hrs = c(8, 9)
      )
      # The first row in `chunk` may be a header row repeating
      # "Receiving Majority..." labels. Detect by checking if col 2 of
      # that row starts with "Receiving" / "Children".
      first_cell_col2 <- chunk[[2]][[1]]
      if (!is.na(first_cell_col2) &&
          grepl("^Receiving|^Children", first_cell_col2,
                ignore.case = TRUE)) {
        chunk <- chunk[-1, , drop = FALSE]
      }
      if (nrow(chunk) == 0) return(NULL)
      rows_per_env <- list()
      env_codes <- c("ec_program_10plus_hrs",
                     "services_other_loc_attended_ec_10plus_hrs",
                     "ec_program_less_10_hrs",
                     "services_other_loc_attended_ec_less_10_hrs")
      env_count_cols <- c(2L, 4L, 6L, 8L)
      env_pct_cols <- c(3L, 5L, 7L, 9L)
      for (j in seq_along(env_codes)) {
        rows_per_env[[j]] <- data.frame(
          end_year = end_year,
          dimension = dim_key,
          subgroup_raw = chunk[[1]],
          environment = env_codes[[j]],
          count = parse_placement_count(chunk[[env_count_cols[[j]]]]),
          percent = parse_placement_pct(
            chunk[[env_pct_cols[[j]]]], scale_to_pct = 1
          ),
          stringsAsFactors = FALSE
        )
      }
      env_long <- do.call(rbind, rows_per_env)
      # Total column is column 10.
      total_col_idx <- 10L
      if (ncol(chunk) >= total_col_idx) {
        totals <- data.frame(
          end_year = end_year,
          dimension = dim_key,
          subgroup_raw = chunk[[1]],
          subgroup_total = parse_placement_count(chunk[[total_col_idx]]),
          stringsAsFactors = FALSE
        )
        env_long <- merge(
          env_long, totals,
          by = c("end_year", "dimension", "subgroup_raw"),
          all.x = TRUE
        )
      } else {
        env_long$subgroup_total <- NA_real_
      }
      env_long
    }
  })

  long <- do.call(rbind, long_per_section)
  if (is.null(long) || nrow(long) == 0) return(tibble::tibble())

  # Standardize subgroup labels. "Total" rows -> "total".
  long$subgroup <- standardize_sped_placement_subgroups(long$subgroup_raw)
  long$subgroup[long$subgroup_raw %in% c("Total", "total")] <- "total"
  long$subgroup_raw <- NULL

  long$county_id <- NA_character_
  long$county_name <- NA_character_
  long$district_id <- NA_character_
  long$district_name <- "New Jersey"
  long$is_state <- TRUE
  long$is_district <- FALSE
  long$is_charter <- FALSE

  long <- long[, c(
    "end_year", "county_id", "county_name",
    "district_id", "district_name",
    "dimension", "subgroup", "environment",
    "count", "percent", "subgroup_total",
    "is_state", "is_district", "is_charter"
  )]
  rownames(long) <- NULL
  tibble::as_tibble(long)
}


# Dispatch helper: tidy a pre-2025 (year, age, level) raw result.
tidy_pre2025_sped_placement <- function(raw_list, end_year, age_group, level) {
  if (level == "district" && age_group == "5-21") {
    parts <- lapply(names(raw_list), function(dim) {
      tidy_pre2025_district_5_21_one(raw_list[[dim]], dim)
    })
    return(dplyr::bind_rows(parts))
  }
  if (level == "district" && age_group == "3-5") {
    parts <- lapply(names(raw_list), function(dim) {
      tidy_pre2025_district_3_5_one(raw_list[[dim]], dim)
    })
    return(dplyr::bind_rows(parts))
  }
  if (level == "state") {
    # We expect exactly one entry in raw_list: the "placement" file.
    if (length(raw_list) != 1) {
      stop(sprintf(
        "Internal error: expected 1 state placement file for %d %s, got %d.",
        end_year, age_group, length(raw_list)
      ), call. = FALSE)
    }
    df <- raw_list[[1]]
    return(tidy_pre2025_state(df, end_year, age_group))
  }
  stop("Internal error: unsupported (age_group, level) combination.",
       call. = FALSE)
}


# -----------------------------------------------------------------------------
# Public API
# -----------------------------------------------------------------------------

#' Fetch NJ Special Education Placement / Educational Environment data
#'
#' Returns the IDEA Section 618 "Student Count and Educational Environment"
#' (placement / Least Restrictive Environment) data published by the NJ DOE,
#' the companion to \code{\link{fetch_sped}} (which returns classification
#' rates). The workbook reports counts and percents of students with
#' disabilities by educational setting (eg "In General Education for 80% or
#' More of the Day", "Separate School", "Residential Facility").
#'
#' @section Coverage:
#' Supports end_years 2020-2025. NJ DOE changed publication conventions
#' multiple times across these years: 2020-2021 are bundled inside an
#' annual zip archive; 2022-2024 publish ~8 single-subgroup workbooks per
#' year; 2025 consolidates everything into one workbook. The fetcher hides
#' these differences and exposes a single tidy schema.
#'
#' One narrow gap: \code{fetch_sped_placement(2021, age_group = "5-21")}
#' errors with a clear message because NJ DOE only published that one slice
#' as a PDF. Similarly, end_year 2020/2022/2023 state-level 5-21 placement
#' and end_year 2020-2022 state-level 3-5 placement are PDF-only and error
#' out. The corresponding district-level data is still available in every
#' affected year. Pre-2020 placement data is not downloadable at all and
#' requires an OPRA request.
#'
#' @section Tidy output schema:
#' One row per (entity x subgroup x environment), with:
#' \itemize{
#'   \item \code{end_year}, \code{county_id}, \code{county_name},
#'     \code{district_id}, \code{district_name} (state rows have NA ids and
#'     \code{district_name = "New Jersey"})
#'   \item \code{subgroup} -- standardized snake_case (\code{"total"},
#'     \code{"black"}, \code{"hispanic"}, \code{"lep"}, \code{"male"}, ...,
#'     plus disability categories like \code{"autism"} and (2025 state output
#'     only) age rows like \code{"age_6"})
#'   \item \code{environment} -- short code for the educational setting (see
#'     Details for valid values)
#'   \item \code{count}, \code{percent} -- counts and percents (0-100 scale)
#'     reported for the cell; suppressed cells (\code{"*"}) become \code{NA}.
#'     Note: pre-2025 district 5-21 workbooks publish counts only, so
#'     \code{percent} is \code{NA} in those rows.
#'   \item \code{subgroup_total} -- the subgroup's row total (Districtwide
#'     Total / Statewide Total) carried for convenience. For pre-2025 district
#'     5-21 rows this is the visible-count sum across environments.
#'   \item \code{is_state}, \code{is_district}, \code{is_charter} -- entity
#'     flags consistent with other njschooldata fetchers (county_id == "80"
#'     marks charter schools/districts)
#'   \item \code{dimension} (state output only) -- which marginal table the
#'     row came from (\code{"racial_ethnic"}, \code{"gender"},
#'     \code{"disability"}, \code{"multilingual_learner"}; 2025 additionally
#'     reports \code{"age"})
#' }
#'
#' @section Environment categories (school-age, 5-21):
#' \code{gen_ed_80_plus}, \code{gen_ed_40_79}, \code{gen_ed_less_40},
#' \code{separate_school}, \code{residential_facility},
#' \code{homebound_hospital}, \code{correction_facility}.
#' 2025 additionally reports \code{parentally_placed_nonpublic}.
#'
#' @section Environment categories (preschool, 3-5 state):
#' \code{ec_program_10plus_hrs},
#' \code{services_other_loc_attended_ec_10plus_hrs},
#' \code{ec_program_less_10_hrs},
#' \code{services_other_loc_attended_ec_less_10_hrs},
#' \code{separate_class}, \code{separate_school}, \code{residential_facility},
#' \code{home}, \code{service_provider_location}.
#' The 3-5 district sheet has no environment dimension -- the tidy output
#' uses \code{environment = "districtwide"} with the districtwide total.
#'
#' @param end_year ending school year (eg 2025 for the 2024-25 school
#'   year). Valid years: 2020 through 2025.
#' @param age_group one of \code{"5-21"} (school-age, default) or
#'   \code{"3-5"} (preschool).
#' @param level one of \code{"district"} (district + charter rows, default)
#'   or \code{"state"} (statewide breakdowns).
#' @param tidy if \code{TRUE} (default), pivots to the long tidy schema
#'   described above. If \code{FALSE}, returns the raw workbook tibble(s)
#'   with minimal cleaning (column names preserved as published; all values
#'   as character; suppression flags retained). For pre-2025 years that
#'   span multiple subgroup files, \code{tidy = FALSE} returns a named list.
#'
#' @return tibble. See "Tidy output schema" for the layout when
#'   \code{tidy = TRUE}.
#'
#' @seealso \code{\link{fetch_sped}} for the SPED classification rate data,
#'   \code{\link{fetch_sped_placement_multi}} for a multi-year wrapper, and
#'   \code{\link{get_raw_sped_placement}} for the underlying raw reader.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # 1. Basic call: school-age district-level placement (2025)
#' placement <- fetch_sped_placement(2025)
#'
#' # 2. Common dplyr filter -- where are Newark's classified students placed?
#' library(dplyr)
#' fetch_sped_placement(2025) %>%
#'   filter(district_name == "Newark Public School District",
#'          subgroup == "total") %>%
#'   select(environment, count, percent) %>%
#'   arrange(desc(percent))
#'
#' # 3. State-level breakdown by disability (2024)
#' fetch_sped_placement(2024, level = "state") %>%
#'   filter(dimension == "disability",
#'          environment == "gen_ed_80_plus") %>%
#'   select(subgroup, count, percent) %>%
#'   arrange(desc(percent))
#'
#' # 4. Earlier-year district 5-21 (pre-2025 returns counts only)
#' fetch_sped_placement(2022, age_group = "5-21", level = "district")
#' }
fetch_sped_placement <- function(end_year,
                                 age_group = "5-21",
                                 level = "district",
                                 tidy = TRUE) {
  # 2021 + 5-21 short-circuit (mandated by design; see plan section 4).
  # We check up front so callers see this error without a network attempt.
  if (end_year == 2021L && age_group == "5-21") {
    sped_placement_21_5_21_error()
  }
  if (level == "state") {
    if (age_group == "5-21" && end_year %in% c(2020L, 2022L, 2023L)) {
      sped_placement_state_pdf_error(end_year, age_group)
    }
    if (age_group == "3-5" && end_year %in% c(2020L, 2021L, 2022L)) {
      sped_placement_state_pdf_error(end_year, age_group)
    }
  }

  raw <- get_raw_sped_placement(
    end_year = end_year,
    age_group = age_group,
    level = level
  )

  if (!tidy) {
    return(raw)
  }

  if (end_year == 2025L) {
    if (level == "district" && age_group == "5-21") {
      return(tidy_sped_placement_district_5_21(raw))
    } else if (level == "district" && age_group == "3-5") {
      return(tidy_sped_placement_district_3_5(raw))
    } else if (level == "state") {
      return(tidy_sped_placement_state(raw, age_group = age_group))
    } else {
      stop(
        "Unsupported (age_group, level) combination.",
        call. = FALSE
      )
    }
  }

  # 2020-2024 path
  tidy_pre2025_sped_placement(raw, end_year, age_group, level)
}


#' Fetch NJ SPED placement data for multiple years
#'
#' Convenience wrapper that calls \code{\link{fetch_sped_placement}} for each
#' year and binds the results. Per-year failures are surfaced as warnings and
#' the year is skipped, matching the package's existing multi-year wrappers.
#'
#' The 2021 Ages 5-21 short-circuit and any pre-2025 PDF-only state-level
#' combinations will surface as warnings here, so a multi-year call like
#' \code{fetch_sped_placement_multi(2020:2025)} happily returns whatever
#' slices exist.
#'
#' @param end_years integer vector of school years
#' @param age_group one of \code{"5-21"} or \code{"3-5"}
#' @param level one of \code{"district"} or \code{"state"}
#' @param tidy logical; passed through to \code{fetch_sped_placement()}
#'
#' @return a single tibble with all successfully-fetched years bound together.
#'
#' @seealso \code{\link{fetch_sped_placement}}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Pull every supported year (district 5-21). 2021/5-21 surfaces as a
#' # warning; other years return data.
#' placement_all <- fetch_sped_placement_multi(2020:2025)
#'
#' # State-level multi-year (only 2024-2025 have 5-21 state placement
#' # available; other years emit a warning).
#' fetch_sped_placement_multi(2020:2025, level = "state")
#' }
fetch_sped_placement_multi <- function(end_years,
                                       age_group = "5-21",
                                       level = "district",
                                       tidy = TRUE) {
  results <- list()
  for (yr in end_years) {
    result <- tryCatch(
      fetch_sped_placement(
        end_year = yr,
        age_group = age_group,
        level = level,
        tidy = tidy
      ),
      error = function(e) {
        warning(
          sprintf(
            "Could not fetch SPED placement data for %d: %s",
            yr, e$message
          ),
          call. = FALSE
        )
        NULL
      }
    )
    if (!is.null(result)) {
      results[[as.character(yr)]] <- result
    }
  }

  if (length(results) == 0) {
    stop(
      "No SPED placement data could be fetched for any requested year.",
      call. = FALSE
    )
  }

  dplyr::bind_rows(results)
}
