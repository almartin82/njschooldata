"""Compatibility data-frame views over the NJ school/district directory.

`fetch_directory()` returns the canonical entities/roles/provenance result.
These two front doors return the source-shaped tables instead, mirroring the
R exports `get_school_directory()` and `get_district_directory()`.

They are declared in the generated compatibility contract, so they need
explicit zero-argument signatures rather than the generic ``*args, **kwargs``
pass-through that ``__getattr__`` would otherwise build for them.

The directory is an always-on source: it is acquired live on every call and is
never served from a cache.
"""

import pandas as pd

from ._r_bridge import call_r_function, r_to_pandas


@r_to_pandas
def get_school_directory() -> pd.DataFrame:
    """
    Get the current NJ school directory.

    Returns
    -------
    pd.DataFrame
        Schools and associated metadata, in the source-shaped layout.

    Examples
    --------
    >>> import njschooldata as njsd
    >>> schools = njsd.get_school_directory()
    """
    return call_r_function("get_school_directory")


@r_to_pandas
def get_district_directory() -> pd.DataFrame:
    """
    Get the current NJ district directory.

    Returns
    -------
    pd.DataFrame
        Districts and associated metadata, in the source-shaped layout.

    Examples
    --------
    >>> import njschooldata as njsd
    >>> districts = njsd.get_district_directory()
    """
    return call_r_function("get_district_directory")
