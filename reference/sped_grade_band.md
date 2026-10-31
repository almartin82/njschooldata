# Grade band of a school's span

A span inside one band returns that band. A span crossing bands returns
"mixed": its share cannot be split by band without assuming every band
has the same rate, so like-for-like leaves it out and reports how much
it left out.

## Usage

``` r
sped_grade_band(grade_low, grade_high)
```

## Arguments

- grade_low, grade_high:

  Lowest and highest grade: "K", or "01" to "12". PK reads as K.
  Anything else gives NA.

## Value

Character vector: elementary, middle, high, mixed or NA.
