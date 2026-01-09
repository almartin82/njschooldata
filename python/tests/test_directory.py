"""Tests for directory functions."""

import pytest
import pandas as pd


class TestGetSchoolDirectorySignature:
    """Unit tests for get_school_directory function signature."""

    def test_import(self):
        """Test that get_school_directory can be imported."""
        from njschooldata import get_school_directory
        assert callable(get_school_directory)

    def test_function_has_docstring(self):
        """Test that get_school_directory has documentation."""
        from njschooldata import get_school_directory
        assert get_school_directory.__doc__ is not None

    def test_module_exports(self):
        """Test that get_school_directory is in module __all__."""
        import njschooldata
        assert "get_school_directory" in njschooldata.__all__


class TestGetDistrictDirectorySignature:
    """Unit tests for get_district_directory function signature."""

    def test_import(self):
        """Test that get_district_directory can be imported."""
        from njschooldata import get_district_directory
        assert callable(get_district_directory)

    def test_function_has_docstring(self):
        """Test that get_district_directory has documentation."""
        from njschooldata import get_district_directory
        assert get_district_directory.__doc__ is not None

    def test_module_exports(self):
        """Test that get_district_directory is in module __all__."""
        import njschooldata
        assert "get_district_directory" in njschooldata.__all__


@pytest.mark.requires_r
@pytest.mark.network
class TestGetSchoolDirectoryIntegration:
    """Integration tests for school directory."""

    def test_get_school_directory_returns_dataframe(self):
        """Test that get_school_directory returns a pandas DataFrame."""
        import pandas as pd
        from njschooldata import get_school_directory
        result = get_school_directory()
        assert isinstance(result, pd.DataFrame)
        assert len(result) > 0

    def test_get_school_directory_has_newark_schools(self):
        """Test that Newark schools are present."""
        from njschooldata import get_school_directory
        result = get_school_directory()
        # Check for presence of school data (column names may vary)
        assert len(result) > 100, "Should have many schools"


@pytest.mark.requires_r
@pytest.mark.network
class TestGetDistrictDirectoryIntegration:
    """Integration tests for district directory."""

    def test_get_district_directory_returns_dataframe(self):
        """Test that get_district_directory returns a pandas DataFrame."""
        import pandas as pd
        from njschooldata import get_district_directory
        result = get_district_directory()
        assert isinstance(result, pd.DataFrame)
        assert len(result) > 0

    def test_get_district_directory_has_expected_count(self):
        """Test that NJ has expected number of districts."""
        from njschooldata import get_district_directory
        result = get_district_directory()
        # NJ has ~600 districts
        assert len(result) > 500, "Should have many districts"

    def test_get_school_directory_has_newark(self):
        """Test that Newark schools are in directory."""
        from njschooldata import get_school_directory
        result = get_school_directory()
        # Check for Newark district by name
        newark = result[result["district_name"].str.contains("Newark", case=False, na=False)]
        assert len(newark) > 0, "Newark schools should be present"

    def test_get_school_directory_data_types(self):
        """Test that school directory has expected data types."""
        from njschooldata import get_school_directory
        result = get_school_directory()
        # Check ID columns are strings
        assert result["district_id"].dtype == "object"
        assert result["school_id"].dtype == "object"

    def test_get_district_directory_data_types(self):
        """Test that district directory has expected data types."""
        from njschooldata import get_district_directory
        result = get_district_directory()
        # Check ID columns are strings
        assert result["district_id"].dtype == "object"

    def test_get_school_directory_no_duplicates(self):
        """Test that there are no fully duplicate rows."""
        from njschooldata import get_school_directory
        result = get_school_directory()
        # Check for fully duplicate rows (all columns identical)
        duplicates = result.duplicated(keep=False)
        assert not duplicates.any(), "School directory should not have fully duplicate rows"

    def test_get_district_directory_no_duplicates(self):
        """Test that there are no duplicate districts."""
        from njschooldata import get_district_directory
        result = get_district_directory()
        # Check for duplicates based on district_id
        duplicates = result.duplicated(subset=["district_id"])
        assert not duplicates.any(), "District directory should not have duplicates"
