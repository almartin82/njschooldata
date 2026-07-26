live_tests_enabled <- function() {
  identical(tolower(Sys.getenv("NJSCHOOLDATA_LIVE_TESTS", unset = "false")), "true")
}

skip_if_no_live_tests <- function() {
  testthat::skip_if_not(
    live_tests_enabled(),
    "Set NJSCHOOLDATA_LIVE_TESTS=true to run NJ DOE live-source tests."
  )
}
