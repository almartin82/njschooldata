# Read an NJ DOE enrollment percentage column as published

NJ DOE publishes some fall-enrollment percentages as a censoring token
instead of a value - most visibly \`"\>95"\`, used from the 2019-20 file
onward wherever a share exceeds 95 percent. A censored cell is UNKNOWN,
not a number, so every non-numeric token becomes \`NA\` and stays
\`NA\`. This mirrors the suppression handling already applied to
graduation data in \[process_grate()\].

## Usage

``` r
enr_pct_published_value(x)
```

## Arguments

- x:

  A percentage column exactly as published.

## Value

A numeric vector, \`NA\` wherever NJ DOE censored or omitted the value.

## Details

Substituting a midpoint (or any other stand-in) for the token would
invent the percentage, and because these populations are published only
as percentages, the count derived by multiplying it by total enrollment
would be an invented headcount presented as an NJ DOE figure.
