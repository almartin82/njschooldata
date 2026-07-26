library(testthat)

live <- identical(
  tolower(Sys.getenv("NJSCHOOLDATA_LIVE_TESTS", unset = "false")),
  "true"
)

if (live) {
  test_check("njschooldata")
} else {
  test_check("njschooldata", filter = "^live-", invert = TRUE)
}
