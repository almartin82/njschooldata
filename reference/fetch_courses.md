# Fetch Course, CTE, and College-Career Data

A unified long-schema front door over the package's existing course,
advanced-coursework, CTE, and college-career fetchers. This is additive:
the source-specific fetchers keep their existing default outputs, while
`fetch_courses()` delegates to them and normalizes published value
columns onto a common `metric`/`value` schema.

## Usage

``` r
fetch_courses(
  type = .course_fetch_types,
  end_year,
  level = "school",
  ...,
  with_status = FALSE,
  annotate = FALSE
)
```

## Arguments

- type:

  Course data family. See details for valid values.

- end_year:

  A school year end, e.g. `2025` for SY2024-25.

- level:

  One of `"school"` or `"district"`, passed to the underlying fetcher.

- ...:

  Optional arguments for specific families. `subject` filters
  `type = "course_enrollment"`; `test_type` is passed to
  `type = "sat_performance"`.

- with_status:

  Logical, default `FALSE`. If `TRUE`, appends a `value_status` column
  classified from each raw published value token before numeric coercion
  in this dispatcher.

- annotate:

  Logical, default `FALSE`. If `TRUE`, appends registry metadata via
  [`annotate_metric`](https://almartin82.github.io/njschooldata/reference/annotate_metric.md).

## Value

A tibble with entity identifiers, optional dimensions such as
`subgroup`, `subgroup_std`, `course_subject`, `course_name`,
`career_cluster`, `test_type`, and `apprenticeship_year`, standard
entity flags, `metric`, `value`, and optionally `value_status`. Metric
names are designed for lookup with
[`annotate_metric`](https://almartin82.github.io/njschooldata/reference/annotate_metric.md).

## Details

The `type` argument maps to existing fetchers as follows:

- `"advanced_access"` –
  [`fetch_advanced_course_access`](https://almartin82.github.io/njschooldata/reference/fetch_advanced_course_access.md)
  with `type = "participation_by_group"`.

- `"courses_offered"` –
  [`fetch_advanced_course_access`](https://almartin82.github.io/njschooldata/reference/fetch_advanced_course_access.md)
  with `type = "courses_offered"`.

- `"dual_enrollment"` –
  [`fetch_advanced_course_access`](https://almartin82.github.io/njschooldata/reference/fetch_advanced_course_access.md)
  with `type = "participation_by_group"`, keeping the dual-enrollment
  rate metrics.

- `"sle"` –
  [`fetch_advanced_course_access`](https://almartin82.github.io/njschooldata/reference/fetch_advanced_course_access.md)
  with `type = "sle"`.

- `"ap_ib_participation"` –
  [`fetch_ap_participation`](https://almartin82.github.io/njschooldata/reference/fetch_ap_participation.md).

- `"course_enrollment"` – one or more course-enrollment fetchers:
  [`fetch_math_course_enrollment`](https://almartin82.github.io/njschooldata/reference/fetch_math_course_enrollment.md),
  [`fetch_science_course_enrollment`](https://almartin82.github.io/njschooldata/reference/fetch_science_course_enrollment.md),
  [`fetch_social_studies_enrollment`](https://almartin82.github.io/njschooldata/reference/fetch_social_studies_enrollment.md),
  [`fetch_world_language_enrollment`](https://almartin82.github.io/njschooldata/reference/fetch_world_language_enrollment.md),
  [`fetch_cs_enrollment`](https://almartin82.github.io/njschooldata/reference/fetch_cs_enrollment.md),
  and
  [`fetch_arts_enrollment`](https://almartin82.github.io/njschooldata/reference/fetch_arts_enrollment.md).
  Use `subject =` in `...` to keep one or more subjects; omitted means
  all subjects.

- `"cte"` –
  [`fetch_cte_participation`](https://almartin82.github.io/njschooldata/reference/fetch_cte_participation.md).

- `"industry_credentials"` –
  [`fetch_industry_credentials`](https://almartin82.github.io/njschooldata/reference/fetch_industry_credentials.md).

- `"work_based_learning"` –
  [`fetch_work_based_learning`](https://almartin82.github.io/njschooldata/reference/fetch_work_based_learning.md).

- `"apprenticeship"` –
  [`fetch_apprenticeship_data`](https://almartin82.github.io/njschooldata/reference/fetch_apprenticeship_data.md).

- `"sat_participation"` –
  [`fetch_sat_participation`](https://almartin82.github.io/njschooldata/reference/fetch_sat_participation.md).

- `"sat_performance"` –
  [`fetch_sat_performance`](https://almartin82.github.io/njschooldata/reference/fetch_sat_performance.md);
  pass `test_type =` through `...` to filter.

- `"college_career"` – stacks `"sat_participation"`,
  `"sat_performance"`, `"ap_ib_participation"`, `"cte"`,
  `"industry_credentials"`, `"work_based_learning"`, and
  `"apprenticeship"`.

Value columns are classified with
[`classify_value_status`](https://almartin82.github.io/njschooldata/reference/classify_value_status.md)
before this dispatcher coerces them with
[`spr_value_numeric`](https://almartin82.github.io/njschooldata/reference/spr_value_numeric.md).
Suppressed or unpublished cells therefore stay honest `NA` values; no
counts or rates are back-derived from another published cell.

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_courses("advanced_access", 2025)
fetch_courses("course_enrollment", 2024, subject = "science")
fetch_courses("cte", 2025, with_status = TRUE)
} # }
```
