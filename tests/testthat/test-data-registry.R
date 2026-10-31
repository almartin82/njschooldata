# Canonical copy: contracts/data-registry/v1/test-data-registry.R. Do not edit in
# a package. Offline: reads only what the package ships.

test_that("the data registry has the contract's shape", {
  reg <- get_data_registry()
  expect_s3_class(reg, "data.frame")
  expect_identical(names(reg), .registry_columns)
  expect_true(all(reg$status %in% .registry_statuses))
  expect_false(anyNA(reg$family))
  expect_gt(sum(reg$status == "served"), 0L)
})

test_that("get_data_registry filters on family and year", {
  reg <- get_data_registry()
  one <- reg[reg$status == "served", ][1, ]
  hit <- get_data_registry(family = one$family, end_year = one$end_year)
  expect_true(all(hit$family == one$family & hit$end_year == one$end_year))
  expect_gt(nrow(hit), 0L)
})

test_that("served years in the registry are exactly the claimed years", {
  reg <- get_data_registry()
  served <- unique(reg[reg$status == "served", c("family", "end_year")])
  # Several types can roll up to one family, so compare after the crosswalk.
  crosswalk <- .registry_read_csv("families.csv")
  cov <- .registry_coverage(crosswalk)
  claimed <- unique(cov[c("family", "end_year")])
  expect_setequal(paste(served$family, served$end_year), paste(claimed$family, claimed$end_year))
})

test_that("every known fact ties to the package and the package to a known fact", {
  expect_identical(.registry_violations(), character())
})

test_that("each rule can fail", {
  sources <- .registry_read_csv("sources.csv")
  gaps <- .registry_read_csv("gaps.csv")
  has_rule <- function(v, n) any(startsWith(v, sprintf("rule %d:", n)))

  dropped <- sources[-seq_len(nrow(sources)), ]
  expect_true(has_rule(.registry_violations(dropped, gaps), 1L))
  expect_true(has_rule(.registry_violations(dropped, gaps), 3L))

  doubled <- rbind(sources, sources)
  doubled$source_id[seq_len(nrow(sources))] <- paste0("copy_", sources$source_id)
  expect_true(has_rule(.registry_violations(doubled, gaps), 1L))

  dead <- sources[1, ]
  dead$source_id <- "dead_source"
  dead$match <- "^no artifact looks like this$"
  dead$fetcher <- NA_character_
  expect_true(has_rule(.registry_violations(rbind(sources, dead), gaps), 2L))

  cov <- get_available_years()
  served <- data.frame(family = .registry_family_of(cov$type[[1]], .registry_read_csv("families.csv")),
                       end_year = as.character(cov$end_year[[1]]), source_id = NA_character_,
                       reason = "not_published", evidence = "self test", checked_on = "2026-01-01",
                       note = NA_character_, stringsAsFactors = FALSE)
  expect_true(has_rule(.registry_violations(sources, served), 4L))
  unknown <- served
  unknown$end_year <- "1900"
  unknown$reason <- "seemed_hard"
  expect_true(has_rule(.registry_violations(sources, unknown), 4L))
})
