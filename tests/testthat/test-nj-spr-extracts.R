test_that("SPR extracts retain source lineage and complete row counts", {
  path <- system.file("extdata/source-contract/contracts/new_jersey_shipped_sources/artifact-manifest.json",
                      package = "njschooldata")
  artifacts <- jsonlite::read_json(path)$artifacts
  extracts <- Filter(function(a) grepl("^spr-school-", a$artifact_id), artifacts)
  expect_length(extracts, 6L)
  for (a in extracts) {
    parent <- a$lineage$parent_workbook
    expect_match(parent$sha256, "^[0-9a-f]{64}$")
    expect_gt(parent$byte_length, 10000000)
    expect_identical(parent$source_identity, a$source_identity)
    expect_identical(parent$source_identity$retrieved_at, "2026-11-01")
    expect_match(parent$source_identity$url, "^https://www.nj.gov/education/")
    expect_lt(a$byte_length, 10000000)
    x <- njschooldata:::.nj_landing_spr_extract(a$lineage$sheet, as.integer(a$selectors$key))
    expect_equal(nrow(x), a$lineage$row_count)
    expect_identical(names(x), unlist(a$lineage$columns, use.names = FALSE))
    expect_true(all(vapply(x, is.character, logical(1))))
  }
})

test_that("each SPR extract stops on same-size tampering, truncation or absence", {
  manifest <- system.file("extdata/source-contract/contracts/new_jersey_shipped_sources/artifact-manifest.json",
                          package = "njschooldata")
  artifacts <- jsonlite::read_json(manifest)$artifacts
  extracts <- Filter(function(a) grepl("^spr-school-", a$artifact_id), artifacts)
  for (a in extracts) local({
    path <- system.file(sub("^inst/", "", a$storage$path), package = "njschooldata")
    bytes <- readBin(path, "raw", n = file.info(path)$size)
    on.exit(writeBin(bytes, path))
    read <- function() njschooldata:::.nj_landing_spr_extract(
      a$lineage$sheet, as.integer(a$selectors$key))
    bad <- bytes
    # Change gzip's timestamp only: decompression still works, so this catches
    # a removed digest check rather than relying on gzip corruption errors.
    bad[5L] <- as.raw(bitwXor(as.integer(bad[5L]), 1L))
    writeBin(bad, path)
    expect_error(read(), "SHA-256 mismatch")
    writeBin(bytes[-length(bytes)], path)
    expect_error(read(), "SHA-256 mismatch")
    unlink(path)
    expect_error(read(), "SHA-256 mismatch")
  })
})
