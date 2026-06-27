# Normalize a pre-redesign SPR grade/test label to the 2025 form

Maps the pre-redesign `grade`/`grade_subject` labels onto the redesigned
`grade_test` vocabulary: `"Grade 03"` -\> `"Grade 3"` (leading zero
stripped; `"Grade 10"` preserved), and the end-of-course codes `"ALG01"`
-\> `"Algebra I"`, `"ALG02"` -\> `"Algebra II"`, `"GEO01"` -\>
`"Geometry"`.

## Usage

``` r
normalize_grade_test(x)
```

## Arguments

- x:

  Character vector of raw labels.

## Value

Character vector of normalized labels.
