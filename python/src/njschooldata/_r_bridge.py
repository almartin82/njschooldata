"""R bridge module for rpy2 integration with njschooldata R package."""

import functools
import re
from pathlib import Path
from typing import Any, Callable

import pandas as pd

from ._generated_contract import R_PACKAGE_MAX_VERSION, R_PACKAGE_MIN_VERSION

try:
    import rpy2.robjects as ro
    from rpy2.robjects import pandas2ri
    from rpy2.robjects.conversion import localconverter
    from rpy2.robjects.packages import importr
except Exception as e:  # pragma: no cover - exercised only without rpy2/R
    ro = None
    pandas2ri = None
    localconverter = None
    importr = None
    _RPY2_IMPORT_ERROR = e
else:
    _RPY2_IMPORT_ERROR = None

# Lazy initialization of R package
_njschooldata_r = None
_r_fetchers_cache = None
_r_package_version_cache = None

_FETCHER_EXPORT_RE = re.compile(r"^(fetch|get|tidy)_")
_NAMESPACE_EXPORT_RE = re.compile(r"^export\(([^)]+)\)\s*$")


R_INTEGER_NA = -2147483648
"""R's NA sentinel for integer vectors (INT_MIN).

rpy2 materialises ``NA_integer_`` as this raw number inside a NumPy int32
column, so a value that is honestly missing in R arrives in pandas as the
concrete number -2147483648: ``pd.isna()`` reports False, ``bool()`` reports
True, and ``sum()`` silently returns a fabricated total. No NJ DOE source
publishes a real value anywhere near INT_MIN, so the sentinel is unambiguous.
"""

# rpy2 surfaces R's NA for logical and character vectors as singleton sentinel
# OBJECTS inside an object-dtype column, not as pandas missing values. Measured
# on this repo's rpy2 3.6.6 / pandas 2.3.3:
#
#     is_charter=NA -> NALogicalType   pd.isna() -> False   bool() raises
#     name=NA       -> NACharacterType pd.isna() -> False   bool() raises
#     n=NA_integer_ -> -2147483648     pd.isna() -> False   bool() -> True
#     x=NA_real_    -> NaN             pd.isna() -> True    (already correct)
#
# Only the double case survives the boundary honestly. The other three make
# missing data read as present, and is_charter -- now genuinely three-valued on
# the R side -- is exactly such a column: an honest R NA would otherwise reach
# Python as a value that passes ``if row["is_charter"]:``.
#
# The test is on the type NAME, never on ``==``: comparing a logical or integer
# NA singleton against INT_MIN answers True while the character and real ones
# answer False, so an equality-based normaliser repairs some NA rows and passes
# the rest through as real values.
_R_NA_SENTINEL_TYPES = frozenset(
    {"NALogicalType", "NACharacterType", "NAIntegerType", "NARealType"}
)


def _is_r_na_sentinel(value: Any) -> bool:
    """True for any of rpy2's NA singleton objects, identified by type name."""
    value_type = type(value)
    return (
        value_type.__name__ in _R_NA_SENTINEL_TYPES
        and value_type.__module__.startswith("rpy2")
    )


def normalise_r_missingness(frame: Any) -> Any:
    """Convert an R frame's missingness to pandas missingness, in place of none.

    Object columns have their rpy2 NA singletons replaced with ``pd.NA``; a
    column whose remaining values are all booleans is then widened to the
    nullable ``boolean`` dtype, so a three-valued flag such as ``is_charter``
    stays three-valued in Python. Integer columns carrying R's INT_MIN sentinel
    widen to nullable ``Int64`` with those cells set to ``pd.NA``.

    An all-NA object column is left as object/``pd.NA``: with no present value
    to inspect there is no evidence it was logical rather than character, and
    guessing a dtype is not this function's job.

    Non-frame inputs pass through untouched.
    """
    if not isinstance(frame, pd.DataFrame):
        return frame

    object_cols = list(frame.select_dtypes(include=["object", "string"]).columns)
    sentinel_cols = [
        column
        for column in frame.columns
        if pd.api.types.is_integer_dtype(frame[column])
        and bool((frame[column] == R_INTEGER_NA).any())
    ]
    if not object_cols and not sentinel_cols:
        return frame

    frame = frame.copy()
    for column in object_cols:
        cleaned = frame[column].map(
            lambda value: pd.NA if _is_r_na_sentinel(value) else value
        )
        present = cleaned.dropna()
        if len(present) > 0 and all(pd.api.types.is_bool(v) for v in present):
            cleaned = cleaned.astype("boolean")
        frame[column] = cleaned
    for column in sentinel_cols:
        frame[column] = frame[column].astype("Int64").mask(
            frame[column] == R_INTEGER_NA, pd.NA
        )
    return frame


class RPackageCompatibilityError(RuntimeError):
    """Raised when the loaded R package is outside Python's supported range."""


def _version_tuple(version: str) -> tuple[int, ...]:
    """Return a comparable numeric release tuple."""
    match = re.match(r"^(\d+(?:\.\d+)*)", version)
    if not match:
        raise RPackageCompatibilityError(
            f"Could not interpret njschooldata R package version {version!r}."
        )
    return tuple(int(part) for part in match.group(1).split("."))


def _assert_supported_r_version(version: str) -> None:
    """Raise an actionable error for an unsupported R package version."""
    installed = _version_tuple(version)
    minimum = _version_tuple(R_PACKAGE_MIN_VERSION)
    maximum = _version_tuple(R_PACKAGE_MAX_VERSION)
    if installed < minimum or installed >= maximum:
        raise RPackageCompatibilityError(
            "Unsupported njschooldata R package version "
            f"{version}. This Python release supports R package versions "
            f">={R_PACKAGE_MIN_VERSION},<{R_PACKAGE_MAX_VERSION}. Install a "
            "compatible R package or upgrade the Python bindings."
        )


def _require_rpy2() -> None:
    """Raise a clear error if rpy2/R bindings are unavailable."""
    if ro is None or pandas2ri is None or localconverter is None or importr is None:
        raise ImportError(
            "rpy2 is required to call njschooldata R functions. "
            "Install the Python package with its runtime dependencies."
        ) from _RPY2_IMPORT_ERROR


def _get_r_package():
    """Lazily load the njschooldata R package."""
    global _njschooldata_r
    _require_rpy2()
    if _njschooldata_r is None:
        try:
            package = importr("njschooldata")
        except Exception as e:
            raise ImportError(
                "The njschooldata R package must be installed. "
                "Install it with: remotes::install_github('almartin82/njschooldata')"
            ) from e
        get_r_package_version()
        _njschooldata_r = package
    return _njschooldata_r


def get_r_package_version() -> str:
    """Return and validate the installed njschooldata R package version."""
    global _r_package_version_cache
    _require_rpy2()
    if _r_package_version_cache is None:
        try:
            version = str(
                ro.r('as.character(utils::packageVersion("njschooldata"))')[0]
            )
        except Exception as e:
            raise ImportError(
                "The njschooldata R package must be installed before using "
                "the Python bridge."
            ) from e
        _assert_supported_r_version(version)
        _r_package_version_cache = version
    return _r_package_version_cache


def _read_exports_from_r() -> list[str]:
    """Read exported R names from the installed njschooldata namespace."""
    _require_rpy2()
    exports = ro.r('getNamespaceExports("njschooldata")')
    return [str(name) for name in exports]


def _parse_namespace_file(path: Path) -> list[str]:
    """Parse simple export(name) entries from an R NAMESPACE file."""
    if not path.exists():
        return []

    exports = []
    for line in path.read_text(encoding="utf-8").splitlines():
        match = _NAMESPACE_EXPORT_RE.match(line.strip())
        if match:
            exports.append(match.group(1).strip().strip('"').strip("'"))
    return exports


def _read_exports_from_installed_namespace() -> list[str]:
    """Read exports from the installed R package NAMESPACE as a fallback."""
    _require_rpy2()
    namespace_path = str(
        ro.r('system.file("NAMESPACE", package = "njschooldata")')[0]
    )
    if not namespace_path:
        return []
    return _parse_namespace_file(Path(namespace_path))


def _read_exports_from_source_namespace() -> list[str]:
    """Read exports from this repository's source-tree NAMESPACE fallback."""
    return _parse_namespace_file(Path(__file__).resolve().parents[3] / "NAMESPACE")


def list_r_fetchers() -> list[str]:
    """
    Return exported R fetch/get/tidy functions available through passthrough.

    Names are read from the repository NAMESPACE first so a source checkout
    cannot silently discover a stale installed R package. Installed-package
    readers remain fallbacks for wheel installations.
    """
    global _r_fetchers_cache
    if _r_fetchers_cache is None:
        errors = []
        exports = []

        for reader in (
            _read_exports_from_source_namespace,
            _read_exports_from_r,
            _read_exports_from_installed_namespace,
        ):
            try:
                exports = reader()
            except Exception as e:  # pragma: no cover - depends on local R setup
                errors.append(e)
                continue
            if exports:
                break

        if not exports and errors:
            raise ImportError(
                "Could not discover njschooldata R exports. Install the R "
                "package or run from a source checkout with NAMESPACE present."
            ) from errors[0]

        _r_fetchers_cache = sorted(
            name for name in set(exports) if _FETCHER_EXPORT_RE.match(name)
        )

    return list(_r_fetchers_cache)


def r_to_pandas(func: Callable) -> Callable:
    """Convert an R data.frame and retain its source-result contract."""
    @functools.wraps(func)
    def wrapper(*args, **kwargs) -> pd.DataFrame:
        _require_rpy2()
        result = func(*args, **kwargs)
        source_results = None
        if not isinstance(result, pd.DataFrame):
            attributes = {
                str(name) for name in getattr(result, "list_attrs", lambda: [])()
            }
            if "njsd_source_results" in attributes:
                records = ro.r["attr"](result, "njsd_source_results", exact=True)
                with localconverter(ro.default_converter + pandas2ri.converter):
                    source_results = normalise_r_missingness(
                        pandas2ri.rpy2py(records)
                    )

        # Use localconverter context for pandas conversion
        with localconverter(ro.default_converter + pandas2ri.converter):
            if isinstance(result, pd.DataFrame):
                converted = result
            elif hasattr(result, "to_pandas"):
                converted = result.to_pandas()
            else:
                converted = pandas2ri.rpy2py(result)
        # Missing must stay missing across the boundary. Without this an honest
        # R `is_charter = NA` reaches pandas as an NALogicalType that pd.isna()
        # reports as present, and an NA_integer_ as the truthy number INT_MIN.
        converted = normalise_r_missingness(converted)
        if isinstance(converted, pd.DataFrame) and isinstance(source_results, pd.DataFrame):
            converted.attrs["source_results"] = source_results
        return converted
    return wrapper


def _python_to_r(value: Any) -> Any:
    """Convert common Python scalar and homogeneous sequence values to R."""
    if isinstance(value, bool):
        return ro.BoolVector([value])[0]
    if isinstance(value, int):
        return ro.IntVector([value])[0]
    if isinstance(value, float):
        return ro.FloatVector([value])[0]
    if isinstance(value, str):
        return ro.StrVector([value])[0]
    if isinstance(value, (list, tuple)):
        values = list(value)
        if not values:
            return value
        if all(isinstance(item, bool) for item in values):
            return ro.BoolVector(values)
        if all(isinstance(item, int) and not isinstance(item, bool) for item in values):
            return ro.IntVector(values)
        if all(
            isinstance(item, (int, float)) and not isinstance(item, bool)
            for item in values
        ):
            return ro.FloatVector(values)
        if all(isinstance(item, str) for item in values):
            return ro.StrVector(values)
    return value


def call_r_function(func_name: str, *args, **kwargs) -> Any:
    """
    Call an R function from njschooldata package.

    Parameters
    ----------
    func_name : str
        Name of the R function to call.
    *args
        Positional arguments to pass to the R function.
    **kwargs
        Keyword arguments to pass to the R function.

    Returns
    -------
    Any
        Result from the R function (typically an R data.frame).
    """
    pkg = _get_r_package()
    r_func = getattr(pkg, func_name)

    # Convert Python types to R types
    r_args = [_python_to_r(arg) for arg in args]
    r_kwargs = {key: _python_to_r(val) for key, val in kwargs.items()}

    return r_func(*r_args, **r_kwargs)
