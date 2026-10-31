# fetch_sped_share() on the package's real bundled files (offline): the IDEA
# classification workbooks, the OPRA C255254 workbook and the Fall Enrollment
# archives. The School Performance Reports basis is tested at the bottom
# against a downloaded workbook when one is available.

share_years <- 2023:2026
share <- local({
  cache <- list()
  function(y) {
    key <- as.character(y)
    if (is.null(cache[[key]])) cache[[key]] <<- suppressWarnings(fetch_sped_share(y))
    cache[[key]]
  }
})
share_bands <- c("elementary", "middle", "high")

test_that("a band equals the sum of its OPRA grade cells read straight from the workbook", {
  raw <- get_raw_sped_by_grade(2025)
  row <- raw[raw[["District Code"]] == "1799", ]
  cell <- function(cols) sum(as.numeric(unlist(row[cols])), na.rm = TRUE)
  x <- share(2025)
  pick <- function(b) x$n_sped[x$district_id %in% "1799" & x$grade_band == b]
  expect_equal(pick("elementary"), cell(c("KG", paste0("Grade_", 1:5))))
  expect_equal(pick("middle"), cell(paste0("Grade_", 6:8)))
  expect_equal(pick("high"), cell(paste0("Grade_", 9:12)))
  # The all-grades row is the IDEA workbook's own figures for the same LEA.
  all_row <- x[x$district_id %in% "1799" & x$grade_band == "all", ]
  expect_equal(c(all_row$n_sped, all_row$n_enrolled, all_row$pct_sped), c(404, 2278, 17.73))
})

test_that("unsuppressed OPRA grade cells reconcile to the IDEA child count", {
  for (y in 2023:2025) {
    x <- share(y)
    g <- suppressWarnings(fetch_sped_by_grade(y))
    outside <- g[g$grade_level %in% c("PK", "NO_GRADE"), ]
    outside_n <- tapply(outside$n_students, outside$district_id, sum, na.rm = TRUE)
    allr <- x[x$entity_level == "district" & x$grade_band == "all", ]
    ok <- 0L
    miss <- list()
    for (d in allr$district_id) {
      b <- x[x$district_id %in% d & x$grade_band %in% share_bands, ]
      if (nrow(b) == 0L || anyNA(b$n_sped) || any(g$suppressed[g$district_id == d])) next
      extra <- if (d %in% names(outside_n)) outside_n[[d]] else 0
      diff <- sum(b$n_sped) + extra - allr$n_sped[allr$district_id == d]
      if (diff != 0) miss[[paste(y, d)]] <- diff
      ok <- ok + 1L
    }
    # Two 2022-23 LEAs (0410, 5210) are one student short in the OPRA cells
    # against the IDEA count: a discrepancy between the two NJDOE files.
    expect_lte(length(miss), if (y == 2023) 2L else 0L)
    expect_true(all(abs(c(0, unlist(miss))) <= 1), info = y)
    expect_gt(ok, 300L)
  }
})

test_that("a band with a suppressed grade cell is NA with published limits, never a floor or zero", {
  # 2022-23: one kindergarten-to-grade-5 cell for this LEA is suppressed (1 to 4).
  raw <- suppressWarnings(fetch_sped_by_grade(2023))
  cells <- raw[raw$district_id == "1799" & raw$grade_level %in% c("K", sprintf("%02d", 1:5)), ]
  expect_equal(sum(cells$suppressed), 1L)
  row <- share(2023)
  row <- row[row$district_id %in% "1799" & row$grade_band == "elementary", ]
  expect_true(is.na(row$n_sped))
  known <- sum(cells$n_students, na.rm = TRUE)
  expect_equal(row$pct_sped_lo, (known + 1) / row$n_enrolled * 100)
  expect_equal(row$pct_sped_hi, (known + 4) / row$n_enrolled * 100)
  for (y in share_years) {
    b <- share(y)
    b <- b[b$grade_band %in% share_bands, ]
    expect_false(any(!is.na(b$n_sped) & b$n_sped == 0 & !is.na(b$pct_sped_lo)))
  }
})

test_that("counts never exceed enrollment and published rates agree with their counts", {
  for (y in share_years) {
    x <- share(y)
    both <- !is.na(x$n_sped) & !is.na(x$n_enrolled)
    expect_true(all(x$n_sped[both] <= x$n_enrolled[both]), info = y)
    pub <- both & !is.na(x$pct_sped)
    expect_true(all(abs(x$n_sped[pub] / x$n_enrolled[pub] * 100 - x$pct_sped[pub]) <= 0.0051), info = y)
    expect_false(any(x$pct_sped > 100, na.rm = TRUE))
  }
})

test_that("PK is left out of every band and Pre-K enrollment does not enter a denominator", {
  x <- share(2025)
  enr <- fetch_enr(2025)
  d <- enr[enr$district_id %in% "1799" & enr$school_id == "999", ]
  k5 <- sum(d$row_total[d$grade_level %in% c("K", sprintf("%02d", 1:5))])
  expect_equal(x$n_enrolled[x$district_id %in% "1799" & x$grade_band == "elementary"], k5)
  expect_setequal(unique(x$grade_band), c("all", share_bands))
})

test_that("charter is the county-80 sector plus the Camden renaissance operators", {
  x <- share(2025)
  flag <- function(id) unique(x$is_charter[x$district_id %in% id & x$entity_level == "district"])
  expect_true(flag("1799"))   # renaissance operator in county 07
  expect_true(flag("1801"))
  expect_true(flag("1802"))
  expect_true(flag("7325"))   # county 80
  expect_false(flag("3570"))
  expect_false(flag("0680"))
  expect_true(all(is.na(x$is_charter[x$entity_level == "state"])))
  # The renaissance names the state lists are the LEAs behind these ids.
  g <- suppressWarnings(fetch_sped_by_grade(2025))
  nm <- unique(g$district_name[g$district_id %in% c("1799", "1801", "1802")])
  expect_equal(length(nm), 3L)
  expect_true(all(g$county_id[g$district_id %in% c("1799", "1801", "1802")] == "07"))
})

test_that("two real rows go through sped_all_vs_all", {
  x <- share(2025)
  focal <- data.frame(district_id = "1799", school_id = NA_character_)
  comp <- data.frame(district_id = "3570", school_id = NA_character_)
  r <- sped_all_vs_all(x, focal, comp)
  expect_equal(r$pct[r$group == "focal"], 404 / 2278 * 100)
  expect_equal(r$pct[r$group == "comparison"], 6795 / 44264 * 100)
  fb <- x[x$district_id %in% "1799" & x$grade_band %in% share_bands, c("grade_band", "n_enrolled")]
  l <- sped_like_for_like(x, focal, comp, fb)
  expect_equal(l$source, "by_band")
  expect_equal(l$n_bands, 3L)
})

test_that("finest grain by default is the district, with band rows; the state row is published", {
  for (y in share_years) {
    x <- share(y)
    expect_false(any(x$entity_level == "school"))
    expect_true(all(x$entity_level %in% c("state", "district")))
    expect_true(sum(x$grade_band %in% share_bands) > 1000L)
  }
  expect_equal(sum(share(2024)$entity_level == "state"), 1L)
  expect_equal(share(2024)$pct_sped[share(2024)$entity_level == "state"], 17.13)
})

test_that("2025-26 warns that the OPRA counts look incomplete and carries no IDEA row", {
  expect_warning(fetch_sped_share(2026), "incomplete")
  expect_false("all" %in% share(2026)$grade_band)
})

test_that("years and bases are validated", {
  expect_error(fetch_sped_share(2022), "not a valid end_year")
  expect_error(fetch_sped_share(2026, basis = "school_report"), "not a valid end_year")
  expect_equal(get_available_years("sped_share"), 2023:2026)
})

test_that("school_report basis returns school rows with spans from the report's own enrollment", {
  x <- tryCatch(fetch_sped_share(2024, basis = "school_report"), error = identity)
  testthat::skip_if(
    inherits(x, "error"),
    "School Performance Reports workbook not available in the local source cache"
  )
  s <- x[x$entity_level == "school", ]
  expect_gt(nrow(s), 2000L)
  expect_true(all(is.na(s$n_sped)))
  expect_true(all(s$pct_sped >= 0 & s$pct_sped <= 100, na.rm = TRUE))
  expect_equal(x$pct_sped_hi - x$pct_sped, rep(0.05, nrow(x)), tolerance = 1e-9)
  expect_equal(sum(x$entity_level == "state"), 1L)
  k <- s[s$district_id == "1799", ]
  expect_equal(nrow(k), 1L)
  expect_true(k$is_charter)
  expect_equal(c(k$grade_low, k$grade_high), c("K", "12"))
  # Pooling school rows by span: the helper reads rate-only rows as a range.
  p <- sped_pool(s[s$district_id == "1799", ])
  expect_equal(p$method, "published_rates_weighted")
})
