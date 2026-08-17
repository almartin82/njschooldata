# NOTE: NJ DOE retired the old state.nj.us achievement file tree in 2024 and
# rehosted the legacy NJASK/HSPA/GEPA summary files under nj.gov at
# education/assessment/results/njask/njask{YY}/ (see nj_legacy_assess_url()).
# 2005-2014 fetch live from nj.gov; 2004 (not rehosted) is recovered from the
# Internet Archive, which rate-limits (HTTP 429) under repeated access. The
# njsd_live() guards below skip on a declared source condition and on nothing
# else -- a parse failure or a failed expectation still reaches the reporter.

test_that("valid_call correctly identifies status of years/grade pairs", {
  expect_true(valid_call(2014, 8))
  expect_false(valid_call(2014, 12))

  expect_true(valid_call(2007, 8))
  expect_false(valid_call(2005, 5))
})

test_that("standard_assess correctly calls data for 2014", {
  skip_if_no_live_tests()

  hspa_ex <- njsd_live(standard_assess(2014, 11), "standard_assess(2014, 11)")

  expect_equal(nrow(hspa_ex), 742)
  expect_equal(ncol(hspa_ex), 560)
  expect_equal(
    sum(hspa_ex$GENERAL_EDUCATION_Number_Enrolled_LAL, na.rm = TRUE), 405655
  )
  expect_equal(
    sum(hspa_ex$GENERAL_EDUCATION_LANGUAGE_ARTS_Scale_Score_Mean, na.rm = TRUE),
    174325.5, tolerance = 0.01
  )

  njask_ex <- njsd_live(standard_assess(2014, 7), "standard_assess(2014, 7)")

  expect_equal(nrow(njask_ex), 1329)
  expect_equal(ncol(njask_ex), 551)
  expect_equal(
    sum(njask_ex$GENERAL_EDUCATION_Number_Enrolled_ELA, na.rm = TRUE), 420111
  )
  expect_equal(
    sum(njask_ex$GENERAL_EDUCATION_LANGUAGE_ARTS_Scale_Score_Mean, na.rm = TRUE),
    265911.4, tolerance = 0.01
  )
})


test_that("fetch_old_nj_assess returns correct output for a variety of calls", {
  skip_if_no_live_tests()

  #2014 njask
  njask_14 <- njsd_live(
    fetch_old_nj_assess(2014, 6),
    "fetch_old_nj_assess(2014, 6)"
  )

  expect_equal(nrow(njask_14), 1505)
  expect_equal(ncol(njask_14), 551)
  expect_equal(
    sum(njask_14$GENERAL_EDUCATION_Number_Enrolled_ELA, na.rm = TRUE), 412827
  )

  #2014 hspa
  hspa_14 <- njsd_live(
    fetch_old_nj_assess(2014, 11),
    "fetch_old_nj_assess(2014, 11)"
  )

  expect_equal(nrow(hspa_14), 742)
  expect_equal(ncol(hspa_14), 560)
  expect_equal(
    sum(hspa_14$GENERAL_EDUCATION_Number_Enrolled_LAL, na.rm = TRUE), 405655
  )

  #2007 gepa
  gepa_07 <- njsd_live(
    fetch_old_nj_assess(2007, 11),
    "fetch_old_nj_assess(2007, 11)"
  )

  expect_equal(nrow(gepa_07), 681)
  expect_equal(ncol(gepa_07), 529)
  expect_equal(
    sum(gepa_07$GENERAL_EDUCATION_Number_Enrolled, na.rm = TRUE), 410704
  )

  #2004 gr3
  njask_04 <- njsd_live(
    fetch_old_nj_assess(2004, 3),
    "fetch_old_nj_assess(2004, 3)"
  )

  expect_equal(nrow(njask_04), 1956)
  expect_equal(ncol(njask_04), 363)
  expect_equal(
    sum(njask_04$GENERAL_EDUCATION_Number_Enrolled, na.rm = TRUE), 418669
  )
})