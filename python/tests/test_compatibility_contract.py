"""Offline R/Python version, bridge, and curated-signature contracts."""

import inspect
import json
import importlib

import pytest

import njschooldata
from njschooldata import _r_bridge
from njschooldata._contract import expected_python_parameters
from njschooldata._generated_contract import (
    PYTHON_PACKAGE_VERSION,
    R_PACKAGE_MAX_VERSION,
    R_PACKAGE_MIN_VERSION,
    R_SIGNATURES,
    SOURCE_COVERAGE,
)


@pytest.mark.parametrize(
    ("module_name", "function_name", "args", "kwargs", "expected"),
    [
        ("enrollment", "fetch_enr", (2025,), {"use_cache": True}, {"use_cache": True}),
        ("ell", "fetch_ell", (2025,), {"with_status": True}, {"with_status": True}),
        (
            "ell",
            "fetch_ell_multi",
            ([2024, 2025],),
            {"with_status": True, "allow_partial": True},
            {"with_status": True, "allow_partial": True},
        ),
        ("sped", "fetch_sped", (2025,), {"with_status": True}, {"with_status": True}),
        (
            "sped",
            "fetch_sped_placement",
            (2025,),
            {"with_status": True},
            {"with_status": True},
        ),
        (
            "sped",
            "fetch_sped_placement_multi",
            ([2024, 2025],),
            {"with_status": True, "allow_partial": True},
            {"with_status": True, "allow_partial": True},
        ),
        (
            "finance",
            "fetch_finance",
            (2025,),
            {"allow_partial": True},
            {"allow_partial": True},
        ),
    ],
)
def test_current_cache_status_and_partial_arguments_reach_r(
    monkeypatch, module_name, function_name, args, kwargs, expected
):
    module = importlib.import_module(f"njschooldata.{module_name}")
    observed = {}

    def fake_call(name, *call_args, **call_kwargs):
        observed.update(call_kwargs)
        return name

    monkeypatch.setattr(module, "call_r_function", fake_call)
    undecorated = inspect.unwrap(getattr(module, function_name))

    assert undecorated(*args, **kwargs) == function_name
    for key, value in expected.items():
        assert observed[key] == value


def test_python_release_matches_generated_r_release():
    assert njschooldata.__version__ == PYTHON_PACKAGE_VERSION == "0.9.26"
    assert njschooldata.SUPPORTED_R_PACKAGE == ">=0.9.26,<0.10.0"


def test_generated_coverage_includes_every_curated_year_bearing_family():
    expected = {
        "enrollment": (1999, 2026),
        "parcc": (2015, 2025),
        "access": (2022, 2025),
        "grate_4yr": (2011, 2025),
        "ell": (2006, 2026),
        "sped": (2015, 2025),
        "sped_placement": (2020, 2025),
        "finance": (2001, 2026),
    }
    for family, (first, last) in expected.items():
        years = SOURCE_COVERAGE[family]["tidy_years"]
        assert (years[0], years[-1]) == (first, last), family

    assert SOURCE_COVERAGE["parcc"]["skipped_years"] == [2020, 2021]


@pytest.mark.parametrize("version", ["0.9.25", "0.10.0", "1.0.0"])
def test_unsupported_r_versions_raise_actionable_error(version):
    with pytest.raises(_r_bridge.RPackageCompatibilityError) as error:
        _r_bridge._assert_supported_r_version(version)

    message = str(error.value)
    assert version in message
    assert R_PACKAGE_MIN_VERSION in message
    assert R_PACKAGE_MAX_VERSION in message
    assert "upgrade" in message.lower() or "install" in message.lower()


def test_curated_python_signatures_match_generated_r_formals():
    for name, contract in R_SIGNATURES.items():
        wrapper = getattr(njschooldata, name)
        python_parameters = list(inspect.signature(wrapper).parameters)
        expected = expected_python_parameters(name, contract["parameters"])
        assert python_parameters == expected, name

        defaults = contract["defaults"] or {}
        for parameter in expected:
            r_default = defaults[parameter]
            python_default = inspect.signature(wrapper).parameters[parameter].default
            if r_default == "<required>":
                assert python_default is inspect.Parameter.empty, (name, parameter)
            elif r_default == "TRUE":
                assert python_default is True, (name, parameter)
            elif r_default == "FALSE":
                assert python_default is False, (name, parameter)
            elif r_default == "NULL":
                assert python_default is None, (name, parameter)
            else:
                assert python_default == json.loads(r_default), (name, parameter)


@pytest.mark.requires_r
def test_generated_signatures_match_loaded_r_package():
    """Catch generated-contract drift against the installed package in CI."""
    get_formals = _r_bridge.ro.r(
        "function(name) { "
        "f <- formals(get(name, envir = asNamespace('njschooldata'))); "
        "list(parameters = if (is.null(names(f))) character() else names(f), "
        "defaults = vapply(f, function(x) { "
        "if (identical(x, quote(expr = ))) '<required>' "
        "else paste(deparse(x, width.cutoff = 500L), collapse = ' ') "
        "}, character(1))) }"
    )

    for name, contract in R_SIGNATURES.items():
        result = get_formals(name)
        assert list(result.rx2("parameters")) == contract["parameters"], name
        parameters = [str(parameter) for parameter in result.rx2("parameters")]
        defaults = {
            parameter: str(value)
            for parameter, value in zip(parameters, result.rx2("defaults"))
        }
        expected_defaults = contract["defaults"] or {}
        assert defaults == expected_defaults, name


@pytest.mark.requires_r
def test_real_bridge_reports_versions_and_reads_registry_without_network():
    versions = njschooldata.version_info()
    assert versions == {
        "python": PYTHON_PACKAGE_VERSION,
        "r": PYTHON_PACKAGE_VERSION,
        "supported_r": f">={R_PACKAGE_MIN_VERSION},<{R_PACKAGE_MAX_VERSION}",
    }

    years = [int(value) for value in _r_bridge.call_r_function(
        "get_valid_years", "enrollment"
    )]
    assert years == SOURCE_COVERAGE["enrollment"]["tidy_years"]
    assert years[0] == 1999
    assert years[-1] == 2026


@pytest.mark.requires_r
def test_real_bridge_preserves_source_results_in_dataframe_attrs():
    make_result = _r_bridge.ro.r(
        "function() { "
        "x <- data.frame(end_year = 2025L, value = 1); "
        "attr(x, 'njsd_source_results') <- data.frame("
        "domain = 'fixture', end_year = 2025L, component = NA_character_, "
        "source_status = 'actual', source_url = 'https://example.test/data.csv', "
        "retrieved_at = NA_character_, digest = 'sha256:fixture', "
        "warning = NA_character_, error = NA_character_); x }"
    )

    converted = _r_bridge.r_to_pandas(make_result)()

    assert converted.iloc[0]["end_year"] == 2025
    source_results = converted.attrs["source_results"]
    assert source_results.iloc[0]["source_status"] == "actual"
    assert source_results.iloc[0]["digest"] == "sha256:fixture"
