"""Tests for enrollment functions."""

import pytest
import pandas as pd


class TestFetchEnrSignature:
    """Unit tests for fetch_enr function signature and error handling."""

    def test_import(self):
        """Test that fetch_enr can be imported."""
        from njschooldata import fetch_enr
        assert callable(fetch_enr)

    def test_function_has_docstring(self):
        """Test that fetch_enr has documentation."""
        from njschooldata import fetch_enr
        assert fetch_enr.__doc__ is not None
        assert "end_year" in fetch_enr.__doc__

    def test_module_exports(self):
        """Test that fetch_enr is in module __all__."""
        import njschooldata
        assert "fetch_enr" in njschooldata.__all__


@pytest.mark.requires_r
@pytest.mark.network
class TestFetchEnrIntegration:
    """Integration tests that fetch real data."""

    def test_fetch_enr_returns_dataframe(self):
        """Test that fetch_enr returns a pandas DataFrame."""
        import pandas as pd
        from njschooldata import fetch_enr
        result = fetch_enr(2020)
        assert isinstance(result, pd.DataFrame)
        assert len(result) > 0

    def test_fetch_enr_has_expected_columns(self):
        """Test that result has key identifier columns."""
        from njschooldata import fetch_enr
        result = fetch_enr(2020)
        expected_cols = ["county_id", "district_id", "school_id"]
        for col in expected_cols:
            assert col in result.columns, f"Missing column: {col}"

    def test_fetch_enr_tidy_format(self):
        """Test tidy parameter returns long format."""
        from njschooldata import fetch_enr
        result = fetch_enr(2020, tidy=True)
        assert "subgroup" in result.columns or "grade_level" in result.columns

    def test_fetch_enr_newark_data(self):
        """Verify Newark district data is present."""
        from njschooldata import fetch_enr
        result = fetch_enr(2020)
        # Newark district ID is 3570
        newark = result[result["district_id"] == "3570"]
        assert len(newark) > 0, "Newark data should be present"

    def test_fetch_enr_data_types(self):
        """Test that columns have expected data types."""
        from njschooldata import fetch_enr
        result = fetch_enr(2020)
        # Check that ID columns are strings or objects
        assert result["county_id"].dtype == "object"
        assert result["district_id"].dtype == "object"
        # Check that enrollment columns are numeric
        assert pd.api.types.is_numeric_dtype(result["male"])

    def test_fetch_enr_no_duplicates(self):
        """Test that there are no duplicate rows."""
        from njschooldata import fetch_enr
        result = fetch_enr(2020)
        # Check for duplicates based on key columns
        # Note: duplicates may exist for different program_codes/grade_levels, which is expected
        # So we check for fully identical rows
        duplicates = result.duplicated()
        assert not duplicates.any(), "Data should not have fully duplicate rows"

    def test_fetch_enr_level_district(self):
        """Test filtering for district-level data."""
        from njschooldata import fetch_enr
        result = fetch_enr(2020)
        # Filter for district-level data (school_id == 999)
        district_data = result[result["school_id"] == "999"]
        assert isinstance(district_data, pd.DataFrame)
        assert len(district_data) > 0, "Should have district-level data"

    def test_fetch_enr_level_state(self):
        """Test filtering for state-level data."""
        from njschooldata import fetch_enr
        result = fetch_enr(2020)
        # Filter for state-level data (district_id == 999 and school_id == 999)
        state_data = result[(result["district_id"] == "999") & (result["school_id"] == "999")]
        assert isinstance(state_data, pd.DataFrame)
        # State level should have relatively few rows
        assert len(state_data) < 1000, f"State data should be limited, got {len(state_data)} rows"
