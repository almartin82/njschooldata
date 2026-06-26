# ==============================================================================
# Tests for fetch_staff_evaluations() and fetch_certificated_staff()
# ==============================================================================
#
# Live-network tests for the two NJ DOE doedata staff sources. Pinned values are
# verified by hand against the published files:
#
#  Staff evaluations (nj.gov/education/doedata/staff/NJDOE_STAFF_EVAL_*.xlsx):
#    2014 (1314): Absecon (0010) / Emma C Attales (050) TEACHERS ->
#        effective=16, highly_effective=10, total=26, ineffective/partially "*"->NA.
#    2014 statewide (county 99 / district 9999) TEACHERS -> effective=78099,
#        total=105759.
#    2015 (1415): Absecon district total (0010/999) TEACHERS -> effective=36,
#        highly_effective=36, total=72. School 050 TEACHERS effective "*"->NA, total=27.
#        DISTRICT_CODE drops the leading zero ("10") -> re-padded to "0010".
#    2016 (1516): Absecon district total TEACHERS -> effective=22,
#        highly_effective=46, total=68. No statewide row published.
#
#  Certificated staff (nj.gov/education/doedata/cs/):
#    cs25 STATE Teacher (gender total) White=94984.6, Total=116878.6; Total-position
#        White=120061.3. cs25 SCHOOL Absecon/Emma C Attales (0010/050) Teacher total
#        White=32.8, Total=35.8; male row White=NA, Total=10.5.
#    cs00 STATE administrators MALE White=4142, Total=4580 (legacy CSV).
#    cs08 STATE administrators MALE White=3821, Total=4449 (legacy CSV).
#    cs00 COUNTY Atlantic teachers total White=2698, Total=3145.
#    Covered years: 2000-2008 (legacy) and 2020-2026 (modern); 2009-2019 error.
# ==============================================================================

eval_cols <- c(
  "end_year", "county_id", "county_name", "district_id", "district_name",
  "school_id", "school_name", "category", "staff_category",
  "ineffective", "partially_effective", "effective", "highly_effective", "total",
  "is_state", "is_county", "is_district", "is_school", "is_charter"
)

cert_cols <- c(
  "end_year", "county_id", "county_name", "district_id", "district_name",
  "school_id", "school_name", "position", "gender",
  "white", "black", "hispanic", "asian", "american_indian",
  "pacific_islander", "two_or_more", "total",
  "is_state", "is_county", "is_district", "is_school", "is_charter"
)

local_big_download_timeout <- function(seconds = 1200, env = parent.frame()) {
  old <- getOption("timeout")
  options(timeout = seconds)
  withr::defer(options(timeout = old), envir = env)
  invisible(old)
}


# ==============================================================================
# Argument validation (no network)
# ==============================================================================

test_that("fetch_staff_evaluations rejects unsupported years and levels", {
  expect_error(fetch_staff_evaluations(2013), "2014.*2015.*2016")
  expect_error(fetch_staff_evaluations(2017), "2014.*2015.*2016")
  expect_error(fetch_staff_evaluations(2015, level = "county"),
               "school.*district")
})

test_that("fetch_certificated_staff rejects uncovered years and bad level", {
  expect_error(fetch_certificated_staff(2015), "2009-2019")
  expect_error(fetch_certificated_staff(2019), "2009-2019")
  expect_error(fetch_certificated_staff(1999), "not covered")
  expect_error(fetch_certificated_staff(2027), "not covered")
  expect_error(fetch_certificated_staff(2025, level = "building"),
               "level must be")
})


# ==============================================================================
# Suppression coercion (pure, no network) -- the load-bearing data-integrity test
# ==============================================================================

test_that("staff_value_numeric maps masked cells to NA, keeps real numbers", {
  expect_true(is.na(staff_value_numeric("*")))
  expect_true(is.na(staff_value_numeric("")))
  expect_true(is.na(staff_value_numeric("<5")))
  expect_true(is.na(staff_value_numeric("<.1")))
  expect_equal(staff_value_numeric("0"), 0)
  expect_equal(staff_value_numeric("26"), 26)
  expect_equal(staff_value_numeric("35.8"), 35.8)
  expect_equal(staff_value_numeric("1,234"), 1234)
  # Already-numeric passes through (fractional FTE preserved).
  expect_equal(staff_value_numeric(c(94984.6, NA)), c(94984.6, NA))
  # Vectorized: masked element is NA, never a guessed digit.
  expect_equal(staff_value_numeric(c("*", "16", "", "0")), c(NA, 16, NA, 0))
})

test_that("normalize_staff_position harmonizes both eras", {
  expect_equal(
    normalize_staff_position(c("ADMINIST", "TEACHER", "SUPPSERV", "SPECSERV",
                               "TOTAL")),
    c("administrators", "teachers", "special_services", "special_services",
      "total")
  )
  expect_equal(
    normalize_staff_position(c("Administrators", "Teacher", "Special Service",
                               "Supervisors/Coordinators", "Total")),
    c("administrators", "teachers", "special_services",
      "supervisors_coordinators", "total")
  )
})

test_that("staff_pad_code re-pads CDS codes and NAs blanks", {
  expect_equal(staff_pad_code(c("10", "0010", 110), 4), c("0010", "0010", "0110"))
  expect_equal(staff_pad_code(c("50", "050"), 3), c("050", "050"))
  expect_true(is.na(staff_pad_code("", 4)))
  expect_true(is.na(staff_pad_code(NA, 2)))
})


# ==============================================================================
# Staff evaluations -- structure + raw-fidelity anchors
# ==============================================================================

test_that("fetch_staff_evaluations returns expected structure", {
  local_big_download_timeout()
  df <- fetch_staff_evaluations(2016)
  expect_s3_class(df, "data.frame")
  expect_true(all(eval_cols %in% names(df)))
  expect_true(all(df$is_school))            # default level = school
  expect_setequal(unique(df$staff_category), c("teachers", "principals_vps"))
  expect_type(df$total, "double")
})

test_that("fetch_staff_evaluations matches verified 2014 source cells", {
  local_big_download_timeout()
  df <- fetch_staff_evaluations(2014)
  a <- df[df$district_id == "0010" & df$school_id == "050" &
            df$staff_category == "teachers", ]
  expect_equal(nrow(a), 1)
  expect_equal(a$effective, 16)
  expect_equal(a$highly_effective, 10)
  expect_equal(a$total, 26)
  expect_true(is.na(a$ineffective))         # "*" -> NA
  expect_true(is.na(a$partially_effective))

  # Statewide aggregate (county 99 / district 9999) is published in 2014 and is
  # returned at level = "district".
  st <- fetch_staff_evaluations(2014, level = "district")
  s <- st[st$is_state & st$staff_category == "teachers", ]
  expect_equal(nrow(s), 1)
  expect_equal(s$effective, 78099)
  expect_equal(s$total, 105759)
})

test_that("fetch_staff_evaluations matches verified 2015 source cells (CDS drift)", {
  local_big_download_timeout()
  # District total: DISTRICT_CODE "10" re-padded to "0010".
  dd <- fetch_staff_evaluations(2015, level = "district")
  d <- dd[dd$district_id == "0010" & dd$staff_category == "teachers" &
            !dd$is_state, ]
  expect_equal(nrow(d), 1)
  expect_equal(d$effective, 36)
  expect_equal(d$highly_effective, 36)
  expect_equal(d$total, 72)

  # School level: school 050 teachers, effective "*" -> NA, total 27.
  ss <- fetch_staff_evaluations(2015)
  s <- ss[ss$district_id == "0010" & ss$school_id == "050" &
            ss$staff_category == "teachers", ]
  expect_equal(nrow(s), 1)
  expect_true(is.na(s$effective))
  expect_equal(s$total, 27)
})

test_that("fetch_staff_evaluations matches 2016 and has no statewide row", {
  local_big_download_timeout()
  dd <- fetch_staff_evaluations(2016, level = "district")
  d <- dd[dd$district_id == "0010" & dd$staff_category == "teachers" &
            !dd$is_state, ]
  expect_equal(nrow(d), 1)
  expect_equal(d$effective, 22)
  expect_equal(d$highly_effective, 46)
  expect_equal(d$total, 68)
  # 2016 publishes no statewide aggregate.
  expect_false(any(dd$is_state))
})


# ==============================================================================
# Certificated staff -- structure + raw-fidelity anchors (both eras)
# ==============================================================================

test_that("fetch_certificated_staff returns expected harmonized structure", {
  local_big_download_timeout()
  df <- fetch_certificated_staff(2025, level = "state")
  expect_s3_class(df, "data.frame")
  expect_true(all(cert_cols %in% names(df)))
  expect_setequal(unique(df$gender), c("total", "male", "female"))
  expect_true(all(df$is_state))
  # FTE values are non-negative doubles.
  expect_type(df$total, "double")
  tt <- df$total[!is.na(df$total)]
  expect_true(all(tt >= 0))
})

test_that("fetch_certificated_staff matches verified cs25 modern source cells", {
  local_big_download_timeout()
  st <- fetch_certificated_staff(2025, level = "state")
  t <- st[st$position == "teachers" & st$gender == "total", ]
  expect_equal(nrow(t), 1)
  expect_equal(t$white, 94984.6)
  expect_equal(t$total, 116878.6)
  tot <- st[st$position == "total" & st$gender == "total", ]
  expect_equal(tot$white, 120061.3)

  # SCHOOL anchor: Absecon (0010) / Emma C Attales (050) Teacher.
  sc <- fetch_certificated_staff(2025)
  a <- sc[sc$district_id == "0010" & sc$school_id == "050" &
            sc$position == "teachers" & sc$gender == "total", ]
  expect_equal(nrow(a), 1)
  expect_equal(a$white, 32.8)
  expect_equal(a$total, 35.8)
  # Modern male/female rows carry the gender headcount; race columns are NA
  # (the modern files do not cross race x gender) -- never 0.
  am <- sc[sc$district_id == "0010" & sc$school_id == "050" &
             sc$position == "teachers" & sc$gender == "male", ]
  expect_equal(nrow(am), 1)
  expect_equal(am$total, 10.5)
  expect_true(is.na(am$white))
})

test_that("fetch_certificated_staff matches verified cs00 / cs08 legacy cells", {
  local_big_download_timeout()
  s00 <- fetch_certificated_staff(2000, level = "state")
  a <- s00[s00$position == "administrators" & s00$gender == "male", ]
  expect_equal(nrow(a), 1)
  expect_equal(a$white, 4142)
  expect_equal(a$total, 4580)

  # A second legacy year anchored independently.
  s08 <- fetch_certificated_staff(2008, level = "state")
  a8 <- s08[s08$position == "administrators" & s08$gender == "male", ]
  expect_equal(nrow(a8), 1)
  expect_equal(a8$white, 3821)
  expect_equal(a8$total, 4449)

  # Legacy county aggregate (CO SUMMARY) anchor.
  co <- fetch_certificated_staff(2000, level = "county")
  at <- co[co$county_name == "ATLANTIC" & co$position == "teachers" &
             co$gender == "total", ]
  expect_equal(nrow(at), 1)
  expect_equal(at$white, 2698)
  expect_equal(at$total, 3145)
})


# ==============================================================================
# Cross-era harmonization: era-absent race columns are NA, not 0
# ==============================================================================

test_that("legacy and modern both return harmonized position/race columns", {
  local_big_download_timeout()
  leg <- fetch_certificated_staff(2000)        # legacy
  mod <- fetch_certificated_staff(2024)        # modern

  # Both expose the same harmonized columns.
  expect_true(all(cert_cols %in% names(leg)))
  expect_true(all(cert_cols %in% names(mod)))

  # Legacy era did not separate Asian from Pacific Islander, nor report
  # multiracial: pacific_islander and two_or_more are NA (never 0).
  expect_true(all(is.na(leg$pacific_islander)))
  expect_true(all(is.na(leg$two_or_more)))
  expect_false(any(leg$pacific_islander == 0, na.rm = TRUE))

  # Modern era populates them on the gender-total rows.
  mt <- mod[mod$gender == "total", ]
  expect_true(any(!is.na(mt$pacific_islander)))
  expect_true(any(!is.na(mt$two_or_more)))

  # Both eras carry the normalized positions.
  expect_true(all(c("administrators", "teachers", "total") %in% leg$position))
  expect_true(all(c("administrators", "teachers") %in% mod$position))
})


# ==============================================================================
# Sanity: one row per (entity, position, gender); Newark present; row counts
# ==============================================================================

test_that("certificated staff is one row per (entity, position, gender)", {
  local_big_download_timeout()
  for (yr in c(2000, 2024)) {
    df <- fetch_certificated_staff(yr)
    dups <- df %>%
      dplyr::count(county_id, district_id, school_id, position, gender) %>%
      dplyr::filter(n > 1)
    expect_equal(nrow(dups), 0, info = paste("year", yr))
  }
})

test_that("certificated staff counts are non-negative and Newark is present", {
  local_big_download_timeout()
  for (yr in c(2000, 2025, 2026)) {
    df <- fetch_certificated_staff(yr)
    expect_true(any(df$district_id == "3570", na.rm = TRUE),
                info = paste("year", yr))
    tt <- df$total[!is.na(df$total)]
    expect_true(all(tt >= 0), info = paste("year", yr))
    expect_true(nrow(df) > 1000, info = paste("year", yr))
  }
})
