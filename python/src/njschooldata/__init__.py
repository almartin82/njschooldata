"""
njschooldata - Python bindings for NJ DOE school data.

This package provides Python access to New Jersey Department of Education
school data via rpy2 bindings to the njschooldata R package.

Examples
--------
>>> import njschooldata as njsd
>>> enr = njsd.fetch_enr(2024)
>>> math = njsd.fetch_parcc(2023, 4, 'math')
>>> schools = njsd.get_school_directory()
"""

from .enrollment import fetch_enr
from .assessment import fetch_parcc, fetch_access
from .graduation import fetch_grad_rate
from .directory import get_school_directory, get_district_directory

__version__ = "0.9.0"

__all__ = [
    "fetch_enr",
    "fetch_parcc",
    "fetch_access",
    "fetch_grad_rate",
    "get_school_directory",
    "get_district_directory",
]
