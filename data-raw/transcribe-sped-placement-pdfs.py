#!/usr/bin/env python3
"""
Transcribe NJ DOE SPED-Placement state-level PDFs to bundled CSVs.

Six PDFs cover end_year 2020, 2021, 2022 x age_group 5-21 and 3-5.
For these (end_year, age_group, level=state) slices NJ DOE only
published a PDF — there is no XLSX/CSV equivalent. The package needs
structured data, so we hand-code each (subgroup, environment) count
into Python constants below, then emit one CSV per slice into
inst/extdata/sped-placement-pdf-transcribed/.

Every number in this script must trace to a specific line of the
pdftotext -layout output in .claude/pdf-text-dumps/<file>.txt. The
companion {slice}_state_source.json files capture the SHA-256 hash of
the source PDF and notes on any source-document anomalies (e.g. the
NJ DOE percent-table misalignments documented below). Suppressed cells
(rendered as `*` in the PDF) become Python `None`, which serialises to
an empty CSV cell representing NA.

Run:
    python data-raw/transcribe-sped-placement-pdfs.py
"""

from __future__ import annotations

import csv
import datetime as _dt
import hashlib
import json
import subprocess
import sys
from pathlib import Path

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------

HERE = Path(__file__).resolve().parent
PKG_ROOT = HERE.parent
DUMP_DIR = PKG_ROOT / ".claude" / "pdf-text-dumps"
OUT_DIR = PKG_ROOT / "inst" / "extdata" / "sped-placement-pdf-transcribed"
FIDELITY_REPORT = DUMP_DIR / "fidelity-report.txt"

OUT_DIR.mkdir(parents=True, exist_ok=True)


# -----------------------------------------------------------------------------
# PDF metadata: file -> (sha256, pdf_url, source label)
# -----------------------------------------------------------------------------

PDF_META = {
    "ey2020_6_21_Placement.pdf": {
        "pdf_url": (
            "https://www.nj.gov/education/specialed/monitor/ideapublicdata/"
            "docs/2019.zip (member: 2019/6_21 Placement.pdf)"
        ),
        "label": "6_21 Placement.pdf",
    },
    "ey2020_3-5_Placement.pdf": {
        "pdf_url": (
            "https://www.nj.gov/education/specialed/monitor/ideapublicdata/"
            "docs/2019.zip (member: 2019/3-5_Placement.pdf)"
        ),
        "label": "3-5_Placement.pdf",
    },
    "ey2021_5_21_Placement.pdf": {
        "pdf_url": (
            "https://www.nj.gov/education/specialed/monitor/ideapublicdata/"
            "docs/2020.zip (member: 2020/5_21 Placement.pdf)"
        ),
        "label": "5_21 Placement.pdf",
    },
    "ey2021_3-5_Placement.pdf": {
        "pdf_url": (
            "https://www.nj.gov/education/specialed/monitor/ideapublicdata/"
            "docs/2020.zip (member: 2020/3-5_Placement.pdf)"
        ),
        "label": "3-5_Placement.pdf",
    },
    "ey2022_5_21_Placement.pdf": {
        "pdf_url": (
            "https://www.nj.gov/education/specialed/monitor/ideapublicdata/"
            "docs/2022%20data/5_21 Placement.pdf"
        ),
        "label": "5_21 Placement.pdf",
    },
    "ey2022_3_5_Placement.pdf": {
        "pdf_url": (
            "https://www.nj.gov/education/specialed/monitor/ideapublicdata/"
            "docs/2022%20data/3_5 Placement.pdf"
        ),
        "label": "3_5 Placement.pdf",
    },
}


def sha256_file(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def regenerate_text_dumps() -> None:
    """Re-run `pdftotext -layout` so the script is self-contained."""
    for fname in PDF_META:
        pdf = DUMP_DIR / fname
        txt = pdf.with_suffix(".txt")
        if not pdf.exists():
            print(f"[skip] {pdf} not found", file=sys.stderr)
            continue
        subprocess.run(
            ["pdftotext", "-layout", str(pdf), str(txt)],
            check=True,
        )


# -----------------------------------------------------------------------------
# Data constants -- hand-coded from pdftotext -layout dumps.
# -----------------------------------------------------------------------------
# Conventions:
#   - None  -> suppressed in PDF (rendered as "*"); becomes empty CSV cell (NA)
#   - 0     -> printed 0 in PDF (true zero)
#   - For percents, None means "missing or known-misaligned in PDF" and is
#     emitted as empty CSV cell. See per-slice NOTES for documentation of
#     known NJ DOE authoring errors that we mark as None.
#
# Each ROWS_*_5_21 / ROWS_*_3_5 dict is:
#     {(dimension, subgroup): {environment: (count, percent), ...}, ...}
# where each subgroup's row spans BOTH the Regular and Separate Settings
# pages (5-21) or BOTH the Regular and Special Education pages (3-5).
#
# For 5-21 each subgroup gets up to 6 envs:
#     gen_ed_80_plus, gen_ed_40_79, gen_ed_less_40,
#     separate_school, residential_facility, homebound_hospital
# (correction_facility is omitted -- not reported in any of these 6 PDFs.)
#
# For 3-5 each subgroup gets up to 7 envs:
#     ec_program_10plus_hrs,                        (Regular pg col 1)
#     services_other_loc_attended_ec_10plus_hrs,    (Regular pg col 2)
#     ec_program_less_10_hrs,                       (Regular pg col 3)
#     services_other_loc_attended_ec_less_10_hrs,   (Regular pg col 4)
#     separate_class,                               (Sep Settings pg col 1)
#     separate_school,                              (Sep Settings pg col 2)
#     residential_facility                          (Sep Settings pg col 3)
# (The 2022 3-5 PDF has no Sep Settings page; those envs are omitted.)


def None_to_zero():
    """Sentinel for hand-coded subgroup_total expressions: where the source
    PDF prints '*' (suppressed) for one of the two page-Total cells we sum,
    we use this marker placeholder of 0 to let the arithmetic compile. We
    then immediately overwrite the affected entries in the TOTALS_* dict
    with the visible-page-only value (or None if both pages are
    suppressed). See the explicit overrides below each TOTALS_* dict."""
    return 0


# =============================================================================
# 2020 5-21 (ey2020_6_21_Placement.pdf)
# =============================================================================
# Source lines:
#   Regular Education counts:    lines 9-16 (race), 34-36 (gender),
#                                52-69 (disability), 94-96 (LEP)
#   Regular Education percents:  lines 22-29 (race), 43-45 (gender),
#                                76-89 (disability), 103-105 (LEP)
#   Separate Settings counts:    lines 111-118 (race), 133-135 (gender),
#                                144-157 (disability), 177-179 (LEP)
#   Separate Settings percents:  lines 123-130 (race), 139-141 (gender),
#                                161-174 (disability), 184-186 (LEP)
#
# NOTE on 2020 5-21 disability percent table: in the Regular Education
# Disability percent table (lines 76-89), the "Visual Impairment" row shows
# percents (*, 0.04, *, 0.15) — those are consistent with count
# (220, 91, 39, 350) → (0.10, 0.04, 0.02, 0.15) ≈ on a denominator of
# ~226000. We accept these as published.

# (dim, subgroup): {env: (count, pct)}
ROWS_2020_5_21 = {
    # ----- Race / Ethnicity -----
    ("racial_ethnic", "white"): {
        "gen_ed_80_plus":      (54848, 23.66),
        "gen_ed_40_79":        (28322, 12.22),
        "gen_ed_less_40":      (10379, 4.48),
        "separate_school":     (6644, 2.87),
        "residential_facility":(219, 0.09),
        "homebound_hospital":  (296, 0.13),
    },
    ("racial_ethnic", "hispanic"): {
        "gen_ed_80_plus":      (27525, 11.87),
        "gen_ed_40_79":        (21062, 9.08),
        "gen_ed_less_40":      (13080, 5.64),
        "separate_school":     (3447, 1.49),
        "residential_facility":(108, 0.05),
        "homebound_hospital":  (193, 0.08),
    },
    ("racial_ethnic", "black"): {
        "gen_ed_80_plus":      (13801, 5.95),
        "gen_ed_40_79":        (11629, 5.02),
        "gen_ed_less_40":      (8420, 3.63),
        "separate_school":     (3283, 1.42),
        "residential_facility":(156, 0.07),
        "homebound_hospital":  (136, 0.06),
    },
    ("racial_ethnic", "asian"): {
        "gen_ed_80_plus":      (4709, 2.03),
        "gen_ed_40_79":        (2511, 1.08),
        "gen_ed_less_40":      (2066, 0.89),
        "separate_school":     (803, 0.35),
        "residential_facility":(22, 0.01),
        "homebound_hospital":  (22, 0.01),
    },
    ("racial_ethnic", "multiracial"): {
        "gen_ed_80_plus":      (2358, 1.02),
        "gen_ed_40_79":        (1462, 0.63),
        "gen_ed_less_40":      (668, 0.29),
        "separate_school":     (304, 0.13),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("racial_ethnic", "native_american"): {
        "gen_ed_80_plus":      (117, 0.05),
        "gen_ed_40_79":        (101, 0.04),
        "gen_ed_less_40":      (59, 0.03),
        "separate_school":     (27, 0.01),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("racial_ethnic", "pacific_islander"): {
        "gen_ed_80_plus":      (130, 0.06),
        "gen_ed_40_79":        (75, 0.03),
        "gen_ed_less_40":      (56, 0.02),
        "separate_school":     (21, 0.01),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("racial_ethnic", "total"): {
        "gen_ed_80_plus":      (103488, 44.64),
        "gen_ed_40_79":        (65162, 28.11),
        "gen_ed_less_40":      (34728, 14.98),
        "separate_school":     (14529, 6.27),
        "residential_facility":(514, 0.22),
        "homebound_hospital":  (670, 0.29),
    },
    # ----- Gender -----
    ("gender", "male"): {
        "gen_ed_80_plus":      (66672, 28.76),
        "gen_ed_40_79":        (43060, 18.57),
        "gen_ed_less_40":      (24714, 10.66),
        "separate_school":     (10467, 4.51),
        "residential_facility":(343, 0.15),
        "homebound_hospital":  (435, 0.19),
    },
    ("gender", "female"): {
        "gen_ed_80_plus":      (36816, 15.88),
        "gen_ed_40_79":        (22102, 9.53),
        "gen_ed_less_40":      (10014, 4.32),
        "separate_school":     (4062, 1.75),
        "residential_facility":(171, 0.07),
        "homebound_hospital":  (235, 0.10),
    },
    ("gender", "total"): {
        "gen_ed_80_plus":      (103488, 44.64),
        "gen_ed_40_79":        (65162, 28.11),
        "gen_ed_less_40":      (34728, 14.98),
        "separate_school":     (14529, 6.27),
        "residential_facility":(514, 0.22),
        "homebound_hospital":  (670, 0.29),
    },
    # ----- Disability -----
    ("disability", "autism"): {
        "gen_ed_80_plus":      (5115, 2.21),
        "gen_ed_40_79":        (4906, 2.12),
        "gen_ed_less_40":      (8341, 3.60),
        "separate_school":     (4669, 2.01),
        "residential_facility":(79, 0.03),
        "homebound_hospital":  (58, 0.03),
    },
    ("disability", "deaf_blindness"): {
        "gen_ed_80_plus":      (None, None),
        "gen_ed_40_79":        (0, 0.00),
        "gen_ed_less_40":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
        "homebound_hospital":  (0, 0.00),
    },
    ("disability", "developmental_delay"): {
        "gen_ed_80_plus":      (0, 0.00),
        "gen_ed_40_79":        (0, 0.00),
        "gen_ed_less_40":      (0, 0.00),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
        "homebound_hospital":  (0, 0.00),
    },
    ("disability", "emotional_disturbance"): {
        "gen_ed_80_plus":      (2385, 1.03),
        "gen_ed_40_79":        (1731, 0.75),
        "gen_ed_less_40":      (1184, 0.51),
        "separate_school":     (1771, 0.76),
        "residential_facility":(110, 0.05),
        "homebound_hospital":  (124, 0.05),
    },
    ("disability", "hearing_impairment"): {
        "gen_ed_80_plus":      (696, 0.30),
        "gen_ed_40_79":        (288, 0.12),
        "gen_ed_less_40":      (175, 0.08),
        "separate_school":     (226, 0.10),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("disability", "multiple_disabilities"): {
        "gen_ed_80_plus":      (1874, 0.81),
        "gen_ed_40_79":        (3202, 1.38),
        "gen_ed_less_40":      (3990, 1.72),
        "separate_school":     (4396, 1.90),
        "residential_facility":(164, 0.07),
        "homebound_hospital":  (182, 0.08),
    },
    ("disability", "intellectual_disability"): {
        "gen_ed_80_plus":      (359, 0.15),
        "gen_ed_40_79":        (1652, 0.71),
        "gen_ed_less_40":      (2844, 1.23),
        "separate_school":     (593, 0.26),
        "residential_facility":(15, 0.01),
        "homebound_hospital":  (14, 0.01),
    },
    ("disability", "other_health_impairment"): {
        "gen_ed_80_plus":      (25841, 11.15),
        "gen_ed_40_79":        (15916, 6.87),
        "gen_ed_less_40":      (5443, 2.35),
        "separate_school":     (2046, 0.88),
        "residential_facility":(78, 0.03),
        "homebound_hospital":  (197, 0.08),
    },
    ("disability", "orthopedic_impairment"): {
        "gen_ed_80_plus":      (206, 0.09),
        "gen_ed_40_79":        (62, 0.03),
        "gen_ed_less_40":      (29, 0.01),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
        "homebound_hospital":  (None, None),
    },
    ("disability", "specific_learning_disability"): {
        "gen_ed_80_plus":      (36469, 15.73),
        "gen_ed_40_79":        (26378, 11.38),
        "gen_ed_less_40":      (6498, 2.80),
        "separate_school":     (453, 0.20),
        "residential_facility":(45, 0.02),
        "homebound_hospital":  (54, 0.02),
    },
    ("disability", "speech_language_impairment"): {
        "gen_ed_80_plus":      (30188, 13.02),
        "gen_ed_40_79":        (10818, 4.67),
        "gen_ed_less_40":      (6095, 2.63),
        "separate_school":     (253, 0.11),
        "residential_facility":(12, 0.01),
        "homebound_hospital":  (20, 0.01),
    },
    ("disability", "traumatic_brain_injury"): {
        "gen_ed_80_plus":      (None, 0.06),
        "gen_ed_40_79":        (118, 0.05),
        "gen_ed_less_40":      (None, 0.04),
        "separate_school":     (75, 0.03),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("disability", "visual_impairment"): {
        "gen_ed_80_plus":      (220, None),
        "gen_ed_40_79":        (91, 0.04),
        "gen_ed_less_40":      (39, None),
        "separate_school":     (None, 0.01),
        "residential_facility":(0, 0.00),
        "homebound_hospital":  (None, None),
    },
    ("disability", "total"): {
        "gen_ed_80_plus":      (103488, 44.64),
        "gen_ed_40_79":        (65162, 28.11),
        "gen_ed_less_40":      (34728, 14.98),
        "separate_school":     (14529, 6.27),
        "residential_facility":(514, 0.22),
        "homebound_hospital":  (670, 0.29),
    },
    # ----- English Learner -----
    ("multilingual_learner", "lep"): {
        "gen_ed_80_plus":      (3777, 1.63),
        "gen_ed_40_79":        (2457, 1.06),
        "gen_ed_less_40":      (1635, 0.71),
        "separate_school":     (124, 0.05),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("multilingual_learner", "non_lep"): {
        "gen_ed_80_plus":      (99711, 43.01),
        "gen_ed_40_79":        (62705, 27.05),
        "gen_ed_less_40":      (33093, 14.27),
        "separate_school":     (14405, 6.21),
        "residential_facility":(511, 0.22),
        "homebound_hospital":  (666, 0.29),
    },
    ("multilingual_learner", "total"): {
        "gen_ed_80_plus":      (103488, 44.64),
        "gen_ed_40_79":        (65162, 28.11),
        "gen_ed_less_40":      (34728, 14.98),
        "separate_school":     (14529, 6.27),
        "residential_facility":(514, 0.22),
        "homebound_hospital":  (670, 0.29),
    },
}

# Per-subgroup totals as reported in the PDF (Total column on each page,
# summed across Regular + Separate Settings pages).
TOTALS_2020_5_21 = {
    ("racial_ethnic", "white"):                  93549 + 7159,
    ("racial_ethnic", "hispanic"):               61667 + 3748,
    ("racial_ethnic", "black"):                  33850 + 3575,
    ("racial_ethnic", "asian"):                  9286 + 847,
    ("racial_ethnic", "multiracial"):            4488 + 330,
    ("racial_ethnic", "native_american"):        277 + 30,
    ("racial_ethnic", "pacific_islander"):       261 + 24,
    ("racial_ethnic", "total"):                  203378 + 15713,
    ("gender", "male"):                          134446 + 11245,
    ("gender", "female"):                        68932 + 4468,
    ("gender", "total"):                         203378 + 15713,
    ("disability", "autism"):                    18362 + 4806,
    ("disability", "deaf_blindness"):            10 + None_to_zero(),  # placeholder
    ("disability", "developmental_delay"):       0 + 0,
    ("disability", "emotional_disturbance"):     5300 + 2005,
    ("disability", "hearing_impairment"):        1159 + 239,
    ("disability", "multiple_disabilities"):     9066 + 4742,
    ("disability", "intellectual_disability"):   4855 + 622,
    ("disability", "other_health_impairment"):   47200 + 2321,
    ("disability", "orthopedic_impairment"):     297 + 18,
    ("disability", "specific_learning_disability"): 69345 + 552,
    ("disability", "speech_language_impairment"):   47101 + 285,
    ("disability", "traumatic_brain_injury"):    333 + 89,
    ("disability", "visual_impairment"):         350 + 26,
    ("disability", "total"):                     203378 + 15713,
    ("multilingual_learner", "lep"):             7869 + 131,
    ("multilingual_learner", "non_lep"):         195509 + 15582,
    ("multilingual_learner", "total"):           203378 + 15713,
}

# The deaf_blindness 5-21 2020 Separate page Total is "*" (suppressed) —
# the Regular page Total is 10. We record the visible Regular total only.
# (See helper below; we replace the placeholder.)


# Fix the deaf_blindness 2020 5-21 placeholder explicitly:
TOTALS_2020_5_21[("disability", "deaf_blindness")] = 10  # Regular page only


# =============================================================================
# 2020 3-5 (ey2020_3-5_Placement.pdf)
# =============================================================================
# Regular Education page (pdftotext lines 26-33 race, 82-84 gender,
#   131-144 disability, 199-201 LEP).
# Special Education Program page (pdftotext lines 243-250 race,
#   278-280 gender, 298-311 disability, 342-344 LEP).
# Note: 2020 3-5 Disability row "Developmental" should be normalised to
# developmental_delay.

ROWS_2020_3_5 = {
    # ----- Race -----
    ("racial_ethnic", "white"): {
        "ec_program_10plus_hrs":                       (2581, 17.38),
        "services_other_loc_attended_ec_10plus_hrs":   (302, 2.03),
        "ec_program_less_10_hrs":                      (288, 1.94),
        "services_other_loc_attended_ec_less_10_hrs":  (538, 3.62),
        "separate_class":      (2305, 15.52),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    ("racial_ethnic", "hispanic"): {
        "ec_program_10plus_hrs":                       (2310, 15.55),
        "services_other_loc_attended_ec_10plus_hrs":   (190, 1.28),
        "ec_program_less_10_hrs":                      (155, 1.04),
        "services_other_loc_attended_ec_less_10_hrs":  (447, 3.01),
        "separate_class":      (1780, 11.99),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    ("racial_ethnic", "black"): {
        "ec_program_10plus_hrs":                       (616, 4.15),
        "services_other_loc_attended_ec_10plus_hrs":   (81, 0.55),
        "ec_program_less_10_hrs":                      (44, 0.30),
        "services_other_loc_attended_ec_less_10_hrs":  (179, 1.21),
        "separate_class":      (650, 4.38),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    ("racial_ethnic", "asian"): {
        "ec_program_10plus_hrs":                       (411, 2.77),
        "services_other_loc_attended_ec_10plus_hrs":   (138, 0.93),
        "ec_program_less_10_hrs":                      (25, 0.17),
        "services_other_loc_attended_ec_less_10_hrs":  (96, 0.65),
        "separate_class":      (627, 4.22),
        "separate_school":     (50, 0.34),
        "residential_facility":(0, 0.00),
    },
    ("racial_ethnic", "multiracial"): {
        "ec_program_10plus_hrs":                       (183, 1.23),
        "services_other_loc_attended_ec_10plus_hrs":   (17, 0.11),
        "ec_program_less_10_hrs":                      (14, 0.09),
        "services_other_loc_attended_ec_less_10_hrs":  (31, 0.21),
        "separate_class":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
    },
    ("racial_ethnic", "native_american"): {
        "ec_program_10plus_hrs":                       (13, 0.09),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
        "separate_class":      (None, None),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("racial_ethnic", "pacific_islander"): {
        "ec_program_10plus_hrs":                       (12, 0.08),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
        "separate_class":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
    },
    ("racial_ethnic", "total"): {
        "ec_program_10plus_hrs":                       (6126, 41.25),
        "services_other_loc_attended_ec_10plus_hrs":   (732, 4.93),
        "ec_program_less_10_hrs":                      (530, 3.57),
        "services_other_loc_attended_ec_less_10_hrs":  (1301, 8.76),
        "separate_class":      (5560, 37.44),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    # ----- Gender -----
    ("gender", "male"): {
        "ec_program_10plus_hrs":                       (4282, 28.83),
        "services_other_loc_attended_ec_10plus_hrs":   (566, 3.81),
        "ec_program_less_10_hrs":                      (356, 2.40),
        "services_other_loc_attended_ec_less_10_hrs":  (938, 6.32),
        "separate_class":      (4117, 27.72),
        "separate_school":     (373, 2.51),
        "residential_facility":(3, 0.02),
    },
    ("gender", "female"): {
        "ec_program_10plus_hrs":                       (1844, 12.42),
        "services_other_loc_attended_ec_10plus_hrs":   (166, 1.12),
        "ec_program_less_10_hrs":                      (174, 1.17),
        "services_other_loc_attended_ec_less_10_hrs":  (363, 2.44),
        "separate_class":      (1443, 9.72),
        "separate_school":     (171, 1.15),
        "residential_facility":(2, 0.01),
    },
    ("gender", "total"): {
        "ec_program_10plus_hrs":                       (6126, 41.25),
        "services_other_loc_attended_ec_10plus_hrs":   (732, 4.93),
        "ec_program_less_10_hrs":                      (530, 3.57),
        "services_other_loc_attended_ec_less_10_hrs":  (1301, 8.76),
        "separate_class":      (5560, 37.44),
        "separate_school":     (544, 3.66),
        "residential_facility":(5, 0.03),
    },
    # ----- Disability -----
    ("disability", "autism"): {
        "ec_program_10plus_hrs":                       (None, None),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
        "separate_class":      (30, 0.20),
        "separate_school":     (10, 0.07),
        "residential_facility":(0, 0.00),
    },
    ("disability", "deaf_blindness"): {
        "ec_program_10plus_hrs":                       (0, 0.00),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
        "separate_class":      (0, 0.00),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("disability", "developmental_delay"): {
        "ec_program_10plus_hrs":                       (6058, 40.79),
        "services_other_loc_attended_ec_10plus_hrs":   (717, 4.83),
        "ec_program_less_10_hrs":                      (521, 3.51),
        "services_other_loc_attended_ec_less_10_hrs":  (1288, 8.67),
        "separate_class":      (5509, 37.10),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    ("disability", "emotional_disturbance"): {
        "ec_program_10plus_hrs":                       (0, 0.00),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
        "separate_class":      (0, 0.00),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("disability", "hearing_impairment"): {
        "ec_program_10plus_hrs":                       (None, None),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
        "separate_class":      (None, None),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("disability", "multiple_disabilities"): {
        "ec_program_10plus_hrs":                       (None, None),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
        "separate_class":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    ("disability", "intellectual_disability"): {
        "ec_program_10plus_hrs":                       (None, None),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
        "separate_class":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
    },
    ("disability", "other_health_impairment"): {
        "ec_program_10plus_hrs":                       (19, 0.13),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
        "separate_class":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
    },
    ("disability", "orthopedic_impairment"): {
        "ec_program_10plus_hrs":                       (0, 0.00),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
        "separate_class":      (None, None),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("disability", "specific_learning_disability"): {
        "ec_program_10plus_hrs":                       (None, None),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
        "separate_class":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
    },
    ("disability", "speech_language_impairment"): {
        "ec_program_10plus_hrs":                       (24, 0.16),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
        "separate_class":      (None, None),
        "separate_school":     (0, 0.00),
        "residential_facility":(None, None),
    },
    ("disability", "traumatic_brain_injury"): {
        "ec_program_10plus_hrs":                       (0, 0.00),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
        "separate_class":      (0, 0.00),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("disability", "visual_impairment"): {
        "ec_program_10plus_hrs":                       (0, 0.00),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
        "separate_class":      (0, 0.00),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("disability", "total"): {
        "ec_program_10plus_hrs":                       (6126, 41.25),
        "services_other_loc_attended_ec_10plus_hrs":   (732, 4.93),
        "ec_program_less_10_hrs":                      (530, 3.57),
        "services_other_loc_attended_ec_less_10_hrs":  (1301, 8.76),
        "separate_class":      (5560, 37.44),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    # ----- English Learner -----
    ("multilingual_learner", "lep"): {
        "ec_program_10plus_hrs":                       (321, 2.16),
        "services_other_loc_attended_ec_10plus_hrs":   (32, 0.22),
        "ec_program_less_10_hrs":                      (22, 0.15),
        "services_other_loc_attended_ec_less_10_hrs":  (24, 0.16),
        "separate_class":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
    },
    ("multilingual_learner", "non_lep"): {
        "ec_program_10plus_hrs":                       (5805, 39.09),
        "services_other_loc_attended_ec_10plus_hrs":   (700, 4.71),
        "ec_program_less_10_hrs":                      (508, 3.42),
        "services_other_loc_attended_ec_less_10_hrs":  (1277, 8.60),
        "separate_class":      (5427, 36.54),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    ("multilingual_learner", "total"): {
        "ec_program_10plus_hrs":                       (6126, 41.25),
        "services_other_loc_attended_ec_10plus_hrs":   (732, 4.93),
        "ec_program_less_10_hrs":                      (530, 3.57),
        "services_other_loc_attended_ec_less_10_hrs":  (1301, 8.76),
        "separate_class":      (5560, 37.44),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
}

# Subgroup totals (Regular page Total + Sep page Total)
TOTALS_2020_3_5 = {
    ("racial_ethnic", "white"):              3709 + 2583,
    ("racial_ethnic", "hispanic"):           3102 + 1905,
    ("racial_ethnic", "black"):              920 + 732,
    ("racial_ethnic", "asian"):              670 + 677,
    ("racial_ethnic", "multiracial"):        245 + 189,
    ("racial_ethnic", "native_american"):    22 + None_to_zero(),
    ("racial_ethnic", "pacific_islander"):   21 + None_to_zero(),
    ("racial_ethnic", "total"):              8689 + 6109,
    ("gender", "male"):                      6142 + 4493,
    ("gender", "female"):                    2547 + 1616,
    ("gender", "total"):                     8689 + 6109,
    ("disability", "autism"):                17 + 40,
    ("disability", "deaf_blindness"):        0 + 0,
    ("disability", "developmental_delay"):   8584 + 6034,
    ("disability", "emotional_disturbance"): 0 + 0,
    # hearing_impairment: Reg total "*" (suppressed), Sep total "*"
    ("disability", "hearing_impairment"):    None,
    ("disability", "multiple_disabilities"): None,  # Reg "*", Sep 12
    ("disability", "intellectual_disability"): None,  # both suppressed
    ("disability", "other_health_impairment"): 26 + None_to_zero(),  # Sep "*"
    ("disability", "orthopedic_impairment"): None,  # Reg "*", Sep "*"
    ("disability", "specific_learning_disability"): 11 + None_to_zero(),  # Sep "*"
    ("disability", "speech_language_impairment"): 35 + 10,
    ("disability", "traumatic_brain_injury"): None,  # Reg "*", Sep 0
    ("disability", "visual_impairment"):     0 + 0,
    ("disability", "total"):                 8689 + 6109,
    ("multilingual_learner", "lep"):         399 + 136,
    ("multilingual_learner", "non_lep"):     8290 + 5973,
    ("multilingual_learner", "total"):       8689 + 6109,
}
# Overwrite the placeholder-using "None_to_zero()" totals where the Sep page
# value is "*" (suppressed) -- emit subgroup_total = Reg page Total only.
TOTALS_2020_3_5[("racial_ethnic", "native_american")] = 22
TOTALS_2020_3_5[("racial_ethnic", "pacific_islander")] = 21
TOTALS_2020_3_5[("disability", "other_health_impairment")] = 26
TOTALS_2020_3_5[("disability", "specific_learning_disability")] = 11

# Where BOTH pages have suppressed totals, leave subgroup_total = None.
# (hearing_impairment, multiple_disabilities, intellectual_disability,
#  orthopedic_impairment, traumatic_brain_injury) -- already None.


# =============================================================================
# 2021 5-21 (ey2021_5_21_Placement.pdf)
# =============================================================================
# Regular Education counts:    lines 13-20 (race), 43-45 (gender),
#                              63-76 (disability), 102-104 (LEP)
# Regular Education percents:  lines 28-35 (race), 53-55 (gender),
#                              [83-95 BROKEN, see note], 112-114 (LEP)
# Separate Settings counts:    lines 121-128 (race), 145-147 (gender),
#                              162-175 (disability), 201-203 (LEP)
# Separate Settings percents:  lines 134-141 (race), 156-158 (gender),
#                              184-197 (disability), 209-211 (LEP)
#
# NOTE on 2021 5-21 Regular Education Disability percent table (page 3,
# pdftotext lines 83-95): the table is misaligned -- it lacks a row for
# "Preschool Disabled (DD)" entirely and the surviving rows do not match
# the count table (e.g. "Hearing Impairment" percent row shows 1/0.72/0.49,
# which is the percent of count 25519 Other Health Impairment, not 664
# Hearing Impairment). We emit percent = NA for every Regular page
# disability row and document in 2021_5-21_state_source.json.
# The Separate Settings disability percent table is intact.

ROWS_2021_5_21 = {
    # ----- Race -----
    ("racial_ethnic", "white"): {
        "gen_ed_80_plus":      (52485, 23.44),
        "gen_ed_40_79":        (26880, 12.01),
        "gen_ed_less_40":      (10241, 4.57),
        "separate_school":     (6302, 2.81),
        "residential_facility":(166, 0.07),
        "homebound_hospital":  (234, 0.10),
    },
    ("racial_ethnic", "hispanic"): {
        "gen_ed_80_plus":      (27618, 12.33),
        "gen_ed_40_79":        (21014, 9.39),
        "gen_ed_less_40":      (13360, 5.97),
        "separate_school":     (3339, 1.49),
        "residential_facility":(64, 0.03),
        "homebound_hospital":  (136, 0.06),
    },
    ("racial_ethnic", "black"): {
        "gen_ed_80_plus":      (13737, 6.14),
        "gen_ed_40_79":        (11336, 5.06),
        "gen_ed_less_40":      (8401, 3.75),
        "separate_school":     (3183, 1.42),
        "residential_facility":(76, 0.03),
        "homebound_hospital":  (95, 0.04),
    },
    ("racial_ethnic", "asian"): {
        "gen_ed_80_plus":      (4667, 2.08),
        "gen_ed_40_79":        (2505, 1.12),
        "gen_ed_less_40":      (2093, 0.93),
        "separate_school":     (778, 0.35),
        "residential_facility":(18, 0.01),
        "homebound_hospital":  (20, 0.01),
    },
    ("racial_ethnic", "multiracial"): {
        "gen_ed_80_plus":      (2523, 1.13),
        "gen_ed_40_79":        (1489, 0.67),
        "gen_ed_less_40":      (708, 0.32),
        "separate_school":     (342, 0.15),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("racial_ethnic", "native_american"): {
        "gen_ed_80_plus":      (120, 0.05),
        "gen_ed_40_79":        (98, 0.04),
        "gen_ed_less_40":      (64, 0.03),
        "separate_school":     (25, 0.01),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("racial_ethnic", "pacific_islander"): {
        "gen_ed_80_plus":      (126, 0.06),
        "gen_ed_40_79":        (76, 0.03),
        "gen_ed_less_40":      (53, 0.02),
        "separate_school":     (18, 0.01),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("racial_ethnic", "total"): {
        "gen_ed_80_plus":      (101276, 45.23),
        "gen_ed_40_79":        (63398, 28.31),
        "gen_ed_less_40":      (34920, 15.60),
        "separate_school":     (13987, 6.25),
        "residential_facility":(333, 0.15),
        "homebound_hospital":  (496, 0.22),
    },
    # ----- Gender -----
    ("gender", "male"): {
        "gen_ed_80_plus":      (65347, 29.19),
        "gen_ed_40_79":        (41718, 18.63),
        "gen_ed_less_40":      (24818, 11.08),
        "separate_school":     (10038, 4.48),
        "residential_facility":(241, 0.11),
        "homebound_hospital":  (308, 0.14),
    },
    ("gender", "female"): {
        "gen_ed_80_plus":      (35929, 16.05),
        "gen_ed_40_79":        (21680, 9.68),
        "gen_ed_less_40":      (10102, 4.51),
        "separate_school":     (3949, 1.76),
        "residential_facility":(92, 0.04),
        "homebound_hospital":  (188, 0.08),
    },
    ("gender", "total"): {
        "gen_ed_80_plus":      (101276, 45.23),
        "gen_ed_40_79":        (63398, 28.31),
        "gen_ed_less_40":      (34920, 15.60),
        "separate_school":     (13987, 6.25),
        "residential_facility":(333, 0.15),
        "homebound_hospital":  (496, 0.22),
    },
    # ----- Disability -----
    # Regular Education percents emitted as None due to misaligned PDF table.
    # Separate Settings percents are intact (lines 184-197).
    ("disability", "autism"): {
        "gen_ed_80_plus":      (5163, None),
        "gen_ed_40_79":        (5033, None),
        "gen_ed_less_40":      (8898, None),
        "separate_school":     (4563, 2.04),
        "residential_facility":(80, 0.04),
        "homebound_hospital":  (43, 0.02),
    },
    ("disability", "deaf_blindness"): {
        "gen_ed_80_plus":      (None, None),
        "gen_ed_40_79":        (0, None),
        "gen_ed_less_40":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
        "homebound_hospital":  (0, 0.00),
    },
    ("disability", "preschool_disability"): {
        "gen_ed_80_plus":      (195, None),
        "gen_ed_40_79":        (47, None),
        "gen_ed_less_40":      (72, None),
        "separate_school":     (14, 0.01),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("disability", "emotional_disturbance"): {
        "gen_ed_80_plus":      (2241, None),
        "gen_ed_40_79":        (1608, None),
        "gen_ed_less_40":      (1103, None),
        "separate_school":     (1634, 0.73),
        "residential_facility":(47, 0.02),
        "homebound_hospital":  (83, 0.04),
    },
    ("disability", "hearing_impairment"): {
        "gen_ed_80_plus":      (664, None),
        "gen_ed_40_79":        (278, None),
        "gen_ed_less_40":      (165, None),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
        "homebound_hospital":  (0, 0.00),
    },
    ("disability", "intellectual_disability"): {
        "gen_ed_80_plus":      (369, None),
        "gen_ed_40_79":        (1677, None),
        "gen_ed_less_40":      (2759, None),
        "separate_school":     (574, 0.26),
        "residential_facility":(10, 0.00),
        "homebound_hospital":  (None, 0.00),
    },
    ("disability", "multiple_disabilities"): {
        "gen_ed_80_plus":      (1883, None),
        "gen_ed_40_79":        (3051, None),
        "gen_ed_less_40":      (3773, None),
        "separate_school":     (4112, 1.84),
        "residential_facility":(111, 0.05),
        "homebound_hospital":  (141, 0.06),
    },
    ("disability", "other_health_impairment"): {
        "gen_ed_80_plus":      (25519, None),
        "gen_ed_40_79":        (15536, None),
        "gen_ed_less_40":      (5409, None),
        "separate_school":     (2047, 0.91),
        "residential_facility":(47, 0.02),
        "homebound_hospital":  (141, 0.06),
    },
    ("disability", "orthopedic_impairment"): {
        "gen_ed_80_plus":      (187, None),
        "gen_ed_40_79":        (61, None),
        "gen_ed_less_40":      (32, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
        "homebound_hospital":  (None, None),
    },
    ("disability", "specific_learning_disability"): {
        "gen_ed_80_plus":      (34992, None),
        "gen_ed_40_79":        (25318, None),
        "gen_ed_less_40":      (6242, None),
        "separate_school":     (440, 0.20),
        "residential_facility":(20, 0.01),
        "homebound_hospital":  (51, 0.02),
    },
    ("disability", "speech_language_impairment"): {
        "gen_ed_80_plus":      (29745, None),
        "gen_ed_40_79":        (10589, None),
        "gen_ed_less_40":      (6335, None),
        "separate_school":     (253, 0.11),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("disability", "traumatic_brain_injury"): {
        "gen_ed_80_plus":      (110, None),
        "gen_ed_40_79":        (107, None),
        "gen_ed_less_40":      (94, None),
        "separate_school":     (70, 0.03),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("disability", "visual_impairment"): {
        "gen_ed_80_plus":      (202, None),
        "gen_ed_40_79":        (93, None),
        "gen_ed_less_40":      (32, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
        "homebound_hospital":  (None, None),
    },
    ("disability", "total"): {
        "gen_ed_80_plus":      (101276, None),
        "gen_ed_40_79":        (63398, None),
        "gen_ed_less_40":      (34920, None),
        "separate_school":     (13987, 6.25),
        "residential_facility":(333, 0.15),
        "homebound_hospital":  (496, 0.22),
    },
    # ----- English Learner -----
    ("multilingual_learner", "lep"): {
        "gen_ed_80_plus":      (3953, 1.77),
        "gen_ed_40_79":        (2551, 1.14),
        "gen_ed_less_40":      (1845, 0.82),
        "separate_school":     (112, 0.05),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("multilingual_learner", "non_lep"): {
        "gen_ed_80_plus":      (97323, 43.47),
        "gen_ed_40_79":        (60847, 27.18),
        "gen_ed_less_40":      (33075, 14.77),
        "separate_school":     (13875, 6.20),
        "residential_facility":(331, 0.15),
        "homebound_hospital":  (490, 0.22),
    },
    ("multilingual_learner", "total"): {
        "gen_ed_80_plus":      (101276, 45.23),
        "gen_ed_40_79":        (63398, 28.31),
        "gen_ed_less_40":      (34920, 15.60),
        "separate_school":     (13987, 6.25),
        "residential_facility":(333, 0.15),
        "homebound_hospital":  (496, 0.22),
    },
}

# Subgroup totals. Note: the 2021 5-21 PDF prints "2E+05" for some
# subgroup totals (Excel scientific-notation overflow); the actual integer
# total is recoverable from the page's other rows. For those subgroups
# we record the integer Total = Reg page Total + Sep page Total using only
# clean integer values from the PDF (Race table "Total" row of 2E+05
# matches: 89606+61992+33474+9265+4720+282+255 = 199594 -> 199594 +
# 14816 = 214410; gender Total "1E+05" male = 65347+41718+24818=131883
# +10587 = 142470).
TOTALS_2021_5_21 = {
    ("racial_ethnic", "white"):                  89606 + 6702,
    ("racial_ethnic", "hispanic"):               61992 + 3539,
    ("racial_ethnic", "black"):                  33474 + 3354,
    ("racial_ethnic", "asian"):                  9265 + 816,
    ("racial_ethnic", "multiracial"):            4720 + 358,
    ("racial_ethnic", "native_american"):        282 + 27,
    ("racial_ethnic", "pacific_islander"):       255 + 20,
    ("racial_ethnic", "total"):                  199594 + 14816,
    ("gender", "male"):                          131883 + 10587,
    ("gender", "female"):                        67711 + 4229,
    ("gender", "total"):                         199594 + 14816,
    ("disability", "autism"):                    19094 + 4686,
    ("disability", "deaf_blindness"):            12,    # Reg Total = 12; Sep Total "*"
    ("disability", "preschool_disability"):      314 + 19,
    ("disability", "emotional_disturbance"):     4952 + 1764,
    ("disability", "hearing_impairment"):        1107 + 242,
    ("disability", "intellectual_disability"):   4805 + 590,
    ("disability", "multiple_disabilities"):     8707 + 4364,
    ("disability", "other_health_impairment"):   46464 + 2235,
    ("disability", "orthopedic_impairment"):     280 + 16,
    ("disability", "specific_learning_disability"): 66552 + 511,
    ("disability", "speech_language_impairment"):   46669 + 274,
    ("disability", "traumatic_brain_injury"):    311 + 84,
    ("disability", "visual_impairment"):         327 + 23,
    ("disability", "total"):                     199594 + 14816,
    ("multilingual_learner", "lep"):             8349 + 120,
    ("multilingual_learner", "non_lep"):         199594 - 8349 + 14816 - 120,  # = matches 191245 + 14696
    ("multilingual_learner", "total"):           199594 + 14816,
}


# =============================================================================
# 2021 3-5 (ey2021_3-5_Placement.pdf)
# =============================================================================
# Regular Education counts:    lines 28-35 (race), 90-92 (gender),
#                              138-151 (disability), 210-212 (LEP)
# Regular Education percents:  lines 59-66 (race), 114-116 (gender),
#                              [174-187 BROKEN, see note], 235-237 (LEP)
# Special Education page counts:   lines 249-256 (race), 279-281 (gender),
#                                  299-312 (disability), 341-343 (LEP)
# Special Education page percents: lines 264-271 (race), 290-292 (gender),
#                                  319-332 (disability), 350-352 (LEP)
#
# NOTE on 2021 3-5 Regular Education Disability percent table (pdftotext
# lines 174-187): column 4 ("Less than 10 Hrs Per Week / Some Other
# Location") is misaligned -- it duplicates column 1 (e.g. Developmental
# Delay shows 40.60 in both col 1 and col 4; should be ~9.13 in col 4
# given count 1228). All other 3-5 disability percent rows look broadly
# right but suspect. We mark all 3-5 Regular Education disability percents
# as None to be safe, and document in 2021_3-5_state_source.json.
# Gender table on Sep Settings page (lines 279-281) contains stray "*"
# characters from the rendered PDF; we use the numeric values present
# (3756/1295/5051 and 4050/1449/5499 for total) and treat the middle
# columns ("Separate School", "Residential Facility") as suppressed.

ROWS_2021_3_5 = {
    # ----- Race -----
    # NOTE: 2021 3-5 Regular Education Race table column 4
    # ("services_other_loc_attended_ec_less_10_hrs") is CORRUPTED in the
    # source PDF -- column 4 values are mis-rendered as duplicates of
    # column 2 (services_other_loc_attended_ec_10plus_hrs). E.g. the
    # White row prints 2361, 231, 259, 231, 3359 but 2361+231+259+231 =
    # 3082 != 3359 (the Total). The Disability and LEP tables on the same
    # page have the correct column-4 values (e.g. Disability Total row =
    # 5513, 603, 554, 1235, 7905 sums correctly). Because the Race column-4
    # cells in the PDF are unreliable, we emit None (NA) for every Race
    # row's services_other_loc_attended_ec_less_10_hrs cell and document
    # the corruption in 2021_3-5_state_source.json. The Race "Total" row
    # column-4 cell (1235) is recoverable from the Disability/LEP Total
    # rows on the same page, but we keep it consistent (NA) and document
    # rather than mix sources.
    ("racial_ethnic", "white"): {
        "ec_program_10plus_hrs":                       (2361, 17.57),
        "services_other_loc_attended_ec_10plus_hrs":   (231, 1.72),
        "ec_program_less_10_hrs":                      (259, 1.93),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),  # CORRUPT
        "separate_class":      (2160, 16.07),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    ("racial_ethnic", "hispanic"): {
        "ec_program_10plus_hrs":                       (2076, 15.45),
        "services_other_loc_attended_ec_10plus_hrs":   (160, 1.19),
        "ec_program_less_10_hrs":                      (185, 1.38),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),  # CORRUPT
        "separate_class":      (1598, 11.89),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    ("racial_ethnic", "black"): {
        "ec_program_10plus_hrs":                       (556, 4.14),
        "services_other_loc_attended_ec_10plus_hrs":   (82, 0.61),
        "ec_program_less_10_hrs":                      (57, 0.42),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),  # CORRUPT
        "separate_class":      (572, 4.26),
        "separate_school":     (55, 0.41),
        "residential_facility":(0, 0.00),
    },
    ("racial_ethnic", "asian"): {
        "ec_program_10plus_hrs":                       (339, 2.52),
        "services_other_loc_attended_ec_10plus_hrs":   (118, 0.88),
        "ec_program_less_10_hrs":                      (32, 0.24),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),  # CORRUPT
        "separate_class":      (529, 3.94),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    ("racial_ethnic", "multiracial"): {
        "ec_program_10plus_hrs":                       (159, 1.18),
        "services_other_loc_attended_ec_10plus_hrs":   (9, 0.07),
        "ec_program_less_10_hrs":                      (18, 0.13),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),  # CORRUPT
        "separate_class":      (173, 1.29),
        "separate_school":     (14, 0.10),
        "residential_facility":(0, 0.00),
    },
    ("racial_ethnic", "native_american"): {
        "ec_program_10plus_hrs":                       (12, 0.09),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),  # CORRUPT
        "separate_class":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
    },
    ("racial_ethnic", "pacific_islander"): {
        "ec_program_10plus_hrs":                       (10, 0.07),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
        "separate_class":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
    },
    ("racial_ethnic", "total"): {
        "ec_program_10plus_hrs":                       (5513, 41.02),
        "services_other_loc_attended_ec_10plus_hrs":   (603, 4.49),
        "ec_program_less_10_hrs":                      (554, 4.12),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),  # CORRUPT
        "separate_class":      (5051, 37.58),
        "separate_school":     (444, None),
        "residential_facility":(None, None),
    },
    # ----- Gender -----
    # Sep Settings page printed Separate School / Residential Facility
    # columns as "*"; counts inferred only from visible cells.
    ("gender", "male"): {
        "ec_program_10plus_hrs":                       (3840, 28.57),
        "services_other_loc_attended_ec_10plus_hrs":   (463, 3.44),
        "ec_program_less_10_hrs":                      (380, 2.83),
        "services_other_loc_attended_ec_less_10_hrs":  (883, 6.57),
        "separate_class":      (3756, 27.94),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    ("gender", "female"): {
        "ec_program_10plus_hrs":                       (1673, 12.45),
        "services_other_loc_attended_ec_10plus_hrs":   (140, 1.04),
        "ec_program_less_10_hrs":                      (174, 1.29),
        "services_other_loc_attended_ec_less_10_hrs":  (352, 2.62),
        "separate_class":      (1295, 9.63),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    ("gender", "total"): {
        "ec_program_10plus_hrs":                       (5513, 41.02),
        "services_other_loc_attended_ec_10plus_hrs":   (603, 4.49),
        "ec_program_less_10_hrs":                      (554, 4.12),
        "services_other_loc_attended_ec_less_10_hrs":  (1235, 9.19),
        "separate_class":      (5051, 37.58),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    # ----- Disability -----
    # Regular Education page disability percent table marked None due to
    # column-4 misalignment (see section header note).
    ("disability", "autism"): {
        "ec_program_10plus_hrs":                       (14, None),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
        "separate_class":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
    },
    ("disability", "deaf_blindness"): {
        "ec_program_10plus_hrs":                       (0, None),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
        "separate_class":      (0, 0.00),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("disability", "developmental_delay"): {
        "ec_program_10plus_hrs":                       (5457, None),
        "services_other_loc_attended_ec_10plus_hrs":   (596, None),
        "ec_program_less_10_hrs":                      (546, None),
        "services_other_loc_attended_ec_less_10_hrs":  (1228, None),
        "separate_class":      (5020, 37.35),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    ("disability", "emotional_disturbance"): {
        "ec_program_10plus_hrs":                       (0, None),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
        "separate_class":      (0, 0.00),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("disability", "hearing_impairment"): {
        "ec_program_10plus_hrs":                       (0, None),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
        "separate_class":      (0, 0.00),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
    },
    ("disability", "intellectual_disability"): {
        "ec_program_10plus_hrs":                       (0, None),
        "services_other_loc_attended_ec_10plus_hrs":   (0, None),
        "ec_program_less_10_hrs":                      (0, None),
        "services_other_loc_attended_ec_less_10_hrs":  (0, None),
        "separate_class":      (0, 0.00),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
    },
    ("disability", "multiple_disabilities"): {
        "ec_program_10plus_hrs":                       (None, None),
        "services_other_loc_attended_ec_10plus_hrs":   (None, 0.00),
        "ec_program_less_10_hrs":                      (None, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
        "separate_class":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
    },
    ("disability", "other_health_impairment"): {
        "ec_program_10plus_hrs":                       (10, None),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (0, None),
        "separate_class":      (None, None),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("disability", "orthopedic_impairment"): {
        "ec_program_10plus_hrs":                       (0, None),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
        "separate_class":      (0, 0.00),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("disability", "specific_learning_disability"): {
        "ec_program_10plus_hrs":                       (None, None),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (0, None),
        "separate_class":      (None, None),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("disability", "speech_language_impairment"): {
        "ec_program_10plus_hrs":                       (25, None),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
        "separate_class":      (None, None),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("disability", "traumatic_brain_injury"): {
        "ec_program_10plus_hrs":                       (0, None),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
        "separate_class":      (0, 0.00),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("disability", "visual_impairment"): {
        "ec_program_10plus_hrs":                       (0, None),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
        "separate_class":      (0, 0.00),
        "separate_school":     (0, 0.00),
        "residential_facility":(0, 0.00),
    },
    ("disability", "total"): {
        "ec_program_10plus_hrs":                       (5513, None),
        "services_other_loc_attended_ec_10plus_hrs":   (603, None),
        "ec_program_less_10_hrs":                      (554, None),
        "services_other_loc_attended_ec_less_10_hrs":  (1235, None),
        "separate_class":      (5051, 37.58),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    # ----- English Learner -----
    ("multilingual_learner", "lep"): {
        "ec_program_10plus_hrs":                       (188, 1.40),
        "services_other_loc_attended_ec_10plus_hrs":   (13, 0.10),
        "ec_program_less_10_hrs":                      (24, 0.18),
        "services_other_loc_attended_ec_less_10_hrs":  (16, 0.12),
        "separate_class":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
    },
    ("multilingual_learner", "non_lep"): {
        "ec_program_10plus_hrs":                       (5325, 39.62),
        "services_other_loc_attended_ec_10plus_hrs":   (590, 4.39),
        "ec_program_less_10_hrs":                      (530, 3.94),
        "services_other_loc_attended_ec_less_10_hrs":  (1219, 9.07),
        "separate_class":      (4993, 37.15),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
    ("multilingual_learner", "total"): {
        "ec_program_10plus_hrs":                       (5513, 41.02),
        "services_other_loc_attended_ec_10plus_hrs":   (603, 4.49),
        "ec_program_less_10_hrs":                      (554, 4.12),
        "services_other_loc_attended_ec_less_10_hrs":  (1235, 9.19),
        "separate_class":      (5051, 37.58),
        "separate_school":     (None, None),
        "residential_facility":(None, None),
    },
}

TOTALS_2021_3_5 = {
    ("racial_ethnic", "white"):              3359 + 2409,
    ("racial_ethnic", "hispanic"):           2875 + 1686,
    ("racial_ethnic", "black"):              840 + 627,
    ("racial_ethnic", "asian"):              585 + 569,
    ("racial_ethnic", "multiracial"):        213 + 187,
    ("racial_ethnic", "native_american"):    16 + 11,
    ("racial_ethnic", "pacific_islander"):   17 + 10,
    ("racial_ethnic", "total"):              7905 + 5499,
    ("gender", "male"):                      5566 + 4050,
    ("gender", "female"):                    2339 + 1449,
    ("gender", "total"):                     7905 + 5499,
    ("disability", "autism"):                24 + 20,
    ("disability", "deaf_blindness"):        0 + 0,
    ("disability", "developmental_delay"):   7827 + 5457,
    ("disability", "emotional_disturbance"): 0 + 0,
    ("disability", "hearing_impairment"):    0,  # Reg = 0, Sep = "*"
    ("disability", "intellectual_disability"): 0,  # Reg = 0, Sep = "*"
    ("disability", "multiple_disabilities"): 12,  # Reg "*", Sep 12
    ("disability", "other_health_impairment"): 14,  # Reg 14, Sep "*"
    ("disability", "orthopedic_impairment"): 0 + 0,
    ("disability", "specific_learning_disability"): None,  # Reg "*", Sep "*"
    ("disability", "speech_language_impairment"): 28,  # Reg 28, Sep "*"
    ("disability", "traumatic_brain_injury"): 0 + 0,
    ("disability", "visual_impairment"):     0 + 0,
    ("disability", "total"):                 7905 + 5499,
    ("multilingual_learner", "lep"):         241 + 59,
    ("multilingual_learner", "non_lep"):     7664 + 5440,
    ("multilingual_learner", "total"):       7905 + 5499,
}


# =============================================================================
# 2022 5-21 (ey2022_5_21_Placement.pdf)
# =============================================================================
# Page 1 (Regular Education) interleaves counts and percents. Lines:
#   Race: 19-26; Gender: 37-39; Disability: 50-63; LEP Status: 74-76.
# Page 2 (Separate Settings) lines:
#   Race: 91-98; Gender: 105-107; Disability: 113-126; LEP Status: 133-135.
#
# ANOMALY: Page 2 LEP Status values exactly duplicate page 2 Gender values
# (EL=3705/Non-EL=9255 == Female=3705/Male=9255), with Total row 12960/5.75
# matching the Gender Total row. This is a NJ DOE copy-paste error in the
# source PDF; we transcribe what the PDF prints and document.

ROWS_2022_5_21 = {
    # ----- Race -----
    ("racial_ethnic", "white"): {
        "gen_ed_80_plus":      (50987, 22.63),
        "gen_ed_40_79":        (26786, 11.89),
        "gen_ed_less_40":      (9954, 4.42),
        "separate_school":     (5924, 2.63),
        "residential_facility":(147, 0.07),
        "homebound_hospital":  (253, 0.11),
    },
    ("racial_ethnic", "hispanic"): {
        "gen_ed_80_plus":      (27809, 12.34),
        "gen_ed_40_79":        (21700, 9.63),
        "gen_ed_less_40":      (13733, 6.09),
        "separate_school":     (3149, 1.40),
        "residential_facility":(52, 0.02),
        "homebound_hospital":  (155, 0.07),
    },
    ("racial_ethnic", "black"): {
        "gen_ed_80_plus":      (13154, 5.84),
        "gen_ed_40_79":        (11227, 4.98),
        "gen_ed_less_40":      (8100, 3.59),
        "separate_school":     (2751, 1.22),
        "residential_facility":(62, 0.03),
        "homebound_hospital":  (70, 0.03),
    },
    ("racial_ethnic", "asian"): {
        "gen_ed_80_plus":      (4623, 2.05),
        "gen_ed_40_79":        (2428, 1.08),
        "gen_ed_less_40":      (2168, 0.96),
        "separate_school":     (760, 0.34),
        "residential_facility":(21, 0.01),
        "homebound_hospital":  (26, 0.01),
    },
    ("racial_ethnic", "multiracial"): {
        "gen_ed_80_plus":      (2748, 1.22),
        "gen_ed_40_79":        (1673, 0.74),
        "gen_ed_less_40":      (788, 0.35),
        "separate_school":     (334, 0.15),
        "residential_facility":(None, None),
        "homebound_hospital":  (14, 0.01),
    },
    ("racial_ethnic", "native_american"): {
        "gen_ed_80_plus":      (125, 0.06),
        "gen_ed_40_79":        (97, 0.04),
        "gen_ed_less_40":      (78, 0.03),
        "separate_school":     (19, 0.01),
        "residential_facility":(0, 0.00),
        "homebound_hospital":  (0, 0.00),
    },
    ("racial_ethnic", "pacific_islander"): {
        "gen_ed_80_plus":      (140, 0.06),
        "gen_ed_40_79":        (116, 0.05),
        "gen_ed_less_40":      (69, 0.03),
        "separate_school":     (23, 0.01),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("racial_ethnic", "total"): {
        "gen_ed_80_plus":      (99586, 44.20),
        "gen_ed_40_79":        (64027, 28.41),
        "gen_ed_less_40":      (34890, 15.47),
        "separate_school":     (12960, 5.76),
        "residential_facility":(292, 0.13),
        "homebound_hospital":  (520, 0.23),
    },
    # ----- Gender -----
    ("gender", "female"): {
        "gen_ed_80_plus":      (35243, 15.64),
        "gen_ed_40_79":        (22195, 9.85),
        "gen_ed_less_40":      (10279, 4.56),
        "separate_school":     (3705, 1.64),
        "residential_facility":(90, 0.04),
        "homebound_hospital":  (212, 0.09),
    },
    ("gender", "male"): {
        "gen_ed_80_plus":      (64343, 28.55),
        "gen_ed_40_79":        (41832, 18.56),
        "gen_ed_less_40":      (24611, 10.92),
        "separate_school":     (9255, 4.11),
        "residential_facility":(202, 0.09),
        "homebound_hospital":  (308, 0.14),
    },
    ("gender", "total"): {
        "gen_ed_80_plus":      (99586, 44.19),
        "gen_ed_40_79":        (64027, 28.41),
        "gen_ed_less_40":      (34890, 15.48),
        "separate_school":     (12960, 5.75),
        "residential_facility":(292, 0.13),
        "homebound_hospital":  (520, 0.23),
    },
    # ----- Disability -----
    ("disability", "autism"): {
        "gen_ed_80_plus":      (5403, 2.40),
        "gen_ed_40_79":        (5438, 2.41),
        "gen_ed_less_40":      (9457, 4.20),
        "separate_school":     (4437, 1.97),
        "residential_facility":(74, 0.03),
        "homebound_hospital":  (71, 0.03),
    },
    ("disability", "deaf_blindness"): {
        "gen_ed_80_plus":      (None, None),
        "gen_ed_40_79":        (None, None),
        "gen_ed_less_40":      (None, None),
        "separate_school":     (None, None),
        "residential_facility":(0, 0.00),
        "homebound_hospital":  (0, 0.00),
    },
    ("disability", "developmental_delay"): {
        "gen_ed_80_plus":      (61, 0.03),
        "gen_ed_40_79":        (16, 0.01),
        "gen_ed_less_40":      (24, 0.01),
        "separate_school":     (13, 0.01),
        "residential_facility":(0, 0.00),
        "homebound_hospital":  (0, 0.00),
    },
    ("disability", "emotional_disturbance"): {
        "gen_ed_80_plus":      (2260, 1.00),
        "gen_ed_40_79":        (1564, 0.69),
        "gen_ed_less_40":      (991, 0.44),
        "separate_school":     (1412, 0.63),
        "residential_facility":(47, 0.02),
        "homebound_hospital":  (68, 0.03),
    },
    ("disability", "hearing_impairment"): {
        "gen_ed_80_plus":      (653, 0.29),
        "gen_ed_40_79":        (278, 0.12),
        "gen_ed_less_40":      (164, 0.07),
        "separate_school":     (202, 0.09),
        "residential_facility":(None, None),
        "homebound_hospital":  (None, None),
    },
    ("disability", "intellectual_disability"): {
        "gen_ed_80_plus":      (400, 0.18),
        "gen_ed_40_79":        (1680, 0.75),
        "gen_ed_less_40":      (2680, 1.19),
        "separate_school":     (528, 0.23),
        "residential_facility":(None, 0.00),
        "homebound_hospital":  (14, 0.01),
    },
    ("disability", "multiple_disabilities"): {
        "gen_ed_80_plus":      (1791, 0.79),
        "gen_ed_40_79":        (3109, 1.38),
        "gen_ed_less_40":      (3580, 1.59),
        "separate_school":     (3847, 1.71),
        "residential_facility":(94, 0.04),
        "homebound_hospital":  (158, 0.07),
    },
    ("disability", "orthopedic_impairment"): {
        "gen_ed_80_plus":      (172, 0.08),
        "gen_ed_40_79":        (53, 0.02),
        "gen_ed_less_40":      (27, 0.01),
        "separate_school":     (16, 0.01),
        "residential_facility":(0, 0.00),
        "homebound_hospital":  (None, 0.00),
    },
    ("disability", "other_health_impairment"): {
        "gen_ed_80_plus":      (25258, 11.21),
        "gen_ed_40_79":        (15490, 6.87),
        "gen_ed_less_40":      (5127, 2.28),
        "separate_school":     (1826, 0.81),
        "residential_facility":(49, 0.02),
        "homebound_hospital":  (139, 0.06),
    },
    ("disability", "specific_learning_disability"): {
        "gen_ed_80_plus":      (34438, 15.28),
        "gen_ed_40_79":        (25454, 11.30),
        "gen_ed_less_40":      (6216, 2.76),
        "separate_school":     (353, 0.16),
        "residential_facility":(None, 0.00),
        "homebound_hospital":  (42, 0.02),
    },
    ("disability", "speech_language_impairment"): {
        "gen_ed_80_plus":      (28858, 12.81),
        "gen_ed_40_79":        (10756, 4.77),
        "gen_ed_less_40":      (6508, 2.89),
        "separate_school":     (232, 0.10),
        "residential_facility":(None, 0.00),
        "homebound_hospital":  (13, 0.01),
    },
    ("disability", "traumatic_brain_injury"): {
        "gen_ed_80_plus":      (91, 0.04),
        "gen_ed_40_79":        (103, 0.05),
        "gen_ed_less_40":      (73, 0.03),
        "separate_school":     (63, 0.03),
        "residential_facility":(None, 0.00),
        "homebound_hospital":  (12, 0.01),
    },
    ("disability", "visual_impairment"): {
        "gen_ed_80_plus":      (196, 0.09),
        "gen_ed_40_79":        (83, 0.04),
        "gen_ed_less_40":      (39, 0.02),
        "separate_school":     (22, 0.01),
        "residential_facility":(0, 0.00),
        "homebound_hospital":  (0, 0.00),
    },
    ("disability", "total"): {
        "gen_ed_80_plus":      (99586, 44.20),
        "gen_ed_40_79":        (64027, 28.41),
        "gen_ed_less_40":      (34890, 15.47),
        "separate_school":     (12960, 5.76),
        "residential_facility":(292, 0.11),
        "homebound_hospital":  (520, 0.24),
    },
    # ----- English Learner -----
    # Page 2 (Separate Settings) LEP values are a copy-paste of page 2
    # Gender values per NJ DOE source-doc error. We transcribe what
    # the PDF shows.
    ("multilingual_learner", "lep"): {
        "gen_ed_80_plus":      (4197, 1.86),
        "gen_ed_40_79":        (3058, 1.36),
        "gen_ed_less_40":      (2172, 0.96),
        "separate_school":     (3705, 1.64),
        "residential_facility":(90, 0.04),
        "homebound_hospital":  (212, 0.09),
    },
    ("multilingual_learner", "non_lep"): {
        "gen_ed_80_plus":      (95389, 42.33),
        "gen_ed_40_79":        (60969, 27.06),
        "gen_ed_less_40":      (32718, 14.52),
        "separate_school":     (9255, 4.11),
        "residential_facility":(202, 0.09),
        "homebound_hospital":  (308, 0.14),
    },
    ("multilingual_learner", "total"): {
        "gen_ed_80_plus":      (99586, 44.19),
        "gen_ed_40_79":        (64027, 28.41),
        "gen_ed_less_40":      (34890, 15.48),
        "separate_school":     (12960, 5.75),
        "residential_facility":(292, 0.13),
        "homebound_hospital":  (520, 0.23),
    },
}

# Subgroup totals: page 1 Total column + page 2 Total column.
TOTALS_2022_5_21 = {
    ("racial_ethnic", "white"):                  87727 + 6324,
    ("racial_ethnic", "hispanic"):               63242 + 3356,
    ("racial_ethnic", "black"):                  32481 + 2883,
    ("racial_ethnic", "asian"):                  9219 + 807,
    ("racial_ethnic", "multiracial"):            5209 + 356,
    ("racial_ethnic", "native_american"):        300 + 19,
    ("racial_ethnic", "pacific_islander"):       325 + 27,
    ("racial_ethnic", "total"):                  198503 + 13772,
    ("gender", "female"):                        67717 + 4007,
    ("gender", "male"):                          130786 + 9765,
    ("gender", "total"):                         198503 + 13772,
    ("disability", "autism"):                    20298 + 4582,
    ("disability", "deaf_blindness"):            None,  # both Totals "*"
    ("disability", "developmental_delay"):       101 + 13,
    ("disability", "emotional_disturbance"):     4815 + 1527,
    ("disability", "hearing_impairment"):        1095 + 208,
    ("disability", "intellectual_disability"):   4760 + 547,
    ("disability", "multiple_disabilities"):     8480 + 4099,
    ("disability", "orthopedic_impairment"):     252 + 17,
    ("disability", "other_health_impairment"):   45875 + 2014,
    ("disability", "specific_learning_disability"): 66108 + 404,
    ("disability", "speech_language_impairment"):   46122 + 252,
    ("disability", "traumatic_brain_injury"):    267 + 78,
    ("disability", "visual_impairment"):         318 + 22,
    ("disability", "total"):                     198503 + 13772,
    ("multilingual_learner", "lep"):             9427 + 4007,
    ("multilingual_learner", "non_lep"):         189076 + 9765,
    ("multilingual_learner", "total"):           198503 + 13772,
}


# =============================================================================
# 2022 3-5 (ey2022_3_5_Placement.pdf)
# =============================================================================
# Only Regular Education page; no Separate Settings page in this PDF.
# Page 1 (Race + Gender + Disability) lines:
#   Race: 24-34; Gender: 48-50; Disability: 64-77.
# Page 2 (LEP Status) lines: 96-98.

ROWS_2022_3_5 = {
    # ----- Race -----
    ("racial_ethnic", "white"): {
        "ec_program_10plus_hrs":                       (2391, 18.34),
        "services_other_loc_attended_ec_10plus_hrs":   (198, 1.52),
        "ec_program_less_10_hrs":                      (283, 2.17),
        "services_other_loc_attended_ec_less_10_hrs":  (423, 3.24),
    },
    ("racial_ethnic", "hispanic"): {
        "ec_program_10plus_hrs":                       (1847, 14.17),
        "services_other_loc_attended_ec_10plus_hrs":   (156, 1.20),
        "ec_program_less_10_hrs":                      (226, 1.73),
        "services_other_loc_attended_ec_less_10_hrs":  (396, 3.04),
    },
    ("racial_ethnic", "black"): {
        "ec_program_10plus_hrs":                       (496, 3.80),
        "services_other_loc_attended_ec_10plus_hrs":   (55, 0.42),
        "ec_program_less_10_hrs":                      (86, 0.66),
        "services_other_loc_attended_ec_less_10_hrs":  (154, 1.18),
    },
    ("racial_ethnic", "asian"): {
        "ec_program_10plus_hrs":                       (299, 2.29),
        "services_other_loc_attended_ec_10plus_hrs":   (89, 0.68),
        "ec_program_less_10_hrs":                      (34, 0.26),
        "services_other_loc_attended_ec_less_10_hrs":  (92, 0.71),
    },
    ("racial_ethnic", "multiracial"): {
        "ec_program_10plus_hrs":                       (153, 1.17),
        "services_other_loc_attended_ec_10plus_hrs":   (15, 0.12),
        "ec_program_less_10_hrs":                      (17, 0.13),
        "services_other_loc_attended_ec_less_10_hrs":  (23, 0.18),
    },
    ("racial_ethnic", "native_american"): {
        "ec_program_10plus_hrs":                       (14, 0.11),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
    },
    ("racial_ethnic", "pacific_islander"): {
        "ec_program_10plus_hrs":                       (21, 0.16),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (12, 0.09),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
    },
    ("racial_ethnic", "total"): {
        "ec_program_10plus_hrs":                       (5221, 40.24),
        "services_other_loc_attended_ec_10plus_hrs":   (517, 3.98),
        "ec_program_less_10_hrs":                      (659, 5.05),
        "services_other_loc_attended_ec_less_10_hrs":  (1098, 8.43),
    },
    # ----- Gender -----
    ("gender", "female"): {
        "ec_program_10plus_hrs":                       (1585, 12.16),
        "services_other_loc_attended_ec_10plus_hrs":   (137, 1.05),
        "ec_program_less_10_hrs":                      (209, 1.60),
        "services_other_loc_attended_ec_less_10_hrs":  (286, 2.19),
    },
    ("gender", "male"): {
        "ec_program_10plus_hrs":                       (3636, 27.89),
        "services_other_loc_attended_ec_10plus_hrs":   (380, 2.91),
        "ec_program_less_10_hrs":                      (450, 3.45),
        "services_other_loc_attended_ec_less_10_hrs":  (812, 6.23),
    },
    ("gender", "total"): {
        "ec_program_10plus_hrs":                       (5221, 40.05),
        "services_other_loc_attended_ec_10plus_hrs":   (517, 3.96),
        "ec_program_less_10_hrs":                      (659, 5.05),
        "services_other_loc_attended_ec_less_10_hrs":  (1098, 8.42),
    },
    # ----- Disability -----
    ("disability", "autism"): {
        "ec_program_10plus_hrs":                       (18, 0.14),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
    },
    ("disability", "developmental_delay"): {
        "ec_program_10plus_hrs":                       (5131, 39.35),
        "services_other_loc_attended_ec_10plus_hrs":   (512, 3.93),
        "ec_program_less_10_hrs":                      (646, 4.95),
        "services_other_loc_attended_ec_less_10_hrs":  (1086, 8.33),
    },
    ("disability", "emotional_disturbance"): {
        "ec_program_10plus_hrs":                       (0, 0.00),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
    },
    ("disability", "hearing_impairment"): {
        "ec_program_10plus_hrs":                       (None, None),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
    },
    ("disability", "intellectual_disability"): {
        "ec_program_10plus_hrs":                       (0, 0.00),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (0, 0.00),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
    },
    ("disability", "multiple_disabilities"): {
        "ec_program_10plus_hrs":                       (None, None),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
    },
    ("disability", "orthopedic_impairment"): {
        "ec_program_10plus_hrs":                       (0, 0.00),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (0, 0.00),
    },
    ("disability", "other_health_impairment"): {
        "ec_program_10plus_hrs":                       (22, 0.17),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
    },
    ("disability", "specific_learning_disability"): {
        "ec_program_10plus_hrs":                       (15, 0.12),
        "services_other_loc_attended_ec_10plus_hrs":   (0, 0.00),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
    },
    ("disability", "speech_language_impairment"): {
        "ec_program_10plus_hrs":                       (31, 0.24),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (None, None),
        "services_other_loc_attended_ec_less_10_hrs":  (None, None),
    },
    ("disability", "total"): {
        "ec_program_10plus_hrs":                       (5221, 40.06),
        "services_other_loc_attended_ec_10plus_hrs":   (517, 3.97),
        "ec_program_less_10_hrs":                      (659, 5.06),
        "services_other_loc_attended_ec_less_10_hrs":  (1098, 8.43),
    },
    # ----- LEP -----
    ("multilingual_learner", "lep"): {
        "ec_program_10plus_hrs":                       (187, 1.43),
        "services_other_loc_attended_ec_10plus_hrs":   (None, None),
        "ec_program_less_10_hrs":                      (12, 0.09),
        "services_other_loc_attended_ec_less_10_hrs":  (32, 0.25),
    },
    ("multilingual_learner", "non_lep"): {
        "ec_program_10plus_hrs":                       (5034, 38.61),
        "services_other_loc_attended_ec_10plus_hrs":   (512, 3.93),
        "ec_program_less_10_hrs":                      (647, 4.96),
        "services_other_loc_attended_ec_less_10_hrs":  (1066, 8.18),
    },
    ("multilingual_learner", "total"): {
        "ec_program_10plus_hrs":                       (5221, 40.04),
        "services_other_loc_attended_ec_10plus_hrs":   (517, 3.97),
        "ec_program_less_10_hrs":                      (659, 5.05),
        "services_other_loc_attended_ec_less_10_hrs":  (1098, 8.43),
    },
}

# Per-subgroup totals from the Total column on page 1 (and page 2 for LEP).
TOTALS_2022_3_5 = {
    ("racial_ethnic", "white"):              3295,
    ("racial_ethnic", "hispanic"):           2625,
    ("racial_ethnic", "black"):              791,
    ("racial_ethnic", "asian"):              514,
    ("racial_ethnic", "multiracial"):        208,
    ("racial_ethnic", "native_american"):    19,
    ("racial_ethnic", "pacific_islander"):   43,
    ("racial_ethnic", "total"):              7495,
    ("gender", "female"):                    2217,
    ("gender", "male"):                      5278,
    ("gender", "total"):                     7495,
    ("disability", "autism"):                23,
    ("disability", "developmental_delay"):   7375,
    ("disability", "emotional_disturbance"): None,  # Total "*"
    ("disability", "hearing_impairment"):    None,  # Total "*"
    ("disability", "intellectual_disability"): None,  # Total "*"
    ("disability", "multiple_disabilities"): None,  # Total "*"
    ("disability", "orthopedic_impairment"): None,  # Total "*"
    ("disability", "other_health_impairment"): 27,
    ("disability", "specific_learning_disability"): 18,
    ("disability", "speech_language_impairment"): 41,
    ("disability", "total"):                 7495,
    ("multilingual_learner", "lep"):         236,
    ("multilingual_learner", "non_lep"):     7259,
    ("multilingual_learner", "total"):       7495,
}


# -----------------------------------------------------------------------------
# Slice definitions: environments emitted in order + notes for source JSON
# -----------------------------------------------------------------------------

ENVS_5_21 = [
    "gen_ed_80_plus", "gen_ed_40_79", "gen_ed_less_40",
    "separate_school", "residential_facility", "homebound_hospital",
]

ENVS_3_5_FULL = [
    "ec_program_10plus_hrs",
    "services_other_loc_attended_ec_10plus_hrs",
    "ec_program_less_10_hrs",
    "services_other_loc_attended_ec_less_10_hrs",
    "separate_class",
    "separate_school",
    "residential_facility",
]

ENVS_3_5_REGULAR_ONLY = [
    "ec_program_10plus_hrs",
    "services_other_loc_attended_ec_10plus_hrs",
    "ec_program_less_10_hrs",
    "services_other_loc_attended_ec_less_10_hrs",
]


SLICES = {
    (2020, "5-21"): {
        "rows": ROWS_2020_5_21,
        "totals": TOTALS_2020_5_21,
        "envs": ENVS_5_21,
        "envs_omitted": ["correction_facility"],
        "omitted_reason": (
            "Not reported in source PDF (PDF predates correctional-facility "
            "environment in NJ DOE reporting)."
        ),
        "pdf": "ey2020_6_21_Placement.pdf",
        "notes": [
            "Source PDF does not include a Correctional Facility environment "
            "column; the package's canonical 5-21 schema includes "
            "correction_facility, but it is omitted here to faithfully reflect "
            "the PDF.",
            "deaf_blindness Separate Settings Total is suppressed (printed as "
            "'*'); subgroup_total reflects the Regular Education page Total "
            "only (10).",
            "The 2020 source PDF does not explicitly document the suppression "
            "threshold. Several subgroup rows have published Totals that "
            "exceed visible-cell-sum + 9 x suppressed-cell-count (e.g. Race "
            "Two-or-more-races Separate Settings Total = 330 with visible 304 "
            "and only two suppressed cells, implying hidden values up to 26; "
            "Disability Traumatic-Brain-Injury Regular Total = 333 with "
            "visible 118 and two suppressed cells). The fidelity report "
            "FLAGGED status records these per-row discrepancies; we transcribe "
            "the PDF as published.",
        ],
    },
    (2020, "3-5"): {
        "rows": ROWS_2020_3_5,
        "totals": TOTALS_2020_3_5,
        "envs": ENVS_3_5_FULL,
        "envs_omitted": [],
        "omitted_reason": None,
        "pdf": "ey2020_3-5_Placement.pdf",
        "notes": [
            "Disability subgroup 'Developmental' in the source PDF is "
            "normalised to developmental_delay in this CSV.",
            "Several disability subgroup_total cells are suppressed on either "
            "or both pages; when only one of the two Totals is visible the "
            "subgroup_total reflects the visible page only; when both are "
            "suppressed subgroup_total is empty (NA).",
            "The 2020 source PDF does not explicitly document the suppression "
            "threshold. Many subgroup rows have published Totals on the "
            "Special Education page that exceed visible-cell-sum + 9 x "
            "suppressed-cell-count -- e.g. Race White Separate Settings Total "
            "= 2583 with visible 2305 and two suppressed cells implies hidden "
            "values summing to 278, far above the 9-per-cell '<10' threshold "
            "asserted in the 2022 PDFs. The fidelity report FLAGGED status "
            "records these per-row discrepancies; we transcribe the PDF as "
            "published.",
        ],
    },
    (2021, "5-21"): {
        "rows": ROWS_2021_5_21,
        "totals": TOTALS_2021_5_21,
        "envs": ENVS_5_21,
        "envs_omitted": ["correction_facility"],
        "omitted_reason": (
            "Not reported in source PDF (PDF predates correctional-facility "
            "environment in NJ DOE reporting)."
        ),
        "pdf": "ey2021_5_21_Placement.pdf",
        "notes": [
            "NJ DOE source-doc error: the Regular Education page disability "
            "percent table (PDF page 3) is misaligned. The percent table is "
            "missing a row for 'Preschool Disabled (DD)' and the surviving "
            "rows do not match the count table (e.g. the 'Hearing Impairment' "
            "percent row prints 1.00/0.72/0.49, which are the percents of "
            "Other Health Impairment counts 25519/15536/5409). For every "
            "disability row on the Regular Education page we emit percent = "
            "NA. The Separate Settings disability percent table on PDF page 5 "
            "is correctly aligned and is transcribed verbatim.",
            "Race/Ethnicity Total row count values for Total environment "
            "render as Excel scientific notation ('2E+05', '1E+05') in the "
            "source PDF; the integer Total values are reconstructed by "
            "summing visible per-subgroup counts (199594 for the Regular "
            "Education page, 14816 for the Separate Settings page).",
            "deaf_blindness Separate Settings Total is suppressed ('*'); "
            "subgroup_total reflects the Regular Education page Total only "
            "(12).",
            "The 2021 source PDF does not explicitly document the suppression "
            "threshold. A few disability subgroup rows have published Totals "
            "that exceed visible-cell-sum + 9 x suppressed-cell-count (e.g. "
            "Hearing Impairment Separate Settings Total = 242 with visible 0 "
            "and two suppressed cells; Speech or Language Impairment Separate "
            "Settings Total = 274 with visible 253 and two suppressed cells; "
            "Visual Impairment Separate Settings Total = 23 with visible 0 "
            "and two suppressed cells). The fidelity report FLAGGED status "
            "records these per-row discrepancies; we transcribe the PDF as "
            "published.",
        ],
    },
    (2021, "3-5"): {
        "rows": ROWS_2021_3_5,
        "totals": TOTALS_2021_3_5,
        "envs": ENVS_3_5_FULL,
        "envs_omitted": [],
        "omitted_reason": None,
        "pdf": "ey2021_3-5_Placement.pdf",
        "notes": [
            "NJ DOE source-doc error #1 (Race count table on Regular "
            "Education page): column 4 ('services_other_loc_attended_ec_"
            "less_10_hrs') is corrupted in the source PDF -- column-4 cells "
            "are mis-rendered as duplicates of column 2 for every Race row. "
            "E.g. the White row prints 2361, 231, 259, 231, 3359 in the PDF "
            "but 2361+231+259+231 = 3082 != 3359 (the published Total). "
            "The Disability and LEP tables on the same page have correctly-"
            "rendered column-4 values (Disability Total = 5513, 603, 554, "
            "1235, 7905 sums correctly). Because the Race column-4 values "
            "in the PDF are unreliable, we emit count = NA for every Race "
            "row's services_other_loc_attended_ec_less_10_hrs cell. The "
            "true column-4 Total (1235) is recoverable from the Disability "
            "Total row on the same page but we leave the Race row NA to "
            "avoid mixing sources.",
            "NJ DOE source-doc error #2 (Disability percent table on "
            "Regular Education page): column 4 of the Regular Education "
            "page disability percent table duplicates column 1 (e.g. "
            "Developmental Delay shows 40.60 in both columns; the correct "
            "value implied by count 1228 is ~9.13). Because this casts "
            "doubt on every cell of that table we emit percent = NA for "
            "every disability row on the Regular Education page. Counts "
            "are transcribed verbatim.",
            "Disability subgroup 'Developmental' in the source PDF is "
            "normalised to developmental_delay in this CSV.",
            "Gender table on the Special Education page (PDF page 2) "
            "renders 'Separate School' and 'Residential Facility' columns "
            "as stray '*' tokens for all gender rows; we record the visible "
            "'Separate Special Education Class' values and emit the other "
            "two envs as NA.",
        ],
    },
    (2022, "5-21"): {
        "rows": ROWS_2022_5_21,
        "totals": TOTALS_2022_5_21,
        "envs": ENVS_5_21,
        "envs_omitted": ["correction_facility"],
        "omitted_reason": (
            "Not reported in source PDF."
        ),
        "pdf": "ey2022_5_21_Placement.pdf",
        "notes": [
            "NJ DOE source-doc error: on PDF page 2 (Separate Settings) the LEP "
            "Status table prints English Learner = 3705 / Non-English Learner "
            "= 9255 -- identical to the Female = 3705 / Male = 9255 row on the "
            "same page's Gender table, and with the same Total row "
            "(12960/292/520). This appears to be a copy-paste of the Gender "
            "values into the LEP rows. We transcribe what the PDF prints and "
            "flag the anomaly here; downstream consumers should compare "
            "against the Regular Education page LEP values (page 1, EL = 9427 "
            "across the three Regular environments) for sanity-checking.",
            "deaf_blindness Total is suppressed on both pages; subgroup_total "
            "is empty (NA).",
        ],
    },
    (2022, "3-5"): {
        "rows": ROWS_2022_3_5,
        "totals": TOTALS_2022_3_5,
        "envs": ENVS_3_5_REGULAR_ONLY,
        "envs_omitted": ["separate_class", "separate_school", "residential_facility"],
        "omitted_reason": (
            "The 2022 3-5 source PDF does not include a Separate Settings "
            "page; only Regular Education environments are reported."
        ),
        "pdf": "ey2022_3_5_Placement.pdf",
        "notes": [
            "Source PDF contains only Regular Education environments (page 1 + "
            "page 2 LEP); there is no Separate Settings page. All separate-"
            "setting environments (separate_class, separate_school, "
            "residential_facility) are omitted from the CSV.",
            "Several disability subgroup_total cells are suppressed (printed "
            "as '*'); subgroup_total is empty (NA) for those rows.",
        ],
    },
}


# -----------------------------------------------------------------------------
# Writers
# -----------------------------------------------------------------------------

DIMENSION_ORDER = ["racial_ethnic", "gender", "disability", "multilingual_learner"]

# Within-dimension subgroup order: emit in the order observed in the PDFs,
# with `total` last.
SUBGROUP_ORDER = {
    "racial_ethnic": [
        "white", "hispanic", "black", "asian",
        "multiracial", "native_american", "pacific_islander", "total",
    ],
    "gender": ["female", "male", "total"],
    "disability": [
        "autism", "deaf_blindness", "preschool_disability", "developmental_delay",
        "emotional_disturbance", "hearing_impairment", "intellectual_disability",
        "multiple_disabilities", "orthopedic_impairment",
        "other_health_impairment", "specific_learning_disability",
        "speech_language_impairment", "traumatic_brain_injury",
        "visual_impairment", "total",
    ],
    "multilingual_learner": ["lep", "non_lep", "total"],
}


def fmt_count(v):
    if v is None:
        return ""
    return str(int(v))


def fmt_percent(v):
    if v is None:
        return ""
    # The PDF prints at most 2 decimal places. Use 'g' to drop trailing zeros
    # but preserve precision faithfully (e.g. 23.66 stays 23.66, 1 stays 1).
    s = f"{v:.4f}".rstrip("0").rstrip(".")
    if s == "":
        s = "0"
    return s


def fmt_total(v):
    if v is None:
        return ""
    return str(int(v))


def emit_csv(end_year: int, age_group: str, slice_def: dict) -> Path:
    rows = slice_def["rows"]
    totals = slice_def["totals"]
    envs = slice_def["envs"]

    out_rows: list[list[str]] = []
    for dim in DIMENSION_ORDER:
        # Subset relevant subgroups for this slice
        present = [(d, sg) for (d, sg) in rows if d == dim]
        if not present:
            continue
        order = SUBGROUP_ORDER[dim]
        # Skip subgroups not actually in the slice
        ordered_sg = [sg for sg in order if (dim, sg) in rows]
        for sg in ordered_sg:
            envrows = rows[(dim, sg)]
            sgt = totals.get((dim, sg))
            for env in envs:
                if env not in envrows:
                    # env absent from this slice's per-row dict -> skip
                    continue
                count, pct = envrows[env]
                out_rows.append([
                    dim, sg, env,
                    fmt_count(count), fmt_percent(pct), fmt_total(sgt),
                ])

    out_path = OUT_DIR / f"{end_year}_{age_group}_state.csv"
    with out_path.open("w", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow([
            "dimension", "subgroup", "environment",
            "count", "percent", "subgroup_total",
        ])
        w.writerows(out_rows)
    return out_path


def emit_source_json(end_year: int, age_group: str, slice_def: dict,
                     pdf_sha: str, now_iso: str) -> Path:
    pdf_fname = slice_def["pdf"]
    pdf_meta = PDF_META[pdf_fname]
    out_path = OUT_DIR / f"{end_year}_{age_group}_state_source.json"
    data = {
        "end_year": end_year,
        "age_group": age_group,
        "level": "state",
        "pdf_filename": pdf_meta["label"],
        "pdf_url": pdf_meta["pdf_url"],
        "pdf_sha256": pdf_sha,
        "transcribed_at": now_iso,
        "transcriber": "njschooldata maintainer (PR #279 amendment)",
        "extraction_tool": (
            "data-raw/transcribe-sped-placement-pdfs.py via poppler "
            "pdftotext -layout"
        ),
        "environments_present": slice_def["envs"],
        "environments_omitted": slice_def["envs_omitted"],
        "omitted_reason": slice_def["omitted_reason"] or "",
        "notes": slice_def["notes"],
    }
    with out_path.open("w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    return out_path


# -----------------------------------------------------------------------------
# Fidelity report
# -----------------------------------------------------------------------------

def fidelity_lines(end_year: int, age_group: str, slice_def: dict) -> list[str]:
    """For each subgroup, sum visible count cells across emitted envs and
    compare to reported subgroup_total. Report suppressed cell count.

    For 5-21 slices that omit correction_facility but report the
    subgroup-row Total only across the visible envs, sum match should
    hold exactly when there are no suppressed cells.
    """
    rows = slice_def["rows"]
    totals = slice_def["totals"]
    envs = slice_def["envs"]
    lines = []
    lines.append(f"--- {end_year} {age_group} state ---")
    n_total_suppressed = 0
    n_flagged = 0
    n_ok = 0
    for dim in DIMENSION_ORDER:
        ordered_sg = [sg for sg in SUBGROUP_ORDER[dim] if (dim, sg) in rows]
        for sg in ordered_sg:
            envrows = rows[(dim, sg)]
            sgt = totals.get((dim, sg))
            visible_sum = 0
            n_suppressed = 0
            for env in envs:
                if env not in envrows:
                    continue
                c, _ = envrows[env]
                if c is None:
                    n_suppressed += 1
                else:
                    visible_sum += c
            if sgt is None:
                status = "TOTAL_SUPPRESSED"
                diff_str = ""
                # Each suppressed cell can hide up to 9 (since suppression
                # means cell size < 10).
                max_hidden = n_suppressed * 9
                lines.append(
                    f"  {dim:<22s} {sg:<32s} "
                    f"vis_sum={visible_sum:>6d} total=NA suppressed={n_suppressed}  "
                    f"(<= {max_hidden} hidden)  [{status}]"
                )
                n_total_suppressed += 1
                continue
            diff = sgt - visible_sum
            max_hidden = n_suppressed * 9
            if diff == 0 and n_suppressed == 0:
                status = "OK"
                n_ok += 1
            elif diff >= 0 and diff <= max_hidden:
                status = "OK (within suppression)"
                n_ok += 1
            else:
                status = "FLAGGED"
                n_flagged += 1
            diff_str = f"diff={diff:+d}"
            lines.append(
                f"  {dim:<22s} {sg:<32s} "
                f"vis_sum={visible_sum:>6d} total={sgt:>6d} "
                f"{diff_str} suppressed={n_suppressed} (<= {max_hidden} hidden)  [{status}]"
            )
    lines.append(
        f"  summary: ok={n_ok} flagged={n_flagged} "
        f"total_suppressed={n_total_suppressed}"
    )
    return lines


# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

def main() -> int:
    # 1. Re-extract text dumps (idempotent; supports `-skip-extract`)
    if "--skip-extract" not in sys.argv:
        try:
            regenerate_text_dumps()
        except FileNotFoundError:
            print(
                "WARN: pdftotext not on PATH; using existing .txt dumps.",
                file=sys.stderr,
            )

    # 2. Hash PDFs (for the audit-trail JSONs)
    shas = {fname: sha256_file(DUMP_DIR / fname) for fname in PDF_META}

    # 3. Emit CSVs + source JSONs
    now = _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    written = []
    fid_lines = []
    summary_rows = []
    for (yr, ag), sdef in SLICES.items():
        sha = shas[sdef["pdf"]]
        csv_path = emit_csv(yr, ag, sdef)
        json_path = emit_source_json(yr, ag, sdef, sha, now)
        written.append(csv_path)
        written.append(json_path)
        # Track summary stats
        with csv_path.open() as f:
            n_rows = sum(1 for _ in f) - 1  # minus header
        # distinct subgroups / envs
        sgs = set()
        evs = set()
        suppressed = 0
        for (d, sg), envrows in sdef["rows"].items():
            sgs.add(sg)
            for env, (c, _p) in envrows.items():
                if env in sdef["envs"]:
                    evs.add(env)
                    if c is None:
                        suppressed += 1
        # Compute fidelity status from the report
        fid_block = fidelity_lines(yr, ag, sdef)
        fid_lines.extend(fid_block)
        fid_lines.append("")
        if any("FLAGGED" in line for line in fid_block):
            status = "FLAGGED"
        else:
            status = "OK"
        summary_rows.append((f"{yr}_{ag}_state", n_rows, len(sgs), len(evs),
                             suppressed, status))

    # 4. Save fidelity report
    FIDELITY_REPORT.write_text("\n".join(fid_lines) + "\n")

    # 5. Print summary
    print("\nFiles written:")
    for p in written:
        print(f"  {p}")
    print("\nFidelity report saved to:", FIDELITY_REPORT)
    print()
    print("Final summary:")
    print(f"  {'slice':<22s} | {'rows':>4s} | {'subgrps':>7s} | "
          f"{'envs':>4s} | {'suppr':>5s} | status")
    print("  " + "-" * 66)
    for slc, n_rows, n_sg, n_env, n_suppr, status in summary_rows:
        print(f"  {slc:<22s} | {n_rows:>4d} | {n_sg:>7d} | "
              f"{n_env:>4d} | {n_suppr:>5d} | {status}")
    print()
    print("Fidelity report:\n")
    print("\n".join(fid_lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
