context("assign_entity_flags characterization")

# These fixtures are CDS identifier codes, not fabricated data VALUES. They
# reproduce the exact per-site flag logic that lived inline before the refactor,
# so the tests are a characterization gate proving assign_entity_flags() is
# behavior-neutral for the existing flag columns.

test_that("assign_entity_flags derives the 7 standard flags (SPR / grad settings)", {
  df <- data.frame(
    county_id  = c("99",   "01",   "01",   "80"),
    district_id = c("9999", "1234", "1234", "5678"),
    school_id  = c("999",  "999",  "010",  "020"),
    stringsAsFactors = FALSE
  )
  # row 1: state, 2: district, 3: school, 4: charter school

  out <- assign_entity_flags(
    df,
    district_school_ids = c("888", "997", "999"),
    recognize_state_label = TRUE
  )

  expect_equal(out$is_state,    c(TRUE,  FALSE, FALSE, FALSE))
  expect_equal(out$is_county,   c(FALSE, FALSE, FALSE, FALSE))
  expect_equal(out$is_district, c(FALSE, TRUE,  FALSE, FALSE))
  expect_equal(out$is_school,   c(FALSE, FALSE, TRUE,  TRUE))
  expect_equal(out$is_charter,  c(FALSE, FALSE, FALSE, TRUE))
  expect_true(all(out$is_charter_sector == FALSE))
  expect_true(all(out$is_allpublic == FALSE))
})

test_that("recognize_state_label flags a literal STATE county code", {
  df <- data.frame(
    county_id  = c("State", "01"),
    district_id = c("State", "1234"),
    school_id  = c(NA_character_, "010"),
    stringsAsFactors = FALSE
  )

  on  <- assign_entity_flags(df, recognize_state_label = TRUE)
  off <- assign_entity_flags(df, recognize_state_label = FALSE)

  expect_equal(on$is_state,  c(TRUE, FALSE))
  expect_equal(off$is_state, c(FALSE, FALSE))
})

test_that("assign_entity_flags reproduces the SPR inline flag logic exactly", {
  df <- data.frame(
    county_id  = c("99",   "01",   "01",   "01",   "80",   "State"),
    district_id = c("9999", "9999", "1234", "1234", "5678", "State"),
    school_id  = c("999",  "999",  "888",  "010",  "020",  "999"),
    stringsAsFactors = FALSE
  )
  # Includes a county-aggregate row (2) which, under the historical inline
  # logic, is flagged both is_county AND is_district; the oracle below captures
  # that exact behavior.

  # Prior inline SPR logic (verbatim), as the oracle.
  is_state <- (df$district_id == "9999" & df$county_id == "99") |
    (toupper(df$county_id) == "STATE")
  expected <- data.frame(
    is_state = is_state,
    is_county = (df$district_id == "9999" & df$county_id != "99") & !is_state,
    is_district = df$school_id %in% c("888", "997", "999") & !is_state,
    is_school = !df$school_id %in% c("888", "997", "999") & !is_state,
    is_charter = df$county_id == "80",
    is_charter_sector = FALSE,
    is_allpublic = FALSE,
    stringsAsFactors = FALSE
  )

  out <- assign_entity_flags(
    df,
    district_school_ids = c("888", "997", "999"),
    recognize_state_label = TRUE
  )

  for (col in names(expected)) {
    expect_equal(out[[col]], expected[[col]], info = col)
  }
})

test_that("assign_entity_flags reproduces the PARCC NA-school-is-district logic", {
  # Raw PARCC (pre-normalization): state row is county 'STATE' with blank
  # district/school, district rows have a school code that is NA, school rows
  # carry a non-NA school code.
  df <- data.frame(
    county_code  = c("STATE",       "01",   "01",   "DFG"),
    district_code = c(NA_character_, "1234", "1234", NA_character_),
    school_code  = c(NA_character_,  NA_character_, "010", NA_character_),
    stringsAsFactors = FALSE
  )

  # Prior inline PARCC logic (verbatim), as the oracle.
  expected <- data.frame(
    is_state = toupper(df$county_code) == "STATE",
    is_district = is.na(df$school_code) & !is.na(df$district_code),
    is_school = !is.na(df$school_code),
    is_charter = df$county_code == "80",
    stringsAsFactors = FALSE
  )

  parcc <- df
  names(parcc) <- c("county_id", "district_id", "school_id")
  out <- assign_entity_flags(
    parcc,
    district_school_ids = character(0),
    recognize_state_label = TRUE,
    na_school_is_district = TRUE
  )

  expect_equal(out$is_state,    expected$is_state)
  expect_equal(out$is_district, expected$is_district)
  expect_equal(out$is_school,   expected$is_school)
  expect_equal(out$is_charter,  expected$is_charter)
})

test_that("id_enr_aggs still runs and appends is_subprogram last", {
  df <- data.frame(
    county_id  = c("99",   "01",   "01"),
    district_id = c("9999", "1234", "1234"),
    school_id  = c("999",  "999",  "010"),
    program_code = c("55",  "55",   "40"),
    stringsAsFactors = FALSE
  )

  out <- id_enr_aggs(df)

  # is_subprogram is the last column and only appended flag beyond the standard 7
  expect_equal(tail(names(out), 1), "is_subprogram")
  expect_equal(out$is_subprogram, c(FALSE, FALSE, TRUE))
  expect_equal(out$is_state,    c(TRUE, FALSE, FALSE))
  expect_equal(out$is_district, c(FALSE, TRUE, FALSE))
  expect_equal(out$is_school,   c(FALSE, FALSE, TRUE))
  # no is_county leakage into schema position: still present as standard flag
  expect_true("is_county" %in% names(out))
})

test_that("id_grad_aggs preserves its historical column order", {
  df <- data.frame(
    county_id  = c("99",   "01"),
    district_id = c("9999", "1234"),
    school_id  = c("999",  "010"),
    stringsAsFactors = FALSE
  )

  out <- id_grad_aggs(df)
  flag_cols <- setdiff(names(out), c("county_id", "district_id", "school_id"))
  expect_equal(
    flag_cols,
    c("is_state", "is_county", "is_district",
      "is_charter_sector", "is_allpublic", "is_school", "is_charter")
  )
})
