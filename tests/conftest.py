"""Pytest configuration: keep every run off the real shared cache."""

from _cache_isolation_guard import pytest_sessionfinish  # noqa: F401  (cache guard)
