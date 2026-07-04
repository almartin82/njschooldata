#' Standardize subgroup labels
#'
#' Maps cleaned subgroup labels onto a shared subgroup vocabulary.
#'
#' @param x Character vector of subgroup labels.
#' @return Character vector using the standard subgroup vocabulary. Values with
#'   no crosswalk entry, or with an explicit no-equivalent entry, return
#'   \code{NA_character_}.
#' @export
standardize_subgroup <- function(x) {
  lookup <- subgroup_std_lookup()
  raw <- as.character(x)
  matched <- match(raw, lookup$raw_value)

  warn_unmatched_subgroups(raw, lookup)

  out <- lookup$subgroup_std[matched]
  out[is.na(matched)] <- NA_character_
  names(out) <- names(x)
  out
}

#' Add standardized subgroup labels
#'
#' Adds \code{subgroup_std} immediately after an existing \code{subgroup}
#' column.
#'
#' @param df Data frame that may contain a \code{subgroup} column.
#' @return \code{df} with \code{subgroup_std} added after \code{subgroup}. If
#'   \code{subgroup} is absent, returns \code{df} unchanged with a message.
#' @export
add_subgroup_std <- function(df) {
  if (!"subgroup" %in% names(df)) {
    message("No subgroup column found; subgroup_std was not added.")
    return(df)
  }

  lookup <- subgroup_std_lookup()
  warn_unmatched_subgroups(df[["subgroup"]], lookup)

  base_df <- df[, setdiff(names(df), "subgroup_std"), drop = FALSE]
  out <- dplyr::left_join(
    base_df,
    lookup,
    by = c("subgroup" = "raw_value")
  )

  original_cols <- names(base_df)
  subgroup_pos <- match("subgroup", original_cols)
  ordered_cols <- append(original_cols, "subgroup_std", after = subgroup_pos)
  out[, ordered_cols, drop = FALSE]
}

subgroup_std_lookup <- function() {
  lookup <- subgroup_crosswalk[, c("raw_value", "subgroup_std"), drop = FALSE]
  lookup <- unique(lookup)

  by_raw <- split(lookup$subgroup_std, lookup$raw_value)
  has_conflict <- vapply(
    by_raw,
    function(value) length(unique(value)) > 1,
    logical(1)
  )
  if (any(has_conflict)) {
    stop(
      "subgroup_crosswalk has conflicting mappings for: ",
      paste(names(by_raw)[has_conflict], collapse = ", "),
      call. = FALSE
    )
  }

  lookup[!duplicated(lookup$raw_value), , drop = FALSE]
}

warn_unmatched_subgroups <- function(x, lookup) {
  raw <- as.character(x)
  unmatched <- unique(raw[!is.na(raw) & !(raw %in% lookup$raw_value)])

  if (length(unmatched) > 0) {
    warning(
      "Unmatched subgroup value(s): ",
      paste(unmatched, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(unmatched)
}
