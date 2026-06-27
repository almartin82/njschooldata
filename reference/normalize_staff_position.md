# Normalize a raw staff POSITION label to a stable snake_case value

Harmonizes the position labels that drift across the legacy CSV era
(`ADMINIST`, `TEACHER`, `SUPPSERV`, `TOTAL`) and the modern xlsx era
(`Administrators`, `Special Service(s)`, `Teacher(s)`,
`Supervisors/Coordinators`, `Total`) onto one set: `administrators`,
`teachers`, `special_services`, `supervisors_coordinators`, `total`.

## Usage

``` r
normalize_staff_position(x)
```

## Arguments

- x:

  Raw position labels.

## Value

Normalized position labels (snake_case).
