test_that("bundled metadata works from an unattached installed namespace", {
  script <- tempfile(fileext = ".R")
  on.exit(unlink(script), add = TRUE)
  writeLines(c(
    paste0(".libPaths(", paste(deparse(.libPaths()), collapse = ""), ")"),
    'stopifnot(!"package:njschooldata" %in% search())',
    'stopifnot(identical(njschooldata::standardize_subgroup("total population"), "total_enrollment"))',
    'out <- njschooldata::add_subgroup_std(data.frame(subgroup = "black"))',
    'stopifnot(identical(out$subgroup_std, "black"))',
    'breaks <- njschooldata::get_era_breaks("econ_disadv")',
    'stopifnot(is.data.frame(breaks), nrow(breaks) > 0L, all(breaks$break_set == "econ_disadv"))',
    'err <- tryCatch(njschooldata::tag_era(data.frame(end_year = 2024L), "unknown"), error = identity)',
    'stopifnot(inherits(err, "error"), grepl("Unknown break_set", conditionMessage(err)))',
    'stopifnot(!"package:njschooldata" %in% search())'
  ), script)
  output <- suppressWarnings(system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", shQuote(script)), stdout = TRUE, stderr = TRUE
  ))
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  expect_equal(status, 0L, info = paste(output, collapse = "\n"))
})
