"""Pytest configuration: keep every run off the real shared cache."""

import importlib.util
from pathlib import Path
import sys

# Importlib-mode pytest does not add tests/ to sys.path. Register the guard so
# its session hook and its own tests share the same cache snapshot.
spec = importlib.util.spec_from_file_location(
    "_cache_isolation_guard", Path(__file__).with_name("_cache_isolation_guard.py")
)
guard = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = guard
spec.loader.exec_module(guard)

from _cache_isolation_guard import pytest_sessionfinish  # noqa: F401  (cache guard)
