# The SPR source is fetched over the network and disk-cached by fetch_spr_data().
# If the NJ DOE SPR source is unreachable these tests skip; they never fail on a
# network problem.

skip_on_cran()

postsec_probe <- tryCatch(
  list(
    district_2017 = fetch_postsecondary_enrollment(2017, level = "district"),
    district_2019 = fetch_postsecondary_enrollment(2019, level = "district"),
    district_2020 = fetch_postsecondary_enrollment(2020, level = "district"),
    district_2023 = fetch_postsecondary_enrollment(2023, level = "district"),
    school_2019 = fetch_postsecondary_enrollment(2019, level = "school")
  ),
  error = function(e) NULL
)

have_postsec_data <- !is.null(postsec_probe) &&
  all(vapply(postsec_probe, function(x) is.data.frame(x) && nrow(x) > 0, logical(1)))

test_that("district 2019 returns both measurement windows with class years", {
  skip_if_not(have_postsec_data, "NJ DOE SPR source unavailable")

  df <- postsec_probe$district_2019
  districtwide <- df[df$is_district & df$subgroup == "total population", ]

  expect_gt(nrow(districtwide), 300)
  expect_true(all(districtwide$class_year[districtwide$measurement_window == "fall"] == 2019))
  expect_true(all(districtwide$class_year[districtwide$measurement_window == "16_month"] == 2018))
})

test_that("Atlantic City pinned district values match live SPR data", {
  skip_if_not(have_postsec_data, "NJ DOE SPR source unavailable")

  ac_2019 <- postsec_probe$district_2019[
    postsec_probe$district_2019$is_district &
      postsec_probe$district_2019$district_id == "0110" &
      postsec_probe$district_2019$subgroup == "total population",
  ]
  ac_2020 <- postsec_probe$district_2020[
    postsec_probe$district_2020$is_district &
      postsec_probe$district_2020$district_id == "0110" &
      postsec_probe$district_2020$subgroup == "total population",
  ]

  fall_2019 <- ac_2019[ac_2019$measurement_window == "fall", ]
  month16_2019 <- ac_2019[ac_2019$measurement_window == "16_month", ]
  fall_2020 <- ac_2020[ac_2020$measurement_window == "fall", ]
  month16_2020 <- ac_2020[ac_2020$measurement_window == "16_month", ]

  # Exactly ONE district total row per window: the Statewide student-group row
  # must have been promoted to a state-reference row, never left as a second
  # indistinguishable "total population" row under the district.
  expect_identical(nrow(fall_2019), 1L)
  expect_identical(nrow(month16_2019), 1L)

  expect_identical(fall_2019$enrolled_any_lower, 57.1)
  expect_identical(fall_2019$enrolled_any_upper, 57.1)
  expect_identical(fall_2019$value_format, "point")
  expect_identical(month16_2019$class_year, 2018L)
  expect_identical(month16_2019$enrolled_any_lower, 59.1)
  expect_identical(month16_2019$enrolled_any_upper, 59.1)

  expect_identical(month16_2020$class_year, 2019L)
  expect_identical(month16_2020$enrolled_any_lower, 63.5)
  expect_identical(month16_2020$enrolled_any_upper, 63.5)
  expect_identical(fall_2020$class_year, 2020L)
  expect_identical(fall_2020$enrolled_any_lower, 49.9)
  expect_identical(fall_2020$enrolled_any_upper, 49.9)
})

test_that("Statewide student-group rows become deduplicated state-reference rows", {
  skip_if_not(have_postsec_data, "NJ DOE SPR source unavailable")

  df <- postsec_probe$district_2019
  st_fall <- df[df$is_state & df$measurement_window == "fall" &
                  df$subgroup == "total population", ]

  expect_identical(nrow(st_fall), 1L)
  expect_identical(st_fall$enrolled_any_lower, 72)
  expect_true(is.na(st_fall$district_id))
  expect_true(is.na(st_fall$district_name))
  expect_false(any(st_fall$is_district))
})

test_that("2023 district ranges are preserved as lower and upper bounds", {
  skip_if_not(have_postsec_data, "NJ DOE SPR source unavailable")

  districtwide <- postsec_probe$district_2023[
    postsec_probe$district_2023$is_district &
      postsec_probe$district_2023$subgroup == "total population",
  ]
  ranges <- districtwide[districtwide$value_format == "range", ]

  expect_gt(nrow(ranges), 0)
  ranges <- ranges[!is.na(ranges$enrolled_any_lower) & !is.na(ranges$enrolled_any_upper), ]
  expect_true(all(ranges$enrolled_any_lower < ranges$enrolled_any_upper))
})

test_that("2017 legacy column variants map to canonical measures", {
  skip_if_not(have_postsec_data, "NJ DOE SPR source unavailable")

  df <- postsec_probe$district_2017

  expect_true(any(!is.na(df$enrolled_any_lower)))
  expect_true("enrolled_out_of_state_lower" %in% names(df))
  expect_true(any(!is.na(df$enrolled_out_of_state_lower[df$measurement_window == "16_month"])))
  expect_true(all(is.na(df$county_name)))
  expect_true(all(is.na(df$district_name)))
})

test_that("2024 and 2025 explain upstream postsecondary enrollment gaps", {
  expect_error(
    fetch_postsecondary_enrollment(2024),
    "zero data rows"
  )
  expect_error(
    fetch_postsecondary_enrollment(2025),
    "removed from the redesigned 2024-25 SPR database"
  )
})

test_that("school level returns school rows", {
  skip_if_not(have_postsec_data, "NJ DOE SPR source unavailable")

  expect_true(any(postsec_probe$school_2019$is_school, na.rm = TRUE))
})

test_that("legacy fetch_postsecondary points to the SPR replacement", {
  expect_error(
    fetch_postsecondary(),
    "fetch_postsecondary_enrollment"
  )
})
