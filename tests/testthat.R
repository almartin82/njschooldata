library(testthat)

run_full_offline <- tolower(Sys.getenv(
  "SCHOOLDATA_RUN_FULL_OFFLINE_TESTS", unset = "false"
)) %in% c("1", "true", "yes")

if (run_full_offline) {
  # Keep the broad parser and fidelity suite available as an explicit offline
  # tier. DOE reads remain behind the separate manual canary entry point.
  Sys.setenv(NJSCHOOLDATA_LIVE_TESTS = "false")
  test_check("njschooldata")
} else {
  # Ordinary installed-build checks cover source identity, representative
  # verified package parses, typed cold misses, cache, transport and directory
  # contracts. The year-by-year and broader parser sweep is opt-in above.
  test_check(
    "njschooldata",
    filter = paste0(
      "^(fast-offline|available-years-contract|source-result|source-transport|",
      "transport-canonical|source-cache-lock|held-source-routing|release-sources|",
      "directory-contract|directory-multiplicity|directory-source-fidelity|",
      "directory-source-provenance|data-registry|program-contract|",
      "source-adapter-fixtures|shipped-fixture-values|nj-spr-extracts)$"
    )
  )
}
