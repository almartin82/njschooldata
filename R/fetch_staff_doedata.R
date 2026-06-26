# ==============================================================================
# NJ DOE doedata staff sources: educator evaluations + certificated staff
# ==============================================================================
#
# Two standalone NJ DOE "doedata" staff downloads, distinct from the SPR-sourced
# staff fetchers (fetch_staff_demographics, fetch_spr_staff_counts, ...):
#
#   fetch_staff_evaluations()   - summative educator evaluation rating
#       distributions (how many teachers / principals land in each tier).
#       Source: nj.gov/education/doedata/staff/ . ONLY 3 years exist:
#       2014 (SY2013-14), 2015 (SY2014-15), 2016 (SY2015-16).
#
#   fetch_certificated_staff()  - certificated-staff FTE counts by position x
#       race x gender, the long historical series. Source:
#       nj.gov/education/doedata/cs/ . Covered years (established empirically):
#       LEGACY CSV era 2000-2008 and MODERN xlsx era 2020-2026. The intermediate
#       2009-2019 Excel files use a drifting, non-uniform layout and ERROR
#       (documented) rather than risk emitting misaligned values.
#
# Data-integrity stance: every number traces to a downloaded NJ DOE file. A "*"
# suppression mask becomes NA, never a guess. A race/gender column that an era
# does not report becomes NA, never 0. Years whose layout maps to no parser
# error loudly instead of producing garbage.
#
# ==============================================================================


# -----------------------------------------------------------------------------
# Suppression-safe numeric coercion (shared)
# -----------------------------------------------------------------------------

#' Coerce a published staff value to numeric, with masked cells -> NA
#'
#' The evaluation workbooks mask small cells with \code{"*"}; both staff sources
#' may carry stray text. This coercion strips thousands commas, maps any masked
#' or non-numeric token (\code{"*"}, \code{""}, a \code{"<N"} range, free text)
#' to \code{NA} BEFORE numeric parsing, and otherwise returns the number. A real
#' published \code{0} stays \code{0}; fractional FTE values (e.g. \code{35.8})
#' are preserved. Already-numeric input is returned unchanged.
#'
#' @param x A character (or numeric) vector from a count / FTE column.
#' @return A numeric vector with masked / suppressed cells as \code{NA}.
#' @keywords internal
staff_value_numeric <- function(x) {
  if (is.numeric(x)) return(x)
  x <- trimws(as.character(x))
  x <- gsub(",", "", x, fixed = TRUE)
  x[x == ""] <- NA_character_
  x[x == "*"] <- NA_character_
  x[grepl("^<", x)] <- NA_character_   # "<5", "<.1", "<N" ranges -> NA, never the digit
  suppressWarnings(as.numeric(x))
}


#' Left-pad an NJ CDS code to a fixed width, preserving leading zeros
#'
#' NJ county/district/school codes are numeric but must keep leading zeros and
#' stay character (e.g. district \code{"10"} in a drift year re-pads to
#' \code{"0010"}). Blank / non-numeric codes (e.g. a statewide aggregate row that
#' carries no code) become \code{NA}.
#'
#' @param x A code vector (character or numeric).
#' @param width Target width (county 2, district 4, school 3).
#' @return A zero-padded character vector, \code{NA} where no numeric code.
#' @keywords internal
staff_pad_code <- function(x, width) {
  n <- suppressWarnings(as.integer(trimws(as.character(x))))
  ifelse(is.na(n), NA_character_, sprintf(paste0("%0", width, "d"), n))
}


#' Normalize a raw staff POSITION label to a stable snake_case value
#'
#' Harmonizes the position labels that drift across the legacy CSV era
#' (\code{ADMINIST}, \code{TEACHER}, \code{SUPPSERV}, \code{TOTAL}) and the modern
#' xlsx era (\code{Administrators}, \code{Special Service(s)}, \code{Teacher(s)},
#' \code{Supervisors/Coordinators}, \code{Total}) onto one set:
#' \code{administrators}, \code{teachers}, \code{special_services},
#' \code{supervisors_coordinators}, \code{total}.
#'
#' @param x Raw position labels.
#' @return Normalized position labels (snake_case).
#' @keywords internal
normalize_staff_position <- function(x) {
  lc <- tolower(trimws(as.character(x)))
  dplyr::case_when(
    lc %in% c("administ", "administrator", "administrators", "admin") ~ "administrators",
    lc %in% c("teacher", "teachers") ~ "teachers",
    lc %in% c("suppserv", "specserv", "special service", "special services") ~ "special_services",
    lc %in% c("supervisors/coordinators", "supervisor/coordinator",
              "supervisors / coordinators") ~ "supervisors_coordinators",
    lc == "total" ~ "total",
    TRUE ~ lc
  )
}


# ==============================================================================
# A) fetch_staff_evaluations()
# ==============================================================================

.staff_eval_urls <- c(
  "2014" = "https://www.nj.gov/education/doedata/staff/NJDOE_STAFF_EVAL_1314.xlsx",
  "2015" = "https://www.nj.gov/education/doedata/staff/NJDOE_STAFF_EVAL_1415.xlsx",
  "2016" = "https://www.nj.gov/education/doedata/staff/NJDOE_STAFF_EVAL_1516.xlsx"
)

.staff_eval_value_cols <- c(
  "ineffective", "partially_effective", "effective", "highly_effective", "total"
)

# Which sheet(s) hold the rating rows, by year. 2014 ships one combined sheet;
# 2015 and 2016 split district totals and school totals into two sheets that are
# read and stacked.
.staff_eval_sheets <- list(
  "2014" = "SQL Results",
  "2015" = c("Suppressed District Totals", "Suppressed School Totals"),
  "2016" = c("Suppressed District Totals", "Suppressed School Totals")
)


#' Download and read the raw staff-evaluation workbook
#'
#' Downloads the standalone NJ DOE summative educator-evaluation workbook for
#' \code{end_year}, validates it is a real \code{.xlsx} (ZIP magic bytes; see
#' \code{\link{is_valid_xlsx}}) so an HTTP error page is never parsed as data,
#' reads the rating sheet(s) for that year (one combined sheet in 2014; the
#' district-totals + school-totals sheets stacked in 2015 / 2016), and returns
#' the raw 12-column rows with their published \code{"*"} masks intact.
#'
#' @param end_year 2014, 2015, or 2016. Other years error.
#' @return A raw data frame of the published evaluation rows.
#' @keywords internal
get_raw_staff_evaluations <- function(end_year) {
  if (!end_year %in% c(2014, 2015, 2016)) {
    stop(
      "staff evaluation data is available for end_year 2014 (SY2013-14), ",
      "2015 (SY2014-15), and 2016 (SY2015-16) only.",
      call. = FALSE
    )
  }

  url <- .staff_eval_urls[[as.character(end_year)]]
  dest <- tempfile(pattern = "njeval_", fileext = ".xlsx")
  on.exit(unlink(dest), add = TRUE)
  downloader::download(url, destfile = dest, mode = "wb")

  if (!is_valid_xlsx(dest)) {
    stop(sprintf(
      paste0(
        "Downloaded staff-evaluation workbook for %d is not a valid .xlsx file ",
        "-- the NJ DOE source may be unavailable or returned an error page.\n  URL: %s"
      ),
      end_year, url
    ), call. = FALSE)
  }

  sheets <- .staff_eval_sheets[[as.character(end_year)]]
  parts <- lapply(sheets, function(sh) {
    d <- readxl::read_excel(dest, sheet = sh, col_types = "text")
    if (ncol(d) != 12) {
      stop(sprintf(
        "Unexpected staff-evaluation layout for %d sheet '%s': %d columns (expected 12). The NJ DOE source format may have changed.",
        end_year, sh, ncol(d)
      ), call. = FALSE)
    }
    names(d) <- c(
      "county_id", "county_name", "district_id", "lea_name",
      "school_id", "school_name", "category",
      "ineffective", "partially_effective", "effective",
      "highly_effective", "total"
    )
    d
  })
  do.call(rbind, parts)
}


#' Tidy a raw staff-evaluation data frame
#'
#' Cleans the CDS codes (re-padded to fixed width, leading zeros preserved),
#' drops the trailing data-certification note rows and any blank rows, maps the
#' raw \code{CATEGORY} to a stable \code{staff_category}, coerces the five rating
#' columns to numeric with masked (\code{"*"}) cells -> \code{NA}, and stamps the
#' entity flags. The statewide aggregate (county \code{"99"} / district
#' \code{"9999"}, present 2014-2015) is flagged \code{is_state}.
#'
#' @param df A raw frame from \code{\link{get_raw_staff_evaluations}}.
#' @param end_year The school year end (added as a column).
#' @return The tidy evaluation data frame.
#' @keywords internal
tidy_staff_evaluations <- function(df, end_year) {
  df$county_id <- staff_pad_code(df$county_id, 2)
  df$district_id <- staff_pad_code(df$district_id, 4)
  df$school_id <- staff_pad_code(df$school_id, 3)

  # Drop the trailing data-certification note rows and any fully blank rows:
  # keep only rows with a real county id and a recognized category.
  df <- df[!is.na(df$county_id) & !is.na(df$category), , drop = FALSE]
  df <- df[df$category %in% c("TEACHERS", "PRIN/AP/VP"), , drop = FALSE]

  df$staff_category <- dplyr::case_when(
    df$category == "TEACHERS" ~ "teachers",
    df$category == "PRIN/AP/VP" ~ "principals_vps",
    TRUE ~ tolower(df$category)
  )

  df[.staff_eval_value_cols] <- lapply(df[.staff_eval_value_cols], staff_value_numeric)

  # The LEA name column is the district name; carry it as district_name.
  df$district_name <- df$lea_name

  is_state <- !is.na(df$county_id) & df$county_id == "99"
  is_district <- !is.na(df$school_id) & df$school_id == "999" & !is_state

  df$end_year <- end_year
  df$is_state <- is_state
  df$is_county <- FALSE
  df$is_district <- is_district
  df$is_school <- !is_state & !is_district
  df$is_charter <- !is.na(df$county_id) & df$county_id == "80"

  df[, c(
    "end_year",
    "county_id", "county_name",
    "district_id", "district_name",
    "school_id", "school_name",
    "category", "staff_category",
    .staff_eval_value_cols,
    "is_state", "is_county", "is_district", "is_school", "is_charter"
  )]
}


#' Fetch Summative Educator Evaluation Rating Distributions
#'
#' Downloads the NJ DOE standalone summative educator-evaluation workbook and
#' returns, for each entity and staff category (teachers vs principals/APs/VPs),
#' how many educators landed in each of the four rating tiers (ineffective,
#' partially effective, effective, highly effective) plus the total evaluated.
#' Rating distributions are a rarely-analyzed window into evaluation-system rigor
#' (e.g. how concentrated ratings are at the top of the scale).
#'
#' @details
#' \strong{Source.} Standalone Excel workbooks under
#' \code{nj.gov/education/doedata/staff/} -- distinct from the SPR-sourced staff
#' fetchers. \strong{Only three years exist:} \code{end_year} 2014 (SY2013-14),
#' 2015 (SY2014-15), and 2016 (SY2015-16); any other year errors.
#'
#' \strong{Sheets differ by year.} The 2014 workbook ships one combined sheet
#' (school rows plus district-total rows, \code{school_id == "999"}); the 2015
#' and 2016 workbooks split district totals and school totals into two sheets
#' that are read and stacked.
#'
#' \strong{Staff category.} The raw \code{CATEGORY} (\code{"TEACHERS"} /
#' \code{"PRIN/AP/VP"}) is normalized to \code{staff_category}
#' (\code{"teachers"} / \code{"principals_vps"}) and the raw label is kept as
#' \code{category}.
#'
#' \strong{Suppression -> NA (never a guessed number).} Small cells are masked
#' with \code{"*"}; every rating column maps \code{"*"} to \code{NA}. A real
#' published \code{0} stays \code{0}. A trailing data-certification note row in
#' each workbook is dropped.
#'
#' \strong{Entity flags.} \code{is_school} (per-school rows) vs \code{is_district}
#' (district totals, \code{school_id == "999"}). A statewide aggregate row
#' (county \code{"99"} / district \code{"9999"}) is present in 2014 and 2015 and
#' is flagged \code{is_state}; it is returned at \code{level = "district"}. The
#' 2016 workbook publishes no statewide row.
#'
#' @param end_year A school year: 2014, 2015, or 2016.
#' @param level \code{"school"} (default) returns the per-school rows;
#'   \code{"district"} returns the district-total rows (\code{school_id == "999"},
#'   plus the statewide aggregate where published).
#'
#' @return Data frame with \code{end_year}, the entity identifiers, the raw
#'   \code{category} and normalized \code{staff_category}, the five numeric rating
#'   columns (\code{ineffective}, \code{partially_effective}, \code{effective},
#'   \code{highly_effective}, \code{total}), and the entity flags
#'   (\code{is_state}, \code{is_county}, \code{is_district}, \code{is_school},
#'   \code{is_charter}).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # School-level teacher rating distribution, 2015-16
#' fetch_staff_evaluations(2016)
#'
#' # District-total rows, including the statewide aggregate (2014)
#' library(dplyr)
#' fetch_staff_evaluations(2014, level = "district") %>%
#'   filter(is_state, staff_category == "teachers")
#'
#' # Share of teachers rated highly effective, by district (2015)
#' fetch_staff_evaluations(2015, level = "district") %>%
#'   filter(staff_category == "teachers", !is_state) %>%
#'   mutate(pct_highly = 100 * highly_effective / total) %>%
#'   select(district_name, highly_effective, total, pct_highly)
#' }
fetch_staff_evaluations <- function(end_year, level = "school") {
  if (!level %in% c("school", "district")) {
    stop(
      "fetch_staff_evaluations() level must be \"school\" or \"district\".",
      call. = FALSE
    )
  }
  if (!end_year %in% c(2014, 2015, 2016)) {
    stop(
      "staff evaluation data is available for end_year 2014 (SY2013-14), ",
      "2015 (SY2014-15), and 2016 (SY2015-16) only.",
      call. = FALSE
    )
  }

  cache_key <- make_cache_key("fetch_staff_evaluations", end_year, level)
  cached <- cache_get(cache_key)
  if (!is.null(cached)) return(cached)

  raw <- get_raw_staff_evaluations(end_year)
  out <- tidy_staff_evaluations(raw, end_year)

  out <- if (level == "school") {
    out[out$is_school, , drop = FALSE]
  } else {
    out[!is.na(out$school_id) & out$school_id == "999", , drop = FALSE]
  }
  rownames(out) <- NULL

  cache_set(cache_key, out)
  out
}


# ==============================================================================
# B) fetch_certificated_staff()
# ==============================================================================

# Covered-year set (established empirically against the live NJ DOE files):
#   legacy CSV era  : 2000-2008  (zip member is a 20-column .CSV)
#   modern xlsx era : 2020-2026  (4-sheet STATE/COUNTY/DISTRICT/SCHOOL workbook)
# The intermediate 2009-2019 Excel files use a drifting, non-uniform 24-column
# layout (header row position, column order and race-column names all vary, and
# an ambiguous "OTHER" race bucket) and are intentionally unsupported -> error.
.certificated_legacy_years <- 2000:2008
.certificated_modern_years <- 2020:2026

.certificated_harmonized_cols <- c(
  "white", "black", "hispanic", "asian", "american_indian",
  "pacific_islander", "two_or_more", "total"
)


#' Resolve the NJ DOE certificated-staff download for a year
#'
#' Returns the download URL, whether it is a zip archive (vs a direct
#' \code{.xlsx}), and the parser era (\code{"legacy"} CSV vs \code{"modern"}
#' xlsx) for \code{end_year}. Filenames drift across the series and are
#' enumerated explicitly; spaces are URL-encoded.
#'
#' @param end_year A covered school year end.
#' @return A list with \code{url}, \code{archive} (logical), and \code{era}.
#' @keywords internal
certificated_staff_source <- function(end_year) {
  base <- "https://www.nj.gov/education/doedata/cs/"
  if (end_year %in% .certificated_legacy_years) {
    return(list(
      url = sprintf("%scs%02d/cert.zip", base, end_year %% 100),
      archive = TRUE, era = "legacy"
    ))
  }
  modern_files <- c(
    "2020" = "cs20/cert_staff_state_1920.zip",
    "2021" = "cs21/Certificated%20Staff%202021.zip",
    "2022" = "cs22/Certificated%20Staff%202122.zip",
    "2023" = "cs23/Certificated%20Staff%202023.zip",
    "2024" = "cs24/CertificatedStaff_2024.zip",
    "2025" = "cs25/Certificated%20Staff%202025.xlsx",
    "2026" = "cs26/Certificated%20Staff%202026.zip"
  )
  key <- as.character(end_year)
  if (!key %in% names(modern_files)) {
    stop(sprintf("No certificated-staff source mapped for end_year %d.", end_year),
         call. = FALSE)
  }
  list(
    url = paste0(base, modern_files[[key]]),
    archive = !grepl("\\.xlsx$", modern_files[[key]]),
    era = "modern"
  )
}


#' Download (and, if zipped, extract) the certificated-staff data file
#'
#' Downloads the source for \code{end_year}, validates the binary (ZIP magic
#' bytes via \code{\link{is_valid_xlsx}} -- a zip and an .xlsx both begin
#' \code{PK}, so this rejects HTML error / bot pages for both), and, for the
#' zip-wrapped years, extracts the single data member. Returns a local path to
#' the data file (a \code{.csv} for the legacy era, a \code{.xlsx} for the
#' modern era).
#'
#' @param end_year A covered school year end.
#' @param work_dir A scratch directory the caller owns and cleans up.
#' @return A list with \code{path}, \code{era}.
#' @keywords internal
certificated_staff_local_file <- function(end_year, work_dir) {
  src <- certificated_staff_source(end_year)
  ext <- if (src$archive) ".zip" else ".xlsx"
  dest <- file.path(work_dir, paste0("cert_", end_year, ext))
  downloader::download(src$url, destfile = dest, mode = "wb")

  if (!is_valid_xlsx(dest)) {
    stop(sprintf(
      paste0(
        "Downloaded certificated-staff file for %d is not a valid archive/workbook ",
        "-- the NJ DOE source may be unavailable or returned an error page.\n  URL: %s"
      ),
      end_year, src$url
    ), call. = FALSE)
  }

  if (!src$archive) {
    return(list(path = dest, era = src$era))
  }

  members <- utils::unzip(dest, list = TRUE)$Name
  data_member <- members[grepl("\\.(csv|xls|xlsx)$", members, ignore.case = TRUE)]
  if (length(data_member) < 1) {
    stop(sprintf("Certificated-staff archive for %d held no data member.", end_year),
         call. = FALSE)
  }
  utils::unzip(dest, files = data_member[1], exdir = work_dir, junkpaths = TRUE)
  list(path = file.path(work_dir, basename(data_member[1])), era = src$era)
}


#' Parse a legacy (2000-2008) certificated-staff CSV into harmonized long form
#'
#' The legacy member is a 20-column CSV (member filename varies:
#' \code{STAT_STFrae.CSV}, \code{STAT_STFSUM.CSV}, \code{STAT_STF.CSV},
#' \code{cert.csv}) with one row per entity x position x sex. \code{POSITION} is
#' printed only on the \code{MALE} row of each (entity, position) triple and is
#' filled down. The race columns are \code{WHITE}, \code{BLACK}, \code{HISP},
#' \code{ALS_IND} (American Indian) and \code{ASI_PAC} (a single combined
#' Asian/Pacific-Islander bucket -- NJ did not separate them in this era, so
#' \code{asian} carries the combined count and \code{pacific_islander} /
#' \code{two_or_more} are \code{NA}, never 0). Entity conventions:
#' state = \code{CONAME == "STATE SUM"}, county = \code{DIST == "9998"}
#' (CO SUMMARY), district total = \code{SCH == "998"} (DIST SUMMARY), school =
#' everything else.
#'
#' @param path Path to the legacy CSV.
#' @param end_year The school year end.
#' @return A harmonized long-by-gender data frame.
#' @keywords internal
parse_certificated_legacy <- function(path, end_year) {
  d <- suppressMessages(readr::read_csv(
    path, col_types = readr::cols(.default = readr::col_character()), trim_ws = TRUE
  ))
  names(d) <- trimws(toupper(names(d)))

  needed <- c("CO", "CONAME", "DIST", "DISTNAME", "SCH", "SCHNAME",
              "POSITION", "SEX", "WHITE", "BLACK", "HISP", "ALS_IND",
              "ASI_PAC", "TOTAL")
  if (!all(needed %in% names(d))) {
    stop(sprintf("Unsupported legacy certificated-staff layout for end_year %d.",
                 end_year), call. = FALSE)
  }

  # POSITION is blank on FEMALE / TOTAL rows; fill down within file order.
  d$POSITION[!nzchar(trimws(d$POSITION))] <- NA
  d <- tidyr::fill(d, "POSITION", .direction = "down")

  for (col in c("CO", "CONAME", "DIST", "SCH", "SEX")) d[[col]] <- trimws(d[[col]])

  is_state <- !is.na(d$CONAME) & d$CONAME == "STATE SUM"
  is_county <- !is.na(d$DIST) & d$DIST == "9998"
  is_district <- !is.na(d$SCH) & d$SCH == "998" & !is_county & !is_state
  is_school <- !is_state & !is_county & !is_district

  out <- data.frame(
    end_year = end_year,
    county_id = staff_pad_code(d$CO, 2),
    county_name = d$CONAME,
    district_id = staff_pad_code(d$DIST, 4),
    district_name = d$DISTNAME,
    school_id = staff_pad_code(d$SCH, 3),
    school_name = d$SCHNAME,
    position = normalize_staff_position(d$POSITION),
    gender = dplyr::recode(tolower(d$SEX),
                           male = "male", female = "female", total = "total",
                           .default = tolower(d$SEX)),
    white = staff_value_numeric(d$WHITE),
    black = staff_value_numeric(d$BLACK),
    hispanic = staff_value_numeric(d$HISP),
    asian = staff_value_numeric(d$ASI_PAC),
    american_indian = staff_value_numeric(d$ALS_IND),
    pacific_islander = NA_real_,
    two_or_more = NA_real_,
    total = staff_value_numeric(d$TOTAL),
    is_state = is_state,
    is_county = is_county,
    is_district = is_district,
    is_school = is_school,
    is_charter = !is.na(d$CO) & d$CO == "80",
    stringsAsFactors = FALSE
  )
  # Statewide rows carry no county/district code; keep county_name "STATE SUM".
  out
}


# Modern-era column synonyms (exact, lower-cased header names). Percent columns
# (%White, Wh_Pct, ...) are deliberately NOT matched.
.certificated_modern_synonyms <- list(
  county_id = c("co code", "co"),
  county_name = c("county"),
  district_id = c("dist code", "dist"),
  district_name = c("district"),
  school_id = c("sch code", "sch"),
  school_name = c("school"),
  position = c("position"),
  white = c("white"),
  black = c("black"),
  hispanic = c("hispanic"),
  asian = c("asian"),
  american_indian = c("american indian"),
  pacific_islander = c("hawaiian native", "pacific islander"),
  two_or_more = c("two or more races", "multi"),
  total = c("total"),
  male = c("male"),
  female = c("female")
)


#' Parse a modern (2020-2026) certificated-staff sheet into harmonized long form
#'
#' Reads one sheet (\code{STATE}/\code{COUNTY}/\code{DISTRICT}/\code{SCHOOL};
#' header on row 2, \code{skip = 1}) and resolves columns by normalized header
#' name -- robust to the 2020 transitional layout (a phantom merged column,
#' plural position labels, \code{"Pacific Islander"}/\code{"Multi"} naming, a
#' \code{"Min"} minority column, no Non-Binary count) and the uniform 2021-2026
#' layout. The trailing \code{"end of worksheet"} sentinel row is dropped. Each
#' source row (one per entity x position, with race counts reported only as a
#' gender total) is expanded to three long rows -- \code{gender} \code{"total"}
#' (race breakdown populated), \code{"male"} and \code{"female"} (race columns
#' \code{NA}, since the modern files do not cross race x gender; \code{total}
#' carries that gender's headcount). Non-binary is published only as a percent
#' (no count) and is not surfaced.
#'
#' @param path Path to the modern \code{.xlsx}.
#' @param sheet Sheet name to read.
#' @param end_year The school year end.
#' @return A harmonized long-by-gender data frame.
#' @keywords internal
parse_certificated_modern <- function(path, sheet, end_year) {
  raw <- suppressMessages(readxl::read_excel(path, sheet = sheet, skip = 1))
  names(raw) <- trimws(names(raw))
  lower <- tolower(names(raw))

  pick <- function(syns) {
    hit <- which(lower %in% syns)
    if (length(hit) == 0) return(NULL)
    raw[[hit[1]]]
  }
  resolved <- lapply(.certificated_modern_synonyms, pick)

  required <- c("position", "white", "black", "hispanic", "asian",
                "american_indian", "total", "male", "female")
  missing <- required[vapply(resolved[required], is.null, logical(1))]
  if (length(missing) > 0) {
    stop(sprintf(
      "Unsupported modern certificated-staff layout for end_year %d sheet '%s' (missing: %s).",
      end_year, sheet, paste(missing, collapse = ", ")
    ), call. = FALSE)
  }

  n <- nrow(raw)
  na_chr <- rep(NA_character_, n)
  na_num <- rep(NA_real_, n)
  getc <- function(nm) if (is.null(resolved[[nm]])) na_chr else as.character(resolved[[nm]])
  getn <- function(nm) if (is.null(resolved[[nm]])) na_num else staff_value_numeric(resolved[[nm]])

  base <- data.frame(
    end_year = end_year,
    county_id = staff_pad_code(getc("county_id"), 2),
    county_name = getc("county_name"),
    district_id = staff_pad_code(getc("district_id"), 4),
    district_name = getc("district_name"),
    school_id = staff_pad_code(getc("school_id"), 3),
    school_name = getc("school_name"),
    position = normalize_staff_position(getc("position")),
    stringsAsFactors = FALSE
  )
  races <- data.frame(
    white = getn("white"), black = getn("black"), hispanic = getn("hispanic"),
    asian = getn("asian"), american_indian = getn("american_indian"),
    pacific_islander = getn("pacific_islander"), two_or_more = getn("two_or_more"),
    total = getn("total")
  )
  male_n <- getn("male")
  female_n <- getn("female")

  empty_races <- data.frame(
    white = na_num, black = na_num, hispanic = na_num, asian = na_num,
    american_indian = na_num, pacific_islander = na_num, two_or_more = na_num
  )

  total_rows <- cbind(base, gender = "total", races)
  male_rows <- cbind(base, gender = "male", empty_races, total = male_n)
  female_rows <- cbind(base, gender = "female", empty_races, total = female_n)

  out <- rbind(total_rows, male_rows, female_rows)

  level_flags <- modern_sheet_flags(sheet, nrow(out))
  out <- cbind(out, level_flags)
  out$is_charter <- !is.na(out$county_id) & out$county_id == "80"

  # Drop the trailing sentinel row ("end of worksheet" / "end of table") and any
  # all-NA position rows.
  out <- out[!is.na(out$position) & !grepl("^end of ", out$position), , drop = FALSE]
  out[, c(
    "end_year", "county_id", "county_name", "district_id", "district_name",
    "school_id", "school_name", "position", "gender",
    .certificated_harmonized_cols, "is_state", "is_county", "is_district",
    "is_school", "is_charter"
  )]
}


#' Entity flags for a modern certificated-staff sheet
#' @keywords internal
modern_sheet_flags <- function(sheet, n) {
  data.frame(
    is_state = rep(sheet == "STATE", n),
    is_county = rep(sheet == "COUNTY", n),
    is_district = rep(sheet == "DISTRICT", n),
    is_school = rep(sheet == "SCHOOL", n),
    stringsAsFactors = FALSE
  )
}


#' Fetch Certificated-Staff FTE Counts (position x race x gender)
#'
#' Downloads the NJ DOE certificated-staff file for \code{end_year} and returns
#' staff full-time-equivalent (FTE) counts by position, race, and gender,
#' harmonized to one tidy long-by-gender schema across two source eras. This is
#' the deep historical staffing series, distinct from the SPR-sourced staff
#' fetchers (which start in 2018).
#'
#' @details
#' \strong{Source + covered years.} Standalone files under
#' \code{nj.gov/education/doedata/cs/}. The covered-year set was established
#' empirically against the live files:
#' \itemize{
#'   \item \strong{Legacy CSV era: 2000-2008} -- a 20-column CSV (one row per
#'     entity x position x sex). Race buckets are \code{WHITE}, \code{BLACK},
#'     \code{HISP}, \code{ALS_IND} (American Indian) and \code{ASI_PAC} (a single
#'     combined Asian/Pacific-Islander group). In this era \code{asian} carries
#'     that combined count and \code{pacific_islander} / \code{two_or_more} are
#'     \code{NA} (NJ did not report them separately) -- never \code{0}.
#'   \item \strong{Modern xlsx era: 2020-2026} -- a four-sheet workbook
#'     (STATE/COUNTY/DISTRICT/SCHOOL) with race reported separately
#'     (\code{asian}, \code{pacific_islander}, \code{two_or_more} all populated).
#'   \item \strong{2009-2019 ERROR (unsupported).} The intermediate Excel files
#'     use a drifting, non-uniform layout (varying header-row position, column
#'     order and race-column names, and an ambiguous \code{OTHER} bucket). Rather
#'     than risk emitting misaligned values, these years error.
#' }
#'
#' \strong{Long-by-gender schema.} Output is one row per
#' (entity, position, gender), \code{gender} in \code{"total"}, \code{"male"},
#' \code{"female"}. The race FTE columns are the race breakdown for that gender:
#' the legacy era reports race x sex, so race columns are populated on all three
#' gender rows; the modern era reports race only as a gender total, so race
#' columns are populated on the \code{"total"} row and \code{NA} on the
#' \code{"male"} / \code{"female"} rows (whose \code{total} carries that gender's
#' headcount). An era-absent race column is \code{NA}, never \code{0}. Non-binary
#' staff are published only as a percent (no count) in the modern files and are
#' not surfaced as a count.
#'
#' \strong{FTE values.} Counts are full-time equivalents and are fractional in
#' the modern era (e.g. \code{35.8}); they are preserved as doubles, never
#' rounded.
#'
#' \strong{Positions.} Normalized to \code{administrators}, \code{teachers},
#' \code{special_services}, \code{supervisors_coordinators}, \code{total}.
#'
#' \strong{Levels.} \code{level} selects the entity grain: \code{"school"}
#' (default), \code{"district"}, \code{"county"}, \code{"state"}. The modern era
#' reads the matching sheet; the legacy era filters the single CSV by its entity
#' conventions (state = \code{STATE SUM}, county = \code{CO SUMMARY}, district =
#' \code{DIST SUMMARY}).
#'
#' @param end_year A school year end in 2000-2008 or 2020-2026. Years 2009-2019
#'   error (unsupported intermediate layout).
#' @param level One of \code{"school"} (default), \code{"district"},
#'   \code{"county"}, \code{"state"}.
#'
#' @return Data frame with \code{end_year}, the entity identifiers, \code{position},
#'   \code{gender}, the race FTE columns (\code{white}, \code{black},
#'   \code{hispanic}, \code{asian}, \code{american_indian}, \code{pacific_islander},
#'   \code{two_or_more}), \code{total}, and the entity flags (\code{is_state},
#'   \code{is_county}, \code{is_district}, \code{is_school}, \code{is_charter}).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Statewide teacher FTE by gender, 2024-25
#' library(dplyr)
#' fetch_certificated_staff(2025, level = "state") %>%
#'   filter(position == "teachers")
#'
#' # School-level teacher race breakdown (gender total), latest year
#' fetch_certificated_staff(2026) %>%
#'   filter(position == "teachers", gender == "total") %>%
#'   select(district_name, school_name, white, black, hispanic, asian, total)
#'
#' # Long-run statewide teacher headcount (legacy + modern)
#' purrr::map_dfr(c(2000, 2005, 2008, 2020, 2025), function(y) {
#'   fetch_certificated_staff(y, level = "state") %>%
#'     filter(position == "teachers", gender == "total") %>%
#'     transmute(end_year, teachers = total)
#' })
#' }
fetch_certificated_staff <- function(end_year, level = "school") {
  valid_levels <- c("school", "district", "county", "state")
  if (!level %in% valid_levels) {
    stop("fetch_certificated_staff() level must be one of: ",
         paste(valid_levels, collapse = ", "), ".", call. = FALSE)
  }
  covered <- c(.certificated_legacy_years, .certificated_modern_years)
  if (!end_year %in% covered) {
    stop(sprintf(
      paste0(
        "certificated-staff data is available for end_year 2000-2008 (legacy CSV) ",
        "and 2020-2026 (modern xlsx). end_year %d is not covered; the 2009-2019 ",
        "intermediate Excel files use a non-uniform layout and are unsupported."
      ),
      end_year
    ), call. = FALSE)
  }

  cache_key <- make_cache_key("fetch_certificated_staff", end_year, level)
  cached <- cache_get(cache_key)
  if (!is.null(cached)) return(cached)

  work_dir <- file.path(tempdir(), paste0("njcert_", end_year, "_", as.integer(stats::runif(1, 1, 1e6))))
  dir.create(work_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(work_dir, recursive = TRUE), add = TRUE)

  local <- certificated_staff_local_file(end_year, work_dir)

  if (local$era == "legacy") {
    out <- parse_certificated_legacy(local$path, end_year)
    keep <- switch(level,
      school = out$is_school,
      district = out$is_district,
      county = out$is_county,
      state = out$is_state
    )
    out <- out[keep, , drop = FALSE]
  } else {
    sheet <- switch(level, school = "SCHOOL", district = "DISTRICT",
                    county = "COUNTY", state = "STATE")
    out <- parse_certificated_modern(local$path, sheet, end_year)
  }
  rownames(out) <- NULL

  cache_set(cache_key, out)
  out
}
