"""Tests for enrollment functions."""

import pytest


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
