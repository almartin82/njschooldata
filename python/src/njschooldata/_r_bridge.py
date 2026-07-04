"""R bridge module for rpy2 integration with njschooldata R package."""

import functools
import re
from pathlib import Path
from typing import Any, Callable

import pandas as pd

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

_FETCHER_EXPORT_RE = re.compile(r"^(fetch|get|tidy)_")
_NAMESPACE_EXPORT_RE = re.compile(r"^export\(([^)]+)\)\s*$")


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
            _njschooldata_r = importr("njschooldata")
        except Exception as e:
            raise ImportError(
                "The njschooldata R package must be installed. "
                "Install it with: remotes::install_github('almartin82/njschooldata')"
            ) from e
    return _njschooldata_r


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

    Names are read from the installed R namespace when available and cached for
    the process. In source checkouts without R available, the repository
    NAMESPACE file is used as a discovery fallback.
    """
    global _r_fetchers_cache
    if _r_fetchers_cache is None:
        errors = []
        exports = []

        for reader in (
            _read_exports_from_r,
            _read_exports_from_installed_namespace,
            _read_exports_from_source_namespace,
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
    """Decorator to convert R data.frame results to pandas DataFrame."""
    @functools.wraps(func)
    def wrapper(*args, **kwargs) -> pd.DataFrame:
        _require_rpy2()
        result = func(*args, **kwargs)
        # Use localconverter context for pandas conversion
        with localconverter(ro.default_converter + pandas2ri.converter):
            if isinstance(result, pd.DataFrame):
                return result
            if hasattr(result, "to_pandas"):
                return result.to_pandas()
            return pandas2ri.rpy2py(result)
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
