"""Tests for assessment functions."""

import pytest
import pandas as pd


class TestFetchParccSignature:
    """Unit tests for fetch_parcc function signature."""

    def test_import(self):
        """Test that fetch_parcc can be imported."""
        from njschooldata import fetch_parcc
        assert callable(fetch_parcc)

    def test_function_has_docstring(self):
        """Test that fetch_parcc has documentation."""
        from njschooldata import fetch_parcc
        assert fetch_parcc.__doc__ is not None
        assert "end_year" in fetch_parcc.__doc__
        assert "grade_or_subj" in fetch_parcc.__doc__

    def test_module_exports(self):
        """Test that fetch_parcc is in module __all__."""
        import njschooldata
        assert "fetch_parcc" in njschooldata.__all__


class TestFetchAccessSignature:
    """Unit tests for fetch_access function signature."""

    def test_import(self):
        """Test that fetch_access can be imported."""
        from njschooldata import fetch_access
        assert callable(fetch_access)

    def test_function_has_docstring(self):
        """Test that fetch_access has documentation."""
        from njschooldata import fetch_access
        assert fetch_access.__doc__ is not None
        assert "end_year" in fetch_access.__doc__

    def test_module_exports(self):
        """Test that fetch_access is in module __all__."""
        import njschooldata
        assert "fetch_access" in njschooldata.__all__


@pytest.mark.requires_r
@pytest.mark.network
class TestFetchParccIntegration:
    """Integration tests for PARCC/NJSLA data."""

    def test_fetch_parcc_returns_dataframe(self):
        """Test that fetch_parcc returns a pandas DataFrame."""
        import pandas as pd
        from njschooldata import fetch_parcc
        result = fetch_parcc(2019, 4, "math")
        assert isinstance(result, pd.DataFrame)
        assert len(result) > 0

    def test_fetch_parcc_grade_level(self):
        """Test fetching specific grade level."""
        from njschooldata import fetch_parcc
        result = fetch_parcc(2019, 8, "ela")
        assert isinstance(result, pd.DataFrame)

    def test_fetch_parcc_algebra(self):
        """Test fetching algebra subject."""
        from njschooldata import fetch_parcc
        result = fetch_parcc(2019, "ALG1", "math")
        assert isinstance(result, pd.DataFrame)


@pytest.mark.requires_r
@pytest.mark.network
class TestFetchAccessIntegration:
    """Integration tests for ACCESS data."""

    def test_fetch_access_returns_dataframe(self):
        """Test that fetch_access returns a pandas DataFrame."""
        import pandas as pd
        from njschooldata import fetch_access
        result = fetch_access(2024)
        assert isinstance(result, pd.DataFrame)
        assert len(result) > 0

    def test_fetch_access_specific_grade(self):
        """Test fetching specific grade."""
        from njschooldata import fetch_access
        result = fetch_access(2024, grade="3")
        assert isinstance(result, pd.DataFrame)

    def test_fetch_parcc_invalid_year(self):
        """Test that invalid year raises appropriate error."""
        from njschooldata import fetch_parcc
        # Test with year too old
        with pytest.raises(Exception):
            fetch_parcc(1990, 4, "math")

    def test_fetch_parcc_invalid_grade(self):
        """Test that invalid grade raises appropriate error."""
        from njschooldata import fetch_parcc
        # Test with invalid grade
        with pytest.raises(Exception):
            fetch_parcc(2019, 15, "math")

    def test_fetch_parcc_invalid_subject(self):
        """Test that invalid subject raises appropriate error."""
        from njschooldata import fetch_parcc
        # Test with invalid subject
        with pytest.raises(Exception):
            fetch_parcc(2019, 4, "invalid_subject")

    def test_fetch_parcc_data_types(self):
        """Test that PARCC data has expected types."""
        from njschooldata import fetch_parcc
        result = fetch_parcc(2019, 4, "math")
        # Check ID columns are strings
        assert result["district_id"].dtype == "object"
        # Check numeric columns
        assert pd.api.types.is_numeric_dtype(result["number_of_valid_scale_scores"])

    def test_fetch_access_data_types(self):
        """Test that ACCESS data has expected types."""
        from njschooldata import fetch_access
        result = fetch_access(2024)
        # Check ID columns are strings
        assert result["district_id"].dtype == "object"

    def test_fetch_parcc_multiple_years(self):
        """Test fetching multiple years of data."""
        from njschooldata import fetch_parcc
        result_2018 = fetch_parcc(2018, 4, "ela")
        result_2019 = fetch_parcc(2019, 4, "ela")
        assert isinstance(result_2018, pd.DataFrame)
        assert isinstance(result_2019, pd.DataFrame)
        assert len(result_2018) > 0
        assert len(result_2019) > 0
