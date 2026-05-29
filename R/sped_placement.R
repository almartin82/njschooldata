# ==============================================================================
# Special Education Placement / Educational Environment (IDEA Section 618)
# ==============================================================================
#
# Fetcher for the NJ DOE Student Count and Educational Environment workbook
# published under IDEA Section 618 public reporting. This is the placement
# (Least Restrictive Environment / LRE) dataset that complements the existing
# fetch_sped() classification-rate fetcher.
#
# Closes #46.
#
# As of v0.9.12, only the SY2024-25 consolidated workbook
# ("2025IDEA618PublicReporting_StudentCountandEducationalEnvironment.xlsx")
# is supported. Earlier years exist on nj.gov but are spread across a dozen
# subgroup-specific files (and some are PDF-only) -- those are tracked as a
# follow-up.
# ==============================================================================


# -----------------------------------------------------------------------------
# Year + URL configuration
# -----------------------------------------------------------------------------

#' Valid years for SPED placement / educational-environment data
#'
#' @return integer vector of supported end years
#' @keywords internal
get_valid_sped_placement_years <- function() {
  # NJ's "Student Count and Educational Environment" file (one consolidated
  # workbook with state + district sheets, age 3-5 and 5-21) first appears
  # for SY2024-25 -- end_year 2025. Earlier years are published under a
  # different, fragmented file structure on nj.gov and are not yet wired up.
  c(2025L)
}


#' Build the IDEA 618 placement workbook URL
#'
#' @param end_year ending school year (currently only 2025)
#' @return character URL
#' @keywords internal
build_sped_placement_url <- function(end_year) {
  paste0(
    "https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/",
    end_year, "_618data/",
    end_year,
    "IDEA618PublicReporting_StudentCountandEducationalEnvironment.xlsx"
  )
}


# -----------------------------------------------------------------------------
# Workbook cache (on-disk, like SPR)
# -----------------------------------------------------------------------------

#' Directory holding cached SPED placement workbooks
#'
#' Mirrors \code{njsd_workbook_cache_dir()} for SPR -- the placement workbook
#' is large enough that we cache it on disk across sessions.
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


#' Download (and disk-cache) the IDEA 618 placement workbook
#'
#' Validates the download as a real .xlsx before caching, so an HTTP error or
#' bot-protection page is never written to the cache or parsed as data.
#'
#' @param end_year ending school year
#' @return path to a local, validated .xlsx file
#' @keywords internal
sped_placement_cached_workbook <- function(end_year) {
  url <- build_sped_placement_url(end_year)

  use_cache <- isTRUE(getOption("njschooldata.workbook_cache", TRUE)) &&
    njsd_cache_enabled()

  if (use_cache) {
    cache_dir <- sped_placement_cache_dir()
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
    dest <- file.path(
      cache_dir,
      sprintf("SPED_Placement_%d.xlsx", end_year)
    )
    if (is_valid_xlsx(dest)) {
      return(dest)
    }
    dl_dir <- cache_dir
  } else {
    dest <- tempfile(pattern = "sped_placement_", fileext = ".xlsx")
    dl_dir <- dirname(dest)
  }

  tmp <- tempfile(
    pattern = "sped_placement_dl_", tmpdir = dl_dir, fileext = ".xlsx"
  )
  on.exit(unlink(tmp), add = TRUE)
  downloader::download(url, destfile = tmp, mode = "wb")

  if (!is_valid_xlsx(tmp)) {
    stop(sprintf(
      paste0(
        "Downloaded SPED placement workbook for %d is not a valid .xlsx ",
        "file -- the NJ DOE source may be unavailable or returned an error ",
        "page.\n  URL: %s"
      ),
      end_year, url
    ), call. = FALSE)
  }

  if (!file.rename(tmp, dest)) {
    file.copy(tmp, dest, overwrite = TRUE)
  }
  dest
}


# -----------------------------------------------------------------------------
# Sheet name dispatch
# -----------------------------------------------------------------------------

# The 2025 workbook has the following sheets we care about for placement:
#   "5-21 District by Ed Environ"  -- school-age, district + charter
#   "3-5 District Counts"          -- preschool, district + charter (totals
#                                    only, no environment dimension)
#   "5-21 State by Ed Environ"     -- school-age, statewide (stacked tables)
#   "3-5 State by Ed Environ"      -- preschool, statewide (stacked tables)
#
# The tidy interface exposes the per-entity sheets directly. The statewide
# sheets are also exposed so users can pull state-level breakdowns.

#' Map (age_group, level) to the workbook sheet name
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
      # The 3-5 District sheet is "Counts" only (no environment breakdown).
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
# Raw reader
# -----------------------------------------------------------------------------

#' Read one raw sheet from the SPED placement workbook
#'
#' Returns the raw tibble for a single sheet with minimal cleaning -- column
#' names are kept as-is from the workbook and all values are kept as
#' character (the workbook embeds "*" suppression flags).
#'
#' @param end_year ending school year (currently only 2025)
#' @param age_group "5-21" or "3-5"
#' @param level "district" or "state"
#'
#' @return tibble of the raw sheet, with an \code{end_year} column appended
#' @export
#'
#' @examples
#' \dontrun{
#' # Raw district-level school-age placement
#' raw <- get_raw_sped_placement(2025, age_group = "5-21", level = "district")
#'
#' # Raw preschool statewide
#' raw_state_3_5 <- get_raw_sped_placement(2025, age_group = "3-5", level = "state")
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
          "Valid years are: %s. Earlier years are published under a ",
          "different, fragmented file structure and are not yet supported ",
          "(see issue #46 follow-up)."
        ),
        end_year, paste(valid_years, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  sheet <- sped_placement_sheet(age_group, level)

  # Check the parsed-sheet session cache first.
  cache_key <- make_cache_key(
    "get_raw_sped_placement",
    end_year = end_year, age_group = age_group, level = level
  )
  cached <- cache_get(cache_key)
  if (!is.null(cached)) {
    return(cached)
  }

  wb <- sped_placement_cached_workbook(end_year)

  # Header is on row 5 in every sheet in the 2025 workbook.
  df <- readxl::read_excel(
    path = wb,
    sheet = sheet,
    skip = 4,
    col_types = "text"
  )

  df$end_year <- end_year

  cache_set(cache_key, df)
  df
}


# -----------------------------------------------------------------------------
# Tidy / reshape helpers
# -----------------------------------------------------------------------------

# School-age (5-21) educational-environment categories. Stored as a named
# vector mapping the canonical short code -> the prefix used in the workbook
# column headers. The same prefix is shared by the Count and Percent columns
# (eg "Separate School Count" and "Separate School Percent").
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


#' Standardize student-group labels to cross-state conventions
#'
#' Maps the verbose NJ student-group labels in the District by Ed Environ
#' sheet (eg "Black or African American", "Multilingual Learner") to the
#' lowercase snake_case names the rest of njschooldata/the 50-state project
#' uses (eg "black", "lep").
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
    x == "Hispanic" ~ "hispanic",
    x == "Native Hawaiian or Pacific Islander" ~ "pacific_islander",
    x == "Native Hawaiian or Other Pacific Islander" ~ "pacific_islander",
    x == "Two or More Races" ~ "multiracial",
    x == "White" ~ "white",
    # Gender
    x == "Female" ~ "female",
    x == "Male" ~ "male",
    x == "Non-Binary/Undesignated" ~ "non_binary",
    # ML status
    x == "Multilingual Learner" ~ "lep",
    x == "Non-Multilingual Learner" ~ "non_lep",
    # Disability categories -- keep snake_case for cross-state consistency
    x == "Auditory Impairment" ~ "auditory_impairment",
    x == "Autism" ~ "autism",
    x == "Deaf-Blindness" ~ "deaf_blindness",
    x == "Emotional Regulation Impairment" ~ "emotional_regulation_impairment",
    x == "Intellectual Disability" ~ "intellectual_disability",
    x == "Multiple Disabilities" ~ "multiple_disabilities",
    x == "Orthopedic Impairment" ~ "orthopedic_impairment",
    x == "Other Health Impairment" ~ "other_health_impairment",
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
#'   - State sheets store percents as decimals (eg 0.4514 = 45.14%)
#'   - District sheets store percents as whole percents (eg 67.3 = 67.3%)
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


#' Tidy the District by Ed Environ sheet (school-age, 5-21)
#'
#' Pivots the wide workbook to long format: one row per
#' (county_id, district_id, subgroup, environment), with \code{count} and
#' \code{percent} columns. Adds standard entity flags.
#'
#' @param df raw tibble from \code{get_raw_sped_placement(level = "district",
#'   age_group = "5-21")}
#' @return tidy tibble
#' @keywords internal
tidy_sped_placement_district_5_21 <- function(df) {
  # Drop the trailing sentinel row.
  df <- df[!is.na(df$`County Code`) &
    df$`County Code` != "end of worksheet", ]

  # Drop the per-district total column -- it's a margin, not an environment.
  # We expose it separately as "districtwide_total" on the output via
  # a join below if needed; for tidy long form, we keep environment rows only.

  # Build long format.
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

  # Per-row totals (Districtwide Total / Percent) -- carry as a separate
  # column so users don't have to re-join.
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

  # Standardize subgroup labels (after the join so totals still match raw).
  out$subgroup <- standardize_sped_placement_subgroups(out$subgroup_raw)
  out$subgroup_raw <- NULL

  # Entity flags. The district sheet contains charter "districts" under
  # county_id == "80"; the rest are traditional public-school districts.
  # There is no state-aggregate row in this sheet (state totals live in the
  # State by Ed Environ sheet).
  out$is_state <- FALSE
  out$is_district <- TRUE
  out$is_charter <- out$county_id == "80"

  # Reorder columns
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


#' Identify the next-table-divider row inside a stacked State sheet
#'
#' The State by Ed Environ sheets stack five tables vertically (by age, by
#' disability, by race, by gender, by ML status), each separated by a
#' descriptive header row and a column-name row. This helper splits the
#' sheet into per-table chunks keyed on the first column.
#'
#' @param df raw tibble (after \code{skip = 4} read)
#' @return named list of per-table tibbles
#' @keywords internal
split_state_ed_environ_tables <- function(df) {
  col1 <- df[[1]]
  # The descriptive header rows for each subsequent table start with
  # "Counts and Percents of ... by Educational Environment and ..." in col 1.
  # The first table has no leading header (just the age rows). Any "<group>
  # Category" / "<group> Group" / "<group>" row immediately below the
  # descriptive header is the column header for that subtable; in our
  # skip=4 read it becomes a *data* row whose first cell is the dimension
  # label (eg "Disability Category", "Racial/Ethnic Group", "Gender",
  # "Multilingual Learner Status"). We use that to slice.

  divider_idx <- grep(
    "^Counts and Percents", col1
  )

  # Table breaks: each "Counts and Percents..." row starts a new table.
  # First table (by age) runs from row 1 to (first divider - 1).
  starts <- c(1, divider_idx + 2) # +2 to skip the "Counts and Percents" row
  # *and* the dimension-label row right below it.
  ends <- c(divider_idx - 1, nrow(df))

  # The category names we'll attach to each table.
  cat_names <- c(
    "age",
    sub(".*by Educational Environment and (.*)$", "\\1",
      col1[divider_idx])
  )
  # Clean up the dimension labels for the per-table key.
  cat_names <- gsub(" Category| Group| Status", "", cat_names)
  cat_names <- tolower(gsub("[^A-Za-z]+", "_", cat_names))
  cat_names <- gsub("_$", "", cat_names)

  out <- lapply(seq_along(starts), function(i) {
    chunk <- df[starts[i]:ends[i], , drop = FALSE]
    # Drop any blank or "end of worksheet" rows.
    chunk <- chunk[!is.na(chunk[[1]]), ]
    chunk <- chunk[!grepl("^end of worksheet$",
                          chunk[[1]], ignore.case = TRUE), ]
    # Drop any rows that are themselves "Counts and Percents..." dividers or
    # the dimension-label row that may sneak in for tables 2..N.
    chunk <- chunk[!grepl("^Counts and Percents",
                          chunk[[1]]), ]
    chunk
  })
  names(out) <- cat_names
  out
}


#' Tidy the State by Ed Environ sheet (5-21 or 3-5)
#'
#' @param df raw tibble from \code{get_raw_sped_placement(level = "state")}
#' @param age_group "5-21" or "3-5"
#' @return tidy tibble in the same long shape as the district output
#' @keywords internal
tidy_sped_placement_state <- function(df, age_group) {
  categories <- if (age_group == "5-21") {
    sped_placement_categories_5_21
  } else {
    sped_placement_categories_3_5
  }

  tables <- split_state_ed_environ_tables(df)

  # Build long output table by table.
  long_per_table <- lapply(names(tables), function(dim_name) {
    chunk <- tables[[dim_name]]
    if (nrow(chunk) == 0) return(NULL)

    # The first column carries the row-dimension label; the rest carry
    # Count/Percent pairs per environment.
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
          # State sheets store percents as decimals -- scale to 0-100.
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

  # State-side totals (Statewide Total / Percent)
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

  # The "age" dimension is special: the row label is "Age 5 (and in
  # Kindergarten)", "Age 6", ..., "Statewide Total". The first 4 dimensions
  # use prose labels we normalize to canonical subgroup names; the "age"
  # rows we keep as-is in the subgroup column (eg "age_5", "age_6") and
  # the statewide marginal becomes subgroup == "total".
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
  # The disability/race/gender/ML tables include their own "Statewide Total"
  # row which is a duplicate of the age "Statewide Total"; mark it "total".
  long$subgroup[long$subgroup_raw == "Statewide Total"] <- "total"

  long$subgroup_raw <- NULL

  # Standard entity flags.
  long$county_id <- NA_character_
  long$county_name <- NA_character_
  long$district_id <- NA_character_
  long$district_name <- "New Jersey"
  long$is_state <- TRUE
  long$is_district <- FALSE
  long$is_charter <- FALSE

  # Reorder
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


#' Tidy the 3-5 District Counts sheet (preschool, totals only)
#'
#' The preschool district sheet does NOT carry an environment dimension -- it
#' only has a districtwide total per (district, student group). The tidy
#' output has the same column shape as the school-age district output, with
#' \code{environment = "districtwide"} and \code{count}/\code{percent} taken
#' from the workbook's Districtwide Total / Districtwide Percent columns.
#' This keeps a uniform tidy schema across age groups.
#'
#' @param df raw tibble from \code{get_raw_sped_placement(level = "district",
#'   age_group = "3-5")}
#' @return tidy tibble
#' @keywords internal
tidy_sped_placement_district_3_5 <- function(df) {
  # The 3-5 District Counts sheet has the typo "Student  Group" (double
  # space) in the header. Detect either spelling.
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
#' Currently only the SY2024-25 consolidated workbook (end_year 2025) is
#' supported. Earlier years are published on nj.gov but under a different,
#' fragmented file structure (one workbook per subgroup, with some
#' subgroups PDF-only). Wiring them up is tracked as a follow-up to
#' issue #46. Pre-2020 placement data is not downloadable at all and
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
#'     plus disability categories like \code{"autism"} and (state output
#'     only) age rows like \code{"age_6"})
#'   \item \code{environment} -- short code for the educational setting (see
#'     Details for valid values)
#'   \item \code{count}, \code{percent} -- counts and percents (0-100 scale)
#'     reported for the cell; suppressed cells (\code{"*"}) become \code{NA}
#'   \item \code{subgroup_total} -- the subgroup's row total (Districtwide
#'     Total / Statewide Total) carried for convenience
#'   \item \code{is_state}, \code{is_district}, \code{is_charter} -- entity
#'     flags consistent with other njschooldata fetchers (county_id == "80"
#'     marks charter schools/districts)
#'   \item \code{dimension} (state output only) -- which marginal table the
#'     row came from (\code{"age"}, \code{"disability"}, \code{"racial_ethnic"},
#'     \code{"gender"}, \code{"multilingual_learner"})
#' }
#'
#' @section Environment categories (school-age, 5-21):
#' \code{gen_ed_80_plus}, \code{gen_ed_40_79}, \code{gen_ed_less_40},
#' \code{separate_school}, \code{residential_facility},
#' \code{homebound_hospital}, \code{correction_facility},
#' \code{parentally_placed_nonpublic}.
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
#'   year). Valid years: 2025.
#' @param age_group one of \code{"5-21"} (school-age, default) or
#'   \code{"3-5"} (preschool).
#' @param level one of \code{"district"} (district + charter rows, default)
#'   or \code{"state"} (statewide breakdowns by age, disability, race/
#'   ethnicity, gender, and multilingual-learner status).
#' @param tidy if \code{TRUE} (default), pivots to the long tidy schema
#'   described above. If \code{FALSE}, returns the raw workbook tibble with
#'   minimal cleaning (column names preserved as published; all values as
#'   character; suppression flags retained).
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
#' # 1. Basic call: school-age district-level placement
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
#' # 3. State-level breakdown by disability
#' fetch_sped_placement(2025, level = "state") %>%
#'   filter(dimension == "disability",
#'          environment == "gen_ed_80_plus") %>%
#'   select(subgroup, count, percent) %>%
#'   arrange(desc(percent))
#'
#' # 4. Preschool placement (statewide, by environment)
#' fetch_sped_placement(2025, age_group = "3-5", level = "state")
#' }
fetch_sped_placement <- function(end_year,
                                 age_group = "5-21",
                                 level = "district",
                                 tidy = TRUE) {
  raw <- get_raw_sped_placement(
    end_year = end_year,
    age_group = age_group,
    level = level
  )

  if (!tidy) {
    return(raw)
  }

  if (level == "district" && age_group == "5-21") {
    tidy_sped_placement_district_5_21(raw)
  } else if (level == "district" && age_group == "3-5") {
    tidy_sped_placement_district_3_5(raw)
  } else if (level == "state") {
    tidy_sped_placement_state(raw, age_group = age_group)
  } else {
    stop(
      "Unsupported (age_group, level) combination.",
      call. = FALSE
    )
  }
}


#' Fetch NJ SPED placement data for multiple years
#'
#' Convenience wrapper that calls \code{\link{fetch_sped_placement}} for each
#' year and binds the results. Skips years that fail with a warning.
#'
#' Currently only end_year 2025 is supported; this wrapper is provided so
#' downstream code can pre-write multi-year pipelines and pick up additional
#' years transparently as they're added.
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
#' # Pull every supported year (currently just 2025)
#' placement_all <- fetch_sped_placement_multi(2025)
#'
#' # As more years come online, just widen the range:
#' # placement_all <- fetch_sped_placement_multi(2020:2025)
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
