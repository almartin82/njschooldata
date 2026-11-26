# Canonical store-recovery tests, vendored byte-for-byte as
# tests/testthat/test-historical-store-recovery.R by scripts/historical-store/sync.py.
# Edit ONLY contracts/historical-store/v1/test-historical-store-recovery.R.
#
# A reader or writer that dies hard (OOM kill, SIGKILL, CI timeout) never runs
# its on.exit cleanup: its lease would pin digests and reserve workspace bytes
# forever, and a dead LOCK owner would make every store call refuse. Lease/LOCK
# tests stub liveness; probe tests stub only the underlying process query, so
# dead / live / unknown are exact without spawning or signalling a process
# (STANDARD D-h).

.store_home <- function() environment(.historical_reclaim_dead_leases)

store_root <- function(env = parent.frame()) {
  root <- file.path(withr::local_tempdir(.local_envir = env), "store")
  .historical_store(root, TRUE)
  root
}

# states: named logical, names are pids. Any pid not named is unknown (NA).
# `stub` replaces the lookup outright (for tests that count queries).
stub_liveness <- function(states, env = parent.frame(), stub = NULL) {
  if (is.null(stub)) stub <- function(pid) {
    value <- states[as.character(pid)]
    if (is.na(names(value))) NA else unname(value)
  }
  home <- .store_home()
  if (isNamespace(home)) {
    testthat::local_mocked_bindings(.historical_process_alive = stub,
                                    .package = getNamespaceName(home), .env = env)
  } else {
    original <- get(".historical_process_alive", envir = home, inherits = FALSE)
    assign(".historical_process_alive", stub, envir = home)
    withr::defer(assign(".historical_process_alive", original, envir = home), envir = env)
  }
}

plant_lease <- function(root, token, pid, host = Sys.info()[["nodename"]],
                        workspace_bytes = 1000) {
  digest <- strrep(substr(token, 1, 1), 64)
  path <- file.path(root, "leases", paste0("lease-", token, ".rds"))
  saveRDS(list(protocol = "historical-lease/v1", pid = pid, host = host,
               digests = digest, source_bytes = stats::setNames(1, digest),
               workspace_bytes = workspace_bytes), path)
  dir.create(file.path(root, "staging", paste0("lease-", token)))
  path
}

plant_lock <- function(root, pid, host = Sys.info()[["nodename"]]) {
  dir.create(file.path(root, "LOCK"))
  saveRDS(list(protocol = "historical-lock/v1", pid = pid, host = host),
          file.path(root, "LOCK", "owner.rds"))
}

test_that("a lease whose owner is confirmed dead is reclaimed, with a warning, at the next reservation", {
  root <- store_root()
  stub_liveness(c("424242" = FALSE))
  lease <- plant_lease(root, "a1", 424242L, workspace_bytes = 1900)
  withr::local_envvar(STATE_SCHOOLDATA_HISTORICAL_CAPACITY_BYTES = "2000")

  expect_warning(.historical_room(root, character(), 500, 0),
                 "Reclaimed 1 historical source lease.*pid 424242")
  expect_false(file.exists(lease))
  expect_false(dir.exists(file.path(root, "staging", "lease-a1")))
  expect_identical(.historical_used(root), 0)
})

test_that("a dead lease is reclaimed before a reserved-workspace reservation is sized", {
  root <- store_root()
  stub_liveness(c("434343" = FALSE))
  lease <- plant_lease(root, "g1", 434343L, workspace_bytes = 1900)
  withr::local_envvar(STATE_SCHOOLDATA_HISTORICAL_CAPACITY_BYTES = "2000")

  expect_warning(
    out <- historical_with_reserved_workspace(numeric(), 500, function(w) "ran", root = root),
    "Reclaimed 1 historical source lease.*pid 434343")
  expect_identical(out, "ran")
  expect_false(file.exists(lease))
})

test_that("live, unknown and foreign-host leases are never reclaimed and still count", {
  root <- store_root()
  # The foreign-host owner pid is "dead" here: only the host check protects it.
  stub_liveness(c("1001" = TRUE, "1003" = FALSE))
  live <- plant_lease(root, "b1", 1001L)
  unknown <- plant_lease(root, "c1", 1002L)
  foreign <- plant_lease(root, "d1", 1003L, host = "some-other-host")
  withr::local_envvar(STATE_SCHOOLDATA_HISTORICAL_CAPACITY_BYTES = "3500")

  expect_no_warning(.historical_room(root, character(), 0, 0))
  expect_no_warning(historical_cache_clear(root))
  expect_true(all(file.exists(c(live, unknown, foreign))))
  expect_true(all(dir.exists(file.path(root, "staging", c("lease-b1", "lease-c1", "lease-d1")))))
  # Their reservations still count: a request that needs their bytes refuses.
  expect_error(.historical_room(root, character(), 600, 0),
               class = "historical_capacity_error")
})

test_that("clear reclaims a dead lease before choosing what to remove", {
  root <- store_root()
  stub_liveness(c("424243" = FALSE))
  plant_lease(root, "e1", 424243L)
  blob <- file.path(root, "blobs", strrep("e", 64))
  writeLines("x", blob)

  expect_warning(removed <- historical_cache_clear(root), "Reclaimed 1")
  expect_identical(removed, strrep("e", 64))
  expect_false(file.exists(blob))
})

plant_recovery_mutex <- function(root, pid = NULL, host = Sys.info()[["nodename"]]) {
  dir.create(file.path(root, "LOCK-recovery"))
  if (!is.null(pid)) saveRDS(list(protocol = "historical-lock-recovery/v1", pid = pid, host = host),
                             file.path(root, "LOCK-recovery", "owner.rds"))
}

# A live owner is waited on, without limit. To observe that wait, liveness
# answers TRUE for `live` a few times, then aborts the call with a sentinel.
abort_after_waiting <- function(live, dead = character(), waits = 3L) {
  seen <- 0L
  function(pid) {
    if (as.character(pid) %in% dead) return(FALSE)
    if (!identical(as.character(pid), as.character(live))) return(NA)
    seen <<- seen + 1L
    if (seen > waits) stop("sentinel: still waiting on a live owner")
    TRUE
  }
}

# Moving LOCK aside succeeds, but the record found in the moved directory is a
# different owner's: the lock changed hands between the check and the move.
swap_owner_on_move_aside <- function(replacement, env = parent.frame()) {
  real <- base::file.rename
  testthat::local_mocked_bindings(file.rename = function(from, to) {
    ok <- real(from, to)
    if (isTRUE(ok) && grepl("^[.]LOCK-dead-", basename(to))) saveRDS(replacement, file.path(to, "owner.rds"))
    ok
  }, .package = "base", .env = env)
}

no_recovery_residue <- function(root) {
  expect_false(dir.exists(file.path(root, "LOCK-recovery")))
  expect_length(list.files(root, pattern = "^[.]LOCK", all.files = TRUE), 0L)
}

test_that("a LOCK whose same-host owner is confirmed dead is recovered automatically, with its leases", {
  root <- store_root()
  stub_liveness(c("515150" = FALSE))
  plant_lock(root, 515150L)
  lease <- plant_lease(root, "h1", 515150L)
  expect_warning(
    expect_message(removed <- historical_cache_clear(root),
                   "Recovered a dead historical source-store lock left by PID 515150"),
    "Reclaimed 1 historical source lease.*pid 515150")
  expect_identical(removed, character())
  expect_false(dir.exists(file.path(root, "LOCK")))
  expect_false(file.exists(lease))
  expect_false(dir.exists(file.path(root, "staging", "lease-h1")))
  no_recovery_residue(root)
  # The next caller finds a clean store.
  expect_no_message(historical_cache_clear(root))
})

test_that("a LOCK held by a live owner is waited on, never taken over", {
  root <- store_root()
  stub_liveness(stub = abort_after_waiting(live = 515152L))
  plant_lock(root, 515152L)
  lease <- plant_lease(root, "h2", 515152L)
  expect_error(historical_cache_clear(root), "sentinel: still waiting")
  expect_identical(readRDS(file.path(root, "LOCK", "owner.rds"))$pid, 515152L)
  expect_true(file.exists(lease))
  no_recovery_residue(root)
})

test_that("a foreign-host or unqueryable LOCK owner still refuses and is left in place", {
  for (case in list(list(pid = 515153L, host = "some-other-host", reason = "foreign_host"),
                    list(pid = 515154L, host = Sys.info()[["nodename"]], reason = "unknown_liveness"))) {
    root <- store_root()
    # The foreign owner pid is "dead" here: only the host check protects it.
    stub_liveness(c("515153" = FALSE))
    plant_lock(root, case$pid, case$host)
    lease <- plant_lease(root, "h3", case$pid, host = case$host)
    err <- expect_error(expect_no_message(historical_cache_clear(root)), class = "historical_lock_error")
    expect_identical(err$reason, case$reason, info = case$reason)
    if (identical(case$reason, "unknown_liveness")) expect_match(conditionMessage(err), "historical_cache_recover|\"recover\"")
    expect_identical(readRDS(file.path(root, "LOCK", "owner.rds"))$pid, case$pid, info = case$reason)
    expect_true(file.exists(lease), info = case$reason)
    no_recovery_residue(root)
  }
})

test_that("a LOCK that changes hands between the move-aside and the re-read is put back, not removed", {
  root <- store_root()
  stub_liveness(c("515155" = FALSE))
  plant_lock(root, 515155L)
  replacement <- list(protocol = "historical-lock/v1", pid = 515156L, host = "some-other-host")
  swap_owner_on_move_aside(replacement)
  err <- expect_error(expect_no_message(historical_cache_clear(root)), class = "historical_lock_error")
  # The restored lock is then examined as the new owner's: foreign, so refused.
  expect_identical(err$reason, "foreign_host")
  expect_identical(readRDS(file.path(root, "LOCK", "owner.rds")), replacement)
  no_recovery_residue(root)
})

test_that("explicit recover puts back a LOCK that changes hands during the move-aside", {
  root <- store_root()
  stub_liveness(c("515157" = FALSE))
  plant_lock(root, 515157L)
  replacement <- list(protocol = "historical-lock/v1", pid = 515158L, host = Sys.info()[["nodename"]])
  swap_owner_on_move_aside(replacement)
  err <- expect_error(historical_cache_recover(root), class = "historical_lock_error")
  expect_identical(err$reason, "owner_changed")
  expect_identical(readRDS(file.path(root, "LOCK", "owner.rds")), replacement)
  no_recovery_residue(root)
})

test_that("while a live process holds the recovery mutex, a dead LOCK is waited on, not moved twice", {
  root <- store_root()
  stub_liveness(stub = abort_after_waiting(live = 3001L, dead = "515159"))
  plant_lock(root, 515159L)
  plant_recovery_mutex(root, 3001L)
  expect_error(historical_cache_clear(root), "sentinel: still waiting")
  expect_identical(readRDS(file.path(root, "LOCK", "owner.rds"))$pid, 515159L)
  expect_true(dir.exists(file.path(root, "LOCK-recovery")))
})

test_that("a recovery mutex left by a dead recoverer refuses automatically and clears on explicit recover", {
  root <- store_root()
  stub_liveness(c("515160" = FALSE, "3002" = FALSE))
  plant_lock(root, 515160L)
  plant_recovery_mutex(root, 3002L)
  err <- expect_error(historical_cache_clear(root), "historical_cache_recover|\"recover\"",
                      class = "historical_lock_error")
  expect_identical(err$reason, "dead_owner")
  expect_true(dir.exists(file.path(root, "LOCK")))

  out <- historical_cache_recover(root)
  expect_true(out$lock_removed)
  expect_false(dir.exists(file.path(root, "LOCK")))
  no_recovery_residue(root)
})

test_that("a recovery mutex with no owner record past the grace period refuses, naming it", {
  root <- store_root()
  stub_liveness(c("515161" = FALSE))
  plant_lock(root, 515161L)
  plant_recovery_mutex(root)
  Sys.setFileTime(file.path(root, "LOCK-recovery"), Sys.time() - 60)
  err <- expect_error(historical_cache_clear(root), "LOCK-recovery", class = "historical_lock_error")
  expect_identical(err$reason, "unknown_owner")
  expect_true(dir.exists(file.path(root, "LOCK")))
  expect_true(dir.exists(file.path(root, "LOCK-recovery")))
})

test_that("explicit recover clears a LOCK whose owner is confirmed dead, then reclaims its leases", {
  root <- store_root()
  stub_liveness(c("515151" = FALSE))
  plant_lock(root, 515151L)
  plant_lease(root, "f1", 515151L)

  expect_warning(out <- historical_cache_recover(root), "Reclaimed 1")
  expect_true(out$lock_removed)
  expect_length(out$leases_reclaimed, 1L)
  expect_false(dir.exists(file.path(root, "LOCK")))
  expect_length(list.files(root, pattern = "^[.]LOCK-dead-", all.files = TRUE), 0L)
  expect_no_error(historical_cache_clear(root))
})

test_that("recover refuses a live, unknown or foreign LOCK owner and leaves it in place", {
  for (case in list(list(pid = 2001L, host = Sys.info()[["nodename"]], reason = "live_owner"),
                    list(pid = 2002L, host = Sys.info()[["nodename"]], reason = "unknown_liveness"),
                    list(pid = 2003L, host = "some-other-host", reason = "foreign_host"))) {
    root <- store_root()
    stub_liveness(c("2001" = TRUE, "2003" = FALSE))
    plant_lock(root, case$pid, case$host)
    err <- expect_error(historical_cache_recover(root), class = "historical_lock_error")
    expect_identical(err$reason, case$reason, info = case$reason)
    expect_true(dir.exists(file.path(root, "LOCK")), info = case$reason)
  }
})

test_that("a clean store recovers as a no-op", {
  root <- store_root()
  expect_no_warning(out <- historical_cache_recover(root))
  expect_false(out$lock_removed)
  expect_length(out$leases_reclaimed, 0L)
})

test_that("the real process-table probe maps ps status 0 to alive and 1 to dead", {
  # Mock below the real probe, including the platform selector so this Unix
  # contract runs on every host. Never stub .historical_process_alive here.
  for (status in c(0L, 1L)) {
    calls <- list()
    testthat::local_mocked_bindings(
      .Platform = modifyList(.Platform, list(OS.type = "unix")),
      system2 = function(command, args, stdout, stderr) {
        calls[[length(calls) + 1L]] <<- list(command, args, stdout, stderr)
        status
      }, .package = "base")
    expect_identical(.historical_process_alive(424242L), status == 0L)
    expect_identical(calls, list(list("ps", c("-p", "424242"), FALSE, FALSE)))
  }
})

test_that("the real process-table probe keeps odd, denied and missing ps outcomes unknown", {
  outcomes <- list(function() 2L, function() 127L,
                   function() stop("Operation not permitted"),
                   function() stop("error in running command: ps not found"))
  for (outcome in outcomes) {
    calls <- list()
    testthat::local_mocked_bindings(
      .Platform = modifyList(.Platform, list(OS.type = "unix")),
      system2 = function(command, args, stdout, stderr) {
        calls[[length(calls) + 1L]] <<- list(command, args, stdout, stderr)
        outcome()
      }, .package = "base")
    expect_identical(.historical_process_alive(424242L), NA)
    expect_identical(calls, list(list("ps", c("-p", "424242"), FALSE, FALSE)))
  }
})

test_that("the real process-table probe rejects invalid PIDs without querying", {
  calls <- 0L
  testthat::local_mocked_bindings(
    .Platform = modifyList(.Platform, list(OS.type = "unix")),
    system2 = function(...) { calls <<- calls + 1L; 0L }, .package = "base")
  for (pid in list(-1L, 0L, NA_integer_, Inf, "invalid", .Machine$integer.max + 1)) {
    expect_identical(.historical_process_alive(pid), NA)
  }
  expect_identical(calls, 0L)
})

test_that("no store function signals a process", {
  home <- .store_home()
  names <- grep("^[.]?historical_", ls(home, all.names = TRUE), value = TRUE)
  functions <- names[vapply(names, function(n) is.function(get(n, envir = home)), logical(1))]
  expect_true(all(c(".historical_process_alive", ".historical_lock",
                    ".historical_reclaim_dead_leases", "historical_cache_recover") %in% functions))
  for (n in functions) {
    text <- paste(deparse(get(n, envir = home), control = "keepInteger"), collapse = "\n")
    expect_false(grepl("pskill|\\bkill(all)?\\b|\\bpkill\\b|\\bsignal\\s*=", text), info = n)
  }
})

# The source store and the processed-results store (processed-v1) have
# separate budgets. The source store's is 3 GiB unless
# STATE_SCHOOLDATA_HISTORICAL_CAPACITY_BYTES or a persisted capacity.rds says
# otherwise; processed-v1 bytes beside it never count against it.
test_that("the source store defaults to 3 GiB; the env var, then capacity.rds, override it", {
  root <- store_root()
  withr::local_envvar(STATE_SCHOOLDATA_HISTORICAL_CAPACITY_BYTES = NA,
                      STATE_SCHOOLDATA_PROCESSED_CAPACITY_BYTES = "1")
  expect_identical(.historical_capacity(root), 3 * 2^30)
  .historical_atomic_rds(5000, file.path(root, "capacity.rds"))
  expect_identical(.historical_capacity(root), 5000)
  withr::local_envvar(STATE_SCHOOLDATA_HISTORICAL_CAPACITY_BYTES = "7000")
  expect_identical(.historical_capacity(root), 7000)
})

test_that("a source reservation counts source bytes only, never processed-v1 beside it", {
  shared <- file.path(withr::local_tempdir(), "state-schooldata")
  root <- file.path(shared, "historical-assets-v1")
  .historical_store(root, TRUE)
  processed <- file.path(shared, "processed-v1", "zzschooldata", "data")
  dir.create(processed, recursive = TRUE)
  writeBin(as.raw(rep(1L, 50000)), file.path(processed, "big.rds"))
  withr::local_envvar(STATE_SCHOOLDATA_HISTORICAL_CAPACITY_BYTES = "2000")
  expect_identical(.historical_used(root), 0)
  expect_no_error(.historical_room(root, character(), 1500, 0))
  expect_identical(
    historical_with_reserved_workspace(numeric(), 1500, function(w) "ran", root = root), "ran")
  expect_true(file.exists(file.path(processed, "big.rds")))
})

# Private-repository release assets (2026-11-09). GitHub answers the anonymous
# release URL of a private repository with 404. With the user's token the API
# asset route answers 302 to a signed URL on another host, which must be
# fetched without the token. The request layer is a double here; no test
# touches the network or a real credential.
release_fixture <- function(private = TRUE) {
  bytes <- charToRaw("private release asset bytes")
  signed <- "https://release-assets.githubusercontent.com/github-production-release-asset/1/abc?sig=x"
  log <- list()
  request <- function(url, method, emit, headers = character()) {
    log[[length(log) + 1L]] <<- list(url = url, method = method, headers = headers)
    redirect <- function(to) list(status_code = 302L, headers = charToRaw(paste0("HTTP/2 302\r\nlocation: ", to, "\r\n\r\n")))
    if (startsWith(url, "https://github.com/")) {
      if (private) return(list(status_code = 404L)) else return(redirect(signed))
    }
    if (startsWith(url, "https://api.github.com/")) {
      if (!identical(unname(headers[["Authorization"]]), "Bearer tok-SECRET-123")) return(list(status_code = 404L))
      if (grepl("/releases/tags/", url)) {
        if (identical(method, "GET")) emit(charToRaw('{"assets":[{"id":11,"name":"other.zip"},{"id":727,"name":"x.zip"}]}'))
        return(list(status_code = 200L))
      }
      if (grepl("/releases/assets/727$", url) && identical(unname(headers[["Accept"]]), "application/octet-stream")) return(redirect(signed))
      return(list(status_code = 403L))
    }
    if (identical(url, signed)) {
      if (identical(method, "GET")) emit(bytes)
      return(list(status_code = 200L))
    }
    stop("unexpected host: ", url)
  }
  list(bytes = bytes, signed = signed, request = request, log = function() log,
       url = "https://github.com/almartin82/zzschooldata/releases/download/sources-1/x.zip")
}
collect_bytes <- function() {
  got <- raw()
  list(emit = function(chunk) { got <<- c(got, chunk); invisible(NULL) }, bytes = function() got)
}
no_gh_path <- function(env = parent.frame()) withr::local_envvar(PATH = withr::local_tempdir(.local_envir = env), .local_envir = env)
fake_gh <- function(body, env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  writeLines(c("#!/bin/sh", body), file.path(dir, "gh"))
  Sys.chmod(file.path(dir, "gh"), "755")
  withr::local_envvar(PATH = dir, .local_envir = env)
}

test_that("the GitHub token comes from GITHUB_PAT, then GITHUB_TOKEN, then gh auth token, else NULL", {
  fake_gh(c('[ "$1 $2" = "auth token" ] || exit 2', 'echo "gho-from-gh"'))
  withr::local_envvar(GITHUB_PAT = "pat-1", GITHUB_TOKEN = "tok-2")
  expect_identical(.historical_github_token(), "pat-1")
  withr::local_envvar(GITHUB_PAT = NA)
  expect_identical(.historical_github_token(), "tok-2")
  withr::local_envvar(GITHUB_TOKEN = NA)
  expect_identical(.historical_github_token(), "gho-from-gh")
  fake_gh(c('echo "not logged in" >&2', "exit 1"))
  expect_null(.historical_github_token())
  no_gh_path()
  expect_null(.historical_github_token())
})

test_that("a private release asset is fetched with the token on api.github.com only, never on the redirected host", {
  fx <- release_fixture()
  no_gh_path()
  withr::local_envvar(GITHUB_PAT = "tok-SECRET-123", GITHUB_TOKEN = NA)
  out <- collect_bytes()
  .historical_github_transport(fx$url, out$emit, .request = fx$request,
                               .token = .historical_github_token, .asset_id = 727)
  expect_identical(out$bytes(), fx$bytes)
  log <- fx$log()
  urls <- vapply(log, `[[`, "", "url")
  authed <- vapply(log, function(r) "Authorization" %in% names(r$headers), logical(1))
  expect_identical(urls, c(fx$url, "https://api.github.com/repos/almartin82/zzschooldata/releases/assets/727",
                           fx$signed, fx$signed))
  expect_identical(authed, c(FALSE, TRUE, FALSE, FALSE))
  expect_true(all(vapply(log[urls == fx$signed], function(r) length(r$headers) == 0L, logical(1))))
})

test_that("without a pinned asset id the id is resolved by tag and name through the API", {
  fx <- release_fixture()
  out <- collect_bytes()
  .historical_github_transport(fx$url, out$emit, .request = fx$request, .token = function() "tok-SECRET-123")
  expect_identical(out$bytes(), fx$bytes)
  urls <- vapply(fx$log(), `[[`, "", "url")
  expect_true("https://api.github.com/repos/almartin82/zzschooldata/releases/tags/sources-1" %in% urls)
  expect_true("https://api.github.com/repos/almartin82/zzschooldata/releases/assets/727" %in% urls)
})

test_that("with no token a private asset is a clear transport error and nothing else is contacted", {
  fx <- release_fixture()
  no_gh_path()
  withr::local_envvar(GITHUB_PAT = NA, GITHUB_TOKEN = NA)
  caught <- tryCatch(.historical_github_transport(fx$url, collect_bytes()$emit, .request = fx$request,
                                                  .token = .historical_github_token, .asset_id = 727),
                     error = identity)
  expect_s3_class(caught, "historical_transport_error")
  expect_identical(caught$status_code, 404L)
  expect_match(conditionMessage(caught), "GITHUB_PAT or GITHUB_TOKEN")
  expect_identical(vapply(fx$log(), `[[`, "", "url"), fx$url)
  # Through the download layer: no retry, no other host.
  fx2 <- release_fixture()
  asset <- list(artifact_id = "x", byte_length = length(fx2$bytes),
                storage = list(backend = "release_asset", download_url = fx2$url, asset_id = 727))
  caught <- tryCatch(.historical_download(asset, withr::local_tempfile(), function(url, emit)
    .historical_github_transport(url, emit, .request = fx2$request, .token = function() NULL)), error = identity)
  expect_s3_class(caught, "historical_transport_error")
  expect_identical(vapply(fx2$log(), `[[`, "", "url"), fx2$url)
})

test_that("a public release asset stays anonymous and never looks a token up", {
  fx <- release_fixture(private = FALSE)
  out <- collect_bytes()
  .historical_github_transport(fx$url, out$emit, .request = fx$request,
                               .token = function() stop("token looked up for a public asset"))
  expect_identical(out$bytes(), fx$bytes)
  expect_false(any(vapply(fx$log(), function(r) length(r$headers) > 0L, logical(1))))
})

test_that("the token never appears in an error, and is refused for any other host", {
  fx <- release_fixture()
  caught <- tryCatch(.historical_github_transport(fx$url, collect_bytes()$emit, .request = fx$request,
                                                  .token = function() "tok-SECRET-123", .asset_id = 999),
                     error = identity)
  expect_s3_class(caught, "historical_transport_error")
  expect_identical(caught$status_code, 403L)
  expect_false(grepl("SECRET", paste(conditionMessage(caught), paste(deparse(unclass(caught)), collapse = ""))))
  # The real request layer refuses before any connection is made.
  caught <- tryCatch(.historical_github_request("https://objects.githubusercontent.com/x", "HEAD", NULL,
                                                c(Authorization = "Bearer tok-SECRET-123")), error = identity)
  expect_s3_class(caught, "historical_policy_error")
  expect_false(grepl("SECRET", paste(conditionMessage(caught), paste(deparse(unclass(caught)), collapse = ""))))
})
