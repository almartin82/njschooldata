# test-directory-live.R -- package-authored live staleness guard for
# directory-contract/v1. Runs ONLY online (skip_if_offline); offline the
# conformance suite still passes on the committed fixture alone.
#
# It calls fetch_directory() against the live NJDOE Homeroom downloads and
# asserts the live result still matches the fixture's coverage declaration and
# source_status, and that row counts have not collapsed. Live drift fails online
# CI and prompts a fixture refresh (see contracts/directory/v1/fixture-contract.md).
#
# The NJDOE Homeroom endpoints sit behind Incapsula bot protection that serves a
# JavaScript challenge to plain HTTP clients. When the runner's httr request is
# challenged, fetch_directory() honestly returns source_status
# "source_unavailable" (a declared miss, not a crash); we skip in that case
# rather than fail, because a bot-blocked runner is a source-availability
# condition, not package drift.

test_that("directory-live: live fetch matches fixture coverage and does not collapse", {
  testthat::skip_on_cran()
  testthat::skip_if_offline()

  fixture_path <- testthat::test_path(
    "fixtures", "directory-contract", "snapshot.rds"
  )
  testthat::skip_if_not(
    file.exists(fixture_path),
    "directory-contract fixture missing"
  )
  fx <- readRDS(fixture_path)

  live <- tryCatch(
    fetch_directory(),
    error = function(e) {
      testthat::skip(paste("live directory fetch failed:", conditionMessage(e)))
    }
  )

  # A bot-blocked / unreachable source is a declared miss, not drift.
  if (identical(live$meta$source_status, "source_unavailable")) {
    testthat::skip(
      "NJDOE Homeroom downloads were unreachable (bot-protection / outage)"
    )
  }

  # Same triple shape.
  expect_true(setequal(names(live), c("entities", "roles", "meta")))
  expect_true(is.data.frame(live$entities))
  expect_true(is.data.frame(live$roles))

  # Same coverage declaration as the fixture.
  cov_live <- live$meta$coverage
  cov_fx <- fx$meta$coverage
  expect_identical(
    as.character(cov_live$entity_types), as.character(cov_fx$entity_types)
  )
  expect_identical(
    as.character(cov_live$district_roles), as.character(cov_fx$district_roles)
  )
  expect_identical(
    as.character(cov_live$school_roles), as.character(cov_fx$school_roles)
  )
  expect_identical(cov_live$org_only, cov_fx$org_only)
  expect_identical(cov_live$principal_only, cov_fx$principal_only)

  # Same source_status (a deliberate change should be accompanied by a fixture
  # refresh and an update here).
  expect_identical(live$meta$source_status, fx$meta$source_status)

  # Non-collapsing row counts: live must retain at least half the fixture's
  # districts, schools, and roles.
  expect_gte(
    live$meta$counts$districts, ceiling(fx$meta$counts$districts * 0.5)
  )
  expect_gte(
    live$meta$counts$schools, ceiling(fx$meta$counts$schools * 0.5)
  )
  expect_gte(
    live$meta$counts$roles_total, ceiling(fx$meta$counts$roles_total * 0.5)
  )

  # Integrity zeros hold on the live pull too.
  expect_identical(as.integer(live$meta$quality$missing_id_count), 0L)
  expect_identical(as.integer(live$meta$quality$placeholder_id_count), 0L)
})
