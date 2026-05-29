# Standardize student-group labels to cross-state conventions

Maps the verbose NJ student-group labels in the District by Ed Environ
sheet (eg "Black or African American", "Multilingual Learner") to the
lowercase snake_case names the rest of njschooldata/the 50-state project
uses (eg "black", "lep").

## Usage

``` r
standardize_sped_placement_subgroups(x)
```

## Arguments

- x:

  character vector of NJ-formatted student group labels

## Value

character vector of standardized subgroup names
