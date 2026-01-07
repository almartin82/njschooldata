"""Graduation data functions."""

import pandas as pd

from ._r_bridge import call_r_function, r_to_pandas


@r_to_pandas
def fetch_grad_rate(
    end_year: int,
    methodology: str = "4 year"
) -> pd.DataFrame:
    """
    Fetch NJ graduation rate data.

    Parameters
    ----------
    end_year : int
        School year (2011-2024).
    methodology : str, default "4 year"
        Graduation rate methodology: "4 year" or "5 year".

    Returns
    -------
    pd.DataFrame
        Graduation rates by school/district and student subgroup.

    Examples
    --------
    >>> import njschooldata as njsd
    >>> grate_2023 = njsd.fetch_grad_rate(2023)
    >>> grate_5yr = njsd.fetch_grad_rate(2019, methodology="5 year")
    """
    return call_r_function("fetch_grad_rate", end_year, methodology)
