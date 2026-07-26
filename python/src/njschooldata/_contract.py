"""Intentional Python-friendly deviations from authoritative R formals."""

# Every curated wrapper otherwise exposes R formal names and defaults exactly.
# These two omissions prevent contradictory interfaces while retaining a more
# natural Python result contract.
CURATED_R_ARGUMENT_OVERRIDES = {
    "fetch_finance_multi": {
        "omit": ["end_year_vector"],
        "reason": "R's deprecated positional alias; Python uses end_years.",
    },
    "fetch_facility_gis": {
        "omit": ["sf"],
        "reason": "Python requests sf=False and performs GeoPandas conversion.",
    },
}


def expected_python_parameters(name: str, r_parameters: list[str]) -> list[str]:
    """Apply the narrow, documented R-to-Python signature mapping."""
    omitted = set(CURATED_R_ARGUMENT_OVERRIDES.get(name, {}).get("omit", []))
    return [parameter for parameter in r_parameters if parameter not in omitted]
