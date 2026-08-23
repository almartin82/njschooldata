# ==============================================================================
# Keep the test suite out of the caller's real on-disk cache
# ==============================================================================
#
# njschooldata keeps three on-disk caches under
# tools::R_user_dir("njschooldata", "cache"):
#
#   spr-workbooks/    SPR Excel databases (the SY2024-25 School file is ~350 MB)
#   sped-placement/   IDEA 618 placement workbooks
#   facilities/       .rds snapshots of the facilities sources, reused 30 days
#
# Without this file the suite reads AND writes those directories on whatever
# machine it runs on, which is wrong in both directions:
#
#   * A test can pass on a warm workbook that a fresh checkout would never
#     have, so any claim about offline coverage measured that way is false.
#   * A test that clears a cache, or writes a stub onto a genuine cache key,
#     mutates state outside the package, and the next ordinary call serves
#     whatever the test left behind. A stub sitting on a real key is fabricated
#     data handed to a user.
#
# NJSCHOOLDATA_CACHE_DIR redirects njsd_cache_root(), and therefore all three
# caches, into a per-process temp directory. The PID is in the path so two
# concurrent runs cannot collide, and so a destructive helper that unlink()s a
# cache root can only reach this run's own scratch space.
#
# The variable is set only when it is absent, so a value supplied by CI, or by
# a developer who deliberately wants a warm cache, still wins.

if (!nzchar(Sys.getenv("NJSCHOOLDATA_CACHE_DIR", unset = ""))) {
  njsd_isolated_cache_root <- file.path(
    tempdir(), sprintf("njschooldata-cache-%d", Sys.getpid())
  )
  dir.create(njsd_isolated_cache_root, recursive = TRUE, showWarnings = FALSE)
  Sys.setenv(NJSCHOOLDATA_CACHE_DIR = njsd_isolated_cache_root)

  withr::defer(
    {
      unlink(njsd_isolated_cache_root, recursive = TRUE, force = TRUE)
      Sys.unsetenv("NJSCHOOLDATA_CACHE_DIR")
    },
    envir = testthat::teardown_env()
  )
}
