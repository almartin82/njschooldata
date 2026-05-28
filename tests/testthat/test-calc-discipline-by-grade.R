# ==============================================================================
# Tests for calc_discipline_rates_by_subgroup(..., by_grade = FALSE)
# ==============================================================================
#
# The by_grade argument controls whether grade_level is included in the
# grouping keys. Existing callers pass data WITHOUT a grade_level column
# (e.g. fetch_disciplinary_removals() pre-PR#275 path), so by_grade = FALSE
# must return bit-for-bit identical output to the original implementation
# for that case.
#
# When by_grade = TRUE on data that DOES carry a grade_level column (e.g.
# fetch_police_notifications_detail() / fetch_arrests() / the redesigned
# RemovalsStudentGroupGrade), the function:
#   - includes grade_level in the per-entity grouping keys
#   - computes risk ratios within each (entity x grade) cell
#   - reconciles: subgroup-only rows ("TOTAL" grade) keep the existing flat
#     semantics
#
# ==============================================================================

# ------------------------------------------------------------------------------
# Fixtures
# ------------------------------------------------------------------------------
# All fixtures hand-crafted as test data ONLY — they do NOT bundle into the
# package and do NOT represent real students. They exist to lock down the
# unit-level math of calc_discipline_rates_by_subgroup(). Numbers are chosen
# to make the expected rate / risk-ratio arithmetic easy to verify by hand.

# Flat fixture: one entity, three subgroups, no grade_level column.
# This mirrors the shape of the legacy fetch_disciplinary_removals() (pre-
# RemovalsStudentGroupGrade) output that existing callers already pass.
make_flat_fixture <- function() {
  data.frame(
    end_year = rep(2024L, 3),
    county_id = rep("01", 3),
    district_id = rep("0110", 3),
    school_id = rep("999", 3),
    subgroup = c("total population", "black", "white"),
    n_students = c(1000, 400, 600),
    removals = c(50, 30, 20),
    stringsAsFactors = FALSE
  )
}

# Subgroup-only rows with a grade_level column where every row is "TOTAL".
# Mirrors a fetch_police_notifications_detail() output filtered to the
# subgroup marginal rows.
make_subgroup_only_with_grade_total <- function() {
  data.frame(
    end_year = rep(2024L, 3),
    county_id = rep("01", 3),
    district_id = rep("0110", 3),
    school_id = rep("999", 3),
    subgroup = c("total population", "black", "white"),
    grade_level = rep("TOTAL", 3),
    n_students = c(1000, 400, 600),
    removals = c(50, 30, 20),
    stringsAsFactors = FALSE
  )
}

# By-grade fixture: same entity, subgroup marginals at TOTAL + grade marginals
# (subgroup = "total population", grade_level = "09".."10"). This is the shape
# fetch_police_notifications_detail() / fetch_arrests() emit.
make_by_grade_fixture <- function() {
  data.frame(
    end_year = rep(2024L, 5),
    county_id = rep("01", 5),
    district_id = rep("0110", 5),
    school_id = rep("999", 5),
    subgroup = c("total population", "black", "white",
                 "total population", "total population"),
    grade_level = c("TOTAL", "TOTAL", "TOTAL", "09", "10"),
    n_students = c(1000, 400, 600, 500, 500),
    removals = c(50, 30, 20, 25, 25),
    stringsAsFactors = FALSE
  )
}


# ==============================================================================
# Backward compatibility: by_grade = FALSE on legacy-shape input
# ==============================================================================

test_that("calc_discipline_rates_by_subgroup default (by_grade=FALSE) preserves legacy behavior", {
  df <- make_flat_fixture()

  # Default invocation must succeed and produce the documented output.
  res <- calc_discipline_rates_by_subgroup(df)

  expect_s3_class(res, "data.frame")
  # 3 input rows -> 3 output rows.
  expect_equal(nrow(res), 3)
  # Output adds discipline_rate, percent_by_subgroup, risk_ratio.
  expect_true(all(c("discipline_rate", "percent_by_subgroup", "risk_ratio") %in%
                    names(res)))

  # discipline_rate = removals / n_students * 1000
  expect_equal(res$discipline_rate[res$subgroup == "total population"], 50)
  expect_equal(res$discipline_rate[res$subgroup == "black"], 75)
  expect_equal(res$discipline_rate[res$subgroup == "white"], 33.3333333,
               tolerance = 1e-4)

  # risk_ratio is computed vs total population (rate = 50)
  expect_equal(res$risk_ratio[res$subgroup == "total population"], 1)
  expect_equal(res$risk_ratio[res$subgroup == "black"], 1.5)
  expect_equal(res$risk_ratio[res$subgroup == "white"], 33.3333333 / 50,
               tolerance = 1e-4)
})

test_that("calc_discipline_rates_by_subgroup by_grade=FALSE ignores grade_level when present", {
  # If the input carries a grade_level column but the caller passes by_grade=FALSE,
  # behaviour must still be the "subgroup marginal" calc — grade rows must NOT
  # silently leak into the subgroup risk-ratio denominator.
  df <- make_subgroup_only_with_grade_total()

  res_flat <- calc_discipline_rates_by_subgroup(
    make_flat_fixture()
  )
  res_with_grade <- calc_discipline_rates_by_subgroup(df, by_grade = FALSE)

  # Same number of rows.
  expect_equal(nrow(res_flat), nrow(res_with_grade))
  # Same discipline_rate per subgroup (order may differ - join by subgroup).
  joined <- merge(
    res_flat[, c("subgroup", "discipline_rate", "risk_ratio")],
    res_with_grade[, c("subgroup", "discipline_rate", "risk_ratio")],
    by = "subgroup", suffixes = c("_flat", "_grade")
  )
  expect_equal(joined$discipline_rate_flat, joined$discipline_rate_grade)
  expect_equal(joined$risk_ratio_flat, joined$risk_ratio_grade)
})


# ==============================================================================
# New behavior: by_grade = TRUE
# ==============================================================================

test_that("calc_discipline_rates_by_subgroup by_grade=TRUE preserves all input rows", {
  df <- make_by_grade_fixture()
  res <- calc_discipline_rates_by_subgroup(df, by_grade = TRUE)

  # All 5 input rows survive (no row drops).
  expect_equal(nrow(res), nrow(df))
  # rate columns are computed for every row.
  expect_true(all(!is.na(res$discipline_rate)))
})

test_that("calc_discipline_rates_by_subgroup by_grade=TRUE has rows_by_grade >= rows_flat", {
  by_grade_df <- make_by_grade_fixture()
  res_grade <- calc_discipline_rates_by_subgroup(by_grade_df, by_grade = TRUE)
  # Flat = only the TOTAL rows
  flat_df <- by_grade_df[by_grade_df$grade_level == "TOTAL", ]
  res_flat <- calc_discipline_rates_by_subgroup(flat_df, by_grade = FALSE)

  expect_gte(nrow(res_grade), nrow(res_flat))
  # Specifically, 5 vs 3 in the fixture.
  expect_equal(nrow(res_grade), 5)
  expect_equal(nrow(res_flat), 3)
})

test_that("calc_discipline_rates_by_subgroup by_grade=TRUE computes rates per (entity, subgroup, grade)", {
  df <- make_by_grade_fixture()
  res <- calc_discipline_rates_by_subgroup(df, by_grade = TRUE)

  # Grade 9: subgroup = "total population", n=500, removals=25 -> rate=50.
  g9 <- res[res$grade_level == "09", ]
  expect_equal(nrow(g9), 1)
  expect_equal(g9$discipline_rate, 50)

  # Grade 10: same shape, rate=50.
  g10 <- res[res$grade_level == "10", ]
  expect_equal(g10$discipline_rate, 50)

  # The TOTAL "total population" row still has its own rate.
  tp_total <- res[res$subgroup == "total population" & res$grade_level == "TOTAL", ]
  expect_equal(tp_total$discipline_rate, 50)
})

test_that("calc_discipline_rates_by_subgroup by_grade=TRUE risk_ratio uses (entity, grade) reference", {
  # When by_grade=TRUE, the risk_ratio reference is the (entity, grade)
  # "total population" rate — so each subgroup is compared against the
  # all-students rate within the SAME grade. For grade=TOTAL rows the
  # reference is the (entity, TOTAL, total-population) rate; for grade=09 rows
  # the reference is the (entity, 09, total-population) rate.
  df <- make_by_grade_fixture()
  res <- calc_discipline_rates_by_subgroup(df, by_grade = TRUE)

  # black @ TOTAL rate = 75; total population @ TOTAL rate = 50 -> RR = 1.5
  black_total <- res[res$subgroup == "black" & res$grade_level == "TOTAL", ]
  expect_equal(black_total$risk_ratio, 1.5)

  # total population @ Grade 9 rate = 50 (its own ref) -> RR = 1
  g9_tp <- res[res$grade_level == "09" & res$subgroup == "total population", ]
  expect_equal(g9_tp$risk_ratio, 1)
})


# ==============================================================================
# Reconciliation: flat path is a slice of the by_grade path
# ==============================================================================

test_that("by_grade=TRUE TOTAL slice matches by_grade=FALSE flat output", {
  # Subgroup-only rows in the by_grade=TRUE output (grade_level == "TOTAL")
  # must have identical discipline_rate and risk_ratio to the corresponding
  # rows from the flat by_grade=FALSE calc.
  by_grade_df <- make_by_grade_fixture()
  flat_df <- by_grade_df[by_grade_df$grade_level == "TOTAL", ]

  res_grade <- calc_discipline_rates_by_subgroup(by_grade_df, by_grade = TRUE)
  res_flat  <- calc_discipline_rates_by_subgroup(flat_df, by_grade = FALSE)

  res_grade_total <- res_grade[res_grade$grade_level == "TOTAL", ]
  joined <- merge(
    res_grade_total[, c("subgroup", "discipline_rate", "risk_ratio")],
    res_flat[, c("subgroup", "discipline_rate", "risk_ratio")],
    by = "subgroup", suffixes = c("_grade", "_flat")
  )
  expect_equal(nrow(joined), 3)
  expect_equal(joined$discipline_rate_grade, joined$discipline_rate_flat)
  expect_equal(joined$risk_ratio_grade, joined$risk_ratio_flat)
})


# ==============================================================================
# Edge case: by_grade=TRUE on data without grade_level column
# ==============================================================================

test_that("calc_discipline_rates_by_subgroup by_grade=TRUE warns and falls through when grade_level missing", {
  # Behavioural choice: if the caller asks for by_grade=TRUE on input that
  # has no grade_level column, we WARN (so the mistake is visible) and fall
  # through to the flat behaviour. We do NOT error — the calc still produces
  # sensible per-subgroup rates and risk ratios from what's available.
  df <- make_flat_fixture()
  expect_warning(
    res <- calc_discipline_rates_by_subgroup(df, by_grade = TRUE),
    "grade_level"
  )

  # Output identical to the flat default (per-subgroup rates).
  flat <- calc_discipline_rates_by_subgroup(df)
  joined <- merge(
    res[, c("subgroup", "discipline_rate", "risk_ratio")],
    flat[, c("subgroup", "discipline_rate", "risk_ratio")],
    by = "subgroup", suffixes = c("_warn", "_flat")
  )
  expect_equal(joined$discipline_rate_warn, joined$discipline_rate_flat)
  expect_equal(joined$risk_ratio_warn, joined$risk_ratio_flat)
})


# ==============================================================================
# Edge case: zero denominator
# ==============================================================================

test_that("calc_discipline_rates_by_subgroup handles zero-denominator gracefully", {
  # When a subgroup has 0 students, discipline_rate is Inf (divide by zero).
  # The function should produce Inf/NaN, and risk_ratio should become NA
  # (mirroring the existing flat-path behavior, which sets non-finite
  # risk_ratio to NA).
  df <- data.frame(
    end_year = rep(2024L, 2),
    county_id = rep("01", 2),
    district_id = rep("0110", 2),
    school_id = rep("999", 2),
    subgroup = c("total population", "non-binary/undesignated gender"),
    n_students = c(1000, 0),
    removals = c(50, 0),
    stringsAsFactors = FALSE
  )

  res <- calc_discipline_rates_by_subgroup(df)
  expect_equal(nrow(res), 2)

  nbn <- res[res$subgroup == "non-binary/undesignated gender", ]
  # rate = 0/0*1000 -> NaN OR Inf depending on numerator. Here 0/0 = NaN.
  expect_true(is.nan(nbn$discipline_rate) || is.na(nbn$discipline_rate))
  # risk_ratio non-finite -> NA per existing convention.
  expect_true(is.na(nbn$risk_ratio))
})
