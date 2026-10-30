# Exact CCD identifiers only; NJ county and district codes are jointly the key.
.attach_program_nces <- function(df) {
  path <- system.file("extdata", "crosswalk", "nj_ccd_state_leaid_2024.csv",
                      package = "njschooldata")
  x <- utils::read.csv(path, colClasses = "character")
  key <- paste0("NJ-", stringr::str_pad(df$county_id, 2, pad = "0"),
                stringr::str_pad(df$district_id, 4, pad = "0"))
  df$nces_dist <- x$nces_dist[match(key, x$state_leaid)]
  df
}

.program_suppressed <- function(x) {
  classify_value_status(x) == "suppressed" |
    (!is.na(x) & trimws(x) %in% c("S", "-"))
}

# Classification counts describe public students with IEPs, rather than the
# separate IDEA student-count release (which also reports nonpublic students).
.sped_contract <- function(df, end_year) {
  df$measure <- "classification_count"
  if (!"disability_category" %in% names(df)) {
    df$disability_category <- "all_disabilities"
  }
  df$subgroup <- "total"
  df$age_group <- if (end_year >= 2023L) "3_21" else NA_character_
  df$grade_level <- NA_character_
  if (!"n_students" %in% names(df)) df$n_students <- df$sped_num
  df$pct_of_enrollment <- df$sped_rate
  if (!"county_id" %in% names(df)) df$county_id <- NA_character_
  if (!"district_id" %in% names(df)) df$district_id <- NA_character_
  .attach_program_nces(df)
}

.sped_published_state <- function(end_year) {
  source <- if (end_year == 2023L) {
    list(directory = "2022public618data/",
         file = "StateClassificationRates_SpecialED_3-21.xlsx",
         skip = 4L, columns = 6:8)
  } else {
    list(directory = "2023_618data/",
         file = "StatewideClassificationRate_2324.xlsx",
         skip = 3L, columns = 1:3)
  }
  url <- paste0(sped_classification_base_url(), source$directory, source$file)
  result <- download_source(url, "xlsx")
  path <- source_result_data(result)
  on.exit(.release_source_result(result), add = TRUE)
  raw <- readxl::read_excel(path, skip = source$skip, col_types = "text",
                            .name_repair = "minimal")[, source$columns]
  total <- raw[tolower(trimws(raw[[1]])) %in% "total", ]
  if (nrow(total) != 1L) stop("Expected one published public statewide classification total.")
  out <- tibble::tibble(
    end_year = end_year, county_id = "99", district_id = "9999",
    district_name = "Statewide Total",
    sped_num = suppressWarnings(as.numeric(total[[2]])),
    sped_rate = suppressWarnings(as.numeric(total[[3]])),
    suppressed = .program_suppressed(total[[2]])
  )
  out <- append_sped_entity_flags(out, is_state = TRUE)
  attach_source_results(out, source_result_record(result, "sped", end_year, "state"))
}
