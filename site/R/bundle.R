# Bundle loading, formatting, and missing-data guards for profile pages.

suppressMessages({ library(dplyr) })

BUNDLE_DIR <- file.path("_bundles")  # relative to site/ (quarto cwd)

#' Load a pre-built district bundle by id.
load_bundle <- function(id) {
  p <- file.path(BUNDLE_DIR, paste0(id, ".rds"))
  if (!file.exists(p)) stop("No bundle for district ", id, " at ", p)
  readRDS(p)
}

# ---- formatting -------------------------------------------------------------
fmt_int    <- function(x) ifelse(is.na(x), "n/a", formatC(round(x), format = "d", big.mark = ","))
fmt_dollar <- function(x) ifelse(is.na(x), "n/a", paste0("$", formatC(round(x), format = "d", big.mark = ",")))
fmt_pct    <- function(x, digits = 1) ifelse(is.na(x), "n/a", paste0(formatC(x, format = "f", digits = digits), "%"))
# grad/assess rates arrive as proportions (0-1) in some fetchers, percents in others
as_pct_scale <- function(x) ifelse(!is.na(x) & max(x, na.rm = TRUE) <= 1.5, x * 100, x)

#' TRUE when a section has usable data (non-null, has rows / finite values).
has_data <- function(x) {
  if (is.null(x)) return(FALSE)
  if (is.data.frame(x)) return(nrow(x) > 0)
  if (is.list(x)) return(length(x) > 0 && !all(vapply(x, function(v) all(is.na(v)), logical(1))))
  any(is.finite(x))
}

#' Ordinal-ish percentile phrasing for prose ("72nd percentile among 37 DFG I peers").
peer_phrase <- function(pctile, n_peers, dfg) {
  if (is.na(pctile)) return("")
  grp <- if (!is.na(dfg)) paste0("DFG ", dfg, " peers") else "peer districts"
  paste0(pctile, suffix_th(pctile), " percentile among ", n_peers, " ", grp)
}
suffix_th <- function(n) {
  if (is.na(n)) return("")
  if (n %% 100 %in% 11:13) return("th")
  switch(as.character(n %% 10), "1"="st","2"="nd","3"="rd","th")
}
