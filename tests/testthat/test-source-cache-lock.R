# Persistent source-cache acquisition: crashed owners must not wedge an entry.
#
# download_source() guards a persistent cache path with `<path>.acquiring/`.
# A process killed mid-download never runs on.exit, so before these fixes its
# lock refused that URL forever (reported as source_unavailable), and a death
# between the payload and sidecar renames left a payload with no sidecar,
# which reads as a legacy entry needing explicit repair. Liveness is stubbed;
# nothing here signals a process.

lock_zip_request <- function(counter) {
  function(url, dest, timeout) {
    counter$calls <- counter$calls + 1L
    work <- tempfile("lock-zip-")
    dir.create(work)
    on.exit(unlink(work, recursive = TRUE), add = TRUE)
    writeLines("lock fixture", file.path(work, "source.txt"))
    zip::zipr(dest, "source.txt", root = work)
    list(status_code = 200L, final_url = url, content_type = "application/zip")
  }
}

plant_lock <- function(cache, pid = 999999L, host = Sys.info()[["nodename"]]) {
  lock <- paste0(cache, ".acquiring")
  dir.create(lock)
  saveRDS(list(pid = pid, host = host, started = Sys.time()),
          file.path(lock, "owner.rds"))
  lock
}

test_that("a lock left by a dead owner on this host is reclaimed with a warning", {
  cache <- tempfile(fileext = ".zip")
  withr::defer(unlink(c(cache, paste0(cache, ".source.rds")), recursive = TRUE))
  lock <- plant_lock(cache)
  local_mocked_bindings(.historical_process_alive = function(pid) FALSE,
                        .package = "njschooldata")
  counter <- new.env(); counter$calls <- 0L
  expect_warning(
    result <- download_source("https://www.nj.gov/lock.zip", "zip", cache_path = cache,
                              request_fn = lock_zip_request(counter), retries = 0L),
    "Reclaimed an abandoned source-cache acquisition lock from dead pid 999999"
  )
  expect_identical(result$source_status, "actual")
  expect_identical(counter$calls, 1L)
  expect_false(dir.exists(lock))
  expect_true(file.exists(paste0(cache, ".source.rds")))
})

test_that("unknown liveness, another host, or a fresh ownerless lock is never reclaimed", {
  local_mocked_bindings(.historical_process_alive = function(pid) NA,
                        .package = "njschooldata")
  counter <- new.env(); counter$calls <- 0L
  for (setup in list(
    function(cache) plant_lock(cache),
    function(cache) plant_lock(cache, host = "some-other-host"),
    function(cache) { lock <- paste0(cache, ".acquiring"); dir.create(lock); lock }
  )) {
    cache <- tempfile(fileext = ".zip")
    lock <- setup(cache)
    busy <- download_source("https://www.nj.gov/lock.zip", "zip", cache_path = cache,
                            request_fn = lock_zip_request(counter), retries = 0L,
                            sleep_fn = function(s) stop("must not wait"))
    expect_identical(busy$source_status, "source_unavailable")
    expect_true(dir.exists(lock))
    unlink(lock, recursive = TRUE)
  }
  expect_identical(counter$calls, 0L)
})

test_that("an ownerless lock older than any acquisition is reclaimed", {
  cache <- tempfile(fileext = ".zip")
  withr::defer(unlink(c(cache, paste0(cache, ".source.rds")), recursive = TRUE))
  lock <- paste0(cache, ".acquiring")
  dir.create(lock)
  Sys.setFileTime(lock, Sys.time() - 3 * 60 * 60)
  counter <- new.env(); counter$calls <- 0L
  expect_warning(
    result <- download_source("https://www.nj.gov/lock.zip", "zip", cache_path = cache,
                              request_fn = lock_zip_request(counter), retries = 0L),
    "with no owner record"
  )
  expect_identical(result$source_status, "actual")
  expect_false(dir.exists(lock))
})

test_that("a live owner is waited for, and its finished entry is read, not refetched", {
  cache <- tempfile(fileext = ".zip")
  withr::defer(unlink(c(cache, paste0(cache, ".source.rds")), recursive = TRUE))
  counter <- new.env(); counter$calls <- 0L
  url <- "https://www.nj.gov/lock.zip"
  # The "other session" finishes its download, then we lock behind it.
  seeded <- download_source(url, "zip", cache_path = paste0(cache, ".seed"),
                            request_fn = lock_zip_request(counter), retries = 0L)
  withr::defer(unlink(c(paste0(cache, ".seed"), paste0(cache, ".seed.source.rds"))))
  lock <- plant_lock(cache, pid = Sys.getpid())
  local_mocked_bindings(.historical_process_alive = function(pid) TRUE,
                        .package = "njschooldata")
  waits <- 0L
  finish_other_session <- function(seconds) {
    waits <<- waits + 1L
    file.copy(paste0(cache, ".seed.source.rds"), paste0(cache, ".source.rds"))
    file.copy(paste0(cache, ".seed"), cache)
    unlink(lock, recursive = TRUE)
  }
  result <- download_source(url, "zip", cache_path = cache,
                            request_fn = lock_zip_request(counter), retries = 0L,
                            sleep_fn = finish_other_session)
  expect_identical(result$source_status, "actual")
  expect_identical(waits, 1L)
  expect_identical(counter$calls, 1L)  # only the seed download
  expect_match(result$warning, "cache", ignore.case = TRUE)
})

test_that("a process that dies between the two promotions leaves a plain miss", {
  cache <- tempfile(fileext = ".zip")
  withr::defer(unlink(c(cache, paste0(cache, ".source.rds"),
                        paste0(cache, ".acquiring")), recursive = TRUE))
  renames <- 0L
  local_mocked_bindings(
    .source_cache_rename = function(from, to) {
      renames <<- renames + 1L
      if (renames == 2L) stop("simulated crash between promotions")
      file.rename(from, to)
    },
    .package = "njschooldata"
  )
  counter <- new.env(); counter$calls <- 0L
  url <- "https://www.nj.gov/lock.zip"
  expect_error(download_source(url, "zip", cache_path = cache,
                               request_fn = lock_zip_request(counter), retries = 0L),
               "simulated crash")
  # Never a payload without its sidecar: that state reads as a legacy entry.
  expect_false(file.exists(cache) && !file.exists(paste0(cache, ".source.rds")))
  again <- download_source(url, "zip", cache_path = cache,
                           request_fn = lock_zip_request(counter), retries = 0L)
  expect_identical(again$source_status, "actual")
  expect_identical(counter$calls, 2L)
  expect_identical(readRDS(paste0(cache, ".source.rds"))$digest, again$digest)
})

test_that("clearing the workbook cache reclaims a dead lock and removes its entry", {
  root <- tempfile("lock-clear-")
  withr::local_options(njschooldata.cache_dir = root)
  withr::defer(unlink(root, recursive = TRUE))
  directory <- njsd_workbook_cache_dir()
  dir.create(directory, recursive = TRUE)
  entry <- file.path(directory, "SPR_school_2020.xlsx")
  writeLines("stand-in bytes", entry)
  plant_lock(entry)
  local_mocked_bindings(.historical_process_alive = function(pid) FALSE,
                        .package = "njschooldata")
  expect_warning(removed <- suppressMessages(njsd_workbook_cache_clear(2020)),
                 "Reclaimed")
  expect_identical(removed, 1L)
  expect_false(file.exists(entry))
  expect_false(dir.exists(paste0(entry, ".acquiring")))
})
