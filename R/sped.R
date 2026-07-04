#' Valid years for SPED data
#'
#' @return vector of valid end years for SPED data
#' @keywords internal
get_valid_sped_years <- function() {
  2015L:2025L
}


sped_classification_base_url <- function() {
  "https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/"
}


sped_classification_source <- function(end_year, level = "district") {
  end_year <- as.integer(end_year)
  base <- sped_classification_base_url()

  district <- list(
    "2025" = list(
      url = paste0(
        base, "2025_618data/",
        "2025IDEA618PublicReporting_ClassificationRates.xlsx"
      ),
      zip_member = NA_character_,
      skip = 4L,
      sheet = "District Rates",
      format = "district"
    ),
    "2024" = list(
      url = paste0(
        base, "2023_618data/",
        "DistrictWide_ClassificationRate_2324_public.xlsx"
      ),
      zip_member = NA_character_,
      skip = 3L,
      sheet = NA_character_,
      format = "district"
    ),
    "2023" = list(
      url = paste0(
        base, "2022public618data/",
        "District_Enrollment_vs_SpecialED_Rates_Publicdata_3_21Age.xlsx"
      ),
      zip_member = NA_character_,
      skip = 3L,
      sheet = NA_character_,
      format = "district"
    ),
    "2022" = list(
      url = paste0(base, "2022%20data/Lea_Classification_Pub.xlsx"),
      zip_member = NA_character_,
      skip = 5L,
      sheet = NA_character_,
      format = "district"
    ),
    "2021" = list(
      url = paste0(base, "2020.zip"),
      zip_member = "2020/Lea_Classification_Pub.xlsx",
      skip = 4L,
      sheet = NA_character_,
      format = "district"
    ),
    "2020" = list(
      url = paste0(base, "2019.zip"),
      zip_member = "2019/Lea_classification_Pub.xlsx",
      skip = 5L,
      sheet = NA_character_,
      format = "district"
    ),
    "2019" = list(
      url = paste0(base, "2018.zip"),
      zip_member = "2018/LEA_Classification2.xlsx",
      skip = 5L,
      sheet = NA_character_,
      format = "district"
    ),
    "2018" = list(
      url = paste0(base, "2017.zip"),
      zip_member = "2017/Lea_Classification.xlsx",
      skip = 0L,
      sheet = NA_character_,
      format = "district"
    ),
    "2017" = list(
      url = paste0(base, "2016.zip"),
      zip_member = "2016/LEA_Classificatiom.xlsx",
      skip = 4L,
      sheet = NA_character_,
      format = "district"
    ),
    "2016" = list(
      url = paste0(base, "2015.zip"),
      zip_member = "2015/LEA_Classification.xlsx",
      skip = 4L,
      sheet = NA_character_,
      format = "district"
    ),
    "2015" = list(
      url = paste0(base, "2014.zip"),
      zip_member = "2014/District_Classification_Rate.xlsx",
      skip = 4L,
      sheet = NA_character_,
      format = "district"
    )
  )

  state <- list(
    "2025" = list(
      url = paste0(
        base, "2025_618data/",
        "2025IDEA618PublicReporting_ClassificationRates.xlsx"
      ),
      zip_member = NA_character_,
      skip = 4L,
      sheet = "State Rates",
      format = "state_2025"
    )
  )

  sources <- if (level == "state") state else district
  src <- sources[[as.character(end_year)]]
  if (is.null(src)) {
    if (level == "state") {
      # The by-disability-category STATE table is only published in the 2025
      # consolidated IDEA-618 workbook ("State Rates" sheet). Earlier years
      # publish the DISTRICT classification rate (all years 2015-2024, via
      # level = "district") but NOT a clean public-only state-by-disability
      # table -- that gap is left honest rather than transcribed/derived.
      stop(paste0(
        "State-level SPED counts by disability category are only available ",
        "for end_year >= 2025 (NJ DOE introduced the 'State Rates' table in ",
        "the 2025 consolidated IDEA-618 workbook). For by-disability counts ",
        "in earlier years use fetch_sped_placement(level = 'state')."
      ), call. = FALSE)
    }
    stop(sprintf("No SPED classification source configured for %d.", end_year),
         call. = FALSE)
  }

  src
}


#' Build SPED data URL
#'
#' @param end_year ending school year
#' @return URL string for the SPED data file
#' @keywords internal
build_sped_url <- function(end_year) {
  sped_classification_source(end_year, level = "district")$url
}


download_sped_classification_workbook <- function(source, end_year) {
  if (!check_url_accessible(source$url)) {
    stop(paste0("SPED data URL is not accessible: ", source$url))
  }

  is_zip <- grepl("\\.zip$", source$url)
  tf <- tempfile(fileext = if (is_zip) ".zip" else ".xlsx")
  utils::download.file(source$url, tf, mode = "wb", quiet = TRUE)

  if (!is_zip) {
    return(tf)
  }

  if (is.na(source$zip_member) || !nzchar(source$zip_member)) {
    stop(sprintf(
      "Internal error: missing zip member for SPED classification %d.",
      end_year
    ), call. = FALSE)
  }

  extract_dir <- tempfile("sped_classification_zip_")
  dir.create(extract_dir, recursive = TRUE, showWarnings = FALSE)
  extracted <- utils::unzip(
    tf, files = source$zip_member, exdir = extract_dir, junkpaths = TRUE
  )
  extracted[[1]]
}


#' read Special ed excel files from the NJ state website
#'
#' @inheritParams get_raw_enr
#' @param level one of \code{"district"} (default; district-level total
#'   classification rate, all supported years) or \code{"state"} (state-level
#'   counts + classification rate by IDEA disability category, 2025+ only --
#'   NJ DOE did not publish the by-disability state table in the older
#'   single-sheet workbooks).
#'
#' @return a dataframe with special ed counts, etc.
#' @keywords internal
get_raw_sped <- function(end_year, level = "district") {
  valid_years <- get_valid_sped_years()

  if (!end_year %in% valid_years) {
    stop(paste0(
      end_year, " is not a valid end_year for SPED data. ",
      "Valid years are: ", paste(valid_years, collapse = ", "), ". ",
      "Data prior to end_year 2015 requires an OPRA request."
    ))
  }
  if (!level %in% c("district", "state")) {
    stop("level must be one of 'district' or 'state'.", call. = FALSE)
  }

  source <- sped_classification_source(end_year, level = level)

  tf <- download_sped_classification_workbook(source, end_year)

  # Every supported source (district 2015-2024 single-sheet workbooks, the
  # 2025 consolidated "District Rates" / "State Rates" sheets) reads through
  # the same header-skip path. Reading as text keeps a trailing "end of
  # worksheet" sentinel row from coercing count/rate columns; clean_sped_df()
  # / tidy_sped_state_disability() coerce to numeric downstream.
  sped <- readxl::read_excel(
    tf,
    sheet = if (is.na(source$sheet)) 1 else source$sheet,
    skip = source$skip,
    na = c('-', '*', 'N', 'S'),
    col_types = "text"
  )

  sped$end_year <- end_year

  return(sped)
}


#' Map NJ county names to 2-digit county ID codes
#'
#' @description Maps New Jersey county names to their standard 2-digit
#' numeric codes (01-21). NJ counties are numbered alphabetically.
#'
#' @param county_name Character vector of county names (case-insensitive).
#'
#' @return Character vector of 2-digit zero-padded county codes.
#'   Returns \code{NA_character_} for unrecognized names.
#'
#' @examples
#' county_name_to_id("ESSEX")
#' county_name_to_id(c("essex", "Hudson", "BERGEN"))
#'
#' @export
county_name_to_id <- function(county_name) {
  nj_counties <- c(
    "ATLANTIC" = "01", "BERGEN" = "02", "BURLINGTON" = "03", "CAMDEN" = "04",
    "CAPE MAY" = "05", "CUMBERLAND" = "06", "ESSEX" = "07", "GLOUCESTER" = "08",
    "HUDSON" = "09", "HUNTERDON" = "10", "MERCER" = "11", "MIDDLESEX" = "12",
    "MONMOUTH" = "13", "MORRIS" = "14", "OCEAN" = "15", "PASSAIC" = "16",
    "SALEM" = "17", "SOMERSET" = "18", "SUSSEX" = "19", "UNION" = "20",
    "WARREN" = "21"
  )
  unname(nj_counties[toupper(county_name)])
}


clean_sped_names <- function(df) {

  #data
  clean <- list(
    #preserve these
    "end_year" = "end_year",

    #disability category (2025+ State Rates sheet)
    "Disability Category" = "disability_category",

    #county ids
    "County" = "county_id",
    "COUNTY" = "county_id",
    "County Code" = "county_id",

    #district ids
    "District" = "district_id",
    "DISTRICT" = "district_id",
    "SUB_DIST" = "district_id",
    "District Code" = "district_id",

    #county name
    "county_name" = "county_name",
    "County Name" = "county_name",
    "COUNTYNAME" = "county_name",

    #district name
    "District Name" = "district_name",
    "DISTRICTNAME" = "district_name",
    "Districts                                 State Agency                            Charter School" = "district_name",

    #special ed count
    "Number Classified" = "sped_num",
    "Special Education Student Count" = "sped_num",
    "Special Ed Student Count" = "sped_num",
    "3-21 Clsfd" = "sped_num",
    "Special Ed. Enrollment" = "sped_num",
    "SPECED" = "sped_num",
    "3-21 Count" = "sped_num",
    "Count of Student with IEPs" = "sped_num",

    #special ed count no speech
    "Number Classified Without Speech" = "sped_num_no_speech",

    #gened count
    "Enrollment*" = "gened_num",
    "Gened" = "gened_num",
    "Enrollment" = "gened_num",
    "General Ed. Enrollment" = "gened_num",
    "GENED" = "gened_num",
    "LEA" = "gened_num",
    "All Students Count" = "gened_num",
    "Total Enrollment" = "gened_num",
    "General Education Enrollement Count" = "gened_num",

    #special ed classification rate
    "Percent Classified" = "sped_rate",
    "Classification Rate" = "sped_rate",
    "Clsfd Rate" = "sped_rate",
    "CLASSIFICATION RATE" = "sped_rate",
    "District Classification Rate" = "sped_rate",
    "Special Education Count" = "sped_num",
    "Classified Student Count" = "sped_num",

    #special ed classification rate no speech
    "Percent Classified Without Speech" = "sped_rate_no_speech"
  )

  names(df) <- map_chr(names(df), ~clean_name(.x, clean))

  return(df)

}


append_sped_entity_flags <- function(df,
                                     is_state = FALSE,
                                     is_district = FALSE,
                                     is_school = FALSE) {
  if (!"is_state" %in% names(df)) {
    df$is_state <- is_state
  }
  if (!"is_county" %in% names(df)) {
    df$is_county <- FALSE
  }
  if (!"is_district" %in% names(df)) {
    df$is_district <- is_district
  }
  if (!"is_school" %in% names(df)) {
    df$is_school <- is_school
  }
  if (!"is_charter" %in% names(df)) {
    df$is_charter <- if ("county_id" %in% names(df)) df$county_id == "80" else FALSE
  }
  if (!"is_charter_sector" %in% names(df)) {
    df$is_charter_sector <- FALSE
  }
  if (!"is_allpublic" %in% names(df)) {
    df$is_allpublic <- FALSE
  }

  df
}


#' Clean SPED data
#'
#' @description Cleans and standardizes SPED data from NJ DOE.
#' @param df raw data frame with cleaned names, output of get_raw_sped with clean_sped_names applied.
#' @param end_year academic year, ending year - eg 2023-2024 is 2024.
#' @param with_status logical. If \code{TRUE}, appends \code{value_status}
#'   classified from the raw \code{sped_rate} token before numeric coercion.
#'
#' @return cleaned data frame
#' @export

clean_sped_df <- function(df, end_year, with_status = FALSE) {
  # Classify from the RAW classification-rate token before numeric coercion so
  # a suppressed cell reads as suppression, not a fabricated 0. Attach it as a
  # column so it survives the row filter below (opt-in; dropped when FALSE).
  if (isTRUE(with_status) && "sped_rate" %in% names(df)) {
    df$value_status <- classify_value_status(df[["sped_rate"]])
  }

  # Coerce value columns to numeric. Sheets are read as text so a trailing
  # "end of worksheet" sentinel row does not force count/rate columns to
  # character; coerce them here.
  num_cols <- intersect(
    c("gened_num", "sped_num", "sped_rate",
      "sped_num_no_speech", "sped_rate_no_speech"),
    names(df)
  )
  for (nc in num_cols) {
    df[[nc]] <- suppressWarnings(as.numeric(df[[nc]]))
  }

  # Remove rows with missing enrollment data (footer / sentinel rows)
  df <- df %>% dplyr::filter(!is.na(gened_num))

  # Derive county_id from county_name when missing (historic data)
  if (!"county_id" %in% names(df) && "county_name" %in% names(df)) {
    df$county_id <- county_name_to_id(df$county_name)
  }

  # Curate column order. any_of() tolerates columns absent in some years and
  # keeps the opt-in value_status when present. Existing columns/order are
  # preserved; entity flags are appended additively.
  df <- df %>%
    dplyr::select(
      dplyr::any_of(c(
        'end_year', 'county_id', 'county_name',
        'district_id', 'district_name',
        'gened_num', 'sped_num',
        'sped_rate',
        'sped_num_no_speech',
        'sped_rate_no_speech',
        'value_status'
      ))
    )

  df <- append_sped_entity_flags(df, is_district = TRUE)

  df
}


#' Standardize NJ disability-category labels to cross-state snake_case
#'
#' Thin wrapper around \code{\link{standardize_sped_placement_subgroups}} that
#' additionally maps the "Statewide Total" rollup row to
#' \code{"all_disabilities"} (the cross-state convention for the all-students
#' disability rollup).
#'
#' @param x character vector of NJ disability-category labels
#' @return character vector of standardized \code{disability_category} values
#' @keywords internal
standardize_sped_disability_category <- function(x) {
  out <- standardize_sped_placement_subgroups(x)
  out[x %in% c("Statewide Total", "Total", "TOTAL", "Statewide total")] <-
    "all_disabilities"
  out
}


#' Tidy the 2025+ "State Rates" by-disability sheet
#'
#' Reshapes the state-level child-count-by-disability table (NJ DOE IDEA 618
#' "State Rates" sheet) into a tidy frame with one row per disability
#' category. Counts are the Dec-1 child count of students with IEPs; the
#' published classification rate is stored as a 0-100 percent (the source
#' reports it as a decimal). The "Statewide Total" rollup row maps to
#' \code{disability_category == "all_disabilities"}.
#'
#' @param df cleaned data frame: output of get_raw_sped(level = "state")
#'   passed through clean_sped_names()
#' @param end_year ending school year
#' @return tidy tibble: end_year, is_state, disability_category, n_students,
#'   sped_rate, suppressed
#' @keywords internal
tidy_sped_state_disability <- function(df, end_year, with_status = FALSE) {
  # clean_sped_names() maps the workbook's "Disability Category" header to
  # itself if unmapped; resolve the label column robustly.
  dis_col <- intersect(
    c("Disability Category", "disability_category"), names(df)
  )[1]
  if (is.na(dis_col)) {
    stop(
      "Could not find the Disability Category column in the State Rates sheet.",
      call. = FALSE
    )
  }

  raw_label <- df[[dis_col]]
  # Drop the "end of worksheet" sentinel and any blank label rows.
  keep <- !is.na(raw_label) &
    !grepl("^end of worksheet$", raw_label, ignore.case = TRUE)
  df <- df[keep, , drop = FALSE]
  raw_label <- raw_label[keep]

  raw_count <- df[["sped_num"]]
  n_students <- suppressWarnings(as.numeric(raw_count))
  # Source reports the classification rate as a decimal (0.0227 = 2.27%);
  # store on the same 0-100 scale used by the district output.
  sped_rate <- round(suppressWarnings(as.numeric(df[["sped_rate"]])) * 100, 2)

  out <- tibble::tibble(
    end_year = end_year,
    is_state = TRUE,
    disability_category = standardize_sped_disability_category(raw_label),
    n_students = n_students,
    sped_rate = sped_rate,
    suppressed = is.na(n_students)
  )

  out <- append_sped_entity_flags(out, is_state = TRUE)
  if (isTRUE(with_status)) {
    # Classify from the RAW child-count token, before numeric coercion, so a
    # suppressed cell reads as suppression rather than a fabricated 0.
    out$value_status <- classify_value_status(raw_count)
  }

  out
}


#' Fetch Special Education Classification Data
#'
#' @description Fetches NJ DOE special education classification data (IDEA
#'   Section 618 public reporting). With \code{level = "district"} (default)
#'   returns the district-level total classification rate (the count of
#'   students with IEPs and the general-education enrollment denominator per
#'   district). With \code{level = "state"} returns the statewide count of
#'   students with IEPs by IDEA disability category (2025+ only).
#'
#'   District-level classification is available for every end_year 2015-2025
#'   (the 2015-2024 archives live in the year-labeled folders/zips of the IDEA
#'   618 public-reporting directory; 2025 is the consolidated workbook). Data
#'   before end_year 2015 requires an OPRA request. The statewide
#'   by-disability-category table is only published for 2025+ (NJ DOE did not
#'   release a clean public-only state-by-disability workbook for earlier
#'   years); that gap is left honest rather than derived. For by-disability
#'   counts and educational placement (LRE) across 2020-2025, see
#'   \code{\link{fetch_sped_placement}}.
#'
#' @param end_year ending school year (e.g., 2025 for the 2024-2025 school
#'   year). Valid years: 2015-2025 (district); 2025 (state).
#' @param level one of \code{"district"} (default) or \code{"state"}. The
#'   \code{"state"} by-disability table is only published for 2025+.
#' @param with_status logical, default \code{FALSE}. When \code{TRUE}, appends
#'   a \code{value_status} column classified from the raw published token
#'   (before numeric coercion) so suppressed cells are distinguishable from a
#'   true zero. Additive; default output is unchanged.
#'
#' @return For \code{level = "district"}: a data frame with columns end_year,
#'   county_id, county_name, district_id, district_name, gened_num, sped_num,
#'   sped_rate, plus the standard entity flags (is_state, is_county,
#'   is_district, is_school, is_charter, is_charter_sector, is_allpublic). For
#'   \code{level = "state"}: a tibble with columns end_year, is_state,
#'   disability_category, n_students, sped_rate, suppressed, plus the entity
#'   flags. Metric polarity/denominator metadata for \code{sped_rate},
#'   \code{sped_num} and \code{gened_num} is available via
#'   \code{\link{metric_meta}} / \code{\link{annotate_metric}}.
#'
#' @seealso \code{\link{fetch_sped_placement}} for IDEA 618 educational
#'   environment / placement data and multi-year by-disability counts.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # 1. District-level classification rates (default)
#' fetch_sped(2025)
#'
#' # 2. Filter to the highest-classification districts
#' library(dplyr)
#' fetch_sped(2025) %>%
#'   filter(gened_num > 1000) %>%
#'   arrange(desc(sped_rate)) %>%
#'   select(district_name, gened_num, sped_num, sped_rate)
#'
#' # 3. Statewide child count by disability category (2025+)
#' fetch_sped(2025, level = "state") %>%
#'   arrange(desc(n_students))
#' }
fetch_sped <- function(end_year, level = "district", with_status = FALSE) {
  if (!level %in% c("district", "state")) {
    stop("level must be one of 'district' or 'state'.", call. = FALSE)
  }

  if (level == "state") {
    return(
      get_raw_sped(end_year, level = "state") %>%
        clean_sped_names() %>%
        tidy_sped_state_disability(end_year, with_status = with_status)
    )
  }

  get_raw_sped(end_year, level = "district") %>%
    clean_sped_names() %>%
    clean_sped_df(., end_year, with_status = with_status)
}
