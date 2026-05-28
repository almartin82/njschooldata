# ==============================================================================
# Tests for fetch_police_notifications_detail() and fetch_arrests()
# ==============================================================================
#
# Live-network tests for the SPR detail (StudentGroup x Grade) sheets:
#
#   fetch_police_notifications_detail()
#     2024: PoliceNotificationByStuGroup
#     2025: PoliceNotificationsGroupGrade
#
#   fetch_arrests()
#     2024: StuArrestbyStudentGroupGradelev
#     2025: ArrestsStudentGroupGrade
#
# Both detail sheets first appear in end_year 2024 (the SY2023-24 SPR redesign);
# they are absent from every SPR workbook 2017-2023. Each row reports counts /
# percents for ONE entity x ONE label, where the label is either a subgroup
# (e.g. "Asian", "Female", "Economically Disadvantaged Students") OR a grade
# (e.g. "Grade 9", "Grade KG"). The fetchers split the raw combined column
# into a normalized `subgroup` + `grade_level` pair so downstream code can
# filter cleanly.
#
# Pinned values are verified against the published NJ DOE SPR workbooks at:
#   https://www.nj.gov/education/sprreports/download/DataFiles/
#
# ==============================================================================

spr_detail_cols <- c(
  "end_year",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name",
  "is_state", "is_county", "is_district", "is_school",
  "is_charter", "is_charter_sector", "is_allpublic"
)

# Standard project subgroup labels, post spr_split_student_group_grade
# normalization. clean_spr_subgroups() covers the bulk; the split helper
# additionally normalizes a few 2024-25 redesign labels to project standard
# (hispanic/latino -> hispanic, etc.).
expected_subgroup_labels <- c(
  "total population",
  "american indian",
  "asian",
  "asian or pacific islander",   # 2025 "Asian, Native Hawaiian, or Pacific Islander"
  "black",
  "economically disadvantaged",
  "female",
  "hispanic",                    # 2024 "Hispanic" + 2025 "Hispanic/Latino"
  "male",
  "non-binary",                  # 2024/2025 "Non-Binary/Undesignated Gender"
  "pacific islander",
  "students with disabilities",
  "multiracial",
  "white"
)

# Standard project grade labels (uppercase PK / K / 01-12 / TOTAL)
expected_grade_labels <- c(
  "TOTAL",
  "PK", "K",
  "01", "02", "03", "04", "05", "06",
  "07", "08", "09", "10", "11", "12"
)

# The 2024-25 School DB is ~352 MB and the District DB ~114 MB; raise R's
# default 60s download timeout for the calling test.
local_big_download_timeout <- function(seconds = 1200, env = parent.frame()) {
  old <- getOption("timeout")
  options(timeout = seconds)
  withr::defer(options(timeout = old), envir = env)
  invisible(old)
}


# ==============================================================================
# Argument validation (no network)
# ==============================================================================

test_that("fetch_police_notifications_detail rejects pre-2024 years", {
  # The GroupGrade police-notifications sheet first appears in SY2023-24 (end_year
  # 2024). Earlier SPR workbooks have only the aggregate PoliceNotifications.
  expect_error(fetch_police_notifications_detail(2017), "end_year >= 2024")
  expect_error(fetch_police_notifications_detail(2023), "end_year >= 2024")
})

test_that("fetch_arrests rejects pre-2024 years", {
  # The arrests sheet first appears in SY2023-24 (end_year 2024); earlier SPR
  # workbooks do not separate arrests from police notifications.
  expect_error(fetch_arrests(2017), "end_year >= 2024")
  expect_error(fetch_arrests(2023), "end_year >= 2024")
})

test_that("fetch_police_notifications_detail rejects invalid level", {
  expect_error(
    fetch_police_notifications_detail(2024, level = "invalid"),
    "level must be one of 'school' or 'district'"
  )
})

test_that("fetch_arrests rejects invalid level", {
  expect_error(
    fetch_arrests(2024, level = "invalid"),
    "level must be one of 'school' or 'district'"
  )
})

test_that("fetch_police_notifications_detail default level is 'school'", {
  # Argument default check (no network call needed if we trust formals()).
  expect_equal(formals(fetch_police_notifications_detail)$level, "school")
})

test_that("fetch_arrests default level is 'school'", {
  expect_equal(formals(fetch_arrests)$level, "school")
})


# ==============================================================================
# fetch_police_notifications_detail() — structure / schema
# ==============================================================================

test_that("fetch_police_notifications_detail returns expected structure (district, 2025)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_police_notifications_detail(2025, level = "district")

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(spr_detail_cols %in% names(df)))

  # The seven police-notification count columns (police_count + six categories).
  expect_true(all(c(
    "police_count", "violent_count", "vandalism_count", "substance_count",
    "weapons_count", "hibcount", "other_count"
  ) %in% names(df)))

  # The matching percent columns.
  expect_true(all(c(
    "police_percent", "violent_percent", "vandalism_percent",
    "substance_percent", "weapons_percent", "hibpercent", "other_percent"
  ) %in% names(df)))

  # Derived normalized columns.
  expect_true("subgroup" %in% names(df))
  expect_true("grade_level" %in% names(df))
  # The raw combined column is preserved for traceability.
  expect_true("student_group_grade" %in% names(df))

  # Counts must be numeric (suppression -> NA, real counts preserved).
  for (col in c("police_count", "violent_count", "vandalism_count",
                "substance_count", "weapons_count", "hibcount",
                "other_count")) {
    expect_type(df[[col]], "double")
    vals <- df[[col]][!is.na(df[[col]])]
    expect_true(all(vals >= 0), info = paste("negative values in", col))
  }
})

test_that("fetch_police_notifications_detail derived subgroup labels are project-standard (2025)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_police_notifications_detail(2025, level = "district")

  # Every subgroup label must be a recognized project standard.
  observed_sub <- unique(df$subgroup[!is.na(df$subgroup)])
  unknown_sub <- setdiff(observed_sub, expected_subgroup_labels)
  expect_equal(unknown_sub, character(0),
               info = paste("unexpected subgroup labels:",
                            paste(unknown_sub, collapse = ", ")))

  # Every grade label must be a recognized project standard.
  observed_grade <- unique(df$grade_level[!is.na(df$grade_level)])
  unknown_grade <- setdiff(observed_grade, expected_grade_labels)
  expect_equal(unknown_grade, character(0),
               info = paste("unexpected grade labels:",
                            paste(unknown_grade, collapse = ", ")))

  # Every row must have BOTH subgroup and grade_level populated:
  #  - subgroup rows: subgroup = <demographic>, grade_level = "TOTAL"
  #  - grade rows:    subgroup = "total population", grade_level = "PK".."12"
  expect_true(all(!is.na(df$subgroup)))
  expect_true(all(!is.na(df$grade_level)))

  # At least one "total population" row (the All-Students / Statewide /
  # Districtwide marginal) and at least one grade row must be present.
  expect_gt(sum(df$subgroup == "total population" & df$grade_level == "TOTAL"), 0)
  expect_gt(sum(df$grade_level %in% c("PK", "K", "09", "12")), 0)
})

test_that("fetch_police_notifications_detail district file has state, county, and district rows (2025)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_police_notifications_detail(2025, level = "district")

  # Many state-level rows (one per subgroup + one per grade).
  expect_gt(sum(df$is_state), 20)
  # Many district rows.
  expect_gt(sum(df$is_district), 1000)
  # District file: school_id is always "999" (the District-Total sentinel).
  expect_true(all(df$school_id == "999"))
})

test_that("fetch_police_notifications_detail preserves school_year on 2025 (redesign)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_police_notifications_detail(2025, level = "district")
  expect_true("school_year" %in% names(df))
  expect_true(all(df$school_year == "2024-25"))
})


# ==============================================================================
# fetch_police_notifications_detail() — year aliasing (2024 legacy)
# ==============================================================================

test_that("fetch_police_notifications_detail 2024 legacy sheet alias parses to same shape", {
  # 2024 SPR uses the legacy name PoliceNotificationByStuGroup; 2025 uses
  # PoliceNotificationsGroupGrade. Both must route through the same fetcher
  # and emit the same canonical column set.
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df24 <- fetch_police_notifications_detail(2024, level = "district")
  df25 <- fetch_police_notifications_detail(2025, level = "district")

  # Canonical count columns must exist in BOTH years.
  canonical_counts <- c("police_count", "violent_count", "vandalism_count",
                        "substance_count", "weapons_count", "hibcount",
                        "other_count")
  expect_true(all(canonical_counts %in% names(df24)))
  expect_true(all(canonical_counts %in% names(df25)))

  # spr_detail_cols + subgroup + grade_level must appear in both.
  expect_true(all(c(spr_detail_cols, "subgroup", "grade_level") %in% names(df24)))
  expect_true(all(c(spr_detail_cols, "subgroup", "grade_level") %in% names(df25)))

  # 2024 has no school_year column; 2025 does.
  expect_false("school_year" %in% names(df24))
  expect_true("school_year" %in% names(df25))

  expect_true(all(df24$end_year == 2024))
  expect_true(all(df25$end_year == 2025))
})


# ==============================================================================
# fetch_police_notifications_detail() — pinned correctness (Atlantic City, 2024)
# ==============================================================================

test_that("fetch_police_notifications_detail pinned values match NJ DOE workbook (Atlantic City, 2024)", {
  # Pinned against PoliceNotificationByStuGroup, District/State workbook SY2023-24,
  # Atlantic City School District (county 01, district 0110), district-total row.
  # Values transcribed directly from the published workbook.
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  ac <- fetch_police_notifications_detail(2024, level = "district") %>%
    dplyr::filter(county_id == "01", district_id == "0110", is_district)

  # "Districtwide" row (the entity-total, normalized to subgroup = "total population",
  # grade_level = "TOTAL").
  dist_total <- ac %>%
    dplyr::filter(subgroup == "total population", grade_level == "TOTAL")
  expect_equal(nrow(dist_total), 1)
  expect_equal(dist_total$police_count, 34)
  expect_equal(dist_total$violent_count, 18)
  expect_equal(dist_total$hibcount, 1)

  # "Black or African American" subgroup row.
  black <- ac %>% dplyr::filter(subgroup == "black", grade_level == "TOTAL")
  expect_equal(nrow(black), 1)
  expect_equal(black$police_count, 21)
  expect_equal(black$violent_count, 14)

  # "Grade 7" row (subgroup = "total population", grade_level = "07").
  g7 <- ac %>% dplyr::filter(grade_level == "07")
  expect_equal(nrow(g7), 1)
  expect_equal(g7$police_count, 7)
  expect_equal(g7$violent_count, 5)

  # Suppression token "<5" must become NA (the hibcount column).
  asian_sub <- ac %>% dplyr::filter(subgroup == "asian", grade_level == "TOTAL")
  expect_true(is.na(asian_sub$hibcount))
})


# ==============================================================================
# fetch_arrests() — structure / schema
# ==============================================================================

test_that("fetch_arrests returns expected structure (district, 2024)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_arrests(2024, level = "district")

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(spr_detail_cols %in% names(df)))

  # The canonical arrest column set: arrested_count + six categories.
  canonical_arrest_counts <- c(
    "arrested_count", "arrested_violent_count", "arrested_vandalism_count",
    "arrested_substance_count", "arrested_weapons_count",
    "arrested_hibcount", "arrested_other_count"
  )
  expect_true(all(canonical_arrest_counts %in% names(df)))

  # Derived normalized columns.
  expect_true("subgroup" %in% names(df))
  expect_true("grade_level" %in% names(df))
  expect_true("student_group_grade" %in% names(df))

  # Counts must be numeric and non-negative.
  for (col in canonical_arrest_counts) {
    expect_type(df[[col]], "double")
    vals <- df[[col]][!is.na(df[[col]])]
    expect_true(all(vals >= 0), info = paste("negative values in", col))
  }
})

test_that("fetch_arrests 2025 column rename: NJ DOE mislabeled police_* -> arrested_*", {
  # The 2025 ArrestsStudentGroupGrade sheet ships with column headers
  # police_count / violent_count / etc. (a copy-paste from the Police
  # Notifications sheet). The actual values are arrest counts. The fetcher
  # renames police_* -> arrested_* for SY2024-25 so the public API is
  # consistent with the 2024 SY2023-24 sheet (which uses arrested_* natively).
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_arrests(2025, level = "district")

  # arrested_* must be present (post-rename).
  expect_true("arrested_count" %in% names(df))
  expect_true("arrested_violent_count" %in% names(df))
  # The police_* aliases must NOT leak through.
  expect_false("police_count" %in% names(df))
  expect_false("violent_count" %in% names(df))
})

test_that("fetch_arrests 2024 vs 2025 emit the same canonical column set", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df24 <- fetch_arrests(2024, level = "district")
  df25 <- fetch_arrests(2025, level = "district")

  canonical_arrest_counts <- c(
    "arrested_count", "arrested_violent_count", "arrested_vandalism_count",
    "arrested_substance_count", "arrested_weapons_count",
    "arrested_hibcount", "arrested_other_count"
  )
  expect_true(all(canonical_arrest_counts %in% names(df24)))
  expect_true(all(canonical_arrest_counts %in% names(df25)))
  expect_true(all(c(spr_detail_cols, "subgroup", "grade_level") %in% names(df24)))
  expect_true(all(c(spr_detail_cols, "subgroup", "grade_level") %in% names(df25)))

  # 2024 has no school_year; 2025 does.
  expect_false("school_year" %in% names(df24))
  expect_true("school_year" %in% names(df25))
  expect_true(all(df24$end_year == 2024))
  expect_true(all(df25$end_year == 2025))
})


# ==============================================================================
# fetch_arrests() — pinned correctness (Atlantic City, 2024)
# ==============================================================================

test_that("fetch_arrests pinned values match NJ DOE workbook (Atlantic City, 2024)", {
  # Pinned against StuArrestbyStudentGroupGradelev, District/State workbook
  # SY2023-24, Atlantic City School District (county 01, district 0110),
  # district-total row.
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  ac <- fetch_arrests(2024, level = "district") %>%
    dplyr::filter(county_id == "01", district_id == "0110", is_district)

  dist_total <- ac %>%
    dplyr::filter(subgroup == "total population", grade_level == "TOTAL")
  expect_equal(nrow(dist_total), 1)
  expect_equal(dist_total$arrested_count, 8)
  expect_equal(dist_total$arrested_violent_count, 6)

  black <- ac %>% dplyr::filter(subgroup == "black", grade_level == "TOTAL")
  expect_equal(nrow(black), 1)
  expect_equal(black$arrested_count, 7)
  expect_equal(black$arrested_violent_count, 6)

  # A grade row: Grade 11 had 2 arrests / 1 violent.
  g11 <- ac %>% dplyr::filter(grade_level == "11")
  expect_equal(nrow(g11), 1)
  expect_equal(g11$arrested_count, 2)
})


# ==============================================================================
# Reconciliation: grade-row totals are close to entity-total
# ==============================================================================

test_that("fetch_police_notifications_detail sum-of-grade-rows reconciles to entity-total (state, 2025)", {
  # For the state row, summing police_count across all grade rows should fall
  # within 5% of the entity-total ("total population" / "TOTAL") row. Small-cell
  # suppression at small grades can drop a few cases, so this is a loose
  # tolerance band rather than exact equality.
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_police_notifications_detail(2025, level = "district") %>%
    dplyr::filter(is_state)

  total_row <- df %>%
    dplyr::filter(subgroup == "total population", grade_level == "TOTAL")
  expect_equal(nrow(total_row), 1)
  entity_total <- total_row$police_count

  grade_sum <- df %>%
    dplyr::filter(grade_level %in% c("PK", "K", sprintf("%02d", 1:12))) %>%
    dplyr::pull(police_count) %>%
    sum(na.rm = TRUE)

  expect_gt(grade_sum, 0)
  rel_diff <- abs(entity_total - grade_sum) / pmax(entity_total, 1)
  expect_lt(rel_diff, 0.05,
            label = sprintf("entity_total=%d, grade_sum=%d, rel_diff=%.4f",
                            entity_total, grade_sum, rel_diff))
})

test_that("fetch_arrests sum-of-grade-rows reconciles to entity-total (state, 2025)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_arrests(2025, level = "district") %>%
    dplyr::filter(is_state)

  total_row <- df %>%
    dplyr::filter(subgroup == "total population", grade_level == "TOTAL")
  expect_equal(nrow(total_row), 1)
  entity_total <- total_row$arrested_count

  grade_sum <- df %>%
    dplyr::filter(grade_level %in% c("PK", "K", sprintf("%02d", 1:12))) %>%
    dplyr::pull(arrested_count) %>%
    sum(na.rm = TRUE)

  expect_gt(grade_sum, 0)
  rel_diff <- abs(entity_total - grade_sum) / pmax(entity_total, 1)
  expect_lt(rel_diff, 0.05,
            label = sprintf("entity_total=%d, grade_sum=%d, rel_diff=%.4f",
                            entity_total, grade_sum, rel_diff))
})


# ==============================================================================
# Multi-year smoke (district level only — school DB is 350+ MB)
# ==============================================================================

test_that("fetch_police_notifications_detail works across supported year range", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  for (yr in c(2024, 2025)) {
    df <- fetch_police_notifications_detail(yr, level = "district")
    expect_s3_class(df, "data.frame")
    expect_gt(nrow(df), 0)
    expect_true(all(spr_detail_cols %in% names(df)))
    expect_true("police_count" %in% names(df))
    expect_true("subgroup" %in% names(df))
    expect_true("grade_level" %in% names(df))
    expect_true(all(df$end_year == yr))
  }
})

test_that("fetch_arrests works across supported year range", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  for (yr in c(2024, 2025)) {
    df <- fetch_arrests(yr, level = "district")
    expect_s3_class(df, "data.frame")
    expect_gt(nrow(df), 0)
    expect_true(all(spr_detail_cols %in% names(df)))
    expect_true("arrested_count" %in% names(df))
    expect_true("subgroup" %in% names(df))
    expect_true("grade_level" %in% names(df))
    expect_true(all(df$end_year == yr))
  }
})
