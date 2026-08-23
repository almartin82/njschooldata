# ==============================================================================
# The suite must not read or write the caller's real on-disk cache
# ==============================================================================
#
# tests/testthat/setup-cache-isolation.R points NJSCHOOLDATA_CACHE_DIR at a
# per-process temp directory. These tests exist so that deleting or breaking
# that file fails the suite loudly instead of silently letting every test read
# and write ~/Library/Caches/org.R-project.R/R/njschooldata.
#
# Two shapes are deliberately avoided here, because both produce a tripwire
# that cannot fail:
#
#   * A test that installs its own override (withr::local_envvar(), an options()
#     call) never observes the ambient value the setup file exists to set, so
#     the file stays green after the setup file is deleted. The first test below
#     therefore installs NO override of its own.
#   * startsWith(x, "") is TRUE for every x in R, so asserting
#     startsWith(root, Sys.getenv("NJSCHOOLDATA_CACHE_DIR")) PASSES when the
#     variable is unset -- exactly the state a mutation check creates. Every
#     startsWith() against the override below is guarded by nzchar() first, and
#     is paired with the negative form against the real cache directory, which
#     a vacuous TRUE cannot satisfy.

njsd_real_cache_dir <- function() {
  tools::R_user_dir("njschooldata", which = "cache")
}


test_that("the ambient cache root is redirected away from the real cache", {
  # No local override: this test reads whatever the setup file left behind.
  # The option is neutralised (that removes an override rather than installing
  # one) so a leaked options() call from an earlier file cannot mask the
  # environment variable this test is here to check.
  withr::local_options(njschooldata.cache_dir = NULL)

  override <- Sys.getenv("NJSCHOOLDATA_CACHE_DIR", unset = "")
  expect_true(nzchar(override))

  root <- njschooldata:::njsd_cache_root()
  real <- njsd_real_cache_dir()

  expect_identical(root, override)
  expect_false(startsWith(root, real))
  expect_true(startsWith(root, override))
  expect_true(dir.exists(root))
})


test_that("every on-disk cache directory resolves under the override", {
  withr::local_options(njschooldata.cache_dir = NULL)

  override <- Sys.getenv("NJSCHOOLDATA_CACHE_DIR", unset = "")
  expect_true(nzchar(override))
  real <- njsd_real_cache_dir()

  dirs <- list(
    spr_workbooks = njschooldata::njsd_workbook_cache_dir(),
    sped_placement = njschooldata:::sped_placement_cache_dir(),
    facilities = njschooldata:::facilities_cache_dir()
  )

  for (nm in names(dirs)) {
    expect_false(startsWith(dirs[[nm]], real), info = nm)
    expect_true(startsWith(dirs[[nm]], override), info = nm)
  }
})


test_that("njsd_cache_root is the only resolver of the user cache directory", {
  # Walking the namespace catches a future fourth cache root that nobody
  # remembered to add to a list, which is precisely how facilities_cache_dir()
  # spent its life bypassing every override the package honoured.
  ns <- asNamespace("njschooldata")
  names_in_ns <- ls(ns, all.names = TRUE)

  offenders <- Filter(function(nm) {
    obj <- tryCatch(get(nm, envir = ns, inherits = FALSE), error = function(e) NULL)
    if (!is.function(obj)) return(FALSE)
    deparsed <- paste(deparse(body(obj)), collapse = "\n")
    grepl("R_user_dir", deparsed, fixed = TRUE)
  }, names_in_ns)

  expect_identical(sort(offenders), "njsd_cache_root")
})


test_that("the default cache root is unchanged when nothing overrides it", {
  # Resolution only; nothing is read or written, so removing the override
  # inside this scope cannot touch the real cache.
  withr::local_envvar(c(NJSCHOOLDATA_CACHE_DIR = NA))
  withr::local_options(njschooldata.cache_dir = NULL)

  expect_identical(njschooldata:::njsd_cache_root(), njsd_real_cache_dir())
})


test_that("options(njschooldata.cache_dir) still outranks the environment", {
  withr::local_options(
    njschooldata.cache_dir = file.path(tempdir(), "njsd-precedence")
  )
  expect_identical(
    njschooldata:::njsd_cache_root(),
    file.path(tempdir(), "njsd-precedence")
  )
  expect_identical(
    njschooldata::njsd_workbook_cache_dir(),
    file.path(tempdir(), "njsd-precedence", "spr-workbooks")
  )
})
