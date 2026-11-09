# Canonical store-recovery tests, vendored byte-for-byte as
# tests/testthat/test-historical-store-recovery.R by scripts/historical-store/sync.py.
# Edit ONLY contracts/historical-store/v1/test-historical-store-recovery.R.
#
# A reader or writer that dies hard (OOM kill, SIGKILL, CI timeout) never runs
# its on.exit cleanup: its lease would pin digests and reserve workspace bytes
# forever, and a dead LOCK owner would make every store call refuse. Liveness
# is STUBBED here, so dead / live / unknown are exact; no test spawns or
# signals a process (STANDARD D-h).

.store_home <- function() environment(.historical_reclaim_dead_leases)

store_root <- function(env = parent.frame()) {
  root <- file.path(withr::local_tempdir(.local_envir = env), "store")
  .historical_store(root, TRUE)
  root
}

# states: named logical, names are pids. Any pid not named is unknown (NA).
stub_liveness <- function(states, env = parent.frame()) {
  stub <- function(pid) {
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

test_that("a stale LOCK is never taken over automatically", {
  for (case in list(list(states = c("515150" = FALSE), reason = "dead_owner"),
                    list(states = c("1" = TRUE), reason = "unknown_liveness"))) {
    root <- store_root()
    stub_liveness(case$states)
    plant_lock(root, 515150L)
    lease <- plant_lease(root, "h1", 515150L)
    err <- expect_error(historical_cache_clear(root), "historical_cache_recover|\"recover\"",
                        class = "historical_lock_error")
    expect_identical(err$reason, case$reason, info = case$reason)
    expect_true(dir.exists(file.path(root, "LOCK")), info = case$reason)
    expect_identical(readRDS(file.path(root, "LOCK", "owner.rds"))$pid, 515150L, info = case$reason)
    expect_true(file.exists(lease), info = case$reason)
  }
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

test_that("liveness is read from the process table: alive, dead and unknown are distinct", {
  skip_on_os("windows")
  expect_true(.historical_process_alive(Sys.getpid()))
  # No system assigns a pid this large; ps answers "no such process".
  expect_false(.historical_process_alive(.Machine$integer.max - 1L))
  expect_identical(.historical_process_alive(-1), NA)
  # Without ps the answer is unknown, never dead.
  withr::local_envvar(PATH = "")
  expect_identical(.historical_process_alive(Sys.getpid()), NA)
  expect_identical(.historical_process_alive(.Machine$integer.max - 1L), NA)
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
