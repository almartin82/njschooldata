# ==============================================================================
# Graduation Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading graduation data from the
# NJ Department of Education website.
#
# ==============================================================================

#' Get a raw graduation file from the NJ website
#'
#' @param end_year End of the academic year - eg 2006-07 is 2007.
#' Valid values are 1998-2025.
#' @param methodology One of c('4 year', '5 year')
#' @return data.frame with raw data from state file
#' @keywords internal
get_raw_grad_file <- function(end_year, methodology = "4 year") {
  source_result_data(get_raw_grad_file_result(end_year, methodology))
}

#' Retrieve and parse a graduation artifact with source provenance
#'
#' @param end_year School-year end year.
#' @param methodology One of `"4 year"` or `"5 year"`.
#' @param request_fn Injectable transport request function.
#' @return An `njsd_source_result`.
#' @keywords internal
get_raw_grad_file_result <- function(end_year, methodology = "4 year",
                                     request_fn = .default_source_request) {
  methodology <- match.arg(methodology, c("4 year", "5 year"))
  valid <- if (methodology == "4 year") {
    get_source_years("grad_count", capability = "raw")
  } else {
    get_source_years("grate_5yr", capability = "raw")
  }
  if (!end_year %in% valid) {
    stop("No registered ", methodology, " graduation source for end_year ",
         end_year, ".", call. = FALSE)
  }
  descriptor <- .graduation_source_descriptor(end_year, methodology)
  transport <- download_source(
    descriptor$url,
    source_type = descriptor$source_type,
    request_fn = request_fn
  )
  if (!identical(transport$source_status, "actual")) return(transport)
  on.exit(unlink(transport$data), add = TRUE)

  parsed <- tryCatch({
    source_path <- transport$data
    unpack_dir <- NULL
    if (descriptor$source_type == "zip") {
      unpack_dir <- tempfile("graduation-unpack-")
      dir.create(unpack_dir)
      on.exit(unlink(unpack_dir, recursive = TRUE), add = TRUE)
      listing <- utils::unzip(source_path, list = TRUE)
      members <- listing$Name[grepl("[.](csv|xlsx?|xls)$", listing$Name,
                                    ignore.case = TRUE)]
      if (!length(members)) {
        stop("Graduation archive contains no CSV or Excel data file.",
             call. = FALSE)
      }
      utils::unzip(source_path, files = members[1], exdir = unpack_dir)
      source_path <- file.path(unpack_dir, members[1])
    }

    extension <- tolower(tools::file_ext(source_path))
    data <- if (extension == "csv") {
      readr::read_csv(source_path, show_col_types = FALSE)
    } else {
      readxl::read_excel(source_path, skip = descriptor$skip)
    }
    if (methodology == "4 year" && end_year == 2011) {
      data <- data[, c(1:7, 9)] %>%
        dplyr::mutate(GRADUATED_COUNT = NA_integer_)
    }
    data$end_year <- end_year
    data
  }, error = identity)

  if (inherits(parsed, "error")) {
    return(new_source_result(
      source_status = "parse_error",
      source_url = transport$source_url,
      retrieved_at = transport$retrieved_at,
      digest = transport$digest,
      error = conditionMessage(parsed)
    ))
  }
  new_source_result(
    data = parsed,
    source_status = "actual",
    source_url = transport$source_url,
    retrieved_at = transport$retrieved_at,
    digest = transport$digest
  )
}

#' Get NJ graduation count data
#'
#' @param end_year End of the academic year - eg 2006-07 is 2007.
#' Valid values are 2012-2025.
#' @return dataframe with the number of graduates per school and district
#' @keywords internal
get_grad_count <- function(end_year) {
  if (end_year < 2012 | end_year > 2025) {
    stop(paste0(end_year, " not yet supported. Valid years are 2012-2025."))
  }

  source_result <- get_raw_grad_file_result(end_year)
  df <- source_result_data(source_result)

  df <- df %>%
    process_grate(end_year)
  attach_source_results(
    df, source_result_record(source_result, "grad_count", end_year, "4-year")
  )
}


#' Get NJ graduation rate data
#'
#' @param end_year End of the academic year - 2011-2012 is 2012.
#' Valid values are 2011-2025.
#' @param methodology Character string specifying calculation methodology.
#' One of "4 year" or "5 year".
#' @return dataframe with the number of graduates per school and district
#' @keywords internal
get_grad_rate <- function(end_year, methodology) {
  if (end_year < 2011 | end_year > 2025) {
    stop("year not yet supported. Valid years are 2011-2025.")
  }

  source_result <- get_raw_grad_file_result(end_year, methodology)
  df <- source_result_data(source_result) %>%
    dplyr::mutate("methodology" = methodology)

  df <- df %>%
    process_grate(end_year)
  attach_source_results(
    df,
    source_result_record(
      source_result, "graduation_rate", end_year, methodology
    )
  )
}


#' Fetch Grad Counts
#'
#' Downloads and processes graduation count data.
#'
#' @param end_year End of the academic year - eg 2006-07 is 2007.
#' Valid values are 2012-2025.
#' @return dataframe with grad counts
#' @export
#' @examples
#' \dontrun{
#' # Get 2023 graduation counts
#' gcount_2023 <- fetch_grad_count(2023)
#' }
fetch_grad_count <- function(end_year) {
  df <- get_grad_count(end_year)
  source_records <- get_source_results(df)
  df <- df %>%
    process_grad_count(end_year)

  df <- tidy_grad_count(df, end_year)

  df <- id_grad_aggs(df)

  possible_cols <- c(
    "end_year",
    "county_id", "county_name",
    "district_id", "district_name",
    "school_id", "school_name",
    "subgroup",
    "cohort_count", "graduated_count",
    "is_state",
    "is_county",
    "is_district",
    "is_charter_sector",
    "is_allpublic",
    "is_school",
    "is_charter"
  )

  df <- df %>%
    dplyr::select(dplyr::one_of(possible_cols))

  attach_source_results(df, source_records)
}


#' Fetch Grad Rate
#'
#' Downloads and processes graduation rate data.
#'
#' @param end_year End of the academic year - eg 2006-07 is 2007.
#' Valid values are 2011-2025.
#' @param methodology Character string specifying calculation methodology.
#' One of "4 year" or "5 year".
#' @return dataframe with grad rate
#' @export
#' @examples
#' \dontrun{
#' # Get 2023 graduation rates
#' grate_2023 <- fetch_grad_rate(2023)
#'
#' # Get 5-year graduation rates
#' grate_5yr <- fetch_grad_rate(2019, methodology = "5 year")
#' }
fetch_grad_rate <- function(end_year, methodology = "4 year") {
  df <- get_grad_rate(end_year, methodology)
  source_records <- get_source_results(df)
  df <- df %>%
    process_grad_rate(end_year, methodology)

  df <- tidy_grad_rate(df, end_year, methodology)

  df <- id_grad_aggs(df)

  df <- df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subgroup,
      grad_rate,
      dplyr::one_of("four_yr_grad_rate", "five_yr_grad_rate"),
      cohort_count, graduated_count,
      methodology,
      is_state,
      is_county,
      is_district,
      is_school,
      is_charter,
      is_charter_sector,
      is_allpublic
    )

  attach_source_results(df, source_records)
}


# -----------------------------------------------------------------------------
# 6-Year Graduation Rate Functions (from School Performance Reports database)
# -----------------------------------------------------------------------------

#' Get SPR database URL for 6-year graduation rates
#'
#' Builds the URL for the School Performance Reports database containing
#' 6-year graduation cohort profile data.
#'
#' @param end_year A school year (2021-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". Determines which database file
#'   to download.
#' @return URL string
#' @keywords internal
get_spr_6yr_grad_url <- function(end_year, level = "school") {
  if (!end_year %in% get_source_years("grate_6yr")) {
    stop(paste0(
      "6-year graduation rate data is available for years: ",
      paste(get_source_years("grate_6yr"), collapse = ", "),
      ". Earlier years do not include 6-year graduation cohort profiles."
    ))
  }
  level <- match.arg(level, c("school", "district"))
  resolve_source_url("grate_6yr", end_year = end_year, level = level)
}


#' Clean 6-year graduation subgroup names
#'
#' Standardizes subgroup names from the SPR 6-year graduation data to match
#' the naming conventions used elsewhere in the package.
#'
#' @param group Vector of subgroup names
#' @return Vector of cleaned subgroup names
#' @keywords internal
clean_6yr_grad_subgroups <- function(group) {
  dplyr::case_when(
    # 2024-25 SPR uses "All Students" for the total row; earlier years used
    # "Schoolwide"/"Districtwide"
    tolower(group) %in% c("schoolwide", "districtwide", "all students") ~ "total population",
    tolower(group) == "american indian or alaska native" ~ "american indian",
    tolower(group) == "black or african american" ~ "black",
    tolower(group) == "economically disadvantaged students" ~ "economically disadvantaged",
    tolower(group) %in% c("english learners", "multilingual learners") ~ "limited english proficiency",
    tolower(group) %in% c("two or more races") ~ "multiracial",
    # 2024-25 SPR renamed "Hispanic" -> "Hispanic/Latino"
    tolower(group) %in% c("hispanic", "hispanic/latino") ~ "hispanic",
    tolower(group) == "native hawaiian or pacific islander" ~ "pacific islander",
    tolower(group) == "asian, native hawaiian, or pacific islander" ~ "asian",
    tolower(group) == "students with disabilities" ~ "students with disabilities",
    TRUE ~ tolower(group)
  )
}


#' Fetch 6-Year Graduation Rate data
#'
#' Downloads and processes 6-year graduation rate data from the NJ School
#' Performance Reports database. This data shows the percentage of students
#' who graduated within six years of entering high school.
#'
#' The 6-year graduation data is from a different source than the 4-year and
#' 5-year data (SPR database vs ACGR files), which is why it has its own
#' fetch function rather than being an option in \code{fetch_grad_rate()}.
#'
#' @param end_year A school year. Year is the end of the academic year - eg
#'   2020-21 school year is end_year '2021'. Valid values are 2021-2025.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#' @return dataframe with 6-year graduation rates including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item subgroup - student group (total population, racial/ethnic groups, etc.)
#'     \item grad_rate_6yr - 6-year graduation rate (0-100 scale)
#'     \item continuing_rate - percentage of students still enrolled after 6 years
#'     \item non_continuing_rate - percentage who dropped out or left
#'     \item persistence_rate - graduates + continuing students (high school persistence)
#'     \item Aggregation flags (is_state, is_district, is_school, is_charter)
#'   }
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 school-level 6-year graduation rates
#' grad6_2024 <- fetch_6yr_grad_rate(2024)
#'
#' # Get district-level 6-year graduation rates
#' grad6_dist <- fetch_6yr_grad_rate(2024, level = "district")
#' }
fetch_6yr_grad_rate <- function(end_year, level = "school") {
  get_spr_6yr_grad_url(end_year, level)
  source_result <- spr_cached_workbook_result(end_year, level)
  tname <- source_result_data(source_result)

  parsed <- tryCatch({

  if (end_year >= 2025) {
    # SY2024-25 restructured the SPR database: the 6-year cohort profile moved
    # from the "6YrGraduationCohortProfile" sheet to the combined
    # "GraduationCohortProfile" sheet (which now holds 4/5/6-year cohorts and
    # requires filtering CohortType == "6-Year"). Headers moved to row 4
    # (skip = 3), rate columns gained _School/_District/_State suffixes, and
    # rate values are now percent strings (e.g. "81.6%").
    suppressers <- c(
      "*", "N", "NA", "", "-", "n/a",
      "Fewer than 10 students in the cohort.",
      "Fewer than 10 graduates."
    )
    df <- readxl::read_excel(
      path = tname,
      sheet = "GraduationCohortProfile",
      skip = 3,
      na = suppressers,
      guess_max = 30000
    )

    df <- df %>%
      dplyr::filter(.data$CohortType == "6-Year")

    if (level == "school") {
      df <- df %>%
        dplyr::rename(
          county_id = CountyCode,
          county_name = CountyName,
          district_id = DistrictCode,
          district_name = DistrictName,
          school_id = SchoolCode,
          school_name = SchoolName,
          subgroup = StudentGroup,
          grad_rate_6yr = Graduated_School,
          continuing_rate = Continuing_School,
          non_continuing_rate = NonContinuing_School,
          persistence_rate = Persisting_School
        ) %>%
        dplyr::select(
          county_id, county_name,
          district_id, district_name,
          school_id, school_name,
          subgroup,
          grad_rate_6yr, continuing_rate, non_continuing_rate, persistence_rate
        )
    } else {
      # District file has no SchoolCode/SchoolName. Real district rows carry
      # their rate in the _District columns; the statewide aggregate row leaves
      # _District blank and only populates _State. The _State columns are
      # repeated on every district row as a reference, so we pull from them ONLY
      # for the statewide row -- using them as a general fallback would fabricate
      # the statewide value onto suppressed districts (whose _District is NA).
      df <- df %>%
        dplyr::rename(
          county_id = CountyCode,
          county_name = CountyName,
          district_id = DistrictCode,
          district_name = DistrictName,
          subgroup = StudentGroup
        ) %>%
        dplyr::mutate(
          .is_state_row = !is.na(county_id) & county_id == "State",
          grad_rate_6yr = dplyr::if_else(.is_state_row, Graduated_State, Graduated_District),
          continuing_rate = dplyr::if_else(.is_state_row, Continuing_State, Continuing_District),
          non_continuing_rate = dplyr::if_else(.is_state_row, NonContinuing_State, NonContinuing_District),
          persistence_rate = dplyr::if_else(.is_state_row, Persisting_State, Persisting_District),
          # "999" fills the missing school_id column on this NJDOE-published
          # district-level file with NJDOE's own district-total CDS code (see
          # DISTRICT_TOTAL_SCHOOL_ID citation in R/config_constants.R); the
          # row itself is a real published district record, not a computed rollup.
          # ID-SOURCE: NJDOE SCHOOL / "SCH CODE" / "School Code" field - "999" is NJDOE's own published district-total school code, printed with that label in STAT_ENR.CSV ("999-DISTRICT TOTAL", 8,909 rows), STAT_GRD.CSV grd06/grd09 ("999-STATE TOTAL"), grd10 grd.xls (SCH NAME "DISTRICT TOTAL"/"STATE TOTAL", 2,365 rows) and every ACGR / Cohort file 2011-2025 (same basis as DISTRICT_TOTAL_SCHOOL_ID, R/config_constants.R); corroborated by the Newark CDS->NCES crosswalk anchor in tests/testthat/test-id-preservation.R. This line fills a school_id column absent from this NJDOE-published SPR district-level 6-year cohort workbook, on a row that IS an NJDOE-published district record, not a computed rollup.
          school_id = "999",
          school_name = "District Total"
        ) %>%
        dplyr::select(
          county_id, county_name,
          district_id, district_name,
          school_id, school_name,
          subgroup,
          grad_rate_6yr, continuing_rate, non_continuing_rate, persistence_rate
        )
    }

    # Strip the trailing "%" from percent strings before numeric coercion.
    rate_cols <- c("grad_rate_6yr", "continuing_rate", "non_continuing_rate", "persistence_rate")
    for (col in rate_cols) {
      df[[col]] <- gsub("%", "", as.character(df[[col]]), fixed = TRUE)
    }
  } else {
    # 2017-2024: legacy "6YrGraduationCohortProfile" sheet, headers on row 1,
    # numeric rate columns named Graduates / Continuing Students /
    # Non-Continuing Student (+ HighSchoolPersistance from 2024).
    df <- readxl::read_excel(
      path = tname,
      sheet = "6YrGraduationCohortProfile",
      na = c("*", "N", "NA", "", "-"),
      guess_max = 10000
    )

    # Check if HighSchoolPersistance column exists (added in 2024)
    has_persistence <- "HighSchoolPersistance" %in% names(df) |
      "StateHighSchoolPersistance" %in% names(df)

    # Standardize column names based on level
    if (level == "school") {
      df <- df %>%
        dplyr::rename(
          county_id = CountyCode,
          county_name = CountyName,
          district_id = DistrictCode,
          district_name = DistrictName,
          school_id = SchoolCode,
          school_name = SchoolName,
          subgroup = StudentGroup,
          grad_rate_6yr = Graduates,
          continuing_rate = `Continuing Students`,
          non_continuing_rate = `Non-Continuing Student`
        )

      # Add persistence_rate if available, otherwise calculate or set NA
      if (has_persistence) {
        df <- df %>% dplyr::rename(persistence_rate = HighSchoolPersistance)
      } else {
        # Calculate persistence = graduates + continuing (not available in early years)
        df <- df %>% dplyr::mutate(persistence_rate = NA_real_)
      }

      df <- df %>%
        dplyr::select(
          county_id, county_name,
          district_id, district_name,
          school_id, school_name,
          subgroup,
          grad_rate_6yr, continuing_rate, non_continuing_rate, persistence_rate
        )
    } else {
      # District/state file: no SchoolCode/SchoolName. The statewide aggregate
      # row (CountyCode == "State") leaves the base rate columns blank and stores
      # its values in parallel "State: <col>" columns -- but those "State:"
      # columns are repeated on *every* district row as a reference, so we pull
      # from them ONLY for the statewide row. Filling NA base values for ordinary
      # (suppressed) districts from the "State:" columns would fabricate data.
      is_state_row <- !is.na(df$CountyCode) & df$CountyCode == "State"
      fill_state <- function(base_col, state_col) {
        base <- df[[base_col]]
        if (state_col %in% names(df)) {
          dplyr::if_else(is_state_row, df[[state_col]], base)
        } else {
          base
        }
      }

      df <- df %>%
        dplyr::mutate(
          grad_rate_6yr = fill_state("Graduates", "State: Graduates"),
          continuing_rate = fill_state("Continuing Students", "State: Continuing Students"),
          non_continuing_rate = fill_state("Non-Continuing Student", "State: Non-Continuing Student"),
          persistence_rate = if (has_persistence) {
            fill_state("HighSchoolPersistance", "State: HighSchoolPersistance")
          } else {
            NA_real_
          },
          # "999" fills the missing school_id column on this NJDOE-published
          # district-level file with NJDOE's own district-total CDS code (see
          # DISTRICT_TOTAL_SCHOOL_ID citation in R/config_constants.R); the
          # row itself is a real published district record, not a computed rollup.
          # ID-SOURCE: NJDOE SCHOOL / "SCH CODE" / "School Code" field - "999" is NJDOE's own published district-total school code, printed with that label in STAT_ENR.CSV ("999-DISTRICT TOTAL", 8,909 rows), STAT_GRD.CSV grd06/grd09 ("999-STATE TOTAL"), grd10 grd.xls (SCH NAME "DISTRICT TOTAL"/"STATE TOTAL", 2,365 rows) and every ACGR / Cohort file 2011-2025 (same basis as DISTRICT_TOTAL_SCHOOL_ID, R/config_constants.R); corroborated by the Newark CDS->NCES crosswalk anchor in tests/testthat/test-id-preservation.R. This line fills a school_id column absent from this NJDOE-published SPR district-level 6-year cohort workbook, on a row that IS an NJDOE-published district record, not a computed rollup.
          school_id = "999",
          school_name = "District Total"
        ) %>%
        dplyr::rename(
          county_id = CountyCode,
          county_name = CountyName,
          district_id = DistrictCode,
          district_name = DistrictName,
          subgroup = StudentGroup
        ) %>%
        dplyr::select(
          county_id, county_name,
          district_id, district_name,
          school_id, school_name,
          subgroup,
          grad_rate_6yr, continuing_rate, non_continuing_rate, persistence_rate
        )
    }
  }

  # Convert rate columns to numeric
  rate_cols <- c("grad_rate_6yr", "continuing_rate", "non_continuing_rate", "persistence_rate")
  for (col in rate_cols) {
    df[[col]] <- as.numeric(df[[col]])
  }

  # Clean subgroup names
  df$subgroup <- clean_6yr_grad_subgroups(df$subgroup)

  # Add metadata
  df$end_year <- end_year
  df$methodology <- "6 year"

  # Remove rows without county_id
  df <- df %>%
    dplyr::filter(!is.na(county_id))

  # Every year's SPR cohort profile -- the legacy "6YrGraduationCohortProfile"
  # (2017-2024) and the 2024-25 "GraduationCohortProfile" -- puts the literal
  # string "State" in the CountyCode/DistrictCode of the statewide aggregate row
  # rather than the numeric 99/9999 codes used elsewhere. Normalize so the
  # aggregation flags below classify the statewide row as is_state (it was
  # silently FALSE for 2017-2024 before this).
  # ID-SOURCE: NJDOE graduation files, COUNTY_ID / DISTRICT_ID fields. "99" and
  #   "9999" are NJDOE's own published statewide county and district codes,
  #   printed with their own labels in every graduation vintage checked: legacy
  #   STAT_GRD.CSV grd06 and grd09 publish "99-NEW JERSEY","9999-NEW JERSEY" on
  #   the statewide row (10 rows each); grd10 grd.xls publishes CO CODE "99" /
  #   DIST CODE "9999" with names "NEW JERSEY"/"STATE TOTAL" (10 rows); and the
  #   ACGR / Cohort series 2011-2025 publishes COUNTY_ID "99" ("STATE") with
  #   DISTRICT_ID "9999" ("STATE TOTAL") on 11-17 rows per file.
  # LIMITATION: the SPR cohort-profile sheet this function reads does NOT print
  #   those codes -- verified in Database_DistrictStateDetail.xlsx SY2023-24,
  #   whose 6YrGraduationCohortProfile sheet has CountyCode == DistrictCode ==
  #   "State" on all 17 statewide rows and no numeric code anywhere. So the
  #   codes are certified from NJDOE's other graduation publications, not from
  #   this workbook; they are the same agency's same CDS scheme for the same
  #   measure, which is why the substitution is a normalization and not an
  #   invention.
  df <- df %>%
    dplyr::mutate(
      # ID-SOURCE: NJDOE graduation files, DISTRICT_ID / "DIST CODE" field --
      #   "9999" is NJDOE's published statewide district code (see the evidence
      #   block above this mutate).
      district_id = dplyr::if_else(district_id == "State", "9999", district_id),
      # ID-SOURCE: NJDOE graduation files, COUNTY_ID / "CO CODE" field -- "99"
      #   is NJDOE's published statewide county code (see the evidence block
      #   above this mutate).
      county_id = dplyr::if_else(county_id == "State", "99", county_id)
    )

  # Add aggregation flags
  df <- df %>%
    dplyr::mutate(
      is_state = district_id == "9999" & county_id == "99",
      is_county = district_id == "9999" & !county_id == "99",
      is_district = school_id %in% c("888", "997", "999") & !is_state,
      is_charter_sector = FALSE,
      is_allpublic = FALSE,
      is_school = !school_id %in% c("888", "997", "999") & !is_state,
      is_charter = county_id == "80"
    )

  # Reorder columns
    df %>%
      dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subgroup,
      grad_rate_6yr, continuing_rate, non_continuing_rate, persistence_rate,
      methodology,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
  }, error = identity)

  if (inherits(parsed, "error")) {
    parse_result <- new_source_result(
      source_status = "parse_error",
      source_url = source_result$source_url,
      retrieved_at = source_result$retrieved_at,
      digest = source_result$digest,
      error = conditionMessage(parsed)
    )
    source_result_data(parse_result)
  }
  attach_source_results(
    parsed,
    source_result_record(
      source_result, "grate_6yr", end_year, level
    )
  )
}


#' Fetch all 6-Year Graduation Rate data
#'
#' Convenience function to download and combine all available 6-year
#' graduation rate data into a single data frame.
#'
#' @param level One of "school", "district", or "both". "both" combines
#'   school and district data. Default is "school".
#' @param allow_partial If `FALSE` (default), any failed year/level aborts the
#'   request. If `TRUE`, successful requests are returned with status available
#'   from [get_source_results()].
#' @return A data frame with all 6-year graduation rate results (2021-2025)
#' @export
#' @examples
#' \dontrun{
#' # Get all school-level 6-year graduation data
#' all_grad6 <- fetch_all_6yr_grad_rate()
#'
#' # Get both school and district data
#' all_grad6_both <- fetch_all_6yr_grad_rate(level = "both")
#' }
fetch_all_6yr_grad_rate <- function(level = "school", allow_partial = FALSE) {
  levels <- if (identical(level, "both")) {
    c("school", "district")
  } else {
    match.arg(level, c("school", "district"))
  }
  requests <- expand.grid(
    end_year = get_source_years("grate_6yr"),
    level = levels,
    stringsAsFactors = FALSE
  )
  captures <- lapply(seq_len(nrow(requests)), function(index) {
    request <- requests[index, ]
    capture_source_call(
      function() fetch_6yr_grad_rate(request$end_year, request$level),
      domain = "grate_6yr", end_year = request$end_year,
      component = request$level
    )
  })
  combine_source_captures(
    captures, allow_partial = allow_partial,
    context = "Six-year graduation multi-source request"
  )
}
