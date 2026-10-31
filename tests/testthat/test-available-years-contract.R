# available-years contract v1: get_available_years(type) claims exactly the
# end years the type's fetcher serves under default arguments.

test_that("available years have the contract shapes offline", {
  coverage <- get_available_years()
  expect_s3_class(coverage, "data.frame")
  expect_identical(names(coverage), c("type", "end_year", "fetcher"))
  expect_type(coverage$type, "character")
  expect_type(coverage$end_year, "integer")
  expect_type(coverage$fetcher, "character")
  expect_equal(coverage, coverage[order(coverage$type, coverage$end_year), ])
  expect_false(anyDuplicated(coverage) > 0L)
  for (type in unique(coverage$type)) {
    years <- get_available_years(type)
    expect_type(years, "integer")
    expect_identical(years, sort(unique(years)))
    expect_false(anyNA(years))
    expect_gt(length(years), 0L)
    expect_identical(coverage$end_year[coverage$type == type], years)
    expect_true(all(coverage$fetcher[coverage$type == type] == .nj_year_fetchers[[type]]))
  }
  for (type in setdiff(names(.nj_year_fetchers), unique(coverage$type))) {
    expect_error(get_available_years(type), "coverage not yet declared")
  }
  expect_error(get_available_years("unknown"), "Declared types:")
  expect_error(get_available_years(NA_character_), "Declared types")
})

test_that("finance year helper preserves its vector shape", {
  expect_identical(get_available_finance_years(), get_available_years("finance"))
})

test_that("assessment requires explicit selectors", {
  expect_error(fetch_parcc(2024), 'argument "subj" is missing, with no default')
  expect_error(get_available_years("assessment"), "coverage not yet declared")
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
      withr::local_options(njschooldata.cache_dir = NULL,
                           njschooldata.workbook_cache = TRUE)
      withr::local_envvar(c(NJSCHOOLDATA_CACHE_DIR = NA_character_,
                            STATE_SCHOOLDATA_HISTORICAL_ROOT = NA_character_))
      old_cache_state <- .njsd_cache$enabled
      withr::defer({ .njsd_cache$enabled <- old_cache_state })
      .njsd_cache$enabled <- TRUE
      coverage <- get_available_years()
      fetcher <- get(coverage$fetcher[match(type, coverage$type)])
      ay_expect_contract(type, get_available_years, fetcher)
    })
  })
}
