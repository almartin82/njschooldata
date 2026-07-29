"""pytest configuration and fixtures."""

import os

import pytest

def _r_available():
    """Probe R only when a collected test explicitly requires it."""
    try:
        from rpy2.robjects.packages import importr
        importr("njschooldata")
        return True
    except Exception:
        return False


def pytest_configure(config):
    """Add custom markers."""
    config.addinivalue_line(
        "markers", "network: tests that require network access to NJ DOE"
    )
    config.addinivalue_line(
        "markers", "requires_r: tests that require R and njschooldata package"
    )


def pytest_collection_modifyitems(config, items):
    """Skip tests based on environment."""
    skip_network = pytest.mark.skip(
        reason="Set NJSCHOOLDATA_LIVE_TESTS=true to run NJ DOE live-source tests"
    )
    skip_r = pytest.mark.skip(reason="R or njschooldata not available")

    live_tests = os.environ.get("NJSCHOOLDATA_LIVE_TESTS", "false").lower() == "true"
    needs_r = any("requires_r" in item.keywords for item in items)
    r_available = _r_available() if needs_r else False

    for item in items:
        if "network" in item.keywords and not live_tests:
            item.add_marker(skip_network)
        if "requires_r" in item.keywords and not r_available:
            item.add_marker(skip_r)


@pytest.fixture
def mock_enrollment_df():
    """Fixture providing mock enrollment data for unit tests."""
    import pandas as pd
    return pd.DataFrame({
        "county_id": ["13", "17"],
        "county_name": ["Essex", "Hudson"],
        "district_id": ["3570", "2390"],
        "district_name": ["Newark City", "Jersey City"],
        "school_id": ["999", "999"],
        "school_name": ["District Total", "District Total"],
        "pk": [1000, 800],
        "k": [2500, 2000],
        "gr_01": [2600, 2100],
    })


@pytest.fixture
def mock_assessment_df():
    """Fixture providing mock assessment data for unit tests."""
    import pandas as pd
    return pd.DataFrame({
        "county_id": ["13", "17"],
        "district_id": ["3570", "2390"],
        "school_id": ["999", "999"],
        "grade": [4, 4],
        "subj": ["math", "math"],
        "valid_scores": [5000, 4000],
        "pct_prof": [35.2, 42.1],
    })
