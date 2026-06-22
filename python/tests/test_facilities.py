"""Tests for facilities functions."""

import pytest


def test_facilities_exports():
    """Facilities functions are exported."""
    import njschooldata

    for name in (
        "fetch_facilities",
        "fetch_facilities_multi",
        "fetch_facility_gis",
        "get_available_facilities",
    ):
        assert hasattr(njschooldata, name)
        assert callable(getattr(njschooldata, name))
        assert name in njschooldata.__all__


@pytest.mark.requires_r
@pytest.mark.network
def test_fetch_facilities_live_schema():
    """Live facilities wrapper returns the canonical schema."""
    import njschooldata

    df = njschooldata.fetch_facilities("finance")
    expected = [
        "category",
        "entity_level",
        "entity_id",
        "entity_name",
        "metric",
        "value",
        "unit",
        "source_agency",
        "source_type",
        "source_url",
        "vintage",
        "nces_dist",
        "nces_sch",
    ]
    assert list(df.columns) == expected
    assert len(df) > 0
    assert set(df["category"].astype(str)) == {"finance"}
