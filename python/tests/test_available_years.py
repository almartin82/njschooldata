"""Available-years return shapes and selector forwarding across the R bridge."""

import pandas as pd
import pytest


@pytest.mark.parametrize("type", [None, "enrollment"])
def test_available_years_contract(monkeypatch, type):
    from njschooldata import enrollment, get_available_years
    from rpy2 import robjects

    calls = []

    def fake_call(name, **kwargs):
        calls.append((name, kwargs))
        if not kwargs:
            return robjects.DataFrame({
                "type": robjects.StrVector(["enrollment", "enrollment"]),
                "end_year": robjects.IntVector([2020, 2022]),
                "fetcher": robjects.StrVector(["fetch_enr", "fetch_enr"]),
            })
        return robjects.IntVector([2020, 2022])

    monkeypatch.setattr(enrollment, "call_r_function", fake_call)
    result = get_available_years(type)
    assert calls == [("get_available_years", {} if type is None else {"type": type})]
    if type is None:
        assert isinstance(result, pd.DataFrame)
        assert list(result.columns) == ["type", "end_year", "fetcher"]
        assert list(result["end_year"]) == [2020, 2022]
    else:
        assert result == [2020, 2022]
        assert all(isinstance(year, int) for year in result)


@pytest.mark.requires_r
def test_real_available_years_contract():
    from njschooldata import get_available_years

    years = get_available_years("enrollment")
    assert years == list(range(1999, 2027))
    assert all(isinstance(year, int) for year in years)
    coverage = get_available_years()
    assert isinstance(coverage, pd.DataFrame)
    assert list(coverage.columns) == ["type", "end_year", "fetcher"]
    enrollment = coverage.loc[coverage["type"] == "enrollment"]
    assert list(enrollment["end_year"]) == years
    assert set(enrollment["fetcher"]) == {"fetch_enr"}
    finance = coverage.loc[coverage["type"] == "finance"]
    assert list(finance["end_year"]) == get_available_years("finance")
    assert set(finance["fetcher"]) == {"fetch_finance"}
    assert get_available_years("finance") == list(range(2001, 2027))
    for type, message in [("assessment", "coverage not yet declared"),
                          ("unknown", "Declared types:")]:
        with pytest.raises(Exception, match=message):
            get_available_years(type)


@pytest.mark.parametrize(
    ("kwargs", "forwarded"),
    [({}, {}), ({"family": "enrollment"}, {"family": "enrollment"}),
     ({"family": "enrollment", "end_year": 2024},
      {"family": "enrollment", "end_year": 2024})],
)
def test_data_registry_forwards_only_selectors_given(monkeypatch, kwargs, forwarded):
    from njschooldata import enrollment, get_data_registry
    from rpy2 import robjects

    calls = []

    def fake_call(name, **call_kwargs):
        calls.append((name, call_kwargs))
        return robjects.DataFrame({
            "family": robjects.StrVector(["enrollment"]),
            "end_year": robjects.IntVector([2024]),
            "status": robjects.StrVector(["served"]),
        })

    monkeypatch.setattr(enrollment, "call_r_function", fake_call)
    result = get_data_registry(**kwargs)
    assert calls == [("get_data_registry", forwarded)]
    assert isinstance(result, pd.DataFrame)
    assert list(result["status"]) == ["served"]


@pytest.mark.requires_r
def test_real_data_registry_contract():
    from njschooldata import get_data_registry

    registry = get_data_registry(family="enrollment", end_year=2024)
    assert isinstance(registry, pd.DataFrame)
    assert list(registry["status"]) == ["served"]
    assert list(registry["source_id"]) == ["fall_enrollment_reports"]
