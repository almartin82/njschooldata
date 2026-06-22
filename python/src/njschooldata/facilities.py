"""School facilities data functions."""

import pandas as pd
import rpy2.robjects as ro
from rpy2.robjects import pandas2ri
from rpy2.robjects.conversion import localconverter

from ._r_bridge import _get_r_package, call_r_function, r_to_pandas


@r_to_pandas
def fetch_facilities(
    category: str,
    year: int | None = None,
    tidy: bool = True,
    use_cache: bool = True,
) -> pd.DataFrame:
    """
    Fetch New Jersey school facilities data by category.

    Parameters
    ----------
    category : str
        Facilities category, such as ``"inventory"``, ``"finance"``, or
        ``"environmental"``.
    year : int or None, default None
        Optional source-vintage filter.
    tidy : bool, default True
        Kept for fleet API parity; facilities returns the canonical long schema.
    use_cache : bool, default True
        Whether to use the R package source cache.

    Returns
    -------
    pd.DataFrame
        Canonical facilities long schema.
    """
    kwargs = {"tidy": tidy, "use_cache": use_cache}
    if year is not None:
        kwargs["year"] = year
    return call_r_function("fetch_facilities", category, **kwargs)


def fetch_facilities_multi(
    category: str,
    years: list[int],
    tidy: bool = True,
    use_cache: bool = True,
) -> pd.DataFrame:
    """
    Fetch New Jersey facilities data for multiple source years.

    Returns a pandas DataFrame in the canonical facilities long schema.
    """
    pkg = _get_r_package()
    with localconverter(ro.default_converter + pandas2ri.converter):
        r_years = ro.IntVector(years)
        r_df = pkg.fetch_facilities_multi(
            category,
            r_years,
            tidy=tidy,
            use_cache=use_cache,
        )
        if isinstance(r_df, pd.DataFrame):
            return r_df
        return pandas2ri.rpy2py(r_df)


def fetch_facility_gis(layer: str = "school_points", use_cache: bool = True):
    """
    Fetch New Jersey facilities GIS data.

    Returns a GeoDataFrame when ``geopandas`` and ``shapely`` are installed;
    otherwise returns a pandas DataFrame with ``latitude``, ``longitude``, and
    ``wkt`` columns.
    """
    pkg = _get_r_package()
    with localconverter(ro.default_converter + pandas2ri.converter):
        r_df = pkg.fetch_facility_gis(layer, sf=False, use_cache=use_cache)
        df = r_df if isinstance(r_df, pd.DataFrame) else pandas2ri.rpy2py(r_df)

    try:
        import geopandas as gpd
        from shapely import wkt as shapely_wkt

        mask = df["wkt"].notna()
        geom = df.loc[mask, "wkt"].apply(shapely_wkt.loads)
        return gpd.GeoDataFrame(df.loc[mask], geometry=geom, crs="EPSG:4326")
    except Exception:
        return df


@r_to_pandas
def get_available_facilities() -> pd.DataFrame:
    """
    Return New Jersey facilities categories with source metadata.
    """
    return call_r_function("get_available_facilities")
