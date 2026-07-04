test_that("classify_value_status distinguishes published-value states", {
  raw <- c(
    "*",
    "<5",
    "<5.00",
    "<.1",
    "Fewer than 10 students",
    "Enrollment for the group is <10 students.",
    "0",
    "53.5",
    "n/a",
    "There is no data available for this school year.",
    ""
  )

  expect_equal(
    as.character(classify_value_status(raw)),
    c(
      "suppressed",
      "suppressed",
      "suppressed",
      "suppressed",
      "suppressed",
      "suppressed",
      "actual",
      "actual",
      "not_applicable",
      "not_published",
      "not_published"
    )
  )
})

test_that("with-status numeric companions classify the same raw token they clean", {
  rs <- rs_value_with_status(c("<5", "0", "*"))
  expect_equal(rs$value, c(NA, 0, NA))
  expect_equal(as.character(rs$status), c("suppressed", "actual", "suppressed"))

  spr <- spr_value_with_status(c(
    "Fewer than 5 seals",
    "Enrollment for the group is <10 students.",
    "53.5"
  ))
  expect_equal(spr$value, c(NA, NA, 53.5))
  expect_equal(as.character(spr$status), c("suppressed", "suppressed", "actual"))
})

test_that("SPR entity value helpers keep default numeric output byte-identical", {
  triple_df <- data.frame(
    is_state = c(FALSE, TRUE, FALSE),
    rate_school = c("1", "*", "0"),
    rate_district = c("10", "N", "<5"),
    rate_state = c("90", "77.7", "88"),
    stringsAsFactors = FALSE
  )

  expected_school <- c(1, NA, 0)
  expected_district <- c(10, 77.7, NA)

  expect_identical(spr_pick_entity_value(triple_df, "rate", "school"), expected_school)
  expect_identical(
    spr_pick_entity_value(triple_df, "rate", "school", with_status = FALSE),
    expected_school
  )
  expect_identical(spr_pick_entity_value(triple_df, "rate", "district"), expected_district)
  expect_identical(
    spr_pick_entity_value(triple_df, "rate", "district", with_status = FALSE),
    expected_district
  )

  picked <- spr_pick_entity_value(triple_df, "rate", "district", with_status = TRUE)
  expect_equal(picked$value, expected_district)
  expect_equal(as.character(picked$status), c("actual", "actual", "suppressed"))

  legacy_df <- data.frame(
    is_state = c(FALSE, TRUE, FALSE),
    entity_rate = c("12", "", "<5"),
    state_rate = c("70", "82.1", "90"),
    stringsAsFactors = FALSE
  )
  expected_legacy <- c(12, 82.1, NA)

  expect_identical(
    spr_legacy_entity_value(legacy_df, "entity_rate", "state_rate", "district"),
    expected_legacy
  )
  expect_identical(
    spr_legacy_entity_value(
      legacy_df, "entity_rate", "state_rate", "district", with_status = FALSE
    ),
    expected_legacy
  )

  legacy_picked <- spr_legacy_entity_value(
    legacy_df, "entity_rate", "state_rate", "district", with_status = TRUE
  )
  expect_equal(legacy_picked$value, expected_legacy)
  expect_equal(as.character(legacy_picked$status), c("actual", "actual", "suppressed"))
})

test_that("finance_value_status classifies structural finance gaps", {
  expect_equal(
    as.character(finance_value_status("per_pupil_total", c(NA, NA, 25), 2025)),
    c("not_yet_observed", "not_yet_observed", "actual")
  )
  expect_equal(
    as.character(finance_value_status(
      "per_pupil_total", c(NA, 0, 25), 2024,
      is_per_pupil = TRUE,
      enrollment_denominator = c(0, NA, 10)
    )),
    c("not_published", "actual", "actual")
  )
})
