context("era breaks")

test_that("njsla break metadata includes the assessment scale break and COVID gaps", {
  njsla_breaks <- get_era_breaks("njsla")

  expect_true(any(
    njsla_breaks$break_year == 2015 &
      njsla_breaks$break_type == "scale_break"
  ))
  expect_true(any(
    njsla_breaks$break_year == 2020 &
      njsla_breaks$break_type == "covid_gap"
  ))
  expect_true(any(
    njsla_breaks$break_year == 2021 &
      njsla_breaks$break_type == "covid_gap"
  ))
})

test_that("assert_no_break_span guards njsla spans across breaks", {
  expect_error(assert_no_break_span(2014:2016, "njsla"), "2015")
  expect_no_error(assert_no_break_span(2016:2018, "njsla"))
})

test_that("tag_era separates years that straddle njsla scale breaks", {
  tagged <- tag_era(
    data.frame(end_year = c(2014L, 2016L), value = c(1, 2)),
    "njsla"
  )

  expect_false(tagged$era_id[tagged$end_year == 2014] ==
    tagged$era_id[tagged$end_year == 2016])
})

test_that("get_era_breaks filters by break_set and allowed break_type values", {
  njsla_breaks <- get_era_breaks("njsla")
  allowed_break_types <- c("scale_break", "covid_gap", "definition_change")

  expect_true(nrow(njsla_breaks) > 0)
  expect_true(all(njsla_breaks$break_set == "njsla"))
  expect_true(all(njsla_breaks$break_type %in% allowed_break_types))
})
