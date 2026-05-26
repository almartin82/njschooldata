# ==============================================================================
# Tests for fetch_state_aid() / tidy_state_aid() / normalize_state_aid_category()
#
# Two layers:
#   1. Pure-logic unit tests on a tiny SYNTHETIC fixture (not NJ DOE figures).
#   2. Live integration tests against the real published workbooks.
# ==============================================================================


# --- synthetic fixture (mimics get_raw_state_aid(): clean_names'd + report_year)

fake_raw_state_aid <- function() {
  tibble::tibble(
    county   = c("Essex", "Camden", NA),
    dist     = c(3570, 680, NA),
    district = c("Newark City", "Camden City", "Total"),
    equalization_aid                  = c(1000, 800, 1800),
    choice_aid                        = c(0, 50, 50),     # -> school_choice_aid
    special_education_categorical_aid = c(60, 40, 100),   # -> special_education_aid
    transportation_aid                = c(20, 15, 35),
    fy25_k_12_aid                     = c(1080, 905, 1985), # total (not a category)
    aid_percent_difference            = c("5%", "3%", "4%"), # character column
    report_year = 2025L
  )
}


test_that("state_aid_year_code maps end_year to the two-year span", {
  expect_equal(state_aid_year_code(2026), "2526")
  expect_equal(state_aid_year_code(2019), "1819")
  expect_equal(state_aid_year_code(2027), "2627")
})

test_that("normalize_state_aid_category resolves cross-year label drift", {
  raw <- c("Choice Aid", "School Choice Aid",
           "Special Education Categorical Aid", "Special Education Aid",
           "Equalization Aid", "Educational Adequacy Aid", "Adjustment Aid",
           "Transportation Aid", "Security Aid",
           "FY25 K-12 Aid", "Aid Percent Difference")
  out <- normalize_state_aid_category(raw)
  expect_equal(out[1], "school_choice_aid")
  expect_equal(out[2], "school_choice_aid")
  expect_equal(out[3], "special_education_aid")
  expect_equal(out[4], "special_education_aid")
  expect_equal(out[5], "equalization_aid")
  expect_equal(out[6], "educational_adequacy_aid")
  expect_equal(out[7], "adjustment_aid")
  expect_equal(out[11], "aid_percent_difference")
})

test_that("tidy_state_aid melts long, normalizes, and flags categories", {
  out <- tidy_state_aid(fake_raw_state_aid(), 2025)

  # 3 entities x 6 value columns
  expect_equal(nrow(out), 18L)
  expect_true(all(c("county_name", "district_code", "district_name",
                    "aid_category", "is_aid_category", "amount") %in% names(out)))

  # the two drifting labels normalized to standard names
  expect_true("school_choice_aid" %in% out$aid_category)
  expect_true("special_education_aid" %in% out$aid_category)

  # categories flagged TRUE; the year total + percent flagged FALSE
  cats <- unique(out$aid_category[out$is_aid_category])
  expect_true(all(c("equalization_aid", "school_choice_aid",
                    "special_education_aid", "transportation_aid") %in% cats))
  expect_false(any(out$is_aid_category[grepl("k_12_aid$|percent", out$aid_category)]))

  # the character percent column was coerced ("5%" -> 5)
  pct <- out %>%
    dplyr::filter(district_code == "3570", aid_category == "aid_percent_difference") %>%
    dplyr::pull(amount)
  expect_equal(pct, 5)
})

test_that("tidy_state_aid pads codes and sets entity flags", {
  out <- tidy_state_aid(fake_raw_state_aid(), 2025)

  nwk <- out %>%
    dplyr::filter(district_code == "3570", aid_category == "equalization_aid")
  expect_equal(nwk$amount, 1000)
  expect_true(nwk$is_district)
  expect_false(nwk$is_state)

  cmd <- out %>%
    dplyr::filter(district_code == "0680", aid_category == "equalization_aid")
  expect_equal(nrow(cmd), 1L)  # 680 padded to 0680

  tot <- out %>%
    dplyr::filter(district_name == "Total", aid_category == "equalization_aid")
  expect_false(tot$is_district)
  expect_true(tot$is_state)
})

test_that("get_raw_state_aid rejects unsupported years", {
  expect_error(get_raw_state_aid(2018), "2019")
})


# --- live integration -------------------------------------------------------

test_that("fetch_state_aid pulls the current-year direct workbook", {
  skip_on_cran()
  skip_if_offline()
  sa <- fetch_state_aid(2027)

  expect_gt(dplyr::n_distinct(sa$district_code[sa$is_district]), 500L)
  expect_true("transportation_aid" %in% sa$aid_category)
  nwk_transp <- sa %>%
    dplyr::filter(district_code == "3570", aid_category == "transportation_aid") %>%
    dplyr::pull(amount)
  expect_true(is.finite(nwk_transp) && nwk_transp > 0)

  # the individual aid categories reconstruct the published current-year total
  totcol <- grep("fy_?0*27_k_12_aid$", unique(sa$aid_category), value = TRUE)[1]
  expect_false(is.na(totcol))
  cat_sum <- sa %>%
    dplyr::filter(district_code == "3570", is_aid_category) %>%
    dplyr::pull(amount) %>% sum(na.rm = TRUE)
  published <- sa %>%
    dplyr::filter(district_code == "3570", aid_category == totcol) %>%
    dplyr::pull(amount)
  expect_equal(cat_sum, published)
})

test_that("fetch_state_aid falls back to the zip bundle for prior years", {
  skip_on_cran()
  skip_if_offline()
  # FY25 has no direct URL; this exercises the zip fallback + spaced member name
  sa <- fetch_state_aid(2025)
  expect_gt(dplyr::n_distinct(sa$district_code[sa$is_district]), 500L)
  expect_true(all(c("equalization_aid", "special_education_aid",
                    "transportation_aid") %in% sa$aid_category))
})

test_that("fetch_many_state_aid stacks years into one long tibble", {
  skip_on_cran()
  skip_if_offline()
  many <- fetch_many_state_aid(2026:2027)
  expect_setequal(sort(unique(many$end_year)), c(2026, 2027))
  expect_true(is.data.frame(many))
})
