# Canonical vendorable historical resolver, store protocol v1.
# Requires only base R, digest, jsonlite, rappdirs and curl. Sourcing is inert.
# See docs/HISTORICAL-ASSET-CACHE.md before adapting a package parser.
#
# Vendored byte-for-byte as R/resolve_historical_asset.R in every package that
# reads the shared historical source store. Edit ONLY
# contracts/historical-store/v1/resolve_historical_asset.R, then run
# scripts/historical-store/sync.py. Package-specific wrappers (option names,
# exported store actions) live in the package's own files, never here.

.historical_error <- function(kind, message, ...) {
  stop(structure(c(list(message = message, call = NULL), list(...)),
                 class = c(paste0("historical_", kind, "_error"), "historical_error", "error", "condition")))
}
.historical_text <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
.historical_number <- function(x, minimum = 0) {
  is.numeric(x) && length(x) == 1L && !is.na(x) && is.finite(x) && x >= minimum && x == floor(x)
}
.historical_token <- function(x) {
  .historical_text(x) && grepl("^[A-Za-z0-9][A-Za-z0-9._-]*$", x) && !x %in% c(".", "..", "latest")
}
.historical_path <- function(x) {
  .historical_text(x) && !grepl("^/|\\\\|^[A-Za-z]:", x) &&
    !any(strsplit(x, "/", fixed = TRUE)[[1L]] %in% c("", ".", ".."))
}
.historical_values <- function(x) as.character(unlist(x, use.names = FALSE))
.historical_selectors <- function(x) {
  is.list(x) && (length(x) == 0L || (!is.null(names(x)) && !anyDuplicated(names(x)) &&
    all(nzchar(names(x))) && all(vapply(x, function(v) {
      values <- unlist(v, use.names = FALSE)
      length(values) > 0L && is.atomic(values) && !anyNA(values)
    }, logical(1)))))
}
.historical_contains <- function(have, need) {
  all(vapply(names(need), function(k) k %in% names(have) &&
               all(.historical_values(need[[k]]) %in% .historical_values(have[[k]])), logical(1)))
}
.historical_closure <- function(manifest, roots) {
  by_id <- setNames(manifest$artifacts, vapply(manifest$artifacts, `[[`, "", "artifact_id"))
  done <- visiting <- character()
  visit <- function(id) {
    if (!id %in% names(by_id)) .historical_error("metadata", paste("Missing runtime asset:", id))
    if (id %in% visiting) .historical_error("metadata", paste("Cyclic runtime dependency:", id))
    if (id %in% done) return(invisible(NULL))
    visiting <<- c(visiting, id)
    for (dependency in by_id[[id]]$runtime_dependencies) visit(dependency)
    visiting <<- setdiff(visiting, id)
    done <<- c(done, id)
  }
  for (id in unlist(roots, use.names = FALSE)) visit(id)
  sort(unique(done))
}
.historical_validate_impl <- function(contract, manifest, package_repository) {
  fail <- function(message) .historical_error("metadata", message)
  if (!is.list(contract) || !is.list(manifest)) fail("Contract and manifest must be objects")
  if (!identical(contract$schema_version, "source-validation-contract/v2") ||
      !identical(manifest$schema_version, "source-validation-artifact-manifest/v2") ||
      !.historical_text(contract$contract_id) || !identical(contract$contract_id, manifest$contract_id)) fail("Expected matching v2 contract and manifest")
  if (!.historical_text(package_repository) || !grepl("^[A-Za-z0-9_.-]+/[a-z]{2}schooldata$", package_repository) ||
      !identical(package_repository, manifest$package_repository)) fail("Manifest differs from owning package repository")
  if (!is.list(manifest$artifacts)) fail("Manifest artifacts must be a list")
  ids <- character()
  for (a in manifest$artifacts) {
    if (!is.list(a)) fail("Artifact must be an object")
    if (!.historical_token(a$artifact_id) || a$artifact_id %in% ids) fail("Invalid or duplicate artifact identity")
    ids <- c(ids, a$artifact_id)
    if (!.historical_text(a$sha256) || !grepl("^[0-9a-f]{64}$", a$sha256) ||
        !.historical_number(a$byte_length, 1) || !.historical_text(a$source_identity) ||
        !.historical_text(a$tier) || !a$tier %in% c("shipped", "repository_archive") || !.historical_selectors(a$selectors)) fail("Invalid digest, length, source identity or selectors")
    s <- a$storage
    if (!is.list(s) || !.historical_text(s$backend)) fail("Missing artifact storage descriptor")
    if (identical(s$backend, "release_asset")) {
      if (!identical(s$repository, package_repository) || !.historical_number(s$release_id, 1) ||
          !.historical_number(s$asset_id, 1) || !.historical_token(s$tag) ||
          !.historical_token(s$asset_name) || a$byte_length >= 2^31) fail("Invalid pinned release asset binding")
      url <- paste0("https://github.com/", package_repository, "/releases/download/", s$tag, "/", s$asset_name)
      if (!identical(s$download_url, url)) fail("Download URL differs from pinned package asset")
    } else if (identical(s$backend, "github_pages")) {
      if (!identical(s$repository, package_repository) || !.historical_token(s$asset_name) ||
          !.historical_text(s$published_commit) || !grepl("^[0-9a-f]{40}$", s$published_commit)) fail("Invalid pinned Pages asset binding")
      repository <- strsplit(package_repository, "/", fixed = TRUE)[[1L]]
      url <- paste0("https://", repository[[1L]], ".github.io/", repository[[2L]],
                    "/historical-assets/", a$sha256, "/", s$asset_name)
      if (!identical(s$download_url, url)) fail("Download URL differs from pinned package Pages asset")
    } else if (s$backend %in% c("git", "git_lfs")) {
      if (!.historical_path(s$path)) fail("Unsafe installed artifact path")
    } else fail("Unsupported artifact backend")
    if (!is.list(a$runtime_dependencies) && !is.character(a$runtime_dependencies)) fail("Runtime dependencies must be an array")
    dependencies <- unlist(a$runtime_dependencies, use.names = FALSE)
    if (anyDuplicated(dependencies) || !all(vapply(as.list(dependencies), .historical_token, logical(1)))) fail("Invalid runtime dependencies")
    lineage <- a$lineage
    if (!is.list(lineage)) fail("Missing state-source lineage")
    if (identical(lineage$kind, "derived")) {
      for (k in c("recipe", "recipe_version", "table_locator")) {
        if (!.historical_text(lineage[[k]])) fail("Incomplete derived lineage")
      }
      # A parent outside this manifest may be named by its state-source
      # identity alone; one of the two is always required.
      if (!.historical_text(lineage$parent_artifact_id) &&
          !.historical_text(lineage$parent_source_identity)) fail("Incomplete derived lineage")
      if (!.historical_number(lineage$row_count)) fail("Invalid derived row count")
    } else if (!identical(lineage$kind, "source")) fail("Invalid state-source lineage")
  }
  for (a in manifest$artifacts) {
    if (identical(a$lineage$kind, "derived") && .historical_text(a$lineage$parent_artifact_id) &&
        !a$lineage$parent_artifact_id %in% ids &&
        !.historical_text(a$lineage$parent_source_identity)) fail("Absent provenance parent lacks state-source identity")
    .historical_closure(manifest, a$artifact_id)
  }
  if (!is.list(contract$selectors)) fail("Contract selectors must be an array")
  names <- vapply(contract$selectors, function(s) {
    if (!.historical_text(s$name) || !is.logical(s$required) || length(s$required) != 1L || is.na(s$required)) fail("Invalid selector declaration")
    s$name
  }, "")
  if (anyDuplicated(names)) fail("Duplicate selectors")
  required <- names[vapply(contract$selectors, `[[`, logical(1), "required")]
  for (a in manifest$artifacts) if (length(setdiff(names(a$selectors), names))) fail("Unknown artifact selectors")
  requests <- contract$runtime_requests
  if (!is.list(requests) || !length(requests)) fail("Missing runtime requests")
  for (r in requests) {
    for (k in c("function", "parser_version", "schema_version")) if (!.historical_text(r[[k]])) fail("Incomplete runtime request")
    if (!.historical_selectors(r$selectors) || length(setdiff(names(r$selectors), names)) ||
        length(setdiff(required, names(r$selectors))) || !.historical_number(r$workspace_bytes)) fail("Invalid request selectors or workspace bound")
    if (!is.list(r$alternatives) || !length(r$alternatives)) fail("Missing parser alternatives")
    by_id <- setNames(manifest$artifacts, ids)
    for (alternative in r$alternatives) {
      roots <- unlist(alternative, use.names = FALSE)
      if (!length(roots) || anyDuplicated(roots) || !all(vapply(as.list(roots), .historical_token, logical(1)))) fail("Invalid parser alternative")
      for (id in .historical_closure(manifest, roots)) {
        if (!.historical_contains(by_id[[id]]$selectors, r$selectors)) fail(paste("Incomplete selector closure:", id))
      }
    }
  }
  if (length(requests) > 1L) for (i in seq_len(length(requests) - 1L)) for (j in seq.int(i + 1L, length(requests))) {
    l <- requests[[i]]; r <- requests[[j]]
    keys <- union(names(l$selectors), names(r$selectors))
    overlap <- all(vapply(keys, function(k) !k %in% names(l$selectors) || !k %in% names(r$selectors) ||
                          length(intersect(.historical_values(l$selectors[[k]]), .historical_values(r$selectors[[k]]))) > 0L, logical(1)))
    if (identical(l[["function"]], r[["function"]]) && overlap) fail("Ambiguous runtime selector coverage")
  }
  invisible(TRUE)
}
.historical_validate <- function(contract, manifest, package_repository) {
  tryCatch(.historical_validate_impl(contract, manifest, package_repository), error = function(e) {
    if (inherits(e, "historical_error")) stop(e)
    .historical_error("metadata", paste("Malformed historical descriptor:", conditionMessage(e)))
  })
}

# Pure metadata selection; cached_digests must be supplied by the caller.
historical_select <- function(contract, manifest, function_name, selectors,
                              package_repository, cached_digests = character()) {
  .historical_validate(contract, manifest, package_repository)
  if (!.historical_text(function_name) || !.historical_selectors(selectors)) .historical_error("metadata", "Invalid historical request")
  matches <- Filter(function(r) identical(r[["function"]], function_name) &&
    setequal(names(r$selectors), names(selectors)) && .historical_contains(r$selectors, selectors), contract$runtime_requests)
  if (length(matches) != 1L) .historical_error("metadata", paste("Unsupported historical request:", function_name))
  request <- matches[[1L]]
  by_id <- setNames(manifest$artifacts, vapply(manifest$artifacts, `[[`, "", "artifact_id"))
  alternatives <- lapply(request$alternatives, function(roots) .historical_closure(manifest, roots))
  selected <- alternatives[[1L]]
  for (alternative in alternatives) if (all(vapply(by_id[alternative], function(a) a$sha256 %in% cached_digests, logical(1)))) {
    selected <- alternative; break
  }
  structure(list(artifacts = unname(by_id[selected]), selectors = selectors,
                 function_name = function_name, parser_version = request$parser_version,
                 schema_version = request$schema_version, workspace_bytes = request$workspace_bytes,
                 package_repository = package_repository, contract = contract, manifest = manifest),
            class = "historical_selection")
}
.historical_selection_check <- function(selection) {
  if (!inherits(selection, "historical_selection")) .historical_error("metadata", "Expected historical_select() result")
  .historical_validate(selection$contract, selection$manifest, selection$package_repository)
  rebuilt <- historical_select(selection$contract, selection$manifest, selection$function_name,
                               selection$selectors, selection$package_repository,
                               vapply(selection$artifacts, `[[`, "", "sha256"))
  if (!identical(rebuilt, selection)) .historical_error("metadata", "Historical selection was modified")
  invisible(TRUE)
}
.historical_canonical <- function(value) {
  if (is.list(value)) {
    if (!is.null(names(value))) value <- value[order(names(value))]
    value <- lapply(value, .historical_canonical)
  }
  value
}
historical_identity <- function(selection) {
  .historical_selection_check(selection)
  binding <- list(protocol = "historical-derived/v1", function_name = selection$function_name,
                  selectors = selection$selectors, parser_version = selection$parser_version,
                  schema_version = selection$schema_version,
                  digests = sort(unique(vapply(selection$artifacts, `[[`, "", "sha256"))))
  digest::digest(as.character(jsonlite::toJSON(.historical_canonical(binding), auto_unbox = TRUE,
                                             null = "null", digits = NA)), algo = "sha256", serialize = FALSE)
}

.historical_root <- function(root = NULL) {
  if (is.null(root)) {
    root <- Sys.getenv("STATE_SCHOOLDATA_HISTORICAL_ROOT", "")
    if (!nzchar(root)) root <- file.path(rappdirs::user_cache_dir("state-schooldata"), "historical-assets-v1")
  }
  if (!.historical_text(root)) .historical_error("store", "Source cache root must be a single path")
  if (.historical_symlink(path.expand(root))) .historical_error("store", "Source-store root cannot be a symbolic link")
  normalizePath(path.expand(root), winslash = "/", mustWork = FALSE)
}
.historical_symlink <- function(path) nzchar(Sys.readlink(path)) && !is.na(Sys.readlink(path))
.historical_store <- function(root, create = FALSE) {
  marker <- file.path(root, "STORE-V1")
  if (.historical_symlink(root)) .historical_error("store", "Source-store root cannot be a symbolic link")
  if (!dir.exists(root)) {
    if (!create) return(FALSE)
    if (file.exists(root) || !dir.create(root, recursive = TRUE, showWarnings = FALSE)) {
      if (!dir.exists(root)) .historical_error("store", "Cannot create historical source store")
    }
  }
  if (!file.exists(marker)) {
    if (!create) {
      if (!length(list.files(root, all.files = TRUE, no.. = TRUE))) return(FALSE)
      .historical_error("store", "Directory is not an owned historical source store")
    }
    init <- file.path(root, ".INITIALIZING")
    if (.historical_symlink(init)) .historical_error("store", "Unsafe source-store initialization lock")
    deadline <- Sys.time() + 5
    acquired <- dir.create(init, showWarnings = FALSE)
    while (!acquired) {
      if (file.exists(marker)) break
      if (Sys.time() >= deadline) .historical_error("store", "Source-store initialization is incomplete")
      Sys.sleep(0.025)
      acquired <- dir.create(init, showWarnings = FALSE)
    }
    if (acquired) on.exit(unlink(init, recursive = TRUE), add = TRUE)
    # Marker promotion is atomic; another initializing writer sees all or none.
    if (!file.exists(marker)) {
      entries <- setdiff(list.files(root, all.files = TRUE, no.. = TRUE), ".INITIALIZING")
      if (length(entries)) .historical_error("store", "Directory is not an owned historical source store")
      pending <- file.path(init, "marker")
      writeLines("state-schooldata-historical-store/v1", pending)
      if (!file.rename(pending, marker)) .historical_error("store", "Cannot initialize owned source store")
    }
  }
  if (.historical_symlink(marker) || !identical(readLines(marker, warn = FALSE), "state-schooldata-historical-store/v1")) .historical_error("store", "Source-store ownership marker is invalid")
  for (subdir in c("blobs", "staging", "leases")) {
    path <- file.path(root, subdir)
    if (.historical_symlink(path) || (file.exists(path) && !dir.exists(path))) .historical_error("store", "Unsafe source-store directory")
    if (create && !dir.exists(path)) dir.create(path, showWarnings = FALSE)
  }
  TRUE
}
.historical_process_alive <- function(pid) {
  # TRUE alive, FALSE confirmed dead, NA unknown. Never signals the process
  # (STANDARD D-h): `ps -p` exits 0 when the pid exists and 1 when it does not;
  # any other outcome (no ps, odd status, error) is unknown, never dead.
  if (!.historical_number(pid, 1) || pid > .Machine$integer.max) return(NA)
  if (.Platform$OS.type == "unix") {
    return(tryCatch({
      status <- suppressWarnings(system2("ps", c("-p", as.character(as.integer(pid))),
                                         stdout = FALSE, stderr = FALSE))
      if (identical(as.integer(status), 0L)) TRUE else if (identical(as.integer(status), 1L)) FALSE else NA
    }, error = function(e) NA))
  }
  # Windows: query the native process list, without sending a signal.
  tryCatch({
    result <- suppressWarnings(system2("tasklist", c("/FI", shQuote(paste("PID eq", as.integer(pid))),
                                                      "/FO", "CSV", "/NH"), stdout = TRUE, stderr = FALSE))
    if (!is.null(attr(result, "status")) && attr(result, "status") != 0L) return(NA)
    rows <- utils::read.csv(text = paste(result, collapse = "\n"), header = FALSE,
                            colClasses = "character", stringsAsFactors = FALSE)
    if (ncol(rows) < 2L) return(FALSE)
    any(rows[[2L]] == as.character(as.integer(pid)))
  }, error = function(e) NA)
}
.historical_lock <- function(root, action, .owner_grace_seconds = 5) {
  .historical_store(root, TRUE)
  lock <- file.path(root, "LOCK")
  if (.historical_symlink(lock)) .historical_error("store", "Unsafe store lock")
  uncertain_since <- Sys.time()
  while (!dir.create(lock, showWarnings = FALSE)) {
    if (!dir.exists(lock)) {
      if (file.exists(lock)) .historical_error("store", "Unsafe store lock file")
      next
    }
    owner_file <- file.path(lock, "owner.rds")
    if (.historical_symlink(owner_file)) .historical_error("store", "Unsafe lock-owner record")
    owner <- tryCatch(suppressWarnings(readRDS(owner_file)), error = function(e) NULL)
    valid <- is.list(owner) && identical(owner$protocol, "historical-lock/v1") &&
      .historical_number(owner$pid, 1) && .historical_text(owner$host)
    if (!valid) {
      if (as.numeric(difftime(Sys.time(), uncertain_since, units = "secs")) > .owner_grace_seconds) {
        .historical_error("lock", paste("Historical lock has no valid owner; if no reader is running, remove", lock, "by hand"), root = root, reason = "unknown_owner")
      }
    } else {
      uncertain_since <- Sys.time()
      if (!identical(owner$host, Sys.info()[["nodename"]])) .historical_error("lock", "Historical lock belongs to another host; explicit recovery is required", root = root, reason = "foreign_host")
      if (owner$pid == Sys.getpid()) .historical_error("lock", "Historical source-store lock cannot be acquired recursively", root = root, reason = "recursive_owner")
      alive <- .historical_process_alive(owner$pid)
      if (!isTRUE(alive)) {
        # Do not misidentify a replacement writer if the observed owner left
        # while liveness was queried. Never steal or remove any writer's lock.
        current <- tryCatch(suppressWarnings(readRDS(owner_file)), error = function(e) NULL)
        if (identical(current, owner)) .historical_error("lock", paste0("Historical lock owner is dead or unqueryable; run ", .historical_recover_call(), " once no reader is running"), root = root, reason = if (identical(alive, FALSE)) "dead_owner" else "unknown_liveness")
      }
      # A live writer has no age timeout: an entire legitimate dependency
      # closure may need several bounded transfers. Waiting is interruptible.
    }
    Sys.sleep(0.025)
  }
  on.exit(unlink(lock, recursive = TRUE), add = TRUE)
  .historical_atomic_rds(list(protocol = "historical-lock/v1", pid = Sys.getpid(),
                             host = Sys.info()[["nodename"]]), file.path(lock, "owner.rds"))
  action()
}
.historical_atomic_rds <- function(value, path) {
  temp <- tempfile("metadata-", dirname(path))
  on.exit(unlink(temp), add = TRUE)
  saveRDS(value, temp, compress = FALSE)
  if (!file.rename(temp, path)) .historical_error("store", "Cannot promote store metadata")
}
.historical_capacity <- function(root) {
  env <- Sys.getenv("STATE_SCHOOLDATA_HISTORICAL_CAPACITY_BYTES", "")
  if (nzchar(env)) {
    value <- suppressWarnings(as.numeric(env))
  } else if (file.exists(file.path(root, "capacity.rds"))) {
    if (.historical_symlink(file.path(root, "capacity.rds"))) .historical_error("store", "Unsafe capacity setting")
    value <- readRDS(file.path(root, "capacity.rds"))
  } else value <- 3 * 2^30  # 3 GiB; processed-v1 has its own, separate budget
  if (!.historical_number(value, 1)) .historical_error("capacity", "Historical capacity must be a positive byte count")
  value
}
.historical_blobs <- function(root) {
  files <- list.files(file.path(root, "blobs"), pattern = "^[0-9a-f]{64}$", full.names = TRUE)
  if (any(vapply(files, .historical_symlink, logical(1))) || any(dir.exists(files))) .historical_error("store", "Unsafe digest-addressed blob")
  files
}
.historical_leases <- function(root, strict = TRUE) {
  files <- list.files(file.path(root, "leases"), pattern = "^lease-.*[.]rds$", full.names = TRUE)
  records <- lapply(files, function(f) {
    if (.historical_symlink(f)) .historical_error("store", "Unsafe lease record")
    record <- tryCatch(suppressWarnings(readRDS(f)), error = function(e) {
      if (!strict && !file.exists(f)) return(NULL)
      .historical_error("store", "Unreadable lease record; refusing reclamation")
    })
    if (is.null(record) && !strict) return(NULL)
    if (!is.list(record) || !identical(record$protocol, "historical-lease/v1") ||
        !.historical_number(record$workspace_bytes) || !is.character(record$digests) ||
        anyNA(record$digests) || any(!grepl("^[0-9a-f]{64}$", record$digests)) ||
        anyDuplicated(record$digests) || !is.numeric(record$source_bytes) ||
        !identical(names(record$source_bytes), record$digests) ||
        !all(vapply(as.list(record$source_bytes), .historical_number, logical(1), minimum = 1))) {
      .historical_error("store", "Invalid lease metadata; refusing reclamation")
    }
    if (!is.null(record$external_bytes) && (!.historical_number(record$external_bytes) ||
        !is.character(record$external_digests) || anyNA(record$external_digests) ||
        any(!grepl("^[0-9a-f]{64}$", record$external_digests)))) {
      .historical_error("store", "Invalid external occupancy reservation")
    }
    record
  })
  Filter(Negate(is.null), records)
}
.historical_used <- function(root, leases = .historical_leases(root), present_digests = character()) {
  blobs <- .historical_blobs(root)
  reserved <- unlist(lapply(leases, `[[`, "source_bytes"))
  reserved <- reserved[!duplicated(names(reserved)) &
                       !names(reserved) %in% c(basename(blobs), present_digests,
                         unlist(lapply(leases, `[[`, "external_digests"), use.names = FALSE))]
  external <- sum(vapply(leases, function(x) if (is.null(x$external_bytes)) 0 else x$external_bytes, 0))
  sum(file.info(blobs)$size, na.rm = TRUE) + sum(reserved) + external + sum(vapply(leases, `[[`, 0, "workspace_bytes"))
}
.historical_room <- function(root, digests = character(), required_bytes = 0, workspace_bytes = 0,
                             capacity = .historical_capacity(root)) {
  if (required_bytes + workspace_bytes > capacity) .historical_error("capacity", "Historical closure cannot fit configured capacity", required_bytes = required_bytes + workspace_bytes, capacity_bytes = capacity)
  .historical_reclaim_dead_leases(root)
  leases <- .historical_leases(root)
  protected <- unique(c(digests, unlist(lapply(leases, `[[`, "digests"), use.names = FALSE)))
  blobs <- .historical_blobs(root)
  missing <- required_bytes - sum(file.info(blobs[basename(blobs) %in% digests])$size)
  used <- .historical_used(root, leases) + missing + workspace_bytes
  candidates <- blobs[!basename(blobs) %in% protected]
  # Decide feasibility before deleting anything, including on failed reservations.
  if (used - sum(file.info(candidates)$size) > capacity) .historical_error("capacity", "Active historical readers prevent this reservation", required_bytes = used - sum(file.info(candidates)$size), capacity_bytes = capacity)
  if (length(candidates)) candidates <- candidates[order(file.info(candidates)$mtime, basename(candidates))]
  for (path in candidates) {
    if (used <= capacity) break
    size <- file.info(path)$size
    if (unlink(path) != 0L) .historical_error("store", "Cannot evict historical blob")
    used <- used - size
  }
  invisible(used)
}
# A reader that died hard (OOM, SIGKILL, CI timeout) never runs its on.exit
# cleanup, so its lease would pin digests and reserve workspace bytes forever.
# Call ONLY while holding the store lock: leases are created and removed only
# under it, so a lease whose same-host owner is confirmed dead cannot be
# revived. Unknown liveness (NA), another host, or an unreadable record is
# left alone; .historical_leases() still refuses unreadable records.
.historical_reclaim_dead_leases <- function(root) {
  files <- list.files(file.path(root, "leases"), pattern = "^lease-.*[.]rds$", full.names = TRUE)
  host <- Sys.info()[["nodename"]]
  reclaimed <- character()
  for (f in files) {
    if (.historical_symlink(f)) next
    record <- tryCatch(suppressWarnings(readRDS(f)), error = function(e) NULL)
    if (!is.list(record) || !identical(record$protocol, "historical-lease/v1") ||
        !.historical_number(record$pid, 1) || !identical(record$host, host) ||
        record$pid == Sys.getpid()) next
    if (!identical(.historical_process_alive(record$pid), FALSE)) next
    token <- sub("[.]rds$", "", basename(f))
    staging <- file.path(root, "staging", token)
    if (!.historical_symlink(staging)) unlink(staging, recursive = TRUE)
    if (unlink(f) != 0L) .historical_error("store", "Cannot reclaim dead reader lease")
    reclaimed <- c(reclaimed, paste0(token, " (pid ", record$pid, ")"))
  }
  if (length(reclaimed)) {
    warning("Reclaimed ", length(reclaimed), " historical source lease(s) left by ",
            "readers that exited without cleanup: ", paste(reclaimed, collapse = ", "),
            call. = FALSE)
  }
  invisible(reclaimed)
}
# How a user reaches recovery from the vendoring package. Packages may also
# expose it as a store action (e.g. historical_source_cache("recover")).
.historical_recover_call <- function() {
  home <- topenv(environment(.historical_recover_call))
  if (!isNamespace(home)) return("historical_cache_recover()")
  package <- getNamespaceName(home)
  wrapper <- get0("historical_source_cache", envir = home, inherits = FALSE)
  actions <- if (is.function(wrapper)) tryCatch(eval(formals(wrapper)$action, baseenv()), error = function(e) NULL)
  if ("historical_source_cache" %in% getNamespaceExports(home) && "recover" %in% actions) {
    return(paste0(package, "::historical_source_cache(\"recover\")"))
  }
  paste0(package, ":::historical_cache_recover()")
}
# Explicit recovery for a LOCK whose same-host owner is confirmed dead. The
# lock is never taken over automatically. The dead lock is moved aside first
# and its owner record re-read, so a lock that changed hands meanwhile is put
# back rather than removed. Dead leases are then reclaimed under the lock.
historical_cache_recover <- function(root = NULL) {
  root <- .historical_root(root)
  if (!.historical_store(root, FALSE)) return(invisible(list(lock_removed = FALSE, leases_reclaimed = character())))
  lock <- file.path(root, "LOCK")
  removed <- FALSE
  if (.historical_symlink(lock)) .historical_error("store", "Unsafe store lock")
  if (dir.exists(lock)) {
    owner_file <- file.path(lock, "owner.rds")
    owner <- tryCatch(suppressWarnings(readRDS(owner_file)), error = function(e) NULL)
    valid <- is.list(owner) && identical(owner$protocol, "historical-lock/v1") &&
      .historical_number(owner$pid, 1) && .historical_text(owner$host)
    if (!valid) .historical_error("lock", paste("Historical lock has no readable owner; if no reader is running, remove", lock, "by hand"), root = root, reason = "unknown_owner")
    if (!identical(owner$host, Sys.info()[["nodename"]])) .historical_error("lock", "Historical lock belongs to another host; recover it on that host", root = root, reason = "foreign_host")
    alive <- .historical_process_alive(owner$pid)
    if (isTRUE(alive)) .historical_error("lock", paste("Historical lock is held by live process", owner$pid), root = root, reason = "live_owner")
    if (!identical(alive, FALSE)) .historical_error("lock", "Historical lock owner liveness is unknown; not recovering", root = root, reason = "unknown_liveness")
    tomb <- file.path(root, paste0(".LOCK-dead-", basename(tempfile(""))))
    if (!file.rename(lock, tomb)) .historical_error("store", "Cannot move dead historical lock aside")
    moved <- tryCatch(suppressWarnings(readRDS(file.path(tomb, "owner.rds"))), error = function(e) NULL)
    if (!identical(moved, owner)) {
      if (!dir.exists(lock) && file.rename(tomb, lock)) .historical_error("lock", "Historical lock changed hands during recovery; it was restored, retry", root = root, reason = "owner_changed")
      .historical_error("lock", paste("Historical lock changed hands during recovery and could not be restored; inspect", tomb), root = root, reason = "owner_changed")
    }
    unlink(tomb, recursive = TRUE)
    removed <- TRUE
  }
  leases <- .historical_lock(root, function() .historical_reclaim_dead_leases(root))
  invisible(list(lock_removed = removed, leases_reclaimed = leases))
}
.historical_verify <- function(path, asset) {
  if (!file.exists(path)) return(FALSE)
  if (.historical_symlink(path) || dir.exists(path)) .historical_error("store", "Unsafe historical blob")
  if (!isTRUE(file.info(path)$size == asset$byte_length) ||
      !identical(digest::digest(path, file = TRUE, algo = "sha256"), asset$sha256)) {
    .historical_error("integrity", paste("Historical asset integrity mismatch:", asset$artifact_id),
                      artifact_id = asset$artifact_id, sha256 = asset$sha256)
  }
  TRUE
}
.historical_pages_scope <- function(url) {
  if (!.historical_text(url) || grepl("[[:space:]#]", url)) return(NULL)
  match <- regmatches(url, regexec(paste0("^https://([A-Za-z0-9_.-]+[.]github[.]io)/",
    "([a-z]{2}schooldata)/historical-assets/[0-9a-f]{64}/[A-Za-z0-9][A-Za-z0-9._-]*$"), url))[[1L]]
  if (length(match) == 3L) match[2:3] else NULL
}
.historical_delivery_url <- function(url, pages_scope = NULL) {
  if (!is.null(pages_scope)) return(identical(.historical_pages_scope(url), pages_scope))
  .historical_text(url) && !grepl("[[:space:]#]", url) &&
    grepl("^https://(github[.]com|release-assets[.]githubusercontent[.]com|objects[.]githubusercontent[.]com)/", url)
}
.historical_github_request <- function(url, method, emit) {
  h <- curl::new_handle(followlocation = FALSE, failonerror = identical(method, "GET"),
                        connecttimeout = 30, timeout = 600, protocols = 2L,
                        redir_protocols = 2L, nobody = identical(method, "HEAD"))
  if (identical(method, "HEAD")) curl::curl_fetch_memory(url, handle = h)
  else tryCatch(curl::curl_fetch_stream(url, emit, handle = h), error = function(e) {
    # HTTP error pages are not source bytes and may exceed the asset's bound.
    # failonerror rejects their bodies before emission; classify only the
    # response status actually observed by curl, preserving HTTP 200 errors.
    status <- curl::handle_data(h)$status_code
    if (.historical_number(status, 400) && status <= 599) {
      .historical_error("transport", paste("Pinned historical asset GET returned HTTP", status), status_code = status)
    }
    stop(e)
  })
}
.historical_github_transport <- function(url, emit, .request = .historical_github_request) {
  # Resolve redirects without automatic following. HEAD transfers no payload;
  # every next destination is checked before contacting it. GET never follows
  # a redirect that differs from the checked HEAD chain.
  pages_scope <- .historical_pages_scope(url)
  for (hop in 0:5) {
    if (!.historical_delivery_url(url, pages_scope)) .historical_error("policy", "Historical delivery leaves permitted HTTPS GitHub asset scope")
    response <- .request(url, "HEAD", NULL)
    status <- response$status_code
    if (status %in% c(301L, 302L, 303L, 307L, 308L)) {
      headers <- curl::parse_headers_list(response$headers)
      if (sum(names(headers) == "location") != 1L) .historical_error("integrity", "Historical delivery redirect has no unique location")
      location <- headers$location
      if (!.historical_text(location)) .historical_error("integrity", "Historical delivery redirect has no unique location")
      if (grepl("^/[^/]", location)) {
        origin <- sub("^(https://[^/]+).*", "\\1", url)
        location <- paste0(origin, location)
      }
      url <- location
      next
    }
    if (!identical(as.integer(status), 200L)) .historical_error("transport", paste("Pinned historical asset HEAD returned HTTP", status), status_code = status)
    result <- .request(url, "GET", emit)
    if (!identical(as.integer(result$status_code), 200L)) .historical_error("transport", "Pinned historical asset changed status or redirect between HEAD and GET", status_code = result$status_code)
    return(invisible(NULL))
  }
  .historical_error("transport", "Historical delivery exceeded its bounded redirect chain")
}
.historical_download <- function(asset, destination, transport = NULL) {
  for (attempt in seq_len(3L)) {
    # A failed GET may already have streamed a body. Reopen the same reserved
    # partial file from zero before retrying; never append failed response bytes.
    output <- file(destination, "wb")
    total <- 0
    emit_error <- NULL
    emit <- function(chunk) {
      if (!is.null(emit_error)) stop(emit_error)
      tryCatch({
        if (!is.raw(chunk) || total + length(chunk) > asset$byte_length) .historical_error("integrity", paste("Historical transfer exceeds committed length:", asset$artifact_id))
        writeBin(chunk, output)
        total <<- total + length(chunk)
        invisible(NULL)
      }, error = function(e) {
        # A transport may replace a callback condition with a libcurl error.
        # Preserve the original local write/integrity failure across that boundary.
        emit_error <<- e
        stop(e)
      })
    }
    retry_error <- tryCatch({
      if (is.null(transport)) {
        .historical_github_transport(asset$storage$download_url, emit)
      } else transport(asset$storage$download_url, emit)
      NULL
    }, error = function(e) {
      if (!is.null(emit_error)) stop(emit_error)
      if (inherits(e, "historical_transport_error") &&
          .historical_number(e$status_code, 500) && e$status_code <= 599) return(e)
      if (inherits(e, "historical_error")) stop(e)
      if (!inherits(e, "curl_error") || !inherits(e, c(
        "curl_error_couldnt_resolve_proxy", "curl_error_couldnt_resolve_host",
        "curl_error_couldnt_connect", "curl_error_operation_timedout",
        "curl_error_got_nothing", "curl_error_send_error", "curl_error_recv_error"
      ))) stop(e)
      .historical_error("transport", paste("Pinned historical asset transfer failed:", asset$artifact_id, conditionMessage(e)), artifact_id = asset$artifact_id)
    }, finally = close(output))
    if (!is.null(emit_error)) stop(emit_error)
    if (is.null(retry_error)) {
      if (total != asset$byte_length) .historical_error("integrity", paste("Truncated historical asset:", asset$artifact_id))
      return(invisible(NULL))
    }
    if (attempt == 3L) stop(retry_error)
    Sys.sleep(2^(attempt - 1L))
  }
}

.historical_new_lease <- function(root, source_bytes, workspace_bytes,
                                  external_bytes = 0, external_digests = character()) {
  directory <- tempfile("lease-", file.path(root, "staging"))
  token <- basename(directory)
  lease <- file.path(root, "leases", paste0(token, ".rds"))
  if (file.exists(lease) || .historical_symlink(lease) ||
      !dir.create(directory, showWarnings = FALSE)) .historical_error("store", "Cannot allocate owned workspace")
  ok <- FALSE
  on.exit(if (!ok) { unlink(directory, recursive = TRUE); unlink(lease) }, add = TRUE)
  record <- list(protocol = "historical-lease/v1", pid = Sys.getpid(),
                 host = Sys.info()[["nodename"]], digests = names(source_bytes),
                 source_bytes = source_bytes, workspace_bytes = workspace_bytes, token = token,
                 external_bytes = external_bytes, external_digests = external_digests)
  .historical_atomic_rds(record, lease)
  result <- list(lease = lease, record = record,
                 workspace = structure(list(directory = directory, byte_limit = workspace_bytes),
                                       class = "historical_workspace"))
  ok <- TRUE
  result
}
.historical_release_lease <- function(root, reservation) {
  .historical_lock(root, function() {
    directory <- reservation$workspace$directory
    lease <- reservation$lease
    if (.historical_symlink(directory) || .historical_symlink(lease) ||
        !identical(normalizePath(dirname(directory)), normalizePath(file.path(root, "staging"))) ||
        !identical(readRDS(lease), reservation$record)) {
      .historical_error("store", "Workspace ownership changed; refusing cleanup")
    }
    if (unlink(directory, recursive = TRUE) != 0L || dir.exists(directory) || file.exists(directory)) {
      .historical_error("store", "Cannot remove owned workspace; reservation retained")
    }
    if (unlink(lease) != 0L || file.exists(lease)) .historical_error("store", "Cannot release workspace reservation")
  })
}

# Capacity/temporary ownership only: the caller retains source acquisition,
# identity validation and publication. Inventory is read under the store lock.
# It reports actual external payload bytes and digest-named borrowed paths;
# those paths are never removed or admitted as verified source by this helper.
historical_with_reserved_workspace <- function(source_bytes, workspace_bytes, callback,
                                               root = NULL, .source_inventory = NULL,
                                               capacity_bytes = NULL) {
  if (!is.numeric(source_bytes) || (length(source_bytes) &&
      (is.null(names(source_bytes)) || anyNA(names(source_bytes)) ||
       any(!grepl("^[0-9a-f]{64}$", names(source_bytes))) || anyDuplicated(names(source_bytes)))) ||
      !all(vapply(as.list(source_bytes), .historical_number, logical(1), minimum = 1)) ||
      !.historical_number(workspace_bytes) || !is.function(callback) ||
      (!is.null(.source_inventory) && !is.function(.source_inventory))) {
    .historical_error("metadata", "Invalid source/workspace reservation")
  }
  if (!length(source_bytes)) source_bytes <- setNames(numeric(), character())
  root <- .historical_root(root)
  capacity <- .historical_capacity(root)
  if (!is.null(capacity_bytes)) {
    if (!.historical_number(capacity_bytes, 1)) .historical_error("capacity", "Invalid workspace capacity")
    capacity <- min(capacity, capacity_bytes)
  }
  if (sum(source_bytes) + workspace_bytes > capacity) .historical_error("capacity", "Source and workspace budget cannot fit", required_bytes = sum(source_bytes) + workspace_bytes, capacity_bytes = capacity)
  reservation <- NULL
  on.exit(if (!is.null(reservation)) .historical_release_lease(root, reservation), add = TRUE)
  .historical_lock(root, function() {
    # A concurrent configure operation may have lowered the store limit.
    capacity <- min(capacity, .historical_capacity(root))
    inventory <- if (is.null(.source_inventory)) list(paths = character(), bytes = 0) else .source_inventory()
    if (!is.list(inventory) || !is.character(inventory$paths) || anyNA(inventory$paths) ||
        (length(inventory$paths) && (is.null(names(inventory$paths)) ||
         anyNA(names(inventory$paths)) || any(!grepl("^[0-9a-f]{64}$", names(inventory$paths))) ||
         any(!nzchar(inventory$paths)))) || !.historical_number(inventory$bytes)) {
      .historical_error("metadata", "Invalid current source inventory")
    }
    paths <- inventory$paths
    .historical_reclaim_dead_leases(root)
    if (any(!file.exists(paths)) || any(dir.exists(paths)) ||
        any(vapply(paths, .historical_symlink, logical(1)))) .historical_error("store", "Unsafe borrowed source inventory")
    if (length(paths) && anyDuplicated(normalizePath(paths))) .historical_error("metadata", "Source inventory counts a path twice")
    sizes <- setNames(file.info(paths)$size, names(paths))
    if (!all(vapply(as.list(sizes), .historical_number, logical(1))) || inventory$bytes < sum(sizes)) .historical_error("metadata", "Current source bytes do not cover borrowed paths")
    leases <- .historical_leases(root)
    lengths <- c(source_bytes, sizes, unlist(lapply(leases, `[[`, "source_bytes")))
    for (id in unique(names(lengths))) if (length(unique(lengths[names(lengths) == id])) != 1L) .historical_error("integrity", "Same source digest has conflicting reservation lengths", sha256 = id)
    held <- unique(c(basename(.historical_blobs(root)), names(paths),
                     unlist(lapply(leases, `[[`, "digests"), use.names = FALSE)))
    used <- .historical_used(root, leases, names(paths)) + inventory$bytes +
      sum(source_bytes[!names(source_bytes) %in% held]) + workspace_bytes
    if (used > capacity) .historical_error("capacity", "Current sources or active workspaces prevent reservation", required_bytes = used, capacity_bytes = capacity)
    # No eviction: external sources and all existing store blobs are preserved.
    # Retain external occupancy in the lease so other API callers cannot omit
    # it while this reader is active. Overlapping inventories are conservatively
    # charged per lease; no unverified identity is used to reduce capacity.
    reservation <<- .historical_new_lease(root, source_bytes, workspace_bytes,
      external_bytes = inventory$bytes, external_digests = if (length(paths)) names(paths) else character())
  })
  callback(reservation$workspace)
}

# Git-backed parents under inst/ are installed with the package: each must be
# present and verify (digest and length), even on a derived-cache hit. Git
# parents outside inst/ are build-excluded and never installed.
.historical_installed_sources <- function(selection) {
  package <- strsplit(selection$package_repository, "/", fixed = TRUE)[[1L]][2L]
  paths <- list()
  for (a in selection$artifacts) {
    if (!a$storage$backend %in% c("git", "git_lfs") || !startsWith(a$storage$path, "inst/")) next
    path <- system.file(sub("^inst/", "", a$storage$path), package = package)
    if (!nzchar(path) || !.historical_verify(path, a)) {
      .historical_error("integrity", paste("Missing installed source:", a$storage$path))
    }
    paths[[a$artifact_id]] <- path
  }
  paths
}

# Parser owns only its bounded workspace; source paths remain leased throughout.
historical_with_assets <- function(selection, parse, root = NULL, offline = FALSE,
                                   .transport = NULL, repair = FALSE) {
  .historical_selection_check(selection)
  if (!is.function(parse)) .historical_error("metadata", "Historical parser must be a function")
  if (!all(vapply(selection$artifacts, function(a) a$storage$backend %in% c(
    "release_asset", "github_pages", "git", "git_lfs"
  ), logical(1)))) .historical_error("metadata", "Resolver source closures use an unsupported storage backend")
  installed <- .historical_installed_sources(selection)
  root <- .historical_root(root)
  assets <- selection$artifacts
  digests <- vapply(assets, `[[`, "", "sha256")
  unique_assets <- assets[!duplicated(digests)]
  digests <- unique(digests)
  # Duplicate content across names/packages shares one blob and one reservation.
  sizes <- vapply(unique_assets, `[[`, 0, "byte_length")
  for (digest in digests) {
    if (length(unique(vapply(Filter(function(a) a$sha256 == digest, assets), `[[`, 0, "byte_length"))) != 1L) .historical_error("metadata", "Same digest has conflicting lengths")
  }
  reservation <- NULL
  cleanup <- function() {
    if (!is.null(reservation)) .historical_release_lease(root, reservation)
  }
  on.exit(cleanup(), add = TRUE)
  paths <- .historical_lock(root, function() {
    capacity <- .historical_capacity(root)
    required <- sum(sizes) + selection$workspace_bytes
    if (required > capacity) .historical_error("capacity", "Historical closure cannot fit configured capacity", required_bytes = required, capacity_bytes = capacity)
    missing <- corrupt <- list()
    for (a in unique_assets) {
      path <- file.path(root, "blobs", a$sha256)
      valid <- tryCatch(.historical_verify(path, a), historical_integrity_error = function(e) {
        if (!repair || offline) stop(e)
        corrupt[[length(corrupt) + 1L]] <<- a
        FALSE
      })
      if (!valid) missing[[length(missing) + 1L]] <- a
    }
    # A git parent that is neither installed nor already in the store is
    # retained locally only; it is never fetched from anywhere.
    local_missing <- Filter(function(a) a$storage$backend %in% c("git", "git_lfs") &&
                              !a$artifact_id %in% names(installed), missing)
    if (length(local_missing)) .historical_error(
      "unpublished", "Historical assets are retained locally and are not published",
      missing = vapply(local_missing, `[[`, "", "artifact_id"),
      digests = vapply(local_missing, `[[`, "", "sha256"))
    remote_missing <- Filter(function(a) a$storage$backend %in% c("release_asset", "github_pages"), missing)
    if (length(remote_missing) && offline) .historical_error("cold_offline", "Historical assets are unavailable offline", missing = vapply(remote_missing, `[[`, "", "artifact_id"), digests = vapply(remote_missing, `[[`, "", "sha256"))
    # A corrupt leased blob cannot be replaced while another parser owns it.
    protected <- unlist(lapply(.historical_leases(root), `[[`, "digests"), use.names = FALSE)
    if (any(vapply(corrupt, `[[`, "", "sha256") %in% protected)) .historical_error("integrity", "Cannot repair an asset held by an active parser")
    .historical_room(root, digests, sum(sizes), selection$workspace_bytes)
    # Replacement reserves staging in addition to the corrupt existing blob.
    if (length(corrupt)) {
      # Once the feasible reservation is established, remove corrupt unleased bytes.
      for (a in corrupt) unlink(file.path(root, "blobs", a$sha256))
    }
    reservation <<- .historical_new_lease(root, setNames(sizes, digests), selection$workspace_bytes)
    workspace <- reservation$workspace$directory
    for (a in missing) {
      temp <- file.path(workspace, paste0(a$sha256, ".partial"))
      if (a$artifact_id %in% names(installed)) {
        if (!file.copy(installed[[a$artifact_id]], temp)) .historical_error("store", "Cannot copy installed source")
      } else .historical_download(a, temp, .transport)
      .historical_verify(temp, a)
      if (!file.rename(temp, file.path(root, "blobs", a$sha256))) .historical_error("store", "Cannot atomically promote historical blob")
    }
    setNames(vapply(assets, function(a) file.path(root, "blobs", a$sha256), ""),
             vapply(assets, `[[`, "", "artifact_id"))
  })
  parse(paths, reservation$workspace)
}

# Streaming workspace writes account selected extraction/copies within the lease.
historical_workspace_write <- function(workspace, name, producer) {
  if (!inherits(workspace, "historical_workspace") || !.historical_token(name) || !is.function(producer)) .historical_error("store", "Invalid owned workspace write")
  path <- file.path(workspace$directory, name)
  if (file.exists(path) || .historical_symlink(path)) .historical_error("store", "Workspace output already exists")
  output <- file(path, "wb")
  ok <- FALSE
  on.exit({ close(output); if (!ok) unlink(path) }, add = TRUE)
  total <- 0
  prior <- sum(file.info(list.files(workspace$directory, full.names = TRUE))$size)
  emit_error <- NULL
  emit <- function(chunk) {
    if (!is.null(emit_error)) stop(emit_error)
    tryCatch({
      if (!is.raw(chunk)) .historical_error("store", "Workspace producer must emit raw bytes")
      if (prior + total + length(chunk) > workspace$byte_limit) .historical_error("capacity", "Owned workspace exceeds reserved capacity", required_bytes = prior + total + length(chunk), capacity_bytes = workspace$byte_limit)
      writeBin(chunk, output)
      total <<- total + length(chunk)
    }, error = function(e) { emit_error <<- e; stop(e) })
  }
  tryCatch(producer(emit), error = function(e) {
    if (!is.null(emit_error)) stop(emit_error)
    stop(e)
  })
  if (!is.null(emit_error)) stop(emit_error)
  ok <- TRUE
  path
}
historical_workspace_extract <- function(workspace, archive, member, name, byte_length) {
  if (!.historical_path(member) || !.historical_number(byte_length)) .historical_error("metadata", "Unsafe selected ZIP member or extraction length")
  total <- 0
  path <- historical_workspace_write(workspace, name, function(emit) {
    input <- unz(archive, member, "rb")
    on.exit(close(input), add = TRUE)
    repeat {
      bytes <- readBin(input, "raw", 65536L)
      if (!length(bytes)) break
      total <<- total + length(bytes)
      if (total > byte_length) .historical_error("integrity", "Selected ZIP member exceeds declared length")
      emit(bytes)
    }
    if (total != byte_length) .historical_error("integrity", "Selected ZIP member length differs from declaration")
  })
  path
}

historical_cache_inspect <- function(selection = NULL, root = NULL) {
  if (!is.null(selection)) .historical_selection_check(selection)
  scope <- if (!is.null(root)) "explicit-root" else if (nzchar(Sys.getenv("STATE_SCHOOLDATA_HISTORICAL_ROOT", ""))) "environment-root" else "shared-user"
  root <- .historical_root(root)
  exists <- .historical_store(root, FALSE)
  blobs <- if (exists) .historical_blobs(root) else character()
  leases <- if (exists) .historical_leases(root, strict = FALSE) else list()
  # Status does not acquire, repair, hash payloads or create a cold store.
  assets <- if (is.null(selection)) list() else lapply(selection$artifacts, function(a) {
    path <- file.path(root, "blobs", a$sha256)
    list(artifact_id = a$artifact_id, sha256 = a$sha256, byte_length = a$byte_length,
         present = path %in% blobs, integrity = "not-checked")
  })
  list(protocol = "state-schooldata-historical-store/v1", root = root, budget_scope = scope,
       capacity_bytes = .historical_capacity(root), used_bytes = if (exists) .historical_used(root, leases) else 0,
       assets = assets, leased_digests = unique(unlist(lapply(leases, `[[`, "digests"), use.names = FALSE)))
}
historical_cache_configure <- function(root = NULL, capacity_bytes) {
  if (!.historical_number(capacity_bytes, 1)) .historical_error("capacity", "Capacity must be a positive byte count")
  root <- .historical_root(root)
  .historical_lock(root, function() {
    .historical_room(root, capacity = capacity_bytes)
    .historical_atomic_rds(capacity_bytes, file.path(root, "capacity.rds"))
  })
  invisible(historical_cache_inspect(root = root))
}
historical_cache_clear <- function(root = NULL) {
  root <- .historical_root(root)
  if (!.historical_store(root, FALSE)) return(invisible(character()))
  .historical_lock(root, function() {
    .historical_reclaim_dead_leases(root)
    leased <- unique(unlist(lapply(.historical_leases(root), `[[`, "digests"), use.names = FALSE))
    files <- .historical_blobs(root)
    eligible <- files[!basename(files) %in% leased]
    for (path in eligible) if (unlink(path) != 0L) .historical_error("store", "Cannot clear historical blob")
    invisible(basename(eligible))
  })
}
historical_cache_warm <- function(selection, root = NULL, offline = FALSE, .transport = NULL) {
  historical_with_assets(selection, function(paths, workspace) NULL, root, offline, .transport)
  invisible(historical_cache_inspect(selection, root))
}
historical_cache_repair <- function(selection, root = NULL, offline = FALSE, .transport = NULL) {
  historical_with_assets(selection, function(paths, workspace) NULL, root, offline, .transport, repair = TRUE)
  invisible(historical_cache_inspect(selection, root))
}

.historical_alternative_selections <- function(selection) {
  matches <- Filter(function(r) identical(r[["function"]], selection$function_name) &&
    setequal(names(r$selectors), names(selection$selectors)) &&
    .historical_contains(r$selectors, selection$selectors), selection$contract$runtime_requests)
  by_id <- setNames(selection$manifest$artifacts,
                    vapply(selection$manifest$artifacts, `[[`, "", "artifact_id"))
  choices <- list(selection)
  identities <- historical_identity(selection)
  for (roots in matches[[1L]]$alternatives) {
    ids <- .historical_closure(selection$manifest, roots)
    candidate <- historical_select(selection$contract, selection$manifest,
                                   selection$function_name, selection$selectors,
                                   selection$package_repository,
                                   vapply(by_id[ids], `[[`, "", "sha256"))
    identity <- historical_identity(candidate)
    if (!identity %in% identities) {
      choices[[length(choices) + 1L]] <- candidate
      identities <- c(identities, identity)
    }
  }
  choices
}

# Derived callbacks own their separate processed store. Only bound envelopes hit.
historical_fetch <- function(selection, parse, root = NULL, offline = FALSE,
                             use_cache = TRUE, derived_get = NULL, derived_put = NULL,
                             .transport = NULL) {
  key <- historical_identity(selection)
  # Installed parents must still exist and verify even on a derived-cache hit.
  .historical_installed_sources(selection)
  if (use_cache && !is.null(derived_get)) {
    # A prior parsed alternative remains valid after its parents are evicted.
    # Current source-cache presence must not turn that result into an offline miss.
    for (candidate in .historical_alternative_selections(selection)) {
      candidate_key <- historical_identity(candidate)
      cached <- derived_get(candidate_key)
      if (is.list(cached) && identical(cached$protocol, "historical-derived/v1") &&
          identical(cached$identity, candidate_key) && "value" %in% names(cached) &&
          identical(cached$provenance, lapply(candidate$artifacts, function(a) list(sha256 = a$sha256, source_identity = a$source_identity, lineage = a$lineage)))) return(cached$value)
    }
  }
  value <- historical_with_assets(selection, parse, root, offline, .transport)
  if (use_cache && !is.null(derived_put)) {
    envelope <- list(protocol = "historical-derived/v1", identity = key,
                     provenance = lapply(selection$artifacts, function(a) list(sha256 = a$sha256, source_identity = a$source_identity, lineage = a$lineage)), value = value)
    derived_put(key, envelope)
  }
  value
}
