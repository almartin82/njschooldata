"""
Tests for pynjschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pynjschooldata
    assert pynjschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pynjschooldata
    assert hasattr(pynjschooldata, 'fetch_enr')
    assert callable(pynjschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pynjschooldata
    assert hasattr(pynjschooldata, 'get_available_years')
    assert callable(pynjschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pynjschooldata
    assert hasattr(pynjschooldata, '__version__')
    assert isinstance(pynjschooldata.__version__, str)


def test_fetch_enr_carries_nces_ids():
    """fetch_enr output carries the federal NCES id columns through rpy2.

    Network/R test: skipped if the R package or NJ DOE data is unavailable.
    """
    import pynjschooldata
    try:
        df = pynjschooldata.fetch_enr(2024)
    except Exception as exc:  # noqa: BLE001 - any R/network failure -> skip
        pytest.skip(f"R/network unavailable: {exc}")

    assert "nces_dist" in df.columns
    assert "nces_sch" in df.columns

    # rpy2 may surface R NA_character_ as a literal "NA"/"NA_character_" string.
    def real(series):
        s = series.dropna().astype(str)
        return s[~s.isin(["NA", "NA_character_", ""])]

    nd = real(df["nces_dist"])
    ns = real(df["nces_sch"])
    assert len(nd) > 0
    assert (nd.str.len() == 7).all()
    assert (ns.str.len() == 12).all()
