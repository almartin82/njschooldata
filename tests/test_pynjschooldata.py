"""
Tests for pynjschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pynjschooldata
    assert pynjschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pynjschooldata
    assert hasattr(pynjschooldata, 'fetch_enr')
    assert callable(pynjschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pynjschooldata
    assert hasattr(pynjschooldata, 'get_available_years')
    assert callable(pynjschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pynjschooldata
    assert hasattr(pynjschooldata, '__version__')
    assert isinstance(pynjschooldata.__version__, str)
