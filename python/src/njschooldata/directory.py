"""School and district directory functions."""

import pandas as pd

from ._r_bridge import call_r_function, r_to_pandas


@r_to_pandas
def get_school_directory() -> pd.DataFrame:
    """
    Get current NJ school directory with metadata.

    Returns
    -------
    pd.DataFrame
        School directory with columns including school_id, school_name,
        address, grades served, and contact information.

    Examples
    --------
    >>> import njschooldata as njsd
    >>> schools = njsd.get_school_directory()
    """
    return call_r_function("get_school_directory")


@r_to_pandas
def get_district_directory() -> pd.DataFrame:
    """
    Get current NJ district directory with metadata.

    Returns
    -------
    pd.DataFrame
        District directory with columns including district_id, district_name,
        address, and contact information.

    Examples
    --------
    >>> import njschooldata as njsd
    >>> districts = njsd.get_district_directory()
    """
    return call_r_function("get_district_directory")
