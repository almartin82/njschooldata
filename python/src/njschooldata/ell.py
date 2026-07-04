"""English Learner population data functions."""

import pandas as pd

from ._r_bridge import call_r_function, r_to_pandas


@r_to_pandas
def fetch_ell(
    end_year: int,
    tidy: bool = True,
    use_cache: bool = False,
) -> pd.DataFrame:
    """
    Fetch New Jersey English Learner population data for a single year.

    This returns EL population counts and shares of enrollment at the state,
    district, and school levels. It is distinct from EL proficiency assessment
    data, which is exposed through :func:`fetch_access`.

    Parameters
    ----------
    end_year : int
        Ending school year, e.g. 2025 for 2024-25. Valid years are 2006-2026.
    tidy : bool, default True
        If True, returns the long cross-state tidy contract. If False, returns
        the wider per-entity frame.
    use_cache : bool, default False
        Whether to use the R package source cache.

    Returns
    -------
    pd.DataFrame
        One row per entity x EL status x subgroup when ``tidy=True``. The NJ
        source publishes a single current-EL headcount per entity, so
        ``el_status`` is ``"current"`` and ``subgroup`` is ``"total"``.
    """
    return call_r_function(
        "fetch_ell",
        end_year,
        tidy=tidy,
        use_cache=use_cache,
    )


@r_to_pandas
def fetch_ell_multi(
    end_years: list[int],
    tidy: bool = True,
    use_cache: bool = False,
) -> pd.DataFrame:
    """
    Fetch New Jersey English Learner population data for multiple years.

    Parameters
    ----------
    end_years : list[int]
        Ending school years, e.g. ``[2023, 2024, 2025]``.
    tidy : bool, default True
        If True, returns the long tidy contract.
    use_cache : bool, default False
        Whether to use the R package source cache.

    Returns
    -------
    pd.DataFrame
        Combined EL population data for all available requested years.
    """
    return call_r_function(
        "fetch_ell_multi",
        end_years,
        tidy=tidy,
        use_cache=use_cache,
    )
