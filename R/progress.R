# ==============================================================================
# Progress Indicators for Batch Downloads
# ==============================================================================

# Package environment for progress state
.njsd_progress <- new.env(parent = emptyenv())
.njsd_progress$enabled <- TRUE

#' Enable or disable progress indicators
#'
#' Controls whether progress messages are shown during batch operations.
#'
#' @param enable Logical; TRUE to enable progress, FALSE to disable
#' @return Previous state (invisibly)
#' @export
#' @examples
#' njsd_progress_enable(FALSE)  # Quiet mode
#' njsd_progress_enable(TRUE)   # Show progress
njsd_progress_enable <- function(enable = TRUE) {
  old_state <- .njsd_progress$enabled
  .njsd_progress$enabled <- enable
  invisible(old_state)
}

#' Check if progress indicators are enabled
#'
#' @return Logical
#' @keywords internal
progress_enabled <- function() {
  .njsd_progress$enabled
}

#' Create a simple progress tracker
#'
#' Creates a progress tracker for batch operations that displays
#' progress messages to the console.
#'
#' @param total Total number of items to process
#' @param task_name Name of the task being performed
#' @return A list with update() and done() functions
#' @keywords internal
#' @examples
#' \dontrun{
#' pb <- progress_tracker(10, "Downloading files")
#' for (i in 1:10) {
#'   Sys.sleep(0.1)
#'   pb$update(i, sprintf("File %d", i))
#' }
#' pb$done()
#' }
progress_tracker <- function(total, task_name = "Processing") {
  if (!progress_enabled()) {
    # Return silent tracker
    return(list(
      update = function(current, item_name = NULL) invisible(NULL),
      done = function(success = TRUE) invisible(NULL),
      tick = function(item_name = NULL) invisible(NULL)
    ))
  }

  current <- 0
  start_time <- Sys.time()
  width <- getOption("width", 80)

  message(sprintf("\n%s (%d items)", task_name, total))
  message(strrep("-", min(nchar(task_name) + 15, width)))

  update <- function(i, item_name = NULL) {
    current <<- i
    pct <- round(i / total * 100)
    elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

    if (i > 0 && elapsed > 0) {
      rate <- i / elapsed
      remaining <- (total - i) / rate
      eta <- format_duration(remaining)
    } else {
      eta <- "calculating..."
    }

    # Build progress message
    if (!is.null(item_name)) {
      msg <- sprintf("[%3d/%d] %3d%% | %s | ETA: %s",
                     i, total, pct, item_name, eta)
    } else {
      msg <- sprintf("[%3d/%d] %3d%% | ETA: %s",
                     i, total, pct, eta)
    }

    # Truncate if too long
    if (nchar(msg) > width - 2) {
      msg <- paste0(substr(msg, 1, width - 5), "...")
    }

    message(msg)
  }

  tick <- function(item_name = NULL) {
    current <<- current + 1
    update(current, item_name)
  }

  done <- function(success = TRUE) {
    elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

    if (success) {
      message(sprintf(
        "\nCompleted %d items in %s",
        total,
        format_duration(elapsed)
      ))
    } else {
      message(sprintf(
        "\nFailed after processing %d/%d items (%s)",
        current,
        total,
        format_duration(elapsed)
      ))
    }
  }

  list(
    update = update,
    tick = tick,
    done = done,
    current = function() current
  )
}

#' Format duration in human-readable form
#'
#' @param seconds Number of seconds
#' @return Character string like "2m 30s" or "1h 5m"
#' @keywords internal
format_duration <- function(seconds) {
  if (is.na(seconds) || !is.finite(seconds) || seconds < 0) {
    return("--")
  }

  if (seconds < 60) {
    return(sprintf("%.0fs", seconds))
  } else if (seconds < 3600) {
    mins <- floor(seconds / 60)
    secs <- round(seconds %% 60)
    return(sprintf("%dm %ds", mins, secs))
  } else {
    hours <- floor(seconds / 3600)
    mins <- round((seconds %% 3600) / 60)
    return(sprintf("%dh %dm", hours, mins))
  }
}

#' Fetch all PARCC/NJSLA results with progress
#'
#' Downloads all available PARCC and NJSLA assessment results with
#' progress indicators showing download status and ETA.
#'
#' @return A data frame with all PARCC/NJSLA results
#' @export
#' @examples
#' \dontrun{
#' all_results <- fetch_all_parcc_with_progress()
#' }
fetch_all_parcc_with_progress <- function() {
  # Build list of all year/grade/subject combinations
  valid_years <- c(2015:2019, 2021:2024)
  grades_ela <- 3:11
  grades_math <- 3:8
  courses <- c("ALG1", "GEO", "ALG2")

  # Count total items
  total_items <- length(valid_years) * (
    length(grades_ela) +  # ELA grades
    length(grades_math) + # Math grades
    length(courses)       # Math courses
  )

  # Adjust for NJSLA (2019+) dropping grade 11 ELA
  njsla_years <- valid_years[valid_years >= 2019]
  total_items <- total_items - length(njsla_years)

  pb <- progress_tracker(total_items, "Fetching PARCC/NJSLA data")
  results <- list()
  item_count <- 0

  for (yr in valid_years) {
    # ELA grades
    ela_grades <- if (yr >= 2019) 3:10 else 3:11

    for (gr in ela_grades) {
      item_count <- item_count + 1
      item_name <- sprintf("%d Grade %d ELA", yr, gr)
      pb$update(item_count, item_name)

      result <- tryCatch({
        fetch_parcc(end_year = yr, grade_or_subj = gr, subj = "ela", tidy = TRUE)
      }, error = function(e) {
        message(sprintf("  Warning: %s", e$message))
        NULL
      })

      if (!is.null(result)) {
        results[[paste(yr, gr, "ela", sep = "_")]] <- result
      }
    }

    # Math grades
    for (gr in grades_math) {
      item_count <- item_count + 1
      item_name <- sprintf("%d Grade %d Math", yr, gr)
      pb$update(item_count, item_name)

      result <- tryCatch({
        fetch_parcc(end_year = yr, grade_or_subj = gr, subj = "math", tidy = TRUE)
      }, error = function(e) {
        message(sprintf("  Warning: %s", e$message))
        NULL
      })

      if (!is.null(result)) {
        results[[paste(yr, gr, "math", sep = "_")]] <- result
      }
    }

    # Math courses
    for (course in courses) {
      item_count <- item_count + 1
      item_name <- sprintf("%d %s", yr, course)
      pb$update(item_count, item_name)

      result <- tryCatch({
        fetch_parcc(end_year = yr, grade_or_subj = course, subj = "math", tidy = TRUE)
      }, error = function(e) {
        message(sprintf("  Warning: %s", e$message))
        NULL
      })

      if (!is.null(result)) {
        results[[paste(yr, course, "math", sep = "_")]] <- result
      }
    }
  }

  pb$done()

  message(sprintf("Successfully fetched %d datasets", length(results)))
  dplyr::bind_rows(results)
}

#' Fetch multiple years of enrollment data with progress
#'
#' @param years Vector of years to fetch
#' @param tidy Return tidy format? (default TRUE)
#' @return Data frame with all enrollment data
#' @export
#' @examples
#' \dontrun{
#' enr_5yr <- fetch_enr_years(2020:2024)
#' }
fetch_enr_years <- function(years, tidy = TRUE) {
  pb <- progress_tracker(length(years), "Fetching enrollment data")
  results <- list()

  for (i in seq_along(years)) {
    yr <- years[i]
    pb$update(i, sprintf("%d enrollment", yr))

    result <- tryCatch({
      fetch_enr(yr, tidy = tidy)
    }, error = function(e) {
      message(sprintf("  Warning: %s", e$message))
      NULL
    })

    if (!is.null(result)) {
      results[[as.character(yr)]] <- result
    }
  }

  pb$done()
  dplyr::bind_rows(results)
}
