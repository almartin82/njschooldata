# Generated from contracts/sped-comparison/v1; do not hand-edit.
row <- function(district_id, school_id = NA_character_, grade_band = "all", n_sped = NA_real_,
                n_enrolled = NA_real_, pct_sped = NA_real_, pct_sped_lo = NA_real_,
                pct_sped_hi = NA_real_, grade_low = NA_character_, grade_high = NA_character_,
                entity_level = if (is.na(school_id)) "district" else "school") {
  data.frame(entity_level = entity_level, district_id = district_id, school_id = school_id, grade_band = grade_band,
             n_sped = n_sped, n_enrolled = n_enrolled, pct_sped = pct_sped,
             pct_sped_lo = pct_sped_lo, pct_sped_hi = pct_sped_hi,
             grade_low = grade_low, grade_high = grade_high, stringsAsFactors = FALSE)
}
ids <- function(district_id, school_id = NA_character_) {
  data.frame(district_id = district_id, school_id = school_id, stringsAsFactors = FALSE)
}

test_that("grade spans sort into bands and crossing spans read as mixed", {
  expect_equal(sped_grade_band(c("K", "PK", "06", "09", "K", "05"), c("05", "05", "08", "12", "08", "06")),
               c("elementary", "elementary", "middle", "high", "mixed", "mixed"))
  expect_true(is.na(sped_grade_band("UG", "05")))
})

test_that("pooling uses counts over enrollment, never an average of rates", {
  p <- sped_pool(rbind(row("1", "a", n_sped = 10, n_enrolled = 100), row("1", "b", n_sped = 90, n_enrolled = 300)))
  expect_equal(p$pct, 25)
  expect_equal(p$pct_lo, 25)
  expect_equal(p$pct_hi, 25)
  expect_equal(p$method, "counts_over_enrollment")
})

test_that("rate-only rows pool to a range from their published bounds", {
  p <- sped_pool(rbind(row("1", "a", pct_sped = 10, pct_sped_lo = 9.5, pct_sped_hi = 10.5, n_enrolled = 100),
                       row("1", "b", pct_sped = 20, pct_sped_lo = 19.5, pct_sped_hi = 20.5, n_enrolled = 300)))
  expect_equal(p$pct, 17.5)
  expect_equal(p$pct_lo, 17)
  expect_equal(p$pct_hi, 18)
  expect_equal(p$share_rate, 1)
})

test_that("a suppressed row widens the range to 0 to 100 and leaves no point figure", {
  p <- sped_pool(rbind(row("1", "a", n_sped = 10, n_enrolled = 100), row("1", "b", n_enrolled = 100)))
  expect_true(is.na(p$pct))
  expect_equal(p$pct_lo, 5)
  expect_equal(p$pct_hi, 55)
  expect_equal(p$share_neither, 0.5)
  expect_equal(p$method, "bounded_range")
})

test_that("a suppressed count with published bounds enters at those bounds", {
  p <- sped_pool(rbind(row("1", "a", n_sped = 10, n_enrolled = 100),
                       row("1", "b", n_enrolled = 100, pct_sped_lo = 1, pct_sped_hi = 9)))
  expect_true(is.na(p$pct))
  expect_equal(p$pct_lo, 5.5)
  expect_equal(p$pct_hi, 9.5)
  expect_equal(p$share_bounds, 0.5)
  expect_equal(p$share_neither, 0)
  expect_equal(p$method, "bounded_range")
})

test_that("a row with no enrollment is reported, not used and not zero", {
  p <- sped_pool(rbind(row("1", "a", n_sped = 10, n_enrolled = 100), row("1", "b", n_sped = 5)))
  expect_equal(p$pct, 10)
  expect_equal(p$rows_no_enrollment, 1L)
  expect_equal(sped_pool(row("1", "b", n_sped = 5))$method, "no_enrollment")
  expect_equal(sped_pool(row("1")[0, ])$method, "no_rows")
})

test_that("all vs all compares whole rows and ignores band rows", {
  rows <- rbind(row("1", "a", n_sped = 10, n_enrolled = 100),
                row("1", "a", grade_band = "high", n_sped = 99, n_enrolled = 100),
                row("2", n_sped = 300, n_enrolled = 2000))
  out <- sped_all_vs_all(rows, ids("1", "a"), ids("2"))
  expect_equal(out$pct, c(10, 15))
  expect_equal(out$group, c("focal", "comparison"))
})

test_that("a school with no state id never reads as its district row", {
  rows <- rbind(row("2", n_sped = 100, n_enrolled = 1000),
                row("2", n_sped = 90, n_enrolled = 100, entity_level = "school"))
  out <- sped_all_vs_all(rows, ids("2"), ids("2"))
  expect_equal(out$pct, c(10, 10))
  expect_equal(out$n_rows, c(1L, 1L))
})

test_that("like for like weights comparison bands by the focal group's mix", {
  rows <- rbind(row("2", "e", n_sped = 12, n_enrolled = 100, grade_low = "K", grade_high = "05"),
                row("2", "m", n_sped = 18, n_enrolled = 100, grade_low = "06", grade_high = "08"),
                row("2", "h", n_sped = 15, n_enrolled = 100, grade_low = "09", grade_high = "12"))
  x <- sped_like_for_like(rows, ids("1", "a"), ids("2", c("e", "m", "h")),
                          data.frame(grade_band = c("elementary", "middle"), n_enrolled = c(20, 80)))
  expect_equal(x$pct, 16.8)
  expect_equal(x$source, "single_band_schools")
  expect_equal(x$n_bands, 2L)
})

test_that("a composite is weighted by the focal mix, not by comparison size", {
  rows <- rbind(row("2", "e", n_sped = 100, n_enrolled = 1000, grade_low = "K", grade_high = "05"),
                row("2", "m", n_sped = 3, n_enrolled = 10, grade_low = "06", grade_high = "08"))
  x <- sped_like_for_like(rows, ids("1", "a"), ids("2", c("e", "m")),
                          data.frame(grade_band = c("elementary", "middle"), n_enrolled = c(50, 50)))
  expect_equal(x$pct, 20)
})

test_that("rows published by band win, and a mixed school is left out and reported", {
  rows <- rbind(row("2", grade_band = "middle", n_sped = 30, n_enrolled = 100))
  x <- sped_like_for_like(rows, ids("1", "a"), ids("2"), data.frame(grade_band = "middle", n_enrolled = 10))
  expect_equal(x$pct, 30)
  expect_equal(x$source, "by_band")

  rows <- rbind(row("2", "m", n_sped = 10, n_enrolled = 100, grade_low = "06", grade_high = "08"),
                row("2", "k8", n_sped = 90, n_enrolled = 100, grade_low = "K", grade_high = "08"))
  x <- sped_like_for_like(rows, ids("1", "a"), ids("2", c("m", "k8")), data.frame(grade_band = "middle", n_enrolled = 10))
  expect_equal(x$pct, 10)
  expect_equal(x$mixed_share, 0.5)
})

test_that("a band with no comparison data blanks the composite with the reason", {
  rows <- row("2", "e", n_sped = 12, n_enrolled = 100, grade_low = "K", grade_high = "05")
  x <- sped_like_for_like(rows, ids("1", "a"), ids("2", "e"),
                          data.frame(grade_band = c("elementary", "high"), n_enrolled = c(50, 50)))
  expect_true(is.na(x$pct))
  expect_match(x$reason, "band high")
})

test_that("an LEA-only comparison cannot produce a composite", {
  x <- sped_like_for_like(row("2", n_sped = 100, n_enrolled = 1000), ids("1", "a"), ids("2"),
                          data.frame(grade_band = "middle", n_enrolled = 10))
  expect_true(is.na(x$pct))
  expect_true(is.na(x$pct_lo))
})

test_that("bounds carry through a composite and unknown bands stop", {
  rows <- rbind(row("2", "m", pct_sped = 10, pct_sped_lo = 9.5, pct_sped_hi = 10.5, n_enrolled = 100,
                    grade_low = "06", grade_high = "08"))
  x <- sped_like_for_like(rows, ids("1", "a"), ids("2", "m"), data.frame(grade_band = "middle", n_enrolled = 10))
  expect_equal(c(x$pct_lo, x$pct_hi), c(9.5, 10.5))
  expect_error(sped_like_for_like(rows, ids("1", "a"), ids("2", "m"),
                                  data.frame(grade_band = "secondary", n_enrolled = 10)), "Unknown grade band")
})

position_rows <- function() {
  rbind(row("1", "f", n_sped = 12, n_enrolled = 100),
        row("2", "a", n_sped = 10, n_enrolled = 100),
        row("2", "b", n_sped = 20, n_enrolled = 100),
        row("2", "c", n_sped = 30, n_enrolled = 100),
        row("2", "d", n_sped = 280, n_enrolled = 700))
}

test_that("position reads the focal pool against rows, not against the comparison pool", {
  x <- sped_position(position_rows(), ids("1", "f"), ids("2", c("a", "b", "c", "d")))
  expect_equal(x$focal_pct, 12)
  expect_equal(c(x$median_lo, x$median_hi), c(25, 25))
  expect_equal(c(x$p25_lo, x$p75_lo), c(15, 35))
  expect_equal(c(x$percentile_lo, x$percentile_hi), c(25, 25))
  expect_equal(x$direction, "below")
  expect_false(x$inside_middle_half)
  expect_equal(x$comparison_lo, 34)
  expect_equal(x$n_used, 4L)
})

test_that("the one-point rule needs a gap above one point after rounding to a half", {
  rows <- rbind(row("1", "f", n_sped = 19, n_enrolled = 100), row("2", "a", n_sped = 10, n_enrolled = 50),
                row("2", "b", n_sped = 20, n_enrolled = 100), row("2", "c", n_sped = 30, n_enrolled = 100))
  expect_equal(sped_position(rows, ids("1", "f"), ids("2", c("a", "b", "c")))$direction, "close")
  rows$n_sped[1] <- 18.6
  expect_equal(sped_position(rows, ids("1", "f"), ids("2", c("a", "b", "c")))$direction, "below")
})

test_that("enrollment weight moves the distribution and the percentile", {
  x <- sped_position(position_rows(), ids("1", "f"), ids("2", c("a", "b", "c", "d")), weight = "enrollment")
  expect_equal(c(x$median_lo, x$p25_lo, x$p75_lo), c(40, 30, 40))
  expect_equal(x$percentile_lo, 10)
})

test_that("focal rows never sit in their own distribution", {
  x <- sped_position(position_rows(), ids("1", "f"), rbind(ids("1", "f"), ids("2", c("a", "b", "c", "d"))))
  expect_equal(x$n_used, 4L)
  expect_equal(x$n_focal_removed, 1L)
  expect_equal(x$percentile_lo, 25)
})

test_that("a suppressed row is excluded and reported, never read as zero", {
  rows <- rbind(position_rows(), row("2", "e", n_enrolled = 400))
  x <- sped_position(rows, ids("1", "f"), ids("2", c("a", "b", "c", "d", "e")))
  expect_equal(x$n_no_value, 1L)
  expect_equal(x$n_used, 4L)
  expect_equal(x$median_lo, 25)
  expect_equal(x$coverage, 1000 / 1400)
})

test_that("a bounded row gives ranges, never a midpoint", {
  rows <- rbind(position_rows()[1:3, ], row("2", "c", pct_sped_lo = 5, pct_sped_hi = 15, n_enrolled = 100))
  x <- sped_position(rows, ids("1", "f"), ids("2", c("a", "b", "c")))
  expect_equal(c(x$median_lo, x$median_hi), c(10, 15))
  expect_equal(c(x$percentile_lo, x$percentile_hi), c(100 * 1 / 3, 100 * 2 / 3))
  expect_equal(x$direction, "unknown")
  expect_true(x$inside_middle_half)
})

test_that("a rate above 100 is out and reported, a focal pool in range stays close", {
  rows <- rbind(position_rows(), row("2", "e", n_sped = 150, n_enrolled = 100), row("1", "g", n_sped = 28, n_enrolled = 100))
  x <- sped_position(rows, ids("1", c("f", "g")), ids("2", c("a", "b", "c", "e")))
  expect_equal(x$n_impossible, 1L)
  expect_equal(x$median_lo, 20)
  expect_equal(x$focal_pct, 20)
  expect_equal(x$direction, "close")
  expect_true(x$inside_middle_half)
})

test_that("focal bands weight the distribution and blank a missing band", {
  rows <- rbind(row("1", "f", n_sped = 12, n_enrolled = 100),
                row("2", "e", n_sped = 10, n_enrolled = 100, grade_low = "K", grade_high = "05"),
                row("2", "m", n_sped = 30, n_enrolled = 100, grade_low = "06", grade_high = "08"),
                row("2", "n", n_sped = 40, n_enrolled = 100, grade_low = "06", grade_high = "08"),
                row("2", "k", n_sped = 90, n_enrolled = 100, grade_low = "K", grade_high = "08"))
  cmp <- ids("2", c("e", "m", "n", "k"))
  x <- sped_position(rows, ids("1", "f"), cmp, focal_bands = data.frame(grade_band = c("elementary", "middle"), n_enrolled = c(75, 25)))
  expect_equal(x$median_lo, 10)
  expect_equal(x$n_mixed, 1L)
  expect_equal(x$coverage, 0.75)
  y <- sped_position(rows, ids("1", "f"), cmp, focal_bands = data.frame(grade_band = "high", n_enrolled = 10))
  expect_match(y$reason, "band high")
  expect_true(is.na(y$median_lo))
})
