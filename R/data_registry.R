# Data registry: for any family and year, do we have it, where did it come from,
# and if not, why not. Computed at call time, offline, from what the package
# already holds. Canonical copy: contracts/data-registry/v1/data_registry.R.
# Do not edit in a package.

.registry_columns <- c(
  "state", "family", "end_year", "source_id", "variant", "status", "mode",
  "fetcher", "n_source_files", "n_derived_files", "bytes", "source_url",
  "publisher", "publisher_type", "title", "year_basis", "landing_url", "reason",
  "evidence", "checked_on"
)

.registry_statuses <- c(
  "served", "held_not_served", "published_not_held", "not_published",
  "source_corrupt", "withdrawn", "not_searched", "always_on"
)

.registry_gap_reasons <- c(
  "published_not_held", "not_published", "source_corrupt", "withdrawn"
)

.registry_package <- function() environmentName(topenv(environment(.registry_package)))

.registry_path <- function(...) {
  path <- system.file(..., package = .registry_package())
  if (nzchar(path)) path else NA_character_
}

.registry_read_csv <- function(name) {
  path <- .registry_path("registry", name)
  if (is.na(path)) return(NULL)
  utils::read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
                  na.strings = "", check.names = FALSE, encoding = "UTF-8")
}

# First crosswalk pattern that matches wins; NA when none does.
.registry_family_of <- function(raw, crosswalk) {
  raw <- tolower(trimws(as.character(raw)))
  for (i in seq_len(nrow(crosswalk))) {
    if (grepl(crosswalk$pattern[[i]], raw, perl = TRUE)) return(crosswalk$family[[i]])
  }
  NA_character_
}

.registry_strings <- function(x) {
  if (is.null(x)) return(character())
  if (is.list(x)) return(unlist(lapply(x, .registry_strings), use.names = FALSE))
  as.character(x)
}

.registry_artifact_families <- function(a, contract_id, category, crosswalk) {
  sel <- a$selectors
  picked <- character()
  for (key in c("family", "category", "dataset", "data_type", "type")) {
    if (!is.null(sel[[key]])) {
      picked <- .registry_strings(sel[[key]])
      break
    }
  }
  fams <- vapply(picked, .registry_family_of, "", crosswalk = crosswalk, USE.NAMES = FALSE)
  fams <- unique(fams[!is.na(fams)])
  if (length(fams)) return(fams)
  path <- a$storage$path
  segments <- if (is.null(path)) character() else strsplit(path, "/", fixed = TRUE)[[1]]
  # A contract named for a family outranks where its file sits: one workbook under
  # enrollment/ can be the ell contract's parent too.
  for (raw in c(contract_id, segments[-length(segments)], category)) {
    fam <- .registry_family_of(raw, crosswalk)
    if (!is.na(fam)) return(fam)
  }
  "other"
}

# School years name their spring: "2012-13" is end_year 2013. A full date such as
# 2026-06-18 says when a file was made, not what year it covers.
.registry_year_of <- function(text) {
  run <- regmatches(text, gregexpr("(?<![0-9])(19|20)[0-9]{2}(19|20)[0-9]{2}(?![0-9])", text, perl = TRUE))[[1]]
  for (one in rev(run)) {
    first <- as.integer(substr(one, 1, 4))
    second <- as.integer(substr(one, 5, 8))
    if (second == first + 1L) return(second)
  }
  text <- gsub("(?<![0-9])(19|20)[0-9]{2}[-_]?[01][0-9][-_]?[0-3][0-9](?![0-9])", " ", text, perl = TRUE)
  span <- regmatches(text, gregexpr("(?<![0-9])(19|20)[0-9]{2}[-_](?:[0-9]{2}|(?:19|20)[0-9]{2})(?![0-9])",
                                    text, perl = TRUE))[[1]]
  for (one in rev(span)) {
    parts <- strsplit(one, "[-_]")[[1]]
    first <- as.integer(parts[[1]])
    second <- as.integer(parts[[2]])
    if (second < 100) second <- second + first - first %% 100
    if (second == first + 1L) return(second)
  }
  one <- regmatches(text, gregexpr("(?<![0-9])(19|20)[0-9]{2}(?![0-9])", text, perl = TRUE))[[1]]
  if (length(one)) as.integer(one[[length(one)]]) else integer()
}

.registry_artifact_years <- function(a) {
  sel <- a$selectors
  for (key in c("end_year", "year", "school_year", "key", "term_year")) {
    if (!is.null(sel[[key]])) {
      years <- unlist(lapply(.registry_strings(sel[[key]]), .registry_year_of))
      if (length(years)) return(sort(unique(years)))
    }
  }
  .registry_year_of(paste(a$artifact_id, a$storage$path))
}

.registry_memo <- new.env(parent = emptyenv())

# Manifests do not change within a process, and a large state holds 18,000 entries.
.registry_artifacts <- function(crosswalk) {
  if (is.null(.registry_memo$artifacts)) {
    .registry_memo$artifacts <- .registry_read_artifacts(crosswalk)
  }
  .registry_memo$artifacts
}

.registry_read_artifacts <- function(crosswalk) {
  base <- .registry_path("extdata", "source-contract")
  empty <- data.frame(artifact_id = character(), lineage = character(), path = character(),
                      url = character(), bytes = numeric(), family = character(),
                      end_year = integer(), match_text = character(), stringsAsFactors = FALSE)
  if (is.na(base)) return(empty)
  # Every manifest on disk: registry.json does not index all of them.
  manifests <- sort(list.files(base, pattern = "^artifact-manifest\\.json$", recursive = TRUE,
                               full.names = TRUE))
  rows <- list()
  for (manifest in manifests) {
    id <- basename(dirname(manifest))
    contract <- file.path(dirname(manifest), "contract.json")
    category <- ""
    if (file.exists(contract)) {
      category <- jsonlite::fromJSON(contract, simplifyVector = FALSE)$category %||% ""
    }
    artifacts <- jsonlite::fromJSON(manifest, simplifyVector = FALSE)$artifacts
    # An `absent` entry records a request that failed. We hold nothing for it.
    artifacts <- Filter(function(a) !identical(a$tier, "absent"), artifacts)
    rows <- c(rows, lapply(artifacts, function(a) {
      identity <- .registry_strings(a$source_identity)
      urls <- identity[grepl("^https?://", identity)]
      years <- .registry_artifact_years(a)
      if (!length(years)) years <- NA_integer_
      list(artifact_id = a$artifact_id %||% "", lineage = a$lineage$kind %||% "source",
           path = a$storage$path %||% "",
           url = if (length(urls)) urls[[1]] else NA_character_,
           bytes = as.numeric(a$byte_length %||% NA_real_),
           families = .registry_artifact_families(a, id, category, crosswalk), years = years,
           match_text = paste(c(identity, a$storage$path %||% ""), collapse = " "))
    }))
  }
  if (!length(rows)) return(empty)
  pick <- function(field, type) vapply(rows, function(r) r[[field]], type)
  at <- rep(seq_along(rows), lengths(lapply(rows, `[[`, "families")) *
              lengths(lapply(rows, `[[`, "years")))
  grid <- lapply(rows, function(r) {
    list(family = rep(r$families, each = length(r$years)),
         end_year = rep(r$years, times = length(r$families)))
  })
  data.frame(artifact_id = pick("artifact_id", "")[at], lineage = pick("lineage", "")[at],
             path = pick("path", "")[at], url = pick("url", NA_character_)[at],
             bytes = pick("bytes", 0)[at],
             family = unlist(lapply(grid, `[[`, "family"), use.names = FALSE),
             end_year = as.integer(unlist(lapply(grid, `[[`, "end_year"), use.names = FALSE)),
             match_text = pick("match_text", "")[at], stringsAsFactors = FALSE)
}

.registry_coverage <- function() {
  ns <- topenv(environment(.registry_coverage))
  fn <- ls(ns, all.names = TRUE, pattern = "_available_years_coverage$")
  cov <- as.data.frame(get(fn[[1]], ns)())[, c("type", "end_year", "mode", "fetcher")]
  names(cov)[names(cov) == "type"] <- "raw_type"
  cov
}

.registry_attach_sources <- function(artifacts, sources) {
  artifacts$source_id <- NA_character_
  if (is.null(sources) || !nrow(artifacts)) return(artifacts)
  for (i in seq_len(nrow(sources))) {
    if (is.na(sources$match[[i]])) next
    hit <- artifacts$family == sources$family[[i]] &
      grepl(sources$match[[i]], artifacts$match_text, perl = TRUE)
    artifacts$source_id[hit & is.na(artifacts$source_id)] <- sources$source_id[[i]]
  }
  artifacts
}

#' What this package holds, serves and is missing, by family and year
#'
#' Computed offline at call time from the package's own coverage table, its
#' source-contract manifests and its two known-fact files. There is no stored
#' copy to fall out of date. Status `not_searched` means nobody has looked: read
#' it as unknown, never as absent.
#'
#' @param family Optional family to keep, such as `"enrollment"`.
#' @param end_year Optional years to keep.
#' @return A data frame with one row per family, year and source. See
#'   `vignette("data-sources")` for the columns.
#' @examples
#' reg <- get_data_registry()
#' subset(reg, status == "served")
#' get_data_registry(family = "enrollment", end_year = 2024)
#' @export
get_data_registry <- function(family = NULL, end_year = NULL) {
  out <- .registry_compute(.registry_read_csv("sources.csv"), .registry_read_csv("gaps.csv"))
  if (!is.null(family)) out <- out[out$family %in% family, , drop = FALSE]
  if (!is.null(end_year)) out <- out[out$end_year %in% end_year, , drop = FALSE]
  out
}

.registry_compute <- function(sources, gaps) {
  crosswalk <- .registry_read_csv("families.csv")
  artifacts <- .registry_attach_sources(.registry_artifacts(crosswalk), sources)
  cov <- .registry_coverage()
  cov$family <- vapply(cov$raw_type, .registry_family_of, "", crosswalk = crosswalk,
                       USE.NAMES = FALSE)
  state <- toupper(substr(.registry_package(), 1, 2))

  held <- artifacts[!is.na(artifacts$end_year) & !artifacts$family %in% c("other", "reference"), ]
  keys <- unique(rbind(cov[c("family", "end_year")], held[c("family", "end_year")]))
  fams <- unique(keys$family)
  windows <- lapply(fams, function(f) {
    years <- keys$end_year[keys$family == f]
    data.frame(family = f, end_year = seq(min(years), max(years)), stringsAsFactors = FALSE)
  })
  grid <- if (length(windows)) do.call(rbind, windows) else
    data.frame(family = character(), end_year = integer(), stringsAsFactors = FALSE)
  if (!is.null(gaps) && nrow(gaps)) {
    extra <- data.frame(family = gaps$family, end_year = as.integer(gaps$end_year),
                        stringsAsFactors = FALSE)
    grid <- unique(rbind(grid, extra))
  }

  rows <- lapply(seq_len(nrow(grid)), function(i) {
    f <- grid$family[[i]]
    y <- grid$end_year[[i]]
    claim <- cov[cov$family == f & cov$end_year == y, ]
    files <- held[held$family == f & held$end_year == y, ]
    ids <- unique(files$source_id[!is.na(files$source_id)])
    if (!length(ids) && nrow(claim) && !is.null(sources) && nrow(sources)) {
      ids <- unique(unlist(lapply(unique(claim$fetcher), function(fetcher) {
        .registry_fetcher_source(sources, f, y, fetcher)
      })))
    }
    if (!length(ids)) ids <- NA_character_
    do.call(rbind, lapply(ids, function(id) {
      mine <- if (is.na(id)) files else files[!is.na(files$source_id) & files$source_id == id, ]
      src <- !is.na(mine$lineage) & mine$lineage == "source"
      status <- if (nrow(claim)) "served" else if (nrow(files)) "held_not_served" else "not_searched"
      data.frame(
        state = state, family = f, end_year = y, source_id = id, variant = NA_character_,
        status = status,
        mode = if (nrow(claim)) paste(sort(unique(claim$mode)), collapse = "; ") else NA_character_,
        fetcher = if (nrow(claim)) paste(sort(unique(claim$fetcher)), collapse = "; ") else NA_character_,
        n_source_files = length(unique(mine$artifact_id[src])),
        n_derived_files = length(unique(mine$artifact_id[!src])),
        bytes = sum(mine$bytes[!duplicated(mine$artifact_id)], na.rm = TRUE),
        source_url = if (any(!is.na(mine$url))) mine$url[!is.na(mine$url)][[1]] else NA_character_,
        stringsAsFactors = FALSE
      )
    }))
  })
  out <- if (length(rows)) do.call(rbind, rows) else NULL
  out <- .registry_add_directory(out, state)
  out <- .registry_apply_gaps(out, gaps)
  out <- .registry_join_sources(out, sources)
  for (col in setdiff(.registry_columns, names(out))) out[[col]] <- NA_character_
  out <- out[order(out$family, out$end_year, out$source_id), .registry_columns]
  rownames(out) <- NULL
  out
}

# A cell with no file of its own family resolves through the source that names its
# fetcher: a live read, or a fetcher reading a file held under another family.
.registry_fetcher_source <- function(sources, family, year, fetcher) {
  hit <- sources$family == family & !is.na(sources$fetcher) & sources$fetcher == fetcher
  first <- suppressWarnings(as.integer(sources$published_first))
  last <- suppressWarnings(as.integer(sources$published_last))
  hit <- hit & (is.na(first) | first <= year) & (is.na(last) | year <= last)
  sources$source_id[hit]
}

.registry_add_directory <- function(out, state) {
  ns <- topenv(environment(.registry_add_directory))
  if (!"fetch_directory" %in% getNamespaceExports(ns)) return(out)
  row <- data.frame(state = state, family = "directory", end_year = NA_integer_,
                    source_id = NA_character_, variant = NA_character_, status = "always_on",
                    mode = "live", fetcher = "fetch_directory", n_source_files = 0L,
                    n_derived_files = 0L, bytes = 0, source_url = NA_character_,
                    stringsAsFactors = FALSE)
  rbind(out, row)
}

.registry_apply_gaps <- function(out, gaps) {
  if (is.null(gaps) || !nrow(gaps)) return(out)
  key <- paste(out$family, out$end_year)
  for (i in seq_len(nrow(gaps))) {
    hit <- key == paste(gaps$family[[i]], gaps$end_year[[i]]) & out$status == "not_searched"
    out$status[hit] <- gaps$reason[[i]]
    out$reason[hit] <- gaps$note[[i]]
    out$evidence[hit] <- gaps$evidence[[i]]
    out$checked_on[hit] <- gaps$checked_on[[i]]
    if (!is.na(gaps$source_id[[i]])) out$source_id[hit] <- gaps$source_id[[i]]
  }
  out
}

.registry_join_sources <- function(out, sources) {
  if (is.null(sources) || !nrow(sources)) return(out)
  at <- match(out$source_id, sources$source_id)
  for (col in c("publisher", "publisher_type", "title", "year_basis", "landing_url")) {
    out[[col]] <- sources[[col]][at]
  }
  out
}

# The four rules. Returns one line per violation; the fleet-standard test fails
# on any line. sources.csv and gaps.csv are arguments so the self-test can show
# every rule failing without touching the package's real files.
.registry_violations <- function(sources = .registry_read_csv("sources.csv"),
                                 gaps = .registry_read_csv("gaps.csv")) {
  crosswalk <- .registry_read_csv("families.csv")
  artifacts <- .registry_artifacts(crosswalk)
  cov <- .registry_coverage()
  cov$family <- vapply(cov$raw_type, .registry_family_of, "", crosswalk = crosswalk,
                       USE.NAMES = FALSE)
  v <- character()
  if (is.null(sources)) return("no inst/registry/sources.csv")

  files <- unique(artifacts[artifacts$lineage == "source", c("artifact_id", "family", "match_text")])
  hits <- integer(nrow(files))
  for (i in seq_len(nrow(sources))) {
    if (is.na(sources$match[[i]])) next
    hit <- files$family == sources$family[[i]] & grepl(sources$match[[i]], files$match_text, perl = TRUE)
    hits <- hits + hit
  }
  for (i in which(hits != 1L)) {
    v <- c(v, sprintf("rule 1: %s file %s matches %d sources", files$family[[i]],
                      files$artifact_id[[i]], hits[[i]]))
  }

  for (i in seq_len(nrow(sources))) {
    has_file <- !is.na(sources$match[[i]]) &&
      any(grepl(sources$match[[i]], artifacts$match_text, perl = TRUE))
    has_fetcher <- !is.na(sources$fetcher[[i]])
    if (!has_file && !has_fetcher) {
      v <- c(v, sprintf("rule 2: source %s matches no file and names no fetcher", sources$source_id[[i]]))
    }
  }

  reg <- .registry_compute(sources, gaps)
  bad <- reg[reg$status == "served" & is.na(reg$source_id), ]
  for (i in seq_len(nrow(bad))) {
    v <- c(v, sprintf("rule 3: served cell %s %s has no source", bad$family[[i]], bad$end_year[[i]]))
  }

  if (!is.null(gaps) && nrow(gaps)) {
    for (i in seq_len(nrow(gaps))) {
      if (any(cov$family == gaps$family[[i]] & cov$end_year == as.integer(gaps$end_year[[i]]))) {
        v <- c(v, sprintf("rule 4: gap on %s %s, which is served", gaps$family[[i]], gaps$end_year[[i]]))
      }
      if (!gaps$reason[[i]] %in% .registry_gap_reasons) {
        v <- c(v, sprintf("rule 4: gap reason %s is not a known reason", gaps$reason[[i]]))
      }
    }
  }
  v
}
