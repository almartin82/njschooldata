# Finance School-Level Source Note

NJ publishes school-level per-pupil expenditure reporting separately from the
district finance sources used by `fetch_finance()`.

Future source:

- NJ DOE ESSA per-pupil expenditure reporting:
  `https://www.nj.gov/education/fpp/audit/audsum/essa/`

Current package behavior:

- `fetch_finance()` remains district/state only.
- `is_school` stays `FALSE`.
- `level = "school"` returns structural gap rows rather than fabricated
  school finance values.
- With `with_status = TRUE`, those structural rows carry
  `value_status = "not_published"`.

Future implementation work should wire the ESSA source as a real school-level
finance source or a separate source-specific fetcher. Do not infer school-level
finance from district totals or per-pupil percentages.
