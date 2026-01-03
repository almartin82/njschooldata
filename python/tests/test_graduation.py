"""Tests for graduation functions."""

import pytest


class TestFetchGradRateSignature:
    """Unit tests for fetch_grad_rate function signature."""

    def test_import(self):
        """Test that fetch_grad_rate can be imported."""
        from njschooldata import fetch_grad_rate
        assert callable(fetch_grad_rate)

    def test_function_has_docstring(self):
        """Test that fetch_grad_rate has documentation."""
        from njschooldata import fetch_grad_rate
        assert fetch_grad_rate.__doc__ is not None
        assert "end_year" in fetch_grad_rate.__doc__
        assert "methodology" in fetch_grad_rate.__doc__

    def test_module_exports(self):
        """Test that fetch_grad_rate is in module __all__."""
        import njschooldata
        assert "fetch_grad_rate" in njschooldata.__all__


@pytest.mark.requires_r
@pytest.mark.network
class TestFetchGradRateIntegration:
    """Integration tests for graduation rate data."""

    def test_fetch_grad_rate_returns_dataframe(self):
        """Test that fetch_grad_rate returns a pandas DataFrame."""
        import pandas as pd
        from njschooldata import fetch_grad_rate
        result = fetch_grad_rate(2019)
        assert isinstance(result, pd.DataFrame)
        assert len(result) > 0

    def test_fetch_grad_rate_has_expected_columns(self):
        """Test that result has key columns."""
        from njschooldata import fetch_grad_rate
        result = fetch_grad_rate(2019)
        expected_cols = ["district_id"]
        for col in expected_cols:
            assert col in result.columns, f"Missing column: {col}"

    def test_fetch_grad_rate_5year(self):
        """Test 5-year methodology."""
        from njschooldata import fetch_grad_rate
        result = fetch_grad_rate(2019, methodology="5 year")
        assert isinstance(result, pd.DataFrame)
        assert len(result) > 0
