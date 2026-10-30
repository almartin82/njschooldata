# available-years contract v1: get_available_years(type) claims exactly the
# end years the type's fetcher serves under default arguments.

test_that("available years have the contract shapes offline", {
  years <- get_available_years("enrollment")
  expect_type(years, "integer")
  expect_identical(years, sort(unique(years)))
  expect_false(anyNA(years))
  expect_gt(length(years), 0L)
  coverage <- get_available_years()
  expect_s3_class(coverage, "data.frame")
  expect_identical(names(coverage), c("type", "end_year", "fetcher"))
  expect_type(coverage$type, "character")
  expect_type(coverage$end_year, "integer")
  expect_type(coverage$fetcher, "character")
  expect_equal(coverage, coverage[order(coverage$type, coverage$end_year), ])
  expect_false(anyDuplicated(coverage) > 0L)
  expect_identical(coverage$end_year[coverage$type == "enrollment"], years)
  expect_true(all(coverage$fetcher[coverage$type == "enrollment"] == "fetch_enr"))
  for (type in setdiff(names(.nj_year_fetchers), unique(coverage$type))) {
    expect_error(get_available_years(type), "coverage not yet declared")
  }
  expect_error(get_available_years("unknown"), "Declared types: enrollment")
  expect_error(get_available_years(NA_character_), "Declared types")
})

test_that("the contract checker can fail", {
  ay_contract_self_test()
})

for (declared_type in unique(get_available_years()$type)) {
  local({
    type <- declared_type
    test_that(paste("live available-years contract:", type), {
      skip_on_cran()
      # Undo the suite's cache isolation and any caller-specific override so
      # this exercises real acquisition through the ordinary persistent cache.
      withr::local_options(njschooldata.cache_dir = NULL)
      withr::local_envvar(c(NJSCHOOLDATA_CACHE_DIR = NA_character_,
                            STATE_SCHOOLDATA_HISTORICAL_ROOT = NA_character_))
      coverage <- get_available_years()
      fetcher <- get(coverage$fetcher[match(type, coverage$type)])
      ay_expect_contract(type, get_available_years, fetcher)
    })
  })
}
