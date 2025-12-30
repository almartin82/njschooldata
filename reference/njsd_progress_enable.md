# Enable or disable progress indicators

Controls whether progress messages are shown during batch operations.

## Usage

``` r
njsd_progress_enable(enable = TRUE)
```

## Arguments

- enable:

  Logical; TRUE to enable progress, FALSE to disable

## Value

Previous state (invisibly)

## Examples

``` r
njsd_progress_enable(FALSE)  # Quiet mode
njsd_progress_enable(TRUE)   # Show progress
```
