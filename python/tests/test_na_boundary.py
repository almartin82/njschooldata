"""R missingness must survive the rpy2 -> pandas boundary.

`is_charter` is three-valued in R: TRUE (NJDOE county 80), FALSE (some other
published county code), NA (the source published no county code at all -- the
"STATE SUM" row of the certificated-staff files, and the statewide SPED
by-disability rollup).

rpy2 does not carry that third value across honestly. Measured on this repo's
rpy2 3.6.6 / pandas 2.3.3:

    R logical NA   -> NALogicalType singleton, pd.isna() -> False
    R character NA -> NACharacterType singleton, pd.isna() -> False
    R integer NA   -> the raw number -2147483648, pd.isna() -> False, bool() True
    R double NA    -> NaN (the only one that already works)

So without normalisation an honest R `is_charter = NA` reaches pandas as a value
that passes ``if row["is_charter"]:``, and an honest NA count sums as roughly
minus two billion. These tests pin the repair.

The core tests need no R: `normalise_r_missingness` operates on a DataFrame, and
the sentinel objects are recognised by TYPE NAME and module, which a stand-in
class can reproduce exactly. They therefore always run.
"""

import pandas as pd
import pytest

from njschooldata._r_bridge import (
    R_INTEGER_NA,
    _is_r_na_sentinel,
    normalise_r_missingness,
)


def _na_singleton(type_name):
    """A stand-in for one of rpy2's NA singleton objects.

    Reproduces the two properties the detector keys on -- the type NAME and the
    rpy2 module -- and the two properties that make the real thing dangerous:
    pd.isna() does not see it, and bool() raises rather than answering.
    """

    class _NASingleton:
        def __bool__(self):
            raise ValueError("R NA is not interpretable as a bool")

    _NASingleton.__name__ = type_name
    _NASingleton.__qualname__ = type_name
    _NASingleton.__module__ = "rpy2.rinterface_lib.sexp"
    return _NASingleton()


class TestSentinelDetection:
    def test_detects_every_na_singleton_by_type_name(self):
        for name in (
            "NALogicalType",
            "NACharacterType",
            "NAIntegerType",
            "NARealType",
        ):
            assert _is_r_na_sentinel(_na_singleton(name))

    def test_does_not_claim_ordinary_values(self):
        for value in (True, False, 0, 1, -1, "NA", "", None, 1.5, float("nan")):
            assert not _is_r_na_sentinel(value)

    def test_ignores_a_lookalike_from_another_module(self):
        """The module check keeps a user class named NALogicalType out."""
        impostor = type("NALogicalType", (), {})()
        assert impostor.__class__.__module__ != "rpy2.rinterface_lib.sexp"
        assert not _is_r_na_sentinel(impostor)

    def test_the_singleton_really_does_evade_pandas(self):
        """The premise of the whole fix, asserted rather than assumed."""
        na = _na_singleton("NALogicalType")
        assert pd.isna(pd.Series([na], dtype=object)).tolist() == [False]
        with pytest.raises(ValueError):
            bool(na)


class TestThreeValuedCharterFlag:
    def _frame(self):
        return pd.DataFrame(
            {
                "is_charter": [True, False, _na_singleton("NALogicalType")],
                "district_id": ["6010", "0010", "6010"],
            }
        )

    def test_na_becomes_pandas_na_and_dtype_is_nullable_boolean(self):
        out = normalise_r_missingness(self._frame())

        assert out["is_charter"].dtype == "boolean"
        assert out["is_charter"].isna().tolist() == [False, False, True]
        assert out["is_charter"].iloc[0] is True or bool(out["is_charter"].iloc[0])
        assert not bool(out["is_charter"].iloc[1])

    def test_the_unknown_row_no_longer_reads_as_a_charter(self):
        """Before the fix this row raised; the point is that it is now missing."""
        out = normalise_r_missingness(self._frame())
        charters = out[out["is_charter"].fillna(False)]
        assert len(charters) == 1
        assert charters["district_id"].tolist() == ["6010"]

    def test_sourced_false_is_preserved_not_swept_to_na(self):
        out = normalise_r_missingness(self._frame())
        assert out["is_charter"].notna().sum() == 2

    def test_input_frame_is_not_mutated(self):
        frame = self._frame()
        normalise_r_missingness(frame)
        assert frame["is_charter"].dtype == object


class TestIntegerSentinel:
    def test_int_min_becomes_missing_in_a_nullable_column(self):
        frame = pd.DataFrame({"n_students": [100, R_INTEGER_NA, 250]})
        out = normalise_r_missingness(frame)

        assert out["n_students"].dtype == "Int64"
        assert out["n_students"].isna().tolist() == [False, True, False]

    def test_a_sum_is_no_longer_catastrophically_wrong(self):
        frame = pd.DataFrame({"n_students": [100, R_INTEGER_NA, 250]})
        assert frame["n_students"].sum() < 0            # the bug
        assert normalise_r_missingness(frame)["n_students"].sum() == 350

    def test_a_column_with_no_sentinel_is_left_alone(self):
        frame = pd.DataFrame({"n_students": [100, 200]})
        out = normalise_r_missingness(frame)
        assert out["n_students"].tolist() == [100, 200]
        assert pd.api.types.is_integer_dtype(out["n_students"])


class TestCharacterSentinel:
    def test_character_na_becomes_missing(self):
        frame = pd.DataFrame(
            {"county_id": ["80", _na_singleton("NACharacterType"), "01"]}
        )
        out = normalise_r_missingness(frame)

        assert out["county_id"].isna().tolist() == [False, True, False]
        assert out["county_id"].tolist()[0] == "80"

    def test_all_na_object_column_is_not_guessed_into_boolean(self):
        """With no present value there is no evidence of the original type."""
        frame = pd.DataFrame(
            {"is_charter": [_na_singleton("NALogicalType")] * 3}
        )
        out = normalise_r_missingness(frame)

        assert out["is_charter"].dtype == object
        assert out["is_charter"].isna().all()


class TestPassthrough:
    def test_non_frame_input_is_returned_untouched(self):
        assert normalise_r_missingness(None) is None
        assert normalise_r_missingness("not a frame") == "not a frame"

    def test_a_clean_frame_is_returned_unchanged(self):
        frame = pd.DataFrame({"a": [1.0, 2.0], "b": ["x", "y"]})
        out = normalise_r_missingness(frame)
        pd.testing.assert_frame_equal(out, frame)


class TestWiring:
    def test_r_to_pandas_routes_through_the_normaliser(self):
        """The decorator, not just the helper, must repair the frame."""
        from njschooldata._r_bridge import r_to_pandas

        frame = pd.DataFrame(
            {"is_charter": [True, _na_singleton("NALogicalType")]}
        )
        wrapped = r_to_pandas(lambda: frame)
        out = wrapped()

        assert out["is_charter"].dtype == "boolean"
        assert out["is_charter"].isna().tolist() == [False, True]


@pytest.mark.requires_r
class TestAgainstRealRpy2Singletons:
    """Same assertions, against rpy2's genuine NA objects rather than a stand-in."""

    def test_real_r_frame_keeps_all_three_values(self):
        import rpy2.robjects as ro
        from rpy2.robjects import pandas2ri
        from rpy2.robjects.conversion import localconverter

        r_df = ro.r(
            'data.frame(is_charter = c(TRUE, FALSE, NA), '
            'n = c(1L, 2L, NA_integer_), '
            'county_id = c("80", "01", NA_character_), '
            'stringsAsFactors = FALSE)'
        )
        with localconverter(ro.default_converter + pandas2ri.converter):
            raw = pandas2ri.rpy2py(r_df)

        # The premise: unrepaired, none of the three NAs registers as missing.
        assert raw["is_charter"].isna().tolist() == [False, False, False]
        assert raw["n"].tolist()[2] == R_INTEGER_NA

        out = normalise_r_missingness(raw)
        assert out["is_charter"].isna().tolist() == [False, False, True]
        assert out["n"].isna().tolist() == [False, False, True]
        assert out["county_id"].isna().tolist() == [False, False, True]
        assert out["n"].sum() == 3
