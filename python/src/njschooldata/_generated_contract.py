"""Generated from the R package. Do not edit by hand."""

import json

_CONTRACT = json.loads(r'''
{
  "python_package_version": "0.9.26",
  "r_package_min_version": "0.9.26",
  "r_package_max_version": "0.10.0",
  "r_signatures": {
    "fetch_enr": {
      "parameters": ["end_year", "tidy", "use_cache"],
      "defaults": {
        "end_year": "<required>",
        "tidy": "FALSE",
        "use_cache": "FALSE"
      }
    },
    "fetch_parcc": {
      "parameters": ["end_year", "grade_or_subj", "subj", "tidy"],
      "defaults": {
        "end_year": "<required>",
        "grade_or_subj": "<required>",
        "subj": "<required>",
        "tidy": "FALSE"
      }
    },
    "fetch_access": {
      "parameters": ["end_year", "grade"],
      "defaults": {
        "end_year": "<required>",
        "grade": "\"all\""
      }
    },
    "fetch_grad_rate": {
      "parameters": ["end_year", "methodology"],
      "defaults": {
        "end_year": "<required>",
        "methodology": "\"4 year\""
      }
    },
    "get_school_directory": {
      "parameters": [],
      "defaults": []
    },
    "get_district_directory": {
      "parameters": [],
      "defaults": []
    },
    "fetch_facilities": {
      "parameters": ["category", "year", "tidy", "use_cache"],
      "defaults": {
        "category": "<required>",
        "year": "NULL",
        "tidy": "TRUE",
        "use_cache": "TRUE"
      }
    },
    "fetch_facilities_multi": {
      "parameters": ["category", "years", "tidy", "use_cache"],
      "defaults": {
        "category": "<required>",
        "years": "<required>",
        "tidy": "TRUE",
        "use_cache": "TRUE"
      }
    },
    "fetch_facility_gis": {
      "parameters": ["layer", "sf", "use_cache"],
      "defaults": {
        "layer": "\"school_points\"",
        "sf": "TRUE",
        "use_cache": "TRUE"
      }
    },
    "get_available_facilities": {
      "parameters": [],
      "defaults": []
    },
    "fetch_finance": {
      "parameters": ["end_year", "tidy", "use_cache", "with_status", "level", "allow_partial"],
      "defaults": {
        "end_year": "<required>",
        "tidy": "TRUE",
        "use_cache": "TRUE",
        "with_status": "FALSE",
        "level": "\"all\"",
        "allow_partial": "FALSE"
      }
    },
    "fetch_finance_multi": {
      "parameters": ["end_year_vector", "end_years", "tidy", "use_cache", "with_status", "level", "allow_partial"],
      "defaults": {
        "end_year_vector": "NULL",
        "end_years": "NULL",
        "tidy": "TRUE",
        "use_cache": "TRUE",
        "with_status": "FALSE",
        "level": "\"all\"",
        "allow_partial": "FALSE"
      }
    },
    "fetch_sped": {
      "parameters": ["end_year", "level", "with_status"],
      "defaults": {
        "end_year": "<required>",
        "level": "\"district\"",
        "with_status": "FALSE"
      }
    },
    "fetch_sped_placement": {
      "parameters": ["end_year", "age_group", "level", "tidy", "with_status"],
      "defaults": {
        "end_year": "<required>",
        "age_group": "\"5-21\"",
        "level": "\"district\"",
        "tidy": "TRUE",
        "with_status": "FALSE"
      }
    },
    "fetch_sped_placement_multi": {
      "parameters": ["end_years", "age_group", "level", "tidy", "with_status", "allow_partial"],
      "defaults": {
        "end_years": "<required>",
        "age_group": "\"5-21\"",
        "level": "\"district\"",
        "tidy": "TRUE",
        "with_status": "FALSE",
        "allow_partial": "FALSE"
      }
    },
    "fetch_ell": {
      "parameters": ["end_year", "tidy", "use_cache", "with_status"],
      "defaults": {
        "end_year": "<required>",
        "tidy": "TRUE",
        "use_cache": "FALSE",
        "with_status": "FALSE"
      }
    },
    "fetch_ell_multi": {
      "parameters": ["end_years", "tidy", "use_cache", "with_status", "allow_partial"],
      "defaults": {
        "end_years": "<required>",
        "tidy": "TRUE",
        "use_cache": "FALSE",
        "with_status": "FALSE",
        "allow_partial": "FALSE"
      }
    }
  },
  "source_coverage": {
    "enrollment": {
      "aliases": ["enrollment", "enr"],
      "raw_years": [1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026],
      "tidy_years": [1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026],
      "skipped_years": []
    },
    "parcc": {
      "aliases": ["parcc", "njsla"],
      "raw_years": [2015, 2016, 2017, 2018, 2019, 2022, 2023, 2024, 2025],
      "tidy_years": [2015, 2016, 2017, 2018, 2019, 2022, 2023, 2024, 2025],
      "skipped_years": [2020, 2021]
    },
    "njgpa": {
      "aliases": "njgpa",
      "raw_years": [2022, 2023, 2024, 2025],
      "tidy_years": [2022, 2023, 2024, 2025],
      "skipped_years": []
    },
    "access": {
      "aliases": ["access", "wida_access"],
      "raw_years": [2022, 2023, 2024, 2025],
      "tidy_years": [2022, 2023, 2024, 2025],
      "skipped_years": []
    },
    "grate_4yr": {
      "aliases": ["grate_4yr", "grad_rate", "graduation_rate"],
      "raw_years": [2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025],
      "tidy_years": [2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025],
      "skipped_years": []
    },
    "grate_5yr": {
      "aliases": "grate_5yr",
      "raw_years": [2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019],
      "tidy_years": [2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019],
      "skipped_years": []
    },
    "grate_6yr": {
      "aliases": ["grate_6yr", "six_year_graduation_rate"],
      "raw_years": [2021, 2022, 2023, 2024, 2025],
      "tidy_years": [2021, 2022, 2023, 2024, 2025],
      "skipped_years": []
    },
    "grad_count": {
      "aliases": ["grad_count", "gcount"],
      "raw_years": [1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025],
      "tidy_years": [2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025],
      "skipped_years": []
    },
    "njask": {
      "aliases": ["njask", "legacy_assess"],
      "raw_years": [2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014],
      "tidy_years": [2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014],
      "skipped_years": []
    },
    "hspa": {
      "aliases": "hspa",
      "raw_years": [2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014],
      "tidy_years": [2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014],
      "skipped_years": []
    },
    "gepa": {
      "aliases": "gepa",
      "raw_years": [2004, 2005, 2006, 2007],
      "tidy_years": [2004, 2005, 2006, 2007],
      "skipped_years": []
    },
    "sped": {
      "aliases": ["sped", "sped_classification"],
      "raw_years": [2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025],
      "tidy_years": [2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025],
      "skipped_years": []
    },
    "sped_placement": {
      "aliases": ["sped_placement", "educational_environment"],
      "raw_years": [2020, 2021, 2022, 2023, 2024, 2025],
      "tidy_years": [2020, 2021, 2022, 2023, 2024, 2025],
      "skipped_years": []
    },
    "tges": {
      "aliases": ["tges", "csg"],
      "raw_years": [2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025],
      "tidy_years": [2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025],
      "skipped_years": []
    },
    "state_aid": {
      "aliases": ["state_aid", "aid"],
      "raw_years": [2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027],
      "tidy_years": [2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027],
      "skipped_years": []
    },
    "finance": {
      "aliases": "finance",
      "raw_years": [2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026],
      "tidy_years": [2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026],
      "skipped_years": []
    },
    "dfg": {
      "aliases": ["dfg", "district_factor_group"],
      "raw_years": [1990, 2000],
      "tidy_years": [1990, 2000],
      "skipped_years": []
    },
    "ell": {
      "aliases": ["ell", "el"],
      "raw_years": [2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026],
      "tidy_years": [2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026],
      "skipped_years": []
    },
    "report_card": {
      "aliases": "report_card",
      "raw_years": [2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019],
      "tidy_years": [2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019],
      "skipped_years": [2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011]
    },
    "msgp": {
      "aliases": "msgp",
      "raw_years": [2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019],
      "tidy_years": [2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019],
      "skipped_years": []
    },
    "special_pop": {
      "aliases": "special_pop",
      "raw_years": [2017, 2018, 2019],
      "tidy_years": [2017, 2018, 2019],
      "skipped_years": []
    },
    "spr": {
      "aliases": ["spr", "school_performance_reports"],
      "raw_years": [2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025],
      "tidy_years": [2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025],
      "skipped_years": []
    },
    "absence": {
      "aliases": ["absence", "chronic_absence"],
      "raw_years": [2017, 2018, 2019, 2021, 2022, 2023, 2024, 2025],
      "tidy_years": [2017, 2018, 2019, 2021, 2022, 2023, 2024, 2025],
      "skipped_years": 2020
    },
    "directory": {
      "aliases": ["directory", "school_directory", "district_directory"],
      "raw_years": [],
      "tidy_years": [],
      "skipped_years": []
    },
    "essa": {
      "aliases": "essa",
      "raw_years": 2017,
      "tidy_years": 2017,
      "skipped_years": []
    },
    "essa_chronic_absence": {
      "aliases": ["essa_chronic_absence", "essa_absence"],
      "raw_years": [2017, 2018, 2019, 2022, 2023, 2024],
      "tidy_years": [2017, 2018, 2019, 2022, 2023, 2024],
      "skipped_years": [2020, 2021]
    },
    "facilities": {
      "aliases": ["facilities", "facility"],
      "raw_years": [],
      "tidy_years": [],
      "skipped_years": []
    }
  }
}
''')

PYTHON_PACKAGE_VERSION = _CONTRACT["python_package_version"]
R_PACKAGE_MIN_VERSION = _CONTRACT["r_package_min_version"]
R_PACKAGE_MAX_VERSION = _CONTRACT["r_package_max_version"]
R_SIGNATURES = _CONTRACT["r_signatures"]
SOURCE_COVERAGE = _CONTRACT["source_coverage"]
