"""Guard: the removed Python directory surface stays removed.

`get_school_directory()` and `get_district_directory()` were thin bindings that
called the R functions of the same name through the r_bridge. The R directory
conversion (directory-contract/v1) removed those R functions, so the Python
bindings could only raise at call time. They were removed rather than migrated.

This suite replaces the old one (which asserted the functions worked) with a
guard that they do not come back. If someone re-adds a binding to a removed R
function, these fail loudly rather than shipping code that errors when called.
"""

import importlib

import pytest

import njschooldata


REMOVED = ["get_school_directory", "get_district_directory"]


class TestDirectorySurfaceRemoved:
    @pytest.mark.parametrize("name", REMOVED)
    def test_not_an_attribute(self, name):
        assert not hasattr(njschooldata, name)

    @pytest.mark.parametrize("name", REMOVED)
    def test_not_in_all(self, name):
        assert name not in njschooldata.__all__

    def test_directory_module_gone(self):
        with pytest.raises(ModuleNotFoundError):
            importlib.import_module("njschooldata.directory")
