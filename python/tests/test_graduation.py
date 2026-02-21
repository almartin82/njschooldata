"""Tests for graduation functions."""

import pytest
import pandas as pd


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

    def test_fetch_grad_rate_4year(self):
        """Test 4-year methodology."""
        from njschooldata import fetch_grad_rate
        result = fetch_grad_rate(2019, methodology="4 year")
        assert isinstance(result, pd.DataFrame)
        assert len(result) > 0

    def test_fetch_grad_rate_invalid_year(self):
        """Test that invalid year raises appropriate error."""
        from njschooldata import fetch_grad_rate
        # Test with year too old
        with pytest.raises(Exception):
            fetch_grad_rate(1990)

    def test_fetch_grad_rate_invalid_methodology(self):
        """Test that invalid methodology raises appropriate error."""
        from njschooldata import fetch_grad_rate
        # Test with invalid methodology
        with pytest.raises(Exception):
            fetch_grad_rate(2019, methodology="invalid")

    def test_fetch_grad_rate_data_types(self):
        """Test that graduation rate data has expected types."""
        from njschooldata import fetch_grad_rate
        result = fetch_grad_rate(2019)
        # Check ID columns are strings
        assert result["district_id"].dtype == "object"
        # Check numeric columns
        assert pd.api.types.is_numeric_dtype(result["grad_rate"])

    def test_fetch_grad_rate_range_validation(self):
        """Test that graduation rates are in valid range."""
        from njschooldata import fetch_grad_rate
        result = fetch_grad_rate(2019)
        # Graduation rates should be between 0 and 100
        grad_rates = result["grad_rate"].dropna()
        assert grad_rates.min() >= 0
        assert grad_rates.max() <= 100
