test_that("a district missing from the directory crosswalk gets its CCD id", {
  # Hainesport (05-1910) and Stow Creek (11-5070) are operating districts that
  # the current-directory crosswalk does not carry.
  df <- data.frame(county_id = c("05", "11", "13", "99"),
                   district_id = c("1910", "5070", "0130", "9999"),
                   school_id = c("999", "999", "999", "999"),
                   stringsAsFactors = FALSE)
  out <- attach_nces_ids(df)
  expect_identical(out$nces_dist[1:2], c("3406420", "3415840"))
  expect_true(is.na(out$nces_dist[4]))
})

test_that("the fallback never reuses an id another district already holds", {
  df <- data.frame(county_id = c("01", "05"), district_id = c("0010", "1910"),
                   school_id = "999", nces_dist = c("3406420", NA),
                   stringsAsFactors = FALSE)
  out <- .fill_nces_dist_from_ccd(df)
  expect_identical(out, c("3406420", NA))
})
