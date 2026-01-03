"""
Tests for pynjschooldata Python wrapper.

Simple tests that mirror the R testthat tests - just verify the Python
wrapper can call R functions and return DataFrames.
"""

import pytest
import pandas as pd


class TestImport:
    """Test that the package can be imported."""

    def test_import_package(self):
        """Package imports successfully."""
        import pynjschooldata as pkg
        assert pkg is not None

    def test_import_functions(self):
        """Expected functions are available."""
        import pynjschooldata as pkg
        assert hasattr(pkg, 'fetch_enr')
        assert hasattr(pkg, 'get_available_years')

    def test_version_exists(self):
        """Package has a version string."""
        import pynjschooldata as pkg
        assert hasattr(pkg, '__version__')
        assert isinstance(pkg.__version__, str)


class TestGetAvailableYears:
    """Test get_available_years function."""

    def test_returns_dict(self):
        """Returns a dictionary with year info."""
        import pynjschooldata as pkg
        years = pkg.get_available_years()
        assert isinstance(years, dict)
        assert 'min_year' in years
        assert 'max_year' in years

    def test_years_are_reasonable(self):
        """Year values are reasonable."""
        import pynjschooldata as pkg
        years = pkg.get_available_years()
        assert years['min_year'] < years['max_year']
        assert years['max_year'] >= 2020
        assert years['max_year'] <= 2030


class TestFetchEnr:
    """Test fetch_enr function."""

    def test_returns_dataframe(self):
        """Returns a pandas DataFrame."""
        import pynjschooldata as pkg
        years = pkg.get_available_years()
        df = pkg.fetch_enr(years['max_year'])
        assert isinstance(df, pd.DataFrame)
        assert len(df) > 0

    def test_has_end_year_column(self):
        """DataFrame has end_year column."""
        import pynjschooldata as pkg
        years = pkg.get_available_years()
        df = pkg.fetch_enr(years['max_year'])
        assert 'end_year' in df.columns

    def test_validates_year_range(self):
        """Invalid years raise errors."""
        import pynjschooldata as pkg
        with pytest.raises(Exception):
            pkg.fetch_enr(1800)
        with pytest.raises(Exception):
            pkg.fetch_enr(2099)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
