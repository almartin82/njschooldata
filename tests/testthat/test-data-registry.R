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

# Isolate routing metadata from each package's real publications and files. These
# fixtures contain no education values, and never read or fetch source bytes.
registry_routing_fixture <- function() {
  fixture <- new.env(parent = environment(.registry_compute))
  for (name in c(".registry_compute", ".registry_violations")) {
    fn <- get(name, envir = fixture)
    environment(fn) <- fixture
    assign(name, fn, envir = fixture)
  }
  fixture$.registry_package <- function() "xxschooldata"
  fixture$.registry_read_csv <- function(name) NULL
  fixture$.registry_add_directory <- function(out, state) out
  fixture$.registry_artifacts <- function(crosswalk) data.frame(
    artifact_id = "reference", lineage = "derived", path = "reference/metadata",
    url = NA_character_, bytes = NA_real_, family = "reference",
    end_year = NA_integer_, match_text = "reference/metadata", stringsAsFactors = FALSE
  )
  fixture$.registry_coverage <- function(crosswalk) data.frame(
    family = "assessment", end_year = 2020L, mode = c("package", "live"),
    fetcher = c("fetch_historical", "fetch_current"), stringsAsFactors = FALSE
  )
  fixture$sources <- data.frame(
    source_id = c("historical", "current"), family = "assessment",
    fetcher = c("fetch_historical", "fetch_current"), fetcher_years = NA_character_,
    match = NA_character_, publisher = "State DOE", publisher_type = "state_doe",
    title = c("Historical release", "Current release"), year_basis = "test_admin",
    landing_url = NA_character_, stringsAsFactors = FALSE
  )
  fixture$gap <- data.frame(
    family = "assessment", end_year = "2020", source_id = "cancelled",
    reason = "not_published", evidence = "Publication cancelled",
    checked_on = "2026-01-01", note = "No spring administration",
    stringsAsFactors = FALSE
  )
  fixture
}

test_that("each source reports only its registered fetcher's coverage", {
  fixture <- registry_routing_fixture()
  reg <- fixture$.registry_compute(fixture$sources, NULL)
  expect_identical(reg$source_id, c("current", "historical"))
  expect_identical(reg$status, c("served", "served"))
  expect_identical(reg$fetcher, c("fetch_current", "fetch_historical"))
  expect_identical(reg$mode, c("live", "package"))
})

test_that("a named gap coexists with other served sources in the same year", {
  fixture <- registry_routing_fixture()
  reg <- fixture$.registry_compute(fixture$sources, fixture$gap)
  gap <- reg[reg$source_id == "cancelled", ]
  expect_equal(nrow(gap), 1L)
  expect_identical(gap$status, "not_published")
  expect_identical(gap$evidence, fixture$gap$evidence)
  expect_identical(gap$checked_on, fixture$gap$checked_on)
  expect_identical(gap$reason, fixture$gap$note)
  expect_setequal(reg$source_id[reg$status == "served"], c("historical", "current"))
  expect_false(any(startsWith(fixture$.registry_violations(fixture$sources, fixture$gap), "rule 4:")))

  fixture$gap$source_id <- "historical"
  expect_true(any(startsWith(fixture$.registry_violations(fixture$sources, fixture$gap), "rule 4:")))
  fixture$gap$source_id <- NA_character_
  expect_true(any(startsWith(fixture$.registry_violations(fixture$sources, fixture$gap), "rule 4:")))
})

test_that("a named gap fills an unknown cell without duplicating it", {
  fixture <- registry_routing_fixture()
  fixture$gap$end_year <- "2019"
  reg <- fixture$.registry_compute(fixture$sources, fixture$gap)
  gap <- reg[reg$end_year == 2019L, ]
  expect_equal(nrow(gap), 1L)
  expect_identical(gap$source_id, "cancelled")
  expect_identical(gap$status, "not_published")
  expect_false(any(startsWith(fixture$.registry_violations(fixture$sources, fixture$gap), "rule 4:")))
})

test_that("fetcher coverage respects a source ID's family and all its fetchers", {
  fixture <- registry_routing_fixture()
  other_family <- fixture$sources[1, ]
  other_family$family <- "staff"
  other_family$fetcher <- "fetch_current"
  another_fetcher <- fixture$sources[1, ]
  another_fetcher$fetcher <- "fetch_current"
  fixture$sources <- rbind(other_family, fixture$sources)
  reg <- fixture$.registry_compute(fixture$sources, NULL)
  historical <- reg[reg$source_id == "historical", ]
  expect_identical(historical$status, "served")
  expect_identical(historical$fetcher, "fetch_historical")
  expect_identical(historical$mode, "package")
  fixture$sources <- rbind(fixture$sources, another_fetcher)
  reg <- fixture$.registry_compute(fixture$sources, NULL)
  historical <- reg[reg$source_id == "historical", ]
  expect_identical(historical$status, "served")
  expect_identical(historical$fetcher, "fetch_current; fetch_historical")
  expect_identical(historical$mode, "live; package")
  expect_identical(reg$fetcher[reg$source_id == "current"], "fetch_current")
})

test_that("a source naming fetch_x is credited with fetch_x_multi coverage", {
  fixture <- registry_routing_fixture()
  fixture$.registry_coverage <- function(crosswalk) data.frame(
    family = "assessment", end_year = 2020L, mode = c("package", "live"),
    fetcher = c("fetch_historical_multi", "fetch_current"), stringsAsFactors = FALSE
  )
  reg <- fixture$.registry_compute(fixture$sources, NULL)
  historical <- reg[reg$source_id == "historical", ]
  expect_identical(historical$status, "served")
  expect_identical(historical$fetcher, "fetch_historical_multi")
  expect_identical(reg$fetcher[reg$source_id == "current"], "fetch_current")
})
