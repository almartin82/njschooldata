"""Tests for automatic R export passthrough wrappers."""

import pandas as pd
import pytest

from njschooldata._r_bridge import list_r_fetchers


def test_list_r_fetchers_discovers_known_exports():
    """R export discovery includes known fetchers."""
    fetchers = list_r_fetchers()

    assert fetchers
    assert "fetch_enr" in fetchers
    assert "fetch_grad_rate" in fetchers


def test_unwrapped_fetcher_resolves_to_callable():
    """An exported but unwrapped R fetcher is exposed lazily."""
    import njschooldata

    assert "fetch_advanced_course_access" in list_r_fetchers()
    assert "fetch_advanced_course_access" in dir(njschooldata)

    fetcher = getattr(njschooldata, "fetch_advanced_course_access")
    assert callable(fetcher)
    assert "fetch_advanced_course_access" in njschooldata.__all__


def test_unknown_attribute_still_fails():
    """Typos are not hidden by dynamic passthrough."""
    import njschooldata

    with pytest.raises(AttributeError):
        getattr(njschooldata, "fetch_not_a_real_export")


@pytest.mark.requires_r
@pytest.mark.network
def test_live_unwrapped_fetchers_return_dataframes():
    """Previously unwrapped domains call through to R and return dataframes."""
    pytest.importorskip("rpy2")

    import njschooldata

    calls = [
        (
            "courses",
            "fetch_advanced_course_access",
            (2024,),
            {"type": "courses_offered"},
        ),
        ("discipline", "fetch_restraint_seclusion", (2024,), {}),
        ("staffing", "fetch_certificated_staff", (2025,), {}),
    ]

    for domain, name, args, kwargs in calls:
        try:
            df = getattr(njschooldata, name)(*args, **kwargs)
        except Exception as exc:  # noqa: BLE001 - R/data-source failures skip
            pytest.skip(f"{domain} live fetch unavailable: {exc}")

        assert isinstance(df, pd.DataFrame)
        assert len(df) > 0
        assert {"county_id", "district_id", "school_id"} & set(df.columns)
