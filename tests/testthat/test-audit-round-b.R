# Retained state-source bytes; no generated education values.
test_that("all SPR readers release temporary handles on every exit", {
  fixture <- source_adapter_fixture("spr-district-2025.xlsx")
  for (exit in c("success", "missing", "interrupt")) {
    for (name in c("fetch_spr_data", "fetch_spr_sheet_raw", "list_spr_sheets", "fetch_6yr_grad_rate")) {
      env <- new.env(parent = asNamespace("njschooldata"))
      f <- get(name, env); environment(f) <- env
      released <- 0L
      owned <- tempfile(fileext = ".xlsx")
      file.copy(fixture, owned)
      env$cache_get <- function(...) NULL
      env$cache_set <- function(...) invisible(NULL)
      env$spr_cached_workbook_result <- function(...) {
        result <- new_source_result(data = owned, source_status = "actual")
        result$release <- function() { released <<- released + 1L; unlink(owned) }
        result
      }
      args <- if (name %in% c("fetch_spr_data", "fetch_spr_sheet_raw")) {
        list(if (exit == "missing") "not-a-published-sheet" else "ChronicAbsenteeismStudentGroup", 2025, "district")
      } else list(2025, "district")
      if (exit == "interrupt") {
        env$source_result_data <- function(...) stop(structure(list(message="diagnostic interruption",call=NULL), class=c("interrupt","condition")))
        expect_true(tryCatch({ do.call(f, args); FALSE }, interrupt = function(e) TRUE))
      } else if (name == "fetch_6yr_grad_rate" || (exit == "missing" && name != "list_spr_sheets")) {
        expect_error(do.call(f, args))
      } else expect_silent(do.call(f, args))
      expect_identical(released, 1L)
      expect_false(file.exists(owned))
    }
  }
})

test_that("actual transport releases failed acquisition and exposes owned success", {
  fixture <- source_adapter_fixture("spr-district-2025.xlsx")
  url <- get_spr_url(2025, "district")
  for (exit in c("success", "error", "interrupt")) {
    owned <- NULL
    request <- function(url, destination, timeout) {
      owned <<- destination
      file.copy(fixture, destination)
      if (exit == "error") stop("diagnostic request error")
      if (exit == "interrupt") stop(structure(list(message="diagnostic interruption",call=NULL),class=c("interrupt","condition")))
      list(status_code=200L, final_url=url)
    }
    if (exit == "interrupt") {
      expect_true(tryCatch({ download_source(url,"xlsx",request_fn=request,retries=0L); FALSE }, interrupt=function(e) TRUE))
    } else {
      result <- download_source(url,"xlsx",request_fn=request,retries=0L)
      if (exit == "success") {
        expect_identical(result$ownership,"temporary")
        expect_true(file.exists(owned))
        .release_source_result(result)
        .release_source_result(result)
      } else expect_identical(result$source_status,"source_unavailable")
    }
    expect_false(file.exists(owned))
  }
})

test_that("borrowed persistent and leased parents are never unlinked by readers", {
  fixture <- source_adapter_fixture("spr-district-2025.xlsx")
  before <- readBin(fixture,"raw",file.info(fixture)$size)
  for (leased in c(FALSE,TRUE)) {
    env <- new.env(parent=asNamespace("njschooldata"))
    f <- list_spr_sheets;environment(f)<-env
    released <- 0L
    env$spr_cached_workbook_result <- function(...) {
      result <- new_source_result(data=fixture,source_status="actual")
      result$ownership <- if (leased) "leased" else "persistent"
      if (leased) result$release <- function() {released <<- released+1L}
      result
    }
    expect_identical(f(2025,"district"),sort(readxl::excel_sheets(fixture)))
    expect_identical(released,as.integer(leased))
    expect_identical(readBin(fixture,"raw",file.info(fixture)$size),before)
  }
})

test_that("the private path-only compatibility helper cannot discard ownership", {
  fixture <- source_adapter_fixture("spr-district-2025.xlsx")
  env <- new.env(parent=asNamespace("njschooldata"))
  f <- spr_cached_workbook;environment(f)<-env
  for(ownership in c("temporary","leased","persistent")) {
    released <- 0L
    env$spr_cached_workbook_result <- function(...) {
      result <- new_source_result(data=fixture,source_status="actual")
      result$ownership <- ownership
      if(ownership != "persistent")result$release<-function(){released<<-released+1L}
      result
    }
    if(ownership == "persistent")expect_identical(f(2025,"district"),fixture)
    else expect_error(f(2025,"district"),"retain and release")
    expect_identical(released,as.integer(ownership!="persistent"))
    expect_true(file.exists(fixture))
  }
})

test_that("transport owns its download until result construction completes", {
  fixture <- source_adapter_fixture("spr-district-2025.xlsx")
  for(exit in c("error","interrupt")) {
    env <- new.env(parent=asNamespace("njschooldata"))
    f <- download_source;environment(f)<-env
    destination <- NULL
    env$new_source_result <- function(...) {
      if(exit=="error")stop("diagnostic result construction error")
      stop(structure(list(message="diagnostic result construction interruption",call=NULL),class=c("interrupt","condition")))
    }
    request <- function(url,path,timeout){destination<<-path;file.copy(fixture,path);list(status_code=200L,final_url=url)}
    if(exit=="error")expect_error(f(get_spr_url(2025,"district"),"xlsx",request_fn=request),"construction error")
    else expect_true(tryCatch({f(get_spr_url(2025,"district"),"xlsx",request_fn=request);FALSE},interrupt=function(c)TRUE))
    expect_false(file.exists(destination))
  }
})
