"""
njschooldata - Python bindings for NJ DOE school data.

This package provides Python access to New Jersey Department of Education
school data via rpy2 bindings to the njschooldata R package.

Examples
--------
>>> import njschooldata as njsd
>>> enr = njsd.fetch_enr(2024)
>>> math = njsd.fetch_parcc(2023, 4, 'math')
"""

import functools

from ._r_bridge import call_r_function, list_r_fetchers, r_to_pandas
from .enrollment import fetch_enr
from .assessment import fetch_parcc, fetch_access
from .graduation import fetch_grad_rate
from .facilities import (
    fetch_facilities,
    fetch_facilities_multi,
    fetch_facility_gis,
    get_available_facilities,
)
from .finance import fetch_finance, fetch_finance_multi
from .sped import fetch_sped, fetch_sped_placement, fetch_sped_placement_multi
from .ell import fetch_ell, fetch_ell_multi

__version__ = "0.9.0"

_CURATED_EXPORTS = [
    "fetch_enr",
    "fetch_parcc",
    "fetch_access",
    "fetch_grad_rate",
    "fetch_facilities",
    "fetch_facilities_multi",
    "fetch_facility_gis",
    "get_available_facilities",
    "fetch_finance",
    "fetch_finance_multi",
    "fetch_sped",
    "fetch_sped_placement",
    "fetch_sped_placement_multi",
    "fetch_ell",
    "fetch_ell_multi",
]

__all__ = sorted(set(_CURATED_EXPORTS).union(list_r_fetchers()))


def _build_passthrough(name: str):
    """Create a lazy pandas-converting wrapper for an R package export."""
    wrapper = r_to_pandas(functools.partial(call_r_function, name))
    wrapper.__name__ = name
    wrapper.__qualname__ = name
    wrapper.__module__ = __name__
    wrapper.__doc__ = (
        f"Pass-through wrapper for the R njschooldata::{name} export."
    )
    return wrapper


def __getattr__(name: str):
    """
    Lazily expose exported R fetch/get/tidy functions without hand wrappers.
    """
    if name in globals():
        return globals()[name]
    if name in list_r_fetchers():
        wrapper = _build_passthrough(name)
        globals()[name] = wrapper
        return wrapper
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


def __dir__():
    """Return typed wrappers plus dynamically available R fetchers."""
    return sorted(set(globals()).union(list_r_fetchers()))
