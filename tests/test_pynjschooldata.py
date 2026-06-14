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


def test_has_fetch_finance():
    """fetch_finance and friends are available."""
    import pynjschooldata
    for name in ("fetch_finance", "fetch_finance_multi",
                 "get_available_finance_years"):
        assert hasattr(pynjschooldata, name)
        assert callable(getattr(pynjschooldata, name))


def test_fetch_finance_canonical_schema():
    """fetch_finance returns the canonical finance schema through rpy2.

    Network/R test: skipped if the R package or NJ DOE data is unavailable.
    """
    import pynjschooldata
    try:
        df = pynjschooldata.fetch_finance(2024)
    except Exception as exc:  # noqa: BLE001 - any R/network failure -> skip
        pytest.skip(f"R/network unavailable: {exc}")

    expected = {
        "end_year", "state_id", "entity_name", "county", "is_state",
        "is_district", "is_school", "is_charter", "nces_dist", "nces_sch",
        "metric", "value", "is_per_pupil", "enrollment_denominator",
    }
    assert expected.issubset(set(df.columns))
    assert "per_pupil_total" in set(df["metric"].astype(str))
    assert "revenue_state" in set(df["metric"].astype(str))


def test_has_fetch_sped():
    """fetch_sped and fetch_sped_placement are available."""
    import pynjschooldata
    for name in ("fetch_sped", "fetch_sped_placement"):
        assert hasattr(pynjschooldata, name)
        assert callable(getattr(pynjschooldata, name))


def test_fetch_sped_state_by_disability():
    """fetch_sped(level="state") returns child count by disability category.

    Network/R test: skipped if the R package or NJ DOE data is unavailable.
    """
    import pynjschooldata
    try:
        df = pynjschooldata.fetch_sped(2025, level="state")
    except Exception as exc:  # noqa: BLE001 - any R/network failure -> skip
        pytest.skip(f"R/network unavailable: {exc}")

    expected = {
        "end_year", "is_state", "disability_category", "n_students",
        "sped_rate", "suppressed",
    }
    assert expected.issubset(set(df.columns))
    cats = set(df["disability_category"].astype(str))
    assert "autism" in cats
    assert "all_disabilities" in cats


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


def test_has_fetch_ell():
    """fetch_ell, fetch_ell_multi, get_available_ell_years are available."""
    import pynjschooldata
    for name in ("fetch_ell", "fetch_ell_multi", "get_available_ell_years"):
        assert hasattr(pynjschooldata, name)
        assert callable(getattr(pynjschooldata, name))


def test_get_available_ell_years():
    """get_available_ell_years returns the documented integer range."""
    import pynjschooldata
    try:
        yrs = pynjschooldata.get_available_ell_years()
    except Exception as exc:  # noqa: BLE001 - any R/network failure -> skip
        pytest.skip(f"R unavailable: {exc}")
    assert 2006 in yrs
    assert 2025 in yrs
    assert min(yrs) == 2006


def test_fetch_ell_tidy_schema():
    """fetch_ell returns the tidy EL population contract through rpy2.

    Network/R test: skipped if the R package or NJ DOE data is unavailable.
    """
    import pynjschooldata
    try:
        df = pynjschooldata.fetch_ell(2025)
    except Exception as exc:  # noqa: BLE001 - any R/network failure -> skip
        pytest.skip(f"R/network unavailable: {exc}")

    expected = {
        "end_year", "district_id", "district_name", "school_id", "school_name",
        "nces_dist", "nces_sch", "is_state", "is_district", "is_school",
        "is_charter", "grade_level", "el_status", "subgroup", "n_students",
        "pct_of_enrollment", "n_students_lower", "n_students_upper",
    }
    assert expected.issubset(set(df.columns))
    assert set(df["el_status"].astype(str)) == {"current"}
    assert set(df["subgroup"].astype(str)) == {"total"}

    # statewide EL count is real and matches the published 2024-25 file
    state = df[df["is_state"].astype(bool)]
    assert len(state) == 1
    assert abs(float(state["n_students"].iloc[0]) - 155304) < 1
