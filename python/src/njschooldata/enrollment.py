"""Enrollment data functions."""

import pandas as pd

from ._r_bridge import call_r_function, r_to_pandas


@r_to_pandas
def fetch_enr(end_year: int, tidy: bool = False) -> pd.DataFrame:
    """
    Fetch NJ school enrollment data for a given year.

    Parameters
    ----------
    end_year : int
        School year (end of academic year, e.g., 2024 for 2023-24).
        Valid values: 2000-2025.
    tidy : bool, default False
        If True, returns long-format data suitable for longitudinal analysis.

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
    return call_r_function("fetch_enr", end_year, tidy)
