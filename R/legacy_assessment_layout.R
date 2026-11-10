# Lazy-loaded datasets live outside the namespace. Load into a private
# environment so namespace-only callers do not depend on the search path.
.legacy_assessment_layout <- function(name) {
  layouts <- new.env(parent = emptyenv())
  topic <- paste0(sub("^layout_", "", name), "_layout")
  utils::data(list = topic, package = "njschooldata", envir = layouts)
  get(name, envir = layouts, inherits = FALSE)
}
