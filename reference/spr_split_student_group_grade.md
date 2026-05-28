# Normalize a raw SPR "student_group_grade" label

The SPR detail sheets (`PoliceNotificationsGroupGrade`,
`ArrestsStudentGroupGrade`, `RemovalsStudentGroupGrade` and their
2023-24 legacy aliases) carry a single column whose rows alternate
between subgroup labels (e.g. `"Black or African American"`,
`"Economically Disadvantaged Students"`) and grade labels (e.g.
`"Grade 9"`, `"Grade KG"`). This helper splits each raw label into a
project-standard `subgroup` + `grade_level` pair so downstream code can
filter the two dimensions independently.

## Usage

``` r
spr_split_student_group_grade(label)
```

## Arguments

- label:

  Character vector of raw labels from the SPR `student_group_grade` /
  `student_group_grade_level` column.

## Value

A data frame with two columns: `subgroup` and `grade_level`, one row per
input label.

## Details

Subgroup rows receive the project-standard subgroup label (matching the
output of
[`clean_spr_subgroups`](https://almartin82.github.io/njschooldata/reference/clean_spr_subgroups.md))
and `grade_level = "TOTAL"`. Grade rows receive
`subgroup = "total population"` and the project-standard grade label
(`"PK"`, `"K"`, `"01"-"12"`).
