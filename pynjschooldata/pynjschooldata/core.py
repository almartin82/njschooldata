"""
Core functions wrapping njschooldata R package via rpy2.
"""

import pandas as pd
from rpy2 import robjects
from rpy2.robjects import pandas2ri
from rpy2.robjects.packages import importr

# Activate pandas conversion
pandas2ri.activate()

# Import the R package (lazy load)
_pkg = None


def _get_pkg():
    """Lazy load the R package."""
    global _pkg
    if _pkg is None:
        _pkg = importr("njschooldata")
    return _pkg


def fetch_enr(end_year: int) -> pd.DataFrame:
    """
    Fetch New Jersey school enrollment data for a single year.

    Parameters
    ----------
    end_year : int
        The ending year of the school year (e.g., 2025 for 2024-25).

    Returns
    -------
    pd.DataFrame
        Enrollment data with columns for school/district identifiers,
        enrollment counts, and demographic breakdowns.

    Examples
    --------
    >>> import pynjschooldata as nj
    >>> df = nj.fetch_enr(2025)
    >>> df.head()
    """
    pkg = _get_pkg()
    r_df = pkg.fetch_enr(end_year)
    return pandas2ri.rpy2py(r_df)


def fetch_enr_multi(end_years: list[int]) -> pd.DataFrame:
    """
    Fetch New Jersey school enrollment data for multiple years.

    Parameters
    ----------
    end_years : list[int]
        List of ending years (e.g., [2020, 2021, 2022]).

    Returns
    -------
    pd.DataFrame
        Combined enrollment data for all requested years.

    Examples
    --------
    >>> import pynjschooldata as nj
    >>> df = nj.fetch_enr_multi([2020, 2021, 2022])
    """
    pkg = _get_pkg()
    r_years = robjects.IntVector(end_years)
    r_df = pkg.fetch_enr_multi(r_years)
    return pandas2ri.rpy2py(r_df)


def tidy_enr(df: pd.DataFrame) -> pd.DataFrame:
    """
    Convert enrollment data to tidy (long) format.

    Parameters
    ----------
    df : pd.DataFrame
        Enrollment data from fetch_enr or fetch_enr_multi.

    Returns
    -------
    pd.DataFrame
        Tidy format with one row per school/year/demographic combination.

    Examples
    --------
    >>> import pynjschooldata as nj
    >>> df = nj.fetch_enr(2025)
    >>> tidy = nj.tidy_enr(df)
    """
    pkg = _get_pkg()
    r_df = pandas2ri.py2rpy(df)
    r_result = pkg.tidy_enr(r_df)
    return pandas2ri.rpy2py(r_result)


def get_available_years() -> dict:
    """
    Get the range of available years for enrollment data.

    Returns
    -------
    dict
        Dictionary with 'min_year' and 'max_year' keys.

    Examples
    --------
    >>> import pynjschooldata as nj
    >>> years = nj.get_available_years()
    >>> print(f"Data available from {years['min_year']} to {years['max_year']}")
    """
    pkg = _get_pkg()
    r_result = pkg.get_available_years()
    return {
        "min_year": int(r_result.rx2("min_year")[0]),
        "max_year": int(r_result.rx2("max_year")[0]),
    }
