"""pytest configuration and fixtures."""

import os

import pytest

# Check if R and njschooldata are available
R_AVAILABLE = False
try:
    import rpy2.robjects as ro
    from rpy2.robjects.packages import importr
    importr("njschooldata")
    R_AVAILABLE = True
except Exception:
    pass


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
    skip_network = pytest.mark.skip(reason="Network tests disabled in CI")
    skip_r = pytest.mark.skip(reason="R or njschooldata not available")

    in_ci = os.environ.get("CI", "false").lower() == "true"

    for item in items:
        if "network" in item.keywords and in_ci:
            item.add_marker(skip_network)
        if "requires_r" in item.keywords and not R_AVAILABLE:
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
