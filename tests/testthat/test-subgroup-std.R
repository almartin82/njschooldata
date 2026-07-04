context("subgroup standardization")

test_that("standardize_subgroup maps known cleaner tokens to the standard vocabulary", {
  expect_equal(standardize_subgroup("total population"), "total_enrollment")
  expect_equal(standardize_subgroup("economically disadvantaged"), "econ_disadv")
  expect_equal(standardize_subgroup("students with disabilities"), "special_ed")
  expect_equal(standardize_subgroup("limited english proficiency"), "lep")
  expect_equal(standardize_subgroup("american indian"), "native_american")
  expect_equal(standardize_subgroup("multiracial"), "multiracial")
  # PARCC-family tokens
  expect_equal(standardize_subgroup("total_population"), "total_enrollment")
  expect_equal(standardize_subgroup("lep_current"), "lep_current")
  expect_equal(standardize_subgroup("non_ed"), "non_econ_disadv")
})

test_that("standardize_subgroup returns NA with a single warning on unmatched tokens", {
  expect_warning(
    res <- standardize_subgroup(c("total population", "not a real subgroup")),
    "not a real subgroup"
  )
  expect_equal(res, c("total_enrollment", NA_character_))
})

test_that("every crosswalk raw_value maps to a valid token or explicit NA", {
  std_vocab <- c(
    "total_enrollment", "econ_disadv", "non_econ_disadv", "special_ed",
    "lep", "lep_current", "lep_former", "native_american", "asian", "black",
    "hispanic", "pacific_islander", "white", "multiracial", "other",
    "male", "female", "non_binary"
  )
  vals <- subgroup_crosswalk$subgroup_std
  expect_true(all(is.na(vals) | vals %in% std_vocab))
  # families are exactly the three cleaners
  expect_setequal(unique(subgroup_crosswalk$vocab_family), c("spr", "parcc", "grad6yr"))
})

test_that("add_subgroup_std inserts subgroup_std immediately after subgroup", {
  df <- data.frame(
    end_year = 2024L,
    subgroup = c("total population", "black", "white"),
    value = c(1, 2, 3),
    stringsAsFactors = FALSE
  )

  out <- add_subgroup_std(df)
  pos <- match("subgroup", names(out))
  expect_equal(names(out)[pos + 1], "subgroup_std")
  expect_equal(out$subgroup_std, c("total_enrollment", "black", "white"))
  # original columns and their order are otherwise preserved
  expect_equal(setdiff(names(df), names(out)), character(0))
})

test_that("add_subgroup_std is a no-op with a message when subgroup is absent", {
  df <- data.frame(a = 1:2, b = 3:4)
  expect_message(out <- add_subgroup_std(df), "No subgroup column")
  expect_identical(out, df)
})
