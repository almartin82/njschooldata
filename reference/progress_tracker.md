# Create a simple progress tracker

Creates a progress tracker for batch operations that displays progress
messages to the console.

## Usage

``` r
progress_tracker(total, task_name = "Processing")
```

## Arguments

- total:

  Total number of items to process

- task_name:

  Name of the task being performed

## Value

A list with update() and done() functions

## Examples

``` r
if (FALSE) { # \dontrun{
pb <- progress_tracker(10, "Downloading files")
for (i in 1:10) {
  Sys.sleep(0.1)
  pb$update(i, sprintf("File %d", i))
}
pb$done()
} # }
```
