"""School finance data functions."""

from typing import Literal, Optional

import pandas as pd

from ._r_bridge import call_r_function, r_to_pandas

FinanceLevel = Literal["all", "state", "district", "school"]


@r_to_pandas
def fetch_finance(
    end_year: int,
    tidy: bool = True,
    use_cache: bool = True,
    with_status: bool = False,
    level: FinanceLevel = "all",
) -> pd.DataFrame:
    """
    Fetch New Jersey school finance data in the canonical cross-state schema.

    Consolidates per-pupil spending and total K-12 state aid onto a single tidy
    schema with a standard ``metric`` vocabulary.

    Parameters
    ----------
    end_year : int
        Ending fiscal/school year, e.g. 2024 for FY2024 / school year 2023-24.
    tidy : bool, default True
        Passed through to the R package.
    use_cache : bool, default True
        Whether to use the R package source cache.
    with_status : bool, default False
        Add a ``value_status`` column for structural missingness.
    level : {"all", "state", "district", "school"}, default "all"
        Entity grain to return. ``"school"`` returns structural gap rows because
        school-level finance is not published by this R fetcher.

    Returns
    -------
    pd.DataFrame
        Finance data with columns including ``end_year``, ``state_id``,
        ``entity_name``, ``county``, entity flags, NCES ids, ``metric``,
        ``value``, ``is_per_pupil``, and ``enrollment_denominator``.

    Examples
    --------
    >>> import njschooldata as njsd
    >>> finance = njsd.fetch_finance(2024)
    >>> finance[finance.metric == "per_pupil_total"].head()
    """
    return call_r_function(
        "fetch_finance",
        end_year,
        tidy=tidy,
        use_cache=use_cache,
        with_status=with_status,
        level=level,
    )


@r_to_pandas
def fetch_finance_multi(
    end_years: Optional[list[int]] = None,
    tidy: bool = True,
    use_cache: bool = True,
    with_status: bool = False,
    level: FinanceLevel = "all",
) -> pd.DataFrame:
    """
    Fetch New Jersey school finance data for multiple years.

    Parameters
    ----------
    end_years : list[int] or None, default None
        Ending fiscal/school years. When omitted, the R package fetches all
        available finance years.
    tidy : bool, default True
        Passed through to the R package.
    use_cache : bool, default True
        Whether to use the R package source cache.
    with_status : bool, default False
        Add a ``value_status`` column for structural missingness.
    level : {"all", "state", "district", "school"}, default "all"
        Entity grain to return.

    Returns
    -------
    pd.DataFrame
        Combined finance data for all requested years in the canonical schema.
    """
    kwargs = {
        "tidy": tidy,
        "use_cache": use_cache,
        "with_status": with_status,
        "level": level,
    }
    if end_years is not None:
        kwargs["end_years"] = end_years
    return call_r_function("fetch_finance_multi", **kwargs)
