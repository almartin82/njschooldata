# ==============================================================================
# Authoritative NJ DOE source registry
# ==============================================================================

.njsd_source_registry <- list(
  enrollment = list(
    aliases = c("enrollment", "enr"),
    raw_years = 1999:2026,
    tidy_years = 1999:2026,
    skipped_years = integer(),
    source_type = "zip",
    hosts = "www.nj.gov",
    resolver = "enrollment"
  ),
  parcc = list(
    aliases = c("parcc", "njsla"),
    raw_years = c(2015:2019, 2022:2025),
    tidy_years = c(2015:2019, 2022:2025),
    skipped_years = c(2020L, 2021L),
    skipped_reasons = c(
      `2020` = "Assessments were cancelled due to COVID-19.",
      `2021` = "New Jersey administered Start Strong rather than PARCC/NJSLA."
    ),
    source_type = "xlsx",
    hosts = "www.nj.gov",
    resolver = "parcc"
  ),
  njgpa = list(
    aliases = "njgpa",
    raw_years = 2022:2025,
    tidy_years = 2022:2025,
    skipped_years = integer(),
    source_type = "xlsx",
    hosts = "www.nj.gov",
    resolver = "njgpa"
  ),
  access = list(
    aliases = c("access", "wida_access"),
    raw_years = 2022:2025,
    tidy_years = 2022:2025,
    skipped_years = integer(),
    source_type = "xlsx",
    hosts = "www.nj.gov",
    resolver = "access"
  ),
  grate_4yr = list(
    aliases = c("grate_4yr", "grad_rate", "graduation_rate"),
    raw_years = 2011:2025,
    tidy_years = 2011:2025,
    skipped_years = integer(),
    source_type = c("zip", "xls", "xlsx"),
    hosts = c("www.nj.gov", "www.state.nj.us"),
    resolver = "grate_4yr"
  ),
  grate_5yr = list(
    aliases = "grate_5yr",
    raw_years = 2012:2019,
    tidy_years = 2012:2019,
    skipped_years = integer(),
    source_type = "xlsx",
    hosts = "www.nj.gov",
    resolver = "grate_5yr"
  ),
  grate_6yr = list(
    aliases = c("grate_6yr", "six_year_graduation_rate"),
    raw_years = 2021:2025,
    tidy_years = 2021:2025,
    skipped_years = integer(),
    source_type = "xlsx",
    hosts = "www.nj.gov",
    resolver = "spr"
  ),
  grad_count = list(
    aliases = c("grad_count", "gcount"),
    raw_years = 1998:2025,
    tidy_years = 2012:2025,
    skipped_years = integer(),
    source_type = c("zip", "xls", "xlsx"),
    hosts = c("www.nj.gov", "www.state.nj.us"),
    resolver = "grad_count"
  ),
  njask = list(
    aliases = c("njask", "legacy_assess"),
    raw_years = 2004:2014,
    tidy_years = 2004:2014,
    skipped_years = integer(),
    source_type = "text",
    hosts = c("www.nj.gov", "www.state.nj.us", "web.archive.org"),
    resolver = NA_character_,
    historical_note = paste0(
      "The 2004 source uses an HTTPS Wayback request whose embedded original ",
      "NJ DOE URL is plaintext HTTP; no direct plaintext request is made."
    )
  ),
  hspa = list(
    aliases = "hspa",
    raw_years = 2004:2014,
    tidy_years = 2004:2014,
    skipped_years = integer(),
    source_type = "text",
    hosts = c("www.nj.gov", "www.state.nj.us", "web.archive.org"),
    resolver = NA_character_,
    historical_note = paste0(
      "The 2004 source uses an HTTPS Wayback request whose embedded original ",
      "NJ DOE URL is plaintext HTTP; no direct plaintext request is made."
    )
  ),
  gepa = list(
    aliases = "gepa",
    raw_years = 2004:2007,
    tidy_years = 2004:2007,
    skipped_years = integer(),
    source_type = "text",
    hosts = c("www.nj.gov", "www.state.nj.us", "web.archive.org"),
    resolver = NA_character_,
    historical_note = paste0(
      "The 2004 source uses an HTTPS Wayback request whose embedded original ",
      "NJ DOE URL is plaintext HTTP; no direct plaintext request is made."
    )
  ),
  sped = list(
    aliases = c("sped", "sped_classification"),
    raw_years = 2015:2025,
    tidy_years = 2015:2025,
    skipped_years = integer(),
    source_type = c("zip", "xlsx"),
    hosts = "www.nj.gov",
    resolver = NA_character_
  ),
  sped_placement = list(
    aliases = c("sped_placement", "educational_environment"),
    raw_years = 2020:2025,
    tidy_years = 2020:2025,
    skipped_years = integer(),
    source_type = c("zip", "xlsx", "csv"),
    hosts = "www.nj.gov",
    resolver = NA_character_
  ),
  tges = list(
    aliases = c("tges", "csg"),
    raw_years = 2001:2025,
    tidy_years = 2001:2025,
    skipped_years = integer(),
    source_type = "zip",
    hosts = "www.nj.gov",
    resolver = "tges"
  ),
  state_aid = list(
    aliases = c("state_aid", "aid"),
    raw_years = 2019:2027,
    tidy_years = 2019:2027,
    skipped_years = integer(),
    source_type = c("xlsx", "zip"),
    hosts = "www.nj.gov",
    resolver = "state_aid"
  ),
  finance = list(
    aliases = "finance",
    raw_years = 2001:2026,
    tidy_years = 2001:2026,
    skipped_years = integer(),
    source_type = c("zip", "xlsx"),
    hosts = "www.nj.gov",
    resolver = NA_character_
  ),
  dfg = list(
    aliases = c("dfg", "district_factor_group"),
    raw_years = c(1990L, 2000L),
    tidy_years = c(1990L, 2000L),
    skipped_years = integer(),
    source_type = "xlsx",
    hosts = "www.nj.gov",
    resolver = "dfg"
  ),
  ell = list(
    aliases = c("ell", "el"),
    raw_years = 2006:2026,
    tidy_years = 2006:2026,
    skipped_years = integer(),
    source_type = "zip",
    hosts = "www.nj.gov",
    resolver = "enrollment"
  ),
  report_card = list(
    aliases = "report_card",
    raw_years = 2012:2019,
    tidy_years = 2012:2019,
    skipped_years = 2003:2011,
    skipped_reasons = stats::setNames(
      rep(
        paste0(
          "NJ DOE removed the 2003-2011 report-card database files and no ",
          "verified public archive is currently configured."
        ),
        9L
      ),
      2003:2011
    ),
    source_type = "xlsx",
    hosts = "www.nj.gov",
    resolver = "report_card"
  ),
  msgp = list(
    aliases = "msgp",
    raw_years = 2012:2019,
    tidy_years = 2012:2019,
    skipped_years = integer(),
    source_type = c("zip", "xlsx"),
    hosts = "www.nj.gov",
    resolver = "report_card"
  ),
  special_pop = list(
    aliases = "special_pop",
    raw_years = 2017:2019,
    tidy_years = 2017:2019,
    skipped_years = integer(),
    source_type = "xlsx",
    hosts = "www.nj.gov",
    resolver = "report_card"
  ),
  spr = list(
    aliases = c("spr", "school_performance_reports"),
    raw_years = 2017:2025,
    tidy_years = 2017:2025,
    skipped_years = integer(),
    source_type = "xlsx",
    hosts = "www.nj.gov",
    resolver = "spr"
  ),
  absence = list(
    aliases = c("absence", "chronic_absence"),
    raw_years = c(2017:2019, 2021:2025),
    tidy_years = c(2017:2019, 2021:2025),
    skipped_years = 2020L,
    skipped_reasons = c(
      `2020` = "Chronic absenteeism was not published for the COVID-disrupted year."
    ),
    source_type = "xlsx",
    hosts = "www.nj.gov",
    resolver = "spr"
  ),
  directory = list(
    aliases = c("directory", "school_directory", "district_directory"),
    raw_years = integer(),
    tidy_years = integer(),
    skipped_years = integer(),
    source_type = "csv",
    hosts = "homeroom4.doe.nj.gov",
    resolver = "directory"
  ),
  directory_spr = list(
    aliases = c("directory_spr", "directory_performance_contacts"),
    raw_years = 2025L,
    tidy_years = 2025L,
    skipped_years = integer(),
    source_type = "json",
    hosts = "www.nj.gov",
    resolver = "directory_spr"
  ),
  essa = list(
    aliases = "essa",
    raw_years = 2017L,
    tidy_years = 2017L,
    skipped_years = integer(),
    source_type = "xlsx",
    hosts = "www.nj.gov",
    resolver = "essa"
  ),
  essa_chronic_absence = list(
    aliases = c("essa_chronic_absence", "essa_absence"),
    raw_years = c(2017:2019, 2022:2024),
    tidy_years = c(2017:2019, 2022:2024),
    skipped_years = c(2020L, 2021L),
    skipped_reasons = c(
      `2020` = "Chronic absenteeism was not reported because of COVID-19.",
      `2021` = "Chronic absenteeism was not reported because of COVID-19."
    ),
    source_type = "xlsx",
    hosts = "www.nj.gov",
    resolver = "essa_chronic_absence"
  ),
  facilities = list(
    aliases = c("facilities", "facility"),
    raw_years = integer(),
    tidy_years = integer(),
    skipped_years = integer(),
    source_type = c("xlsx", "json", "html"),
    hosts = c("www.nj.gov", "services2.arcgis.com", "www.njsda.gov"),
    resolver = "facilities",
    sources = list(
      njdoe_cds = list(
        url = "https://www.nj.gov/education/sleds/keydocs/docs/County_District_School_Code_List.xlsx",
        agency = "NJDOE", source_type = "xlsx",
        vintage = "CDS list current as of 2026-06-15"
      ),
      njgin_school_points = list(
        url = paste0(
          "https://services2.arcgis.com/XVOqAjTOJ5P6ngMu/arcgis/rest/services/",
          "School_Point_Locations_of_NJ/FeatureServer/0/query"
        ),
        agency = "NJGIN", source_type = "arcgis",
        vintage = "NJGIN school points modified 2023-05-10"
      ),
      njsda_active_projects = list(
        url = "https://www.njsda.gov/Projects/CapitalProgram",
        agency = "NJSDA", source_type = "html",
        vintage = "NJSDA active capital portfolio, accessed 2026-06-22"
      ),
      njdoe_sda_allocation = list(
        url = "https://www.nj.gov/education/facilities/docs/SDA/DistrictAllocationTable.xlsx",
        agency = "NJDOE", source_type = "xlsx",
        vintage = "FY2026 SDA Emergent/Capital Maintenance allocation"
      ),
      njdoe_lead_soa = list(
        url = "https://www.nj.gov/education/lead/docs/24-25SOA_SubmissionsLeadDW102825.xlsx",
        agency = "NJDOE", source_type = "xlsx",
        vintage = "2024-2025 Lead SOA submissions, file dated 2025-10-28"
      )
    )
  )
)

# Compatibility constants are derived from the registry. They remain internal
# objects because downstream package code historically referenced them.
ENR_VALID_YEARS <- .njsd_source_registry$enrollment$tidy_years
PARCC_VALID_YEARS <- .njsd_source_registry$parcc$tidy_years
GRATE_4YR_VALID_YEARS <- .njsd_source_registry$grate_4yr$tidy_years
GRATE_5YR_VALID_YEARS <- .njsd_source_registry$grate_5yr$tidy_years
GCOUNT_VALID_YEARS <- .njsd_source_registry$grad_count$raw_years
LEGACY_ASSESS_VALID_YEARS <- .njsd_source_registry$njask$tidy_years
ELL_VALID_YEARS <- .njsd_source_registry$ell$tidy_years

#' Return the authoritative NJ DOE source registry
#'
#' @return A named list describing source capabilities and ownership.
#' @keywords internal
get_source_registry <- function() {
  .njsd_source_registry
}

#' Resolve a source family alias
#'
#' @param data_type Registered family name or alias.
#' @return Canonical family name.
#' @keywords internal
resolve_data_family <- function(data_type) {
  if (length(data_type) != 1L || is.na(data_type)) {
    stop("`data_type` must be one registered source family.", call. = FALSE)
  }
  data_type <- tolower(as.character(data_type))
  matches <- names(Filter(
    function(entry) data_type %in% tolower(entry$aliases),
    .njsd_source_registry
  ))
  if (length(matches) != 1L) {
    stop(sprintf("Unknown data type: '%s'", data_type), call. = FALSE)
  }
  matches
}

#' Get raw or tidy source coverage
#'
#' @param data_type Registered family name or alias.
#' @param capability Either `"tidy"` or `"raw"`.
#' @return Integer vector of supported end years.
#' @keywords internal
get_source_years <- function(data_type, capability = c("tidy", "raw")) {
  capability <- match.arg(capability)
  family <- resolve_data_family(data_type)
  as.integer(.njsd_source_registry[[family]][[paste0(capability, "_years")]])
}

#' Get valid years for a data type
#'
#' Coverage comes from the package's authoritative source registry. Raw and
#' tidy support can differ; this compatibility front door reports tidy support.
#'
#' @param data_type Registered family name or alias.
#' @return Integer vector of valid school-year end years.
#' @export
#' @examples
#' get_valid_years("enrollment")
#' get_valid_years("parcc")
get_valid_years <- function(data_type) {
  get_source_years(data_type, capability = "tidy")
}

#' Check whether a year is supported
#'
#' @param end_year School-year end year.
#' @param data_type Registered family name or alias.
#' @param capability Either `"tidy"` or `"raw"`.
#' @return A single logical value.
#' @keywords internal
is_valid_year <- function(end_year, data_type, capability = c("tidy", "raw")) {
  end_year %in% get_source_years(data_type, match.arg(capability))
}

#' Get enrollment years available from the tidy front door
#'
#' @return Integer vector of school-year end years.
#' @export
get_available_years <- function() {
  get_source_years("enrollment")
}

#' Get English Learner population years
#'
#' @return Integer vector of school-year end years.
#' @export
get_available_ell_years <- function() {
  get_source_years("ell")
}

#' Get finance years with at least one registered component
#'
#' @return Integer vector of school-year end years.
#' @export
get_available_finance_years <- function() {
  get_source_years("finance")
}

#' Hosts permitted by registered NJ DOE sources
#'
#' @return Character vector of host names.
#' @keywords internal
source_host_allowlist <- function() {
  sort(unique(unlist(lapply(.njsd_source_registry, `[[`, "hosts"))))
}

.assessment_source_url <- function(end_year, grade, subject) {
  subject <- tolower(subject)
  subject_prefix <- switch(subject,
    ela = "ELA",
    math = "MAT",
    science = "SCI",
    stop("`subject` must be one of: ela, math, science.", call. = FALSE)
  )

  if (is.numeric(grade)) {
    grade_token <- sprintf("%02d", as.integer(grade))
  } else {
    grade_token <- toupper(as.character(grade))
    if (grepl("ALG|GEO", grade_token)) {
      grade_token <- gsub("ALG", "ALG0", grade_token)
      grade_token <- if (end_year == 2019) {
        gsub("^GEO01$", "GEO", grade_token)
      } else {
        gsub("^GEO$", "GEO01", grade_token)
      }
      subject_prefix <- ""
    }
  }

  stem <- "https://www.nj.gov/education/assessment/results/reports/"
  school_year <- paste0(substr(end_year - 1L, 3, 4), substr(end_year, 3, 4))
  if (end_year < 2019) {
    if (end_year == 2017 && is.numeric(grade) && grade >= 10) {
      grade_token <- paste0("0", grade_token)
    }
    if (end_year == 2018 && subject == "ela") {
      grade_token <- paste0("0", grade_token)
    }
    season <- if (end_year >= 2016) "spring/" else "parcc/"
    return(paste0(stem, school_year, "/", season,
                  subject_prefix, grade_token, ".xlsx"))
  }

  year_suffix <- paste0(end_year - 1L, "-", substr(end_year, 3, 4))
  filename <- if (end_year == 2019 || end_year >= 2025) {
    paste0(subject_prefix, grade_token, "%20NJSLA%20DATA%20",
           year_suffix, ".xlsx")
  } else {
    paste0(subject_prefix, grade_token, "_NJSLA_DATA_",
           year_suffix, ".xlsx")
  }
  paste0(stem, school_year, "/spring/", filename)
}

.njgpa_source_url <- function(end_year, subject) {
  prefix <- switch(tolower(subject),
    ela = "ELAGP",
    math = "MATGP",
    stop("NJGPA subject must be 'ela' or 'math'.", call. = FALSE)
  )
  school_year <- paste0(substr(end_year - 1L, 3, 4), substr(end_year, 3, 4))
  suffix <- paste0(end_year - 1L, "-", substr(end_year, 3, 4))
  filename <- if (end_year >= 2025) {
    paste0(prefix, "%20NJGPA%20DATA%20", suffix, ".xlsx")
  } else {
    paste0(prefix, "_NJGPA_DATA_", suffix, ".xlsx")
  }
  folder <- if (end_year == 2022) "spring" else "njgpa"
  paste0("https://www.nj.gov/education/assessment/results/reports/",
         school_year, "/", folder, "/", filename)
}

.tges_source_url <- function(end_year) {
  base <- "https://www.nj.gov/education/guide/docs"
  if (end_year == 2024) return(paste0(base, "/2024/TGES24_Zipped.zip"))
  if (end_year == 2025) return(paste0(base, "/2025/TGES2025_Zipped.zip"))
  suffix <- if (end_year <= 2010) "_CSG.zip" else "_TGES.zip"
  paste0(base, "/", end_year, suffix)
}

.report_card_source_urls <- function(end_year) {
  end_year <- as.integer(end_year)
  standalone <- c(
    `2012` = paste0(
      "https://www.nj.gov/education/spr/download/archive/201112/",
      "nj%20pr12%20database.xlsx"
    ),
    `2013` = paste0(
      "https://www.nj.gov/education/spr/download/archive/201213/",
      "nj%20pr13%20database.xlsx"
    ),
    `2014` = paste0(
      "https://www.nj.gov/education/spr/download/archive/201314/",
      "2014%20performance%20report%20database.xlsx"
    ),
    `2015` = paste0(
      "https://www.nj.gov/education/spr/download/archive/201415/",
      "2015PRDATABASE.xlsx"
    ),
    `2016` = paste0(
      "https://www.nj.gov/education/sprreports/download/DataFiles/2015-2016/",
      "Database_SchoolDetail.xlsx"
    )
  )
  if (end_year <= 2016L) {
    return(c(school = unname(standalone[[as.character(end_year)]])))
  }

  folder <- paste0(end_year - 1L, "-", end_year)
  base <- paste0(
    "https://www.nj.gov/education/sprreports/download/DataFiles/",
    folder, "/"
  )
  c(
    school = paste0(base, "Database_SchoolDetail.xlsx"),
    district = paste0(base, "Database_DistrictStateDetail.xlsx")
  )
}

state_aid_year_code <- function(end_year) {
  end_year <- as.integer(end_year)
  sprintf("%02d%02d", (end_year - 1L) %% 100L, end_year %% 100L)
}

.graduation_source_descriptor <- function(end_year, methodology = "4 year") {
  end_year <- as.integer(end_year)
  methodology <- match.arg(methodology, c("4 year", "5 year"))
  base <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/"

  if (methodology == "4 year" && end_year <= 2010) {
    return(list(
      url = paste0(
        "https://www.state.nj.us/education/data/grd/grd",
        substr(end_year + 1L, 3, 4), "/grd.zip"
      ),
      source_type = "zip", skip = 0L
    ))
  }

  four_year <- list(
    `2011` = c("ACGR2012_gradrate.xls", "xls", "0"),
    `2012` = c("ACGR2012_grd.xls", "xls", "0"),
    `2013` = c("ACGR2013_4Year.xlsx", "xlsx", "0"),
    `2014` = c("ACGR2014_4Year.xlsx", "xlsx", "0"),
    `2015` = c("ACGR2015_4Year.xlsx", "xlsx", "0"),
    `2016` = c("ACGR2016_4Year.xlsx", "xlsx", "0"),
    `2017` = c("ACGR2017_4Year.xlsx", "xlsx", "0"),
    `2018` = c("ACGR2018_4YearGraduation.xlsx", "xlsx", "3"),
    `2019` = c(
      "ACGR2019_Cohort2019_4-YearAdjustedCohortGraduationRatesByStudentGroup.xlsx",
      "xlsx", "3"
    ),
    `2020` = c(
      "Cohort2020_4YearAdjustedCohortGraduationRatesandCountsbyStudentGroup.xlsx",
      "xlsx", "5"
    ),
    `2021` = c(
      "Cohort2021_4YearAdjustedCohortGraduationRatesandCountsbyStudentGroup.xlsx",
      "xlsx", "5"
    ),
    `2022` = c(
      "Cohort2022_4YearAdjustedCohortGraduationRatesandCountsbyStudentGroup.xlsx",
      "xlsx", "5"
    ),
    `2023` = c(
      "Cohort2023_4YearAdjustedCohortGraduationRatesbyStudentGroup.xlsx",
      "xlsx", "5"
    ),
    `2024` = c(
      "Cohort2024_4YearAdjustedCohortGraduationRatesbyStudentGroup.xlsx",
      "xlsx", "5"
    ),
    `2025` = c(
      "Cohort2025_4YearAdjustedCohortGraduationRatesbyStudentGroup.xlsx",
      "xlsx", "5"
    )
  )
  five_year <- list(
    `2012` = c("ACGR2013_4And5YearCohort12.xlsx", "xlsx", "0"),
    `2013` = c("ACGR2014_4And5YearCohort13.xlsx", "xlsx", "0"),
    `2014` = c("ACGR2015_4And5YearCohort14.xlsx", "xlsx", "0"),
    `2015` = c("ACGR2016_4And5YearCohort14.xlsx", "xlsx", "0"),
    `2016` = c("ACGR2017_4And5YearCohort.xlsx", "xlsx", "0"),
    `2017` = c("ACGR2018_4and5YearGraduationRates.xlsx", "xlsx", "3"),
    `2018` = c(
      "ACGR2019_Cohort20184-YearAnd5-YearAdjustedCohortGraduationRates.xlsx",
      "xlsx", "3"
    ),
    `2019` = c(
      "Cohort2019_4-YearAnd5-YearAdjustedCohortGraduationRates.xlsx",
      "xlsx", "3"
    )
  )
  descriptor <- if (methodology == "4 year") {
    four_year[[as.character(end_year)]]
  } else {
    five_year[[as.character(end_year)]]
  }
  if (is.null(descriptor)) {
    stop("No registered ", methodology, " graduation source for end_year ",
         end_year, ".", call. = FALSE)
  }
  list(
    url = paste0(base, descriptor[[1]]),
    source_type = descriptor[[2]],
    skip = as.integer(descriptor[[3]])
  )
}

#' Resolve a registered NJ DOE source URL
#'
#' @param data_type Registered family name or alias.
#' @param end_year School-year end year, where applicable.
#' @param ... Resolver-specific fields such as `grade`, `subject`, or `level`.
#' @return One or more candidate source URLs.
#' @keywords internal
resolve_source_url <- function(data_type, end_year = NULL, ...) {
  family <- resolve_data_family(data_type)
  entry <- .njsd_source_registry[[family]]
  args <- list(...)

  if (length(entry$raw_years) && !is.null(end_year) &&
      !as.integer(end_year) %in% entry$raw_years) {
    stop("No registered ", family, " source for end_year ", end_year, ".",
         call. = FALSE)
  }

  switch(entry$resolver,
    enrollment = {
      yy <- substr(end_year, 3, 4)
      prev_yy <- substr(end_year - 1L, 3, 4)
      base <- paste0("https://www.nj.gov/education/doedata/enr/enr", yy, "/")
      paste0(base, c("enrollment_", "Enrollment_"), prev_yy, yy, ".zip")
    },
    parcc = .assessment_source_url(
      as.integer(end_year), args$grade, args$subject
    ),
    njgpa = .njgpa_source_url(as.integer(end_year), args$subject),
    access = {
      sy_start <- substr(end_year - 1L, 3, 4)
      sy_end <- substr(end_year, 3, 4)
      directory <- if (end_year >= 2023) "access" else "dlm"
      paste0(
        "https://www.nj.gov/education/assessment/results/reports/",
        sy_start, sy_end, "/", directory, "/ACCESS_ELLS_DataFile_",
        end_year - 1L, "-", sy_end, ".xlsx"
      )
    },
    spr = {
      level <- match.arg(args$level %||% "school", c("school", "district"))
      filename <- if (level == "school") {
        "Database_SchoolDetail.xlsx"
      } else {
        "Database_DistrictStateDetail.xlsx"
      }
      paste0(
        "https://www.nj.gov/education/sprreports/download/DataFiles/",
        end_year - 1L, "-", end_year, "/", filename
      )
    },
    tges = .tges_source_url(as.integer(end_year)),
    state_aid = {
      code <- state_aid_year_code(end_year)
      base <- "https://www.nj.gov/education/stateaid"
      c(
        direct = sprintf(
          "%s/%s/FY%02d_GBM_District_Details.xlsx",
          base, code, as.integer(end_year) %% 100L
        ),
        archive = sprintf("%s/zippedfiles/%s.zip", base, code)
      )
    },
    dfg = {
      revision <- as.integer(args$revision %||% 2000L)
      if (!revision %in% entry$raw_years) {
        stop("DFG revision must be one of: 1990, 2000.", call. = FALSE)
      }
      "https://www.nj.gov/education/stateaid/docs/DFG2000.xlsx"
    },
    report_card = {
      urls <- .report_card_source_urls(as.integer(end_year))
      level <- args$level
      if (is.null(level)) urls else {
        level <- match.arg(level, names(urls))
        unname(urls[[level]])
      }
    },
    grate_4yr = .graduation_source_descriptor(
      as.integer(end_year), "4 year"
    )$url,
    grate_5yr = .graduation_source_descriptor(
      as.integer(end_year), "5 year"
    )$url,
    grad_count = .graduation_source_descriptor(
      as.integer(end_year), "4 year"
    )$url,
    directory = {
      level <- match.arg(args$level %||% "school", c("school", "district"))
      if (level == "school") get_school_directory_url() else get_district_directory_url()
    },
    directory_spr = get_directory_spr_url(),
    essa = {
      file_type <- match.arg(args$file_type, c("comprehensive", "targeted"))
      filename <- if (file_type == "comprehensive") {
        "public_comprehensivefile.xlsx"
      } else {
        "public_targetfile.xlsx"
      }
      paste0(
        "https://www.nj.gov/education/title1/accountability/progress/17/",
        filename
      )
    },
    essa_chronic_absence = {
      urls <- c(
        `2024` = paste0(
          "https://www.nj.gov/education/title1/accountability/docs/2024/",
          "2023_24_Accountability_Workbook_File_Comprehensive_Support_and_Improvement.xlsx"
        ),
        `2023` = paste0(
          "https://www.nj.gov/education/title1/accountability/docs/2024/",
          "2022_2023_Accountability_Workbook_File_Comprehensive_Support_and_Improvement.xlsx"
        ),
        `2022` = paste0(
          "https://www.nj.gov/education/title1/accountability/docs/22/",
          "Public_Comprehensive_Workbook_File_January_2023.xlsx"
        ),
        `2019` = paste0(
          "https://www.nj.gov/education/title1/accountability/docs/19/",
          "2018-19%20Accountability%20Workbook%20File,%20Comprehensive%20Support%20and%20Improvement.xlsx"
        ),
        `2018` = paste0(
          "https://www.nj.gov/education/title1/accountability/docs/18/",
          "Final%202017-18%20Accountability%20Workbook%20File,%20Comprehensive%20Support%20and%20Improvement.xlsx"
        ),
        `2017` = paste0(
          "https://www.nj.gov/education/title1/accountability/docs/18/",
          "Final%202016-17%20Accountability%20Workbook%20File,%20Comprehensive%20Support%20and%20Improvement.xlsx"
        )
      )
      unname(urls[[as.character(end_year)]])
    },
    facilities = {
      source <- args$source
      descriptor <- entry$sources[[source]]
      if (is.null(descriptor)) {
        stop("Unknown facilities source: ", source, ".", call. = FALSE)
      }
      descriptor$url
    },
    stop("No URL resolver is registered for source family '", family, "'.",
         call. = FALSE)
  )
}

#' Current Homeroom school-directory CSV endpoint
#'
#' @return Character URL.
#' @keywords internal
get_school_directory_url <- function() {
  "https://homeroom4.doe.nj.gov/public/publicschools/download/"
}

#' Current Homeroom district-directory CSV endpoint
#'
#' @return Character URL.
#' @keywords internal
get_district_directory_url <- function() {
  "https://homeroom4.doe.nj.gov/public/districtpublicschools/download/"
}

#' Latest published NJDOE School Performance Reports contact roster
#'
#' The lightweight JSON backing NJDOE's public report search contains the same
#' native CDS identifiers plus school principal and district superintendent
#' contacts. It is the official fallback when Homeroom's Imperva policy blocks
#' non-interactive clients.
#'
#' @return Character URL.
#' @keywords internal
get_directory_spr_url <- function() {
  "https://www.nj.gov/education/spr/data/202425/schools.json"
}
