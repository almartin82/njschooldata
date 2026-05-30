# ==============================================================================
# Tests for fetch_sped_placement() (IDEA 618 Educational Environment)
# ==============================================================================
# Closes #46.
#
# v1 (PR #278) covered end_year 2025 only; v2 extends coverage to 2020-2024.
# Network tests hit the live NJ DOE source and are gated behind
# skip_if_offline() the same way as the rest of the package's network tests.
# ==============================================================================


# ------------------------------------------------------------------
# Offline tests: argument validation + helpers
# ------------------------------------------------------------------

test_that("get_valid_sped_placement_years covers 2020-2025", {
  expect_equal(get_valid_sped_placement_years(), 2020L:2025L)
})

test_that("build_sped_placement_url uses the IDEA 618 path (2025 only)", {
  url <- build_sped_placement_url(2025)
  expect_match(url, "ideapublicdata/docs/2025_618data/", fixed = TRUE)
  expect_match(url, "StudentCountandEducationalEnvironment\\.xlsx$")
  expect_error(build_sped_placement_url(2024L), "only covers end_year 2025")
})

test_that("enumerate_sped_placement_files returns one row for 2025", {
  files <- enumerate_sped_placement_files(2025L)
  expect_s3_class(files, "tbl_df")
  expect_equal(nrow(files), 1)
  expect_equal(files$end_year, 2025L)
  expect_equal(files$file_label, "consolidated")
  expect_match(files$url, "2025IDEA618PublicReporting", fixed = TRUE)
})

test_that("enumerate_sped_placement_files returns multi-file rows for pre-2025", {
  files_24 <- enumerate_sped_placement_files(2024L)
  expect_true(nrow(files_24) >= 8)
  expect_true(all(c("race", "gender", "disability", "lep") %in%
                    files_24$subgroup_dim))
  expect_true(all(c("5-21", "3-5") %in% files_24$age_group))
  # 2024 should also include state-level placement files
  expect_true(any(files_24$level == "state"))

  files_22 <- enumerate_sped_placement_files(2022L)
  expect_true(nrow(files_22) >= 8)
  expect_match(files_22$url[[1]], "2022%20data", fixed = TRUE)

  files_20 <- enumerate_sped_placement_files(2020L)
  expect_true(nrow(files_20) >= 8)
  # 2020 ships as a zip; zip_member should be populated
  expect_true(all(!is.na(files_20$zip_member)))
  expect_match(files_20$url[[1]], "2019\\.zip$")
})

test_that("fetch_sped_placement rejects unsupported years", {
  expect_error(fetch_sped_placement(1999), "not a valid")
  expect_error(fetch_sped_placement(2019), "not a valid")
  expect_error(fetch_sped_placement(2026), "not a valid")
})

test_that("fetch_sped_placement validates age_group and level", {
  expect_error(
    fetch_sped_placement(2025, age_group = "k-12"),
    "age_group"
  )
  expect_error(
    fetch_sped_placement(2025, level = "school"),
    "level"
  )
})

test_that("pdf_only_slice() identifies the 6 transcribed-CSV slices", {
  # Only state-level pre-2023 combinations route to the bundled PDF CSVs.
  for (yr in c(2020L, 2021L, 2022L)) {
    expect_true(pdf_only_slice(yr, "5-21", "state"))
    expect_true(pdf_only_slice(yr, "3-5", "state"))
    # District-level for the same year is structured data, never PDF.
    expect_false(pdf_only_slice(yr, "5-21", "district"))
    expect_false(pdf_only_slice(yr, "3-5", "district"))
  }
  # 2023 state 5-21 ships as a (typo-named) Excel; 2023 state 3-5 too.
  expect_false(pdf_only_slice(2023L, "5-21", "state"))
  expect_false(pdf_only_slice(2023L, "3-5", "state"))
  # 2024 + 2025 state files are also structured.
  expect_false(pdf_only_slice(2024L, "5-21", "state"))
  expect_false(pdf_only_slice(2025L, "5-21", "state"))
})

test_that("read_transcribed_pdf_slice returns canonical state-level schema", {
  for (yr in c(2020L, 2021L, 2022L)) {
    for (ag in c("5-21", "3-5")) {
      df <- read_transcribed_pdf_slice(yr, ag)
      expect_true(is.data.frame(df))
      expect_true(nrow(df) > 0)
      expected_cols <- c(
        "end_year", "county_id", "county_name",
        "district_id", "district_name",
        "dimension", "subgroup", "environment",
        "count", "percent", "subgroup_total",
        "is_state", "is_district", "is_charter"
      )
      expect_true(all(expected_cols %in% names(df)))
      expect_equal(unique(df$end_year), yr)
      expect_true(all(df$is_state))
      expect_false(any(df$is_district))
      expect_false(any(df$is_charter))
      expect_equal(unique(df$district_name), "New Jersey")
    }
  }
})

test_that("each transcribed-PDF CSV has a sibling _source.json audit trail", {
  # We deliberately avoid a JSON dependency by checking required tokens
  # via regex; the actual JSON is also human-readable for auditors.
  for (yr in c(2020L, 2021L, 2022L)) {
    for (ag in c("5-21", "3-5")) {
      json <- system.file(
        "extdata", "sped-placement-pdf-transcribed",
        sprintf("%d_%s_state_source.json", yr, ag),
        package = "njschooldata"
      )
      expect_true(nzchar(json) && file.exists(json),
                  info = sprintf("missing source JSON for %d %s", yr, ag))
      txt <- paste(readLines(json, warn = FALSE), collapse = "\n")
      expect_match(txt, sprintf('"end_year"[[:space:]]*:[[:space:]]*%d', yr))
      expect_match(txt, sprintf('"age_group"[[:space:]]*:[[:space:]]*"%s"', ag))
      expect_match(txt, '"level"[[:space:]]*:[[:space:]]*"state"')
      expect_match(txt, '"pdf_sha256"[[:space:]]*:[[:space:]]*"[0-9a-f]{64}"')
      expect_match(txt, '"pdf_url"[[:space:]]*:[[:space:]]*"https?://')
    }
  }
})

test_that("standardize_sped_placement_subgroups normalizes NJ labels", {
  input <- c(
    "Districtwide",
    "Black or African American",
    "Black", # 2020 variant
    "Hispanic",
    "Hispanic/Latino", # 2022+ state file variant
    "Native Hawaiian or Pacific Islander",
    "Two or More Races",
    "Two or More", # 2020 variant
    "Multilingual Learner",
    "Non-Multilingual Learner",
    "English Learner",
    "Non-Englishh Learner", # 2020 typo
    "Autism",
    "Deaf-Blindness",
    "Deaf Blindness", # 2022+ variant
    "Deaf- Blindness", # 2020/2021 3-5 variant
    "Hearing impairment", # 2021+ casing
    "Pre-School Disabled", # 2020/2021 3-5 variant
    "Developmental Delay",
    "Speech or Language Impairment"
  )
  expected <- c(
    "total",
    "black",
    "black",
    "hispanic",
    "hispanic",
    "pacific_islander",
    "multiracial",
    "multiracial",
    "lep",
    "non_lep",
    "lep",
    "non_lep",
    "autism",
    "deaf_blindness",
    "deaf_blindness",
    "deaf_blindness",
    "hearing_impairment",
    "preschool_disability",
    "developmental_delay",
    "speech_language_impairment"
  )
  expect_equal(standardize_sped_placement_subgroups(input), expected)
})

test_that("parse_placement_count and parse_placement_pct handle suppression", {
  expect_equal(
    parse_placement_count(c("42", "*", "0", "N")),
    c(42, NA, 0, NA)
  )
  expect_equal(
    parse_placement_pct(c("12.3", "*", "0.0"), scale_to_pct = 1),
    c(12.3, NA, 0)
  )
  expect_equal(
    parse_placement_pct(c("0.123", "*", "1"), scale_to_pct = 100),
    c(12.3, NA, 100)
  )
})


test_that("pick_col returns first matching column or NA", {
  df <- data.frame(a = 1, b = 2, c = 3)
  expect_equal(pick_col(df, c("a", "b")), "a")
  expect_equal(pick_col(df, c("z", "b")), "b")
  expect_true(is.na(pick_col(df, c("z", "q"))))
})


# ------------------------------------------------------------------
# Offline tests: fixture-based parsers (real NJ DOE subsets)
# ------------------------------------------------------------------

# Each fixture is a real subset of a real NJ DOE workbook -- header rows
# preserved, data rows trimmed to a small number of districts. Subsetting
# was done by row-deletion only (no value edits).

fixture_path <- function(name) {
  system.file("extdata", "test-fixtures", "sped-placement", name,
              package = "njschooldata")
}

test_that("tidy_pre2025_district_5_21_one parses 2024 race fixture", {
  fx <- fixture_path("ey2024_5-21_district_race_subset.xlsx")
  skip_if(fx == "" || !file.exists(fx), "Fixture not installed")

  raw <- readxl::read_excel(fx, sheet = 1, col_types = "text", skip = 5)
  raw$end_year <- 2024L
  raw$subgroup_dim <- "race"
  raw$age_group <- "5-21"
  raw$source_file <- basename(fx)

  out <- tidy_pre2025_district_5_21_one(raw, "race")
  expect_s3_class(out, "tbl_df")
  expect_true(nrow(out) > 0)
  expect_true(all(c(
    "end_year", "county_id", "county_name",
    "district_id", "district_name",
    "subgroup", "environment",
    "count", "percent", "subgroup_total",
    "is_state", "is_district", "is_charter"
  ) %in% names(out)))
  expect_true(all(out$is_district))
  expect_true("white" %in% out$subgroup)
  expect_true("hispanic" %in% out$subgroup)
  # Pre-2025 district 5-21 files publish counts only -- percent should be NA.
  expect_true(all(is.na(out$percent)))
  expect_true(all(out$end_year == 2024L))
})

test_that("tidy_pre2025_district_5_21_one expands 2020 disability codes", {
  fx <- fixture_path("ey2020_5-21_district_disability_subset.xlsx")
  skip_if(fx == "" || !file.exists(fx), "Fixture not installed")

  raw <- readxl::read_excel(fx, sheet = 1, col_types = "text", skip = 5)
  raw$end_year <- 2020L
  raw$subgroup_dim <- "disability"
  raw$age_group <- "5-21"
  raw$source_file <- basename(fx)

  out <- tidy_pre2025_district_5_21_one(raw, "disability")
  expect_true(nrow(out) > 0)
  # 2-letter codes (AUT, EMN, ID, MD, ...) should have been expanded to
  # full names and then to snake_case via standardize_sped_placement_subgroups.
  expect_true(any(c("autism", "multiple_disabilities",
                    "intellectual_disability") %in% out$subgroup))
  # No raw 2-letter codes should leak through.
  expect_false(any(c("AUT", "EMN", "ID", "MD") %in% out$subgroup))
})


# ------------------------------------------------------------------
# Network tests: 2025 structure + fidelity (preserves v1 coverage)
# ------------------------------------------------------------------

test_that("fetch_sped_placement (district 5-21) returns expected structure", {
  skip_if_offline()

  df <- tryCatch(fetch_sped_placement(2025), error = function(e) NULL)
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expected_cols <- c(
    "end_year", "county_id", "county_name",
    "district_id", "district_name",
    "subgroup", "environment",
    "count", "percent", "subgroup_total",
    "is_state", "is_district", "is_charter"
  )
  expect_true(all(expected_cols %in% names(df)))
  expect_true(nrow(df) > 0)
  expect_equal(unique(df$end_year), 2025)

  # 8 educational-environment categories for school-age (2025)
  expect_setequal(
    unique(df$environment),
    c(
      "gen_ed_80_plus", "gen_ed_40_79", "gen_ed_less_40",
      "separate_school", "residential_facility",
      "homebound_hospital", "correction_facility",
      "parentally_placed_nonpublic"
    )
  )

  expect_true(all(
    c("total", "black", "hispanic", "lep", "male", "female")
      %in% df$subgroup
  ))

  expect_false(any("Districtwide" %in% df$subgroup))
  expect_false(any("Multilingual Learner" %in% df$subgroup))
})


test_that("fetch_sped_placement entity flags are coherent", {
  skip_if_offline()
  df <- tryCatch(fetch_sped_placement(2025), error = function(e) NULL)
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_true(all(df$is_district))
  expect_false(any(df$is_state))
  expect_true(all(df$is_charter == (df$county_id == "80")))
})


test_that("fetch_sped_placement counts sum to subgroup_total (fidelity)", {
  skip_if_offline()
  df <- tryCatch(fetch_sped_placement(2025), error = function(e) NULL)
  skip_if(is.null(df), "SPED placement workbook not accessible")

  newark <- df[
    df$district_name == "Newark Public School District" &
      df$subgroup == "total",
  ]
  skip_if(nrow(newark) == 0, "Newark not present in workbook")
  total <- unique(newark$subgroup_total)
  visible_sum <- sum(newark$count, na.rm = TRUE)
  n_suppressed <- sum(is.na(newark$count))
  expect_true(visible_sum <= total)
  expect_true(visible_sum >= total - 9 * n_suppressed)
})


test_that("fetch_sped_placement(tidy=FALSE) returns raw workbook tibble", {
  skip_if_offline()
  raw <- tryCatch(
    fetch_sped_placement(2025, tidy = FALSE),
    error = function(e) NULL
  )
  skip_if(is.null(raw), "SPED placement workbook not accessible")

  expect_true("County Code" %in% names(raw))
  expect_true("Student Group" %in% names(raw))
  expect_true(
    "In General Education for 80% or More of the Day Count" %in% names(raw)
  )
})


test_that("fetch_sped_placement (state 5-21) returns 5 dimension breakdowns", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2025, level = "state"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_setequal(
    unique(df$dimension),
    c("age", "disability", "racial_ethnic", "gender", "multilingual_learner")
  )
  expect_true(all(df$is_state))
  expect_false(any(df$is_district))
})


test_that("state 5-21: counts within a subgroup sum to subgroup_total", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2025, level = "state"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  asian <- df[df$dimension == "racial_ethnic" & df$subgroup == "asian", ]
  skip_if(nrow(asian) == 0, "Asian subgroup missing from state sheet")
  expect_equal(
    sum(asian$count, na.rm = TRUE),
    unique(asian$subgroup_total)
  )
})


test_that("fetch_sped_placement (district 3-5) returns districtwide totals", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2025, age_group = "3-5", level = "district"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_true(all(df$environment == "districtwide"))
  expect_true(all(df$is_district))
})


test_that("fetch_sped_placement (state 3-5) uses preschool environments", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2025, age_group = "3-5", level = "state"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_true("ec_program_10plus_hrs" %in% df$environment)
  expect_true("separate_class" %in% df$environment)
  expect_false("gen_ed_80_plus" %in% df$environment)
})


# ------------------------------------------------------------------
# Network tests: pre-2025 coverage
# ------------------------------------------------------------------

test_that("fetch_sped_placement (2024 district 5-21) returns canonical schema", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2024, age_group = "5-21", level = "district"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  # Same columns as 2025
  expected_cols <- c(
    "end_year", "county_id", "county_name",
    "district_id", "district_name",
    "subgroup", "environment",
    "count", "percent", "subgroup_total",
    "is_state", "is_district", "is_charter"
  )
  expect_true(all(expected_cols %in% names(df)))
  expect_true(nrow(df) > 0)
  expect_equal(unique(df$end_year), 2024)

  # Pre-2025 files publish counts only -> percent is NA
  expect_true(all(is.na(df$percent)))

  # Standardized subgroup labels present
  expect_true(all(c("white", "black", "hispanic", "lep", "male", "female") %in%
                    df$subgroup))
})


test_that("2024 schema matches 2025 schema", {
  skip_if_offline()
  df24 <- tryCatch(fetch_sped_placement(2024), error = function(e) NULL)
  df25 <- tryCatch(fetch_sped_placement(2025), error = function(e) NULL)
  skip_if(is.null(df24) || is.null(df25), "Network or workbook unavailable")
  expect_equal(sort(names(df24)), sort(names(df25)))
})


test_that("fetch_sped_placement (2022 district 5-21) parses race subgroups", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2022, age_group = "5-21", level = "district"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_true(nrow(df) > 0)
  expect_equal(unique(df$end_year), 2022)
  expect_true("white" %in% df$subgroup)
  expect_true("hispanic" %in% df$subgroup)
})


test_that("fetch_sped_placement (2020 district 5-21) expands abbrev codes", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2020, age_group = "5-21", level = "district"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_true(nrow(df) > 0)
  expect_equal(unique(df$end_year), 2020)
  # 2020 disability uses AUT/EMN/ID/MD/... abbreviation codes; verify they
  # were expanded and standardized.
  expect_true(any(c("autism", "intellectual_disability",
                    "multiple_disabilities") %in% df$subgroup))
  expect_false(any(c("AUT", "EMN", "ID", "MD") %in% df$subgroup))
})


test_that("fetch_sped_placement (2021 district 3-5) returns districtwide totals", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2021, age_group = "3-5", level = "district"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_true(nrow(df) > 0)
  expect_true(all(df$environment == "districtwide"))
  expect_equal(unique(df$end_year), 2021)
})


test_that("fetch_sped_placement (2024 state 5-21) parses 4 dimensions", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2024, age_group = "5-21", level = "state"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_true(all(df$is_state))
  expect_true(all(c("racial_ethnic", "gender", "disability",
                    "multilingual_learner") %in% df$dimension))
  # State row gets New Jersey label
  expect_true(all(df$district_name == "New Jersey"))
})


test_that("2024 state 5-21 fidelity: env counts sum to subgroup_total", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2024, age_group = "5-21", level = "state"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  asian <- df[df$dimension == "racial_ethnic" & df$subgroup == "asian", ]
  skip_if(nrow(asian) == 0, "Asian subgroup missing from state file")
  total <- unique(asian$subgroup_total)
  visible_sum <- sum(asian$count, na.rm = TRUE)
  n_suppressed <- sum(is.na(asian$count))
  # Some suppression possible; allow tolerance.
  expect_true(visible_sum <= total)
  expect_true(visible_sum >= total - 9 * n_suppressed)
})


test_that("2022 district 5-21 fidelity: env counts <= subgroup_total", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2022, age_group = "5-21", level = "district"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  # For one large district + total-equivalent subgroup, the env counts
  # should sum to the subgroup_total (which is itself the env-count sum,
  # so this is a self-consistency check).
  newark <- df[df$district_name %in%
                 c("Newark Public School District",
                   "NEWARK PUBLIC SCHOOL DISTRICT",
                   "Newark Public Schools District") &
                 df$subgroup == "white", ]
  skip_if(nrow(newark) == 0,
          "Newark white subgroup not present in 2022 workbook")
  total <- unique(newark$subgroup_total)
  visible_sum <- sum(newark$count, na.rm = TRUE)
  expect_equal(visible_sum, total)
})


test_that("fetch_sped_placement_multi binds years and skips bad ones", {
  skip_if_offline()
  df <- suppressWarnings(
    tryCatch(
      fetch_sped_placement_multi(c(1999L, 2025L)),
      error = function(e) NULL
    )
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_true(nrow(df) > 0)
  expect_equal(unique(df$end_year), 2025)
})


# ------------------------------------------------------------------
# 2021 district 5-21 (Plan 1: the previously-blocked slice that is
# actually published as Excel inside docs/2020.zip)
# ------------------------------------------------------------------

test_that("fetch_sped_placement (2021 district 5-21) returns canonical schema", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2021, age_group = "5-21", level = "district"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_true(nrow(df) > 0)
  expect_equal(unique(df$end_year), 2021)
  expect_true(all(df$is_district))
  expect_false(any(df$is_state))
  # Pre-2025 district 5-21 files publish counts only -> percent is NA
  expect_true(all(is.na(df$percent)))
  # 2021 uses same 2-letter disability codes as 2020 -- verify expansion
  expect_true(any(c("autism", "specific_learning_disability") %in% df$subgroup))
  expect_false(any(c("AUT", "SLD") %in% df$subgroup))
})


test_that("fetch_sped_placement_multi(2020:2025) contains 2021/5-21 district rows", {
  skip_if_offline()
  df <- suppressWarnings(
    tryCatch(
      fetch_sped_placement_multi(2020:2025,
                                 age_group = "5-21", level = "district"),
      error = function(e) NULL
    )
  )
  skip_if(is.null(df), "SPED placement workbook(s) not accessible")

  expect_true(any(df$end_year == 2021))
  # Every year between 2020 and 2025 should be represented (no Excel gap)
  expect_setequal(unique(df$end_year), 2020:2025)
})


# ------------------------------------------------------------------
# Pre-2023 state-level slices: now served from bundled PDF-transcribed
# CSVs (Plan 2 coverage). These are offline tests because the CSVs ship
# with the package -- no network required.
# ------------------------------------------------------------------

test_that("PDF-sourced state slices return non-empty data (no network)", {
  for (yr in c(2020L, 2021L, 2022L)) {
    for (ag in c("5-21", "3-5")) {
      label <- sprintf("%d %s", yr, ag)
      df <- fetch_sped_placement(yr, age_group = ag, level = "state")
      expect_true(nrow(df) > 0, label = label)
      expect_true(all(df$is_state), label = label)
      expect_equal(unique(df$end_year), yr, label = label)
      expect_setequal(
        unique(df$dimension),
        c("racial_ethnic", "gender", "disability", "multilingual_learner")
      )
    }
  }
})


test_that("transcribed PDF slices: env counts <= subgroup_total (fidelity)", {
  # Pick the cleanest, anomaly-free slice (2022 5-21) and verify White
  # row's visible env counts sum exactly to subgroup_total.
  df <- fetch_sped_placement(2022, age_group = "5-21", level = "state")
  white <- df[df$dimension == "racial_ethnic" & df$subgroup == "white", ]
  expect_true(nrow(white) > 0)
  visible_sum <- sum(white$count, na.rm = TRUE)
  total <- unique(white$subgroup_total)
  expect_equal(visible_sum, total)
})


test_that("fetch_sped_placement(tidy=FALSE) on PDF slice returns tidy schema", {
  # PDF-sourced slices have no "raw" representation, so tidy=FALSE returns
  # the same canonical schema as tidy=TRUE.
  raw <- fetch_sped_placement(2020, age_group = "5-21", level = "state",
                              tidy = FALSE)
  tidy <- fetch_sped_placement(2020, age_group = "5-21", level = "state",
                               tidy = TRUE)
  expect_equal(names(raw), names(tidy))
  expect_equal(nrow(raw), nrow(tidy))
})


# ------------------------------------------------------------------
# 2023 state 5-21 Excel (now wired via the typo-named NJ DOE file)
# ------------------------------------------------------------------

test_that("fetch_sped_placement (2023 state 5-21) parses typo-named Excel", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2023, age_group = "5-21", level = "state"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_true(nrow(df) > 0)
  expect_true(all(df$is_state))
  expect_equal(unique(df$end_year), 2023)
  expect_true(all(c("racial_ethnic", "gender", "disability",
                    "multilingual_learner") %in% df$dimension))
  # Spot check: White gen_ed_80_plus = 50750 per the source workbook.
  white80 <- df[df$dimension == "racial_ethnic" &
                  df$subgroup == "white" &
                  df$environment == "gen_ed_80_plus", ]
  expect_equal(nrow(white80), 1)
  expect_equal(white80$count, 50750)
})


test_that("fetch_sped_placement_multi covers 2020-2022 district 5-21 without gaps", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement_multi(c(2020L, 2021L, 2022L)),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  # All three years now present; 2021 is no longer short-circuited (the
  # district-level data was always available inside docs/2020.zip; the
  # state-level rollup ships from the bundled PDF-transcribed CSV).
  expect_setequal(unique(df$end_year), c(2020L, 2021L, 2022L))
})
