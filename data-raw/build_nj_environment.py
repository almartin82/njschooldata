"""Rebuild the public IND_5C projection from the bundled NJDOE Tableau workbook.

Run with python3 -I data-raw/build_nj_environment.py. Requires tableauhyperapi.
No requests are made. The complete original archive remains the source parent.
LOCAL is the displayed source text. No *_UNSUP field is exported.
"""

import csv
from pathlib import Path
import tempfile
import zipfile

from tableauhyperapi import Connection, HyperProcess, Telemetry


root = Path(__file__).resolve().parents[1] / "inst/extdata/program-sources"
columns = [
    "COUNTY_CODE", "COUNTY_NAME", "DISTRICT_CODE", "DISTRICT_NAME", "INDICATOR",
    "REPORT_YEAR", "SCHOOL_YEAR", "FFY", "NUMERATOR", "DENOMINATOR", "LOCAL", "NOTES",
]
with tempfile.TemporaryDirectory(prefix="nj-environment-") as directory:
    with zipfile.ZipFile(root / "environment-profiles.twbx") as archive:
        members = [n for n in archive.namelist() if "SPPAPR" in n and n.endswith(".hyper")]
        if len(members) != 1:
            raise ValueError("Expected one SPPAPR Hyper source")
        path = Path(directory) / "profiles.hyper"
        path.write_bytes(archive.read(members[0]))
    with HyperProcess(Telemetry.DO_NOT_SEND_USAGE_DATA_TO_TABLEAU,
                      parameters={"log_dir": directory}) as process:
        with Connection(process.endpoint, str(path)) as connection:
            tables = [t for t in connection.catalog.get_table_names("Extract")
                      if "SPPAPR" in str(t)]
            if len(tables) != 1:
                raise ValueError("Expected one SPPAPR profile table")
            fields = ",".join('"' + name + '"' for name in columns)
            query = (f"SELECT {fields} FROM {tables[0]} WHERE \"INDICATOR\"='IND_5C' "
                     'ORDER BY "SCHOOL_YEAR","DISTRICT_CODE","COUNTY_CODE","REPORT_YEAR"')
            rows = connection.execute_list_query(query)
    with (root / "environment-5c.csv").open("w", newline="") as output:
        writer = csv.writer(output)
        writer.writerow(columns)
        writer.writerows(rows)
