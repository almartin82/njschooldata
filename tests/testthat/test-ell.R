# ==============================================================================
# Tests for fetch_ell() — NJ English Learner population data
# ==============================================================================
#
# The data tests hit the NJ DOE Fall Enrollment files over the network and are
# skipped automatically when the source is unavailable. They double as the LIVE
# pipeline test (URL availability -> download -> parse -> schema -> quality ->
# aggregation -> fidelity -> pinned values).
# ==============================================================================

# canonical tidy contract column order
ell_cols <- c(
  "end_year",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name",
  "cds_code", "nces_dist", "nces_sch",
  "is_state", "is_district", "is_school", "is_charter",
  "grade_level", "el_status", "subgroup",
  "n_students", "total_enrollment", "pct_of_enrollment",
  "n_students_lower", "n_students_upper"
)

# fetch a count-complete year and a percent-only year once; reuse across tests.
ell_2025 <- tryCatch(suppressWarnings(fetch_ell(2025)), error = function(e) NULL)
ell_2015 <- tryCatch(suppressWarnings(fetch_ell(2015)), error = function(e) NULL)
ell_2021 <- tryCatch(suppressWarnings(fetch_ell(2021)), error = function(e) NULL)
have_2025 <- !is.null(ell_2025) && nrow(ell_2025) > 0
have_2015 <- !is.null(ell_2015) && nrow(ell_2015) > 0
have_2021 <- !is.null(ell_2021) && nrow(ell_2021) > 0


# ------------------------------------------------------------------------------
# Offline tests (no network)
# ------------------------------------------------------------------------------

test_that("get_available_ell_years returns a sane integer range", {
  yrs <- get_available_ell_years()
  expect_true(is.integer(yrs))
  expect_true(2006 %in% yrs)
  expect_true(2025 %in% yrs)
  expect_equal(min(yrs), 2006)
  expect_false(2005 %in% yrs)
})

test_that("an out-of-range year returns the empty, correctly-typed tidy frame", {
  e <- fetch_ell(2005)
  expect_equal(names(e), ell_cols)
  expect_equal(nrow(e), 0L)
  expect_type(e$n_students, "double")
  expect_type(e$pct_of_enrollment, "double")
  expect_type(e$district_id, "character")
  expect_type(e$is_state, "logical")
})

test_that("ell_locate_cols handles the EL/MLL rename and percent spacing", {
  modern <- ell_locate_cols(c("Total Enrollment", "Multilingual Learners",
                              "%Multilingual Learners"))
  expect_equal(modern$count, "Multilingual Learners")
  expect_equal(modern$pct, "%Multilingual Learners")

  legacy <- ell_locate_cols(c("English Learners", "% English Learners"))
  expect_equal(legacy$count, "English Learners")
  expect_equal(legacy$pct, "% English Learners")

  pct_only <- ell_locate_cols(c("Total Enrollment", "%English Learners"))
  expect_true(is.na(pct_only$count))
  expect_equal(pct_only$pct, "%English Learners")
})


# ------------------------------------------------------------------------------
# Schema
# ------------------------------------------------------------------------------

test_that("fetch_ell emits exactly the canonical columns in order", {
  skip_if_not(have_2025, "NJ DOE enrollment source unavailable")
  expect_equal(names(ell_2025), ell_cols)
})

test_that("el_status and subgroup carry the documented constant values", {
  skip_if_not(have_2025, "NJ DOE enrollment source unavailable")
  expect_equal(unique(ell_2025$el_status), "current")
  expect_equal(unique(ell_2025$subgroup), "total")
  expect_equal(unique(ell_2025$grade_level), "TOTAL")
})

test_that("entity flags are mutually exclusive and cover every row", {
  skip_if_not(have_2025, "NJ DOE enrollment source unavailable")
  flagsum <- ell_2025$is_state + ell_2025$is_district + ell_2025$is_school
  expect_true(all(flagsum == 1))
  expect_equal(sum(ell_2025$is_state), 1L)
})


# ------------------------------------------------------------------------------
# Data quality
# ------------------------------------------------------------------------------

test_that("counts and percentages are finite and non-negative", {
  skip_if_not(have_2025, "NJ DOE enrollment source unavailable")
  n <- ell_2025$n_students[!is.na(ell_2025$n_students)]
  expect_true(all(is.finite(n)))
  expect_true(all(n >= 0))

  p <- ell_2025$pct_of_enrollment[!is.na(ell_2025$pct_of_enrollment)]
  expect_true(all(is.finite(p)))
  expect_true(all(p >= 0 & p <= 100))
})

test_that("no duplicate rows per entity x el_status x subgroup", {
  skip_if_not(have_2025, "NJ DOE enrollment source unavailable")
  dupes <- ell_2025 %>%
    dplyr::count(cds_code, el_status, subgroup, grade_level) %>%
    dplyr::filter(n > 1)
  expect_equal(nrow(dupes), 0L)
})

test_that("suppression bounds equal the point value (NJ does not suppress EL)", {
  skip_if_not(have_2025, "NJ DOE enrollment source unavailable")
  has_count <- !is.na(ell_2025$n_students)
  expect_true(all(ell_2025$n_students_lower[has_count] == ell_2025$n_students[has_count]))
  expect_true(all(ell_2025$n_students_upper[has_count] == ell_2025$n_students[has_count]))
  # where the count is NA (percent-only years), the bounds are NA too
  expect_true(all(is.na(ell_2025$n_students_lower[!has_count])))
})


# ------------------------------------------------------------------------------
# Aggregation + fidelity
# ------------------------------------------------------------------------------

test_that("state EL count equals the sum of district counts (count-complete year)", {
  skip_if_not(have_2025, "NJ DOE enrollment source unavailable")
  state_n <- ell_2025$n_students[ell_2025$is_state]
  dist_sum <- sum(ell_2025$n_students[ell_2025$is_district], na.rm = TRUE)
  expect_equal(dist_sum, state_n, tolerance = 0.01)
})

test_that("pct_of_enrollment reconciles with count / total enrollment", {
  skip_if_not(have_2025, "NJ DOE enrollment source unavailable")
  d <- ell_2025 %>%
    dplyr::filter(!is.na(n_students), total_enrollment > 0)
  recomputed <- d$n_students / d$total_enrollment * 100
  expect_equal(d$pct_of_enrollment, recomputed, tolerance = 0.01)
})

test_that("EL counts never exceed total enrollment", {
  skip_if_not(have_2025, "NJ DOE enrollment source unavailable")
  d <- ell_2025 %>% dplyr::filter(!is.na(n_students), !is.na(total_enrollment))
  expect_true(all(d$n_students <= d$total_enrollment + 1e-6))
})


# ------------------------------------------------------------------------------
# Percent-only COVID-era years (2020-2022 district/school)
# ------------------------------------------------------------------------------

test_that("2021 publishes a real statewide count but percent-only districts", {
  skip_if_not(have_2021, "NJ DOE enrollment source unavailable")
  st <- ell_2021 %>% dplyr::filter(is_state)
  expect_false(is.na(st$n_students))            # state count is real
  expect_equal(st$n_students, 95059, tolerance = 0.5)
  # district counts are not published for 2021 -> NA, but the share is
  dist <- ell_2021 %>% dplyr::filter(is_district)
  expect_true(all(is.na(dist$n_students)))
  expect_true(all(!is.na(dist$pct_of_enrollment)))
})


# ------------------------------------------------------------------------------
# Pinned real values (trace to published NJ DOE enrollment files)
# ------------------------------------------------------------------------------

test_that("pinned statewide EL counts match the published files", {
  skip_if_not(have_2015 && have_2025, "NJ DOE enrollment source unavailable")
  # 2014-15 file: statewide LEP = 70,119 of 1,369,379 enrolled
  st15 <- ell_2015 %>% dplyr::filter(is_state)
  expect_equal(st15$n_students, 70119, tolerance = 0.5)
  expect_equal(st15$total_enrollment, 1369379, tolerance = 0.5)
  # 2024-25 file: statewide Multilingual Learners = 155,304
  st25 <- ell_2025 %>% dplyr::filter(is_state)
  expect_equal(st25$n_students, 155304, tolerance = 0.5)
})

test_that("pinned district value (Newark, 2024-25) matches the published file", {
  skip_if_not(have_2025, "NJ DOE enrollment source unavailable")
  nwk <- ell_2025 %>% dplyr::filter(district_id == "3570", is_district)
  expect_equal(nrow(nwk), 1L)
  expect_equal(nwk$n_students, 12623, tolerance = 0.5)
  expect_equal(nwk$total_enrollment, 43980, tolerance = 0.5)
})

test_that("fetch_ell_multi binds years and warns on unavailable ones", {
  skip_if_not(have_2025, "NJ DOE enrollment source unavailable")
  expect_warning(
    m <- fetch_ell_multi(c(2004, 2025)),
    "Skipping years"
  )
  expect_true(all(m$end_year == 2025))
})

test_that("tidy = FALSE returns the wide per-entity frame with el_count", {
  skip_if_not(have_2025, "NJ DOE enrollment source unavailable")
  w <- fetch_ell(2025, tidy = FALSE)
  expect_true("el_count" %in% names(w))
  expect_true("el_pct" %in% names(w))
  expect_false("n_students" %in% names(w))
})
