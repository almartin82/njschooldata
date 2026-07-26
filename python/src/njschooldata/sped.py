"""Special education data functions."""

import pandas as pd

from ._r_bridge import call_r_function, r_to_pandas


@r_to_pandas
def fetch_sped(
    end_year: int,
    level: str = "district",
    with_status: bool = False,
) -> pd.DataFrame:
    """
    Fetch New Jersey special education classification data.

    Parameters
    ----------
    end_year : int
        Ending school year, e.g. 2025 for 2024-25.
    level : str, default "district"
        ``"district"`` returns district-level classification rates.
        ``"state"`` returns statewide student counts by disability category
        where available.
    with_status : bool, default False
        Include row-level observation status fields where supported.

    Returns
    -------
    pd.DataFrame
        For ``level="district"``, classification counts and rates by district.
        For ``level="state"``, child counts by disability category.
    """
    return call_r_function(
        "fetch_sped", end_year, level=level, with_status=with_status
    )


@r_to_pandas
def fetch_sped_placement(
    end_year: int,
    age_group: str = "5-21",
    level: str = "district",
    tidy: bool = True,
    with_status: bool = False,
) -> pd.DataFrame:
    """
    Fetch special education placement / educational environment data.

    IDEA Section 618 educational environment data is the companion to
    :func:`fetch_sped`, covering least restrictive environment placement.

    Parameters
    ----------
    end_year : int
        Ending school year. Valid years are 2020 through 2025.
    age_group : str, default "5-21"
        ``"5-21"`` for school-age students or ``"3-5"`` for preschool.
    level : str, default "district"
        ``"district"`` or ``"state"``.
    tidy : bool, default True
        If True, returns the long tidy schema.
    with_status : bool, default False
        Include row-level observation status fields where supported.

    Returns
    -------
    pd.DataFrame
        One row per entity, subgroup, and educational environment.
    """
    return call_r_function(
        "fetch_sped_placement",
        end_year,
        age_group=age_group,
        level=level,
        tidy=tidy,
        with_status=with_status,
    )


@r_to_pandas
def fetch_sped_placement_multi(
    end_years: list[int],
    age_group: str = "5-21",
    level: str = "district",
    tidy: bool = True,
    with_status: bool = False,
    allow_partial: bool = False,
) -> pd.DataFrame:
    """
    Fetch special education placement data for multiple years.

    Strict mode is the default. Set ``allow_partial=True`` to return successful
    years while retaining per-year status in
    ``DataFrame.attrs["source_results"]``.
    """
    return call_r_function(
        "fetch_sped_placement_multi",
        end_years,
        age_group=age_group,
        level=level,
        tidy=tidy,
        with_status=with_status,
        allow_partial=allow_partial,
    )
