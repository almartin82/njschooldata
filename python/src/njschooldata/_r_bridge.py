"""R bridge module for rpy2 integration with njschooldata R package."""

import functools
from typing import Any, Callable

import pandas as pd
import rpy2.robjects as ro
from rpy2.robjects import pandas2ri
from rpy2.robjects.packages import importr

# Enable automatic pandas conversion
pandas2ri.activate()

# Lazy initialization of R package
_njschooldata_r = None


def _get_r_package():
    """Lazily load the njschooldata R package."""
    global _njschooldata_r
    if _njschooldata_r is None:
        try:
            _njschooldata_r = importr("njschooldata")
        except Exception as e:
            raise ImportError(
                "The njschooldata R package must be installed. "
                "Install it with: remotes::install_github('almartin82/njschooldata')"
            ) from e
    return _njschooldata_r


def r_to_pandas(func: Callable) -> Callable:
    """Decorator to convert R data.frame results to pandas DataFrame."""
    @functools.wraps(func)
    def wrapper(*args, **kwargs) -> pd.DataFrame:
        result = func(*args, **kwargs)
        if hasattr(result, "to_pandas"):
            return result.to_pandas()
        return pandas2ri.rpy2py(result)
    return wrapper


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
    r_args = []
    for arg in args:
        if isinstance(arg, bool):
            r_args.append(ro.BoolVector([arg])[0])
        elif isinstance(arg, int):
            r_args.append(ro.IntVector([arg])[0])
        elif isinstance(arg, float):
            r_args.append(ro.FloatVector([arg])[0])
        elif isinstance(arg, str):
            r_args.append(ro.StrVector([arg])[0])
        else:
            r_args.append(arg)

    r_kwargs = {}
    for key, val in kwargs.items():
        if isinstance(val, bool):
            r_kwargs[key] = ro.BoolVector([val])[0]
        elif isinstance(val, int):
            r_kwargs[key] = ro.IntVector([val])[0]
        elif isinstance(val, float):
            r_kwargs[key] = ro.FloatVector([val])[0]
        elif isinstance(val, str):
            r_kwargs[key] = ro.StrVector([val])[0]
        else:
            r_kwargs[key] = val

    return r_func(*r_args, **r_kwargs)
