# get_district_directory() / get_school_directory() were the pre-conversion
# wide-format directory functions. directory-contract/v1 replaces both with
# fetch_directory(), returning list(entities, roles, meta) (see
# test-directory-contract.R for the full conformance suite against the
# committed fixture, and test-directory-live.R for the live-source guard).
# This guard makes sure the legacy surface stays removed rather than
# silently reappearing.

test_that("legacy get_district_directory/get_school_directory surface stays removed", {
  ns <- asNamespace("njschooldata")
  expect_false(exists("get_district_directory", where = ns, inherits = FALSE))
  expect_false(exists("get_school_directory", where = ns, inherits = FALSE))
  expect_false(exists("clear_directory_cache", where = ns, inherits = FALSE))
})
