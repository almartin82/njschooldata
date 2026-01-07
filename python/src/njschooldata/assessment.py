"""Assessment data functions (PARCC/NJSLA, ACCESS)."""

from typing import Union

import pandas as pd

from ._r_bridge import call_r_function, r_to_pandas


@r_to_pandas
def fetch_parcc(
    end_year: int,
    grade_or_subj: Union[int, str],
    subj: str,
    tidy: bool = False
) -> pd.DataFrame:
    """
    Fetch PARCC/NJSLA assessment data.

    Parameters
    ----------
    end_year : int
        School year (2015-2024). 2020 was cancelled due to COVID.
    grade_or_subj : int or str
        Grade level (3-11) or math subject code ('ALG1', 'GEO', 'ALG2').
    subj : str
        Subject: 'ela', 'math', or 'science' (science: 2019+ only).
    tidy : bool, default False
        If True, applies additional data cleaning.

    Returns
    -------
    pd.DataFrame
        Assessment results by school/district with proficiency levels.

    Examples
    --------
    >>> import njschooldata as njsd
    >>> math_g4 = njsd.fetch_parcc(2023, 4, 'math')
    >>> alg1 = njsd.fetch_parcc(2023, 'ALG1', 'math')
    """
    return call_r_function("fetch_parcc", end_year, grade_or_subj, subj, tidy)


@r_to_pandas
def fetch_access(end_year: int, grade: str = "all") -> pd.DataFrame:
    """
    Fetch ACCESS for ELLs assessment data.

    Parameters
    ----------
    end_year : int
        School year (2022-2024).
    grade : str, default "all"
        Grade level: "K" or 0-12, or "all" for all grades.

    Returns
    -------
    pd.DataFrame
        ACCESS English proficiency results by school/district.

    Examples
    --------
    >>> import njschooldata as njsd
    >>> access_2024 = njsd.fetch_access(2024)
    >>> access_g3 = njsd.fetch_access(2024, grade="3")
    """
    return call_r_function("fetch_access", end_year, grade)
