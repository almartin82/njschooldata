# Honest guards for live NJ DOE fetches.
#
# njschooldata classifies every source outcome (R/source_result.R). A request
# that does not yield usable data stops with a condition whose class names the
# reason:
#
#   njsd_source_unavailable  the artifact could not be retrieved at all
#   njsd_not_published       NJ DOE does not publish this slice
#   njsd_not_yet_observed    the reporting period has not produced it yet
#   njsd_parse_error         we retrieved something and could not read it
#
# Only the first three are the source's business, and only those are an honest
# reason to skip a live test. `njsd_parse_error` is OUR defect: reporting it as
# "source unavailable" blames NJ DOE for a package bug, which is exactly how a
# broken parse can sit green for months. So does an unclassed `stop()`, which
# is how an argument or coverage-boundary error arrives.
#
# The blanket form these guards replace did worse than mislabel the cause.
# testthat signals a failed expectation as a subclass of `error`:
#
#   class(tryCatch(testthat::expect_true(FALSE), error = identity))
#   #> "expectation_failure" "expectation" "error" "condition"
#
# so `tryCatch(expr, error = function(e) NULL)` followed by a skip swallowed
# the assertions' own failures too, and the suite still exited 0.
#
# `expr` is evaluated lazily inside the handler stack, so callers write the
# fetch inline: njsd_live(fetch_sped(2025), "fetch_sped(2025)").
njsd_live <- function(expr, what) {
  force(what)
  tryCatch(
    expr,
    njsd_source_unavailable = function(e) {
      testthat::skip(paste0(
        what, ": NJ DOE source unavailable -- ", conditionMessage(e)
      ))
    },
    njsd_not_published = function(e) {
      testthat::skip(paste0(
        what, ": NJ DOE declares this slice not published -- ",
        conditionMessage(e)
      ))
    },
    njsd_not_yet_observed = function(e) {
      testthat::skip(paste0(
        what, ": NJ DOE has not yet published this slice -- ",
        conditionMessage(e)
      ))
    }
  )
}
