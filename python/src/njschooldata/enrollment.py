"""Enrollment data functions."""

from typing import Optional, Union

import pandas as pd

from ._r_bridge import call_r_function, r_to_pandas


@r_to_pandas
def fetch_enr(
    end_year: int,
    tidy: bool = False,
    use_cache: bool = False,
) -> pd.DataFrame:
    """
    Fetch NJ school enrollment data for a given year.

    Parameters
    ----------
    end_year : int
        School year (end of academic year, e.g., 2024 for 2023-24).
        Valid values: 1999-2026.
    tidy : bool, default False
        If True, returns long-format data suitable for longitudinal analysis.
    use_cache : bool, default False
        Whether to reuse a validated artifact from the R package source cache.

    Returns
    -------
    pd.DataFrame
        Enrollment data with columns including district_id, school_id,
        enrollment counts by grade and demographic subgroups.

    Examples
    --------
    >>> import njschooldata as njsd
    >>> enr_2024 = njsd.fetch_enr(2024)
    >>> enr_tidy = njsd.fetch_enr(2024, tidy=True)
    """
    return call_r_function(
        "fetch_enr", end_year, tidy=tidy, use_cache=use_cache
    )


def get_available_years(type: Optional[str] = None) -> Union[list[int], pd.DataFrame]:
    """Return served end years as list[int], or all coverage as a DataFrame.

    With ``type="enrollment"``, return explicit years under default selectors.
    With no type, return columns ``type``, ``end_year``, and ``fetcher``.
    Known families whose coverage is undeclared raise an R error.
    """
    # Omitting the argument lets R supply NULL without converting Python None.
    if type is None:
        return r_to_pandas(call_r_function)("get_available_years")
    return [int(year) for year in call_r_function("get_available_years", type=type)]
