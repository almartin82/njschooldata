# Split a DARS "Student Group" label into normalized subgroup + grade_level

The DARS `Student Group` column mixes three kinds of label in one
column: the schoolwide total (`"Schoolwide"` in 2022-23,
`"School Total"` in 2023-24), demographic subgroups (race, gender,
economically disadvantaged, students with disabilities), and grade
levels (`"Grade Preschool"`, `"Grade Kindergarten"`, `"Grade 1"` ..
`"Grade 12"`). This helper splits each label into a project-standard
`subgroup` + `grade_level` pair so the two dimensions can be filtered
independently.

## Usage

``` r
rs_split_student_group(label)
```

## Arguments

- label:

  Character vector of raw `Student Group` labels.

## Value

A data frame with two columns: `subgroup` and `grade_level`.

## Details

Grade rows get `subgroup = "total population"` and a project-standard
grade label (`"PK"`, `"K"`, `"01"-"12"`); subgroup and schoolwide rows
get `grade_level = "TOTAL"`. The mapping is a deterministic
re-expression of the published labels, not an inference. (The shared
[`spr_split_student_group_grade()`](https://almartin82.github.io/njschooldata/reference/spr_split_student_group_grade.md)
helper does not handle the exact DARS labels - the hyphen in
`"Black or African-American"`, the spelled-out
`"Grade Preschool"`/`"Grade Kindergarten"`, or the 2023-24
`"School Total"` total label - so DARS does the split locally.)
