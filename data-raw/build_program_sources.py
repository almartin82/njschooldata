"""Explicit maintainer acquisition of complete NJDOE program releases and CCD keys."""
import csv
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = "new_jersey_shipped_sources"
SPED = "https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/"
sources = [
    ("sped", 2023, SPED + "2022public618data/District_Enrollment_vs_SpecialED_Rates_Publicdata_3_21Age.xlsx"),
    ("sped", 2024, SPED + "2023_618data/DistrictWide_ClassificationRate_2324_public.xlsx"),
    ("sped", 2025, SPED + "2025_618data/2025IDEA618PublicReporting_ClassificationRates.xlsx"),
    ("sped_state", 2023, SPED + "2022public618data/StateClassificationRates_SpecialED_3-21.xlsx"),
    ("sped_state", 2024, SPED + "2023_618data/StatewideClassificationRate_2324.xlsx"),
] + [
    ("enrollment", year,
     f"https://www.nj.gov/education/doedata/enr/enr{year % 100}/"
     f"{'Enrollment' if year == 2026 else 'enrollment'}_{(year-1) % 100}{year % 100}.zip")
    for year in range(2023, 2027)
]


def acquire(url):
    with urlopen(Request(url, headers={"User-Agent": "Mozilla/5.0"}), timeout=90) as response:
        content = response.read()
        final_url = response.url
    return content, final_url, datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")


if __name__ == "__main__":
    artifacts = []
    for family, year, url in sources:
        content, final_url, retrieved = acquire(url)
        if not content.startswith(b"PK"):
            raise ValueError(f"Not a ZIP/Excel source: {url}")
        path = Path("inst/extdata/program-sources") / f"{family}-{year}{Path(url).suffix}"
        (ROOT / path).parent.mkdir(parents=True, exist_ok=True)
        (ROOT / path).write_bytes(content)
        artifacts.append({
            "artifact_id": f"{family}-{year}",
            "source_identity": {"url": final_url, "requested_url": url, "retrieved_at": retrieved},
            "tier": "shipped", "byte_length": len(content),
            "sha256": hashlib.sha256(content).hexdigest(),
            "selectors": {"family": family, "key": str(year)},
            "storage": {"path": path.as_posix()}, "lineage": {"kind": "source"},
        })
        print(f"{family}-{year}: {len(content)} bytes", flush=True)

    manifest = {"schema_version": "source-validation-artifact-manifest/v1",
                "contract_id": CONTRACT, "artifacts": artifacts}
    required = [{"artifact_id": a["artifact_id"], "selectors": a["selectors"]} for a in artifacts]
    for base in (ROOT / "data-raw/source-validation-spec", ROOT / "inst/extdata/source-contract/contracts"):
        directory = base / CONTRACT
        (directory / "artifact-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
        contract = json.loads((directory / "contract.json").read_text())
        contract["required_artifacts"] = required
        (directory / "contract.json").write_text(json.dumps(contract, indent=2) + "\n")

    # Store identifiers ONLY. Never retain CCD population values in the package.
    ccd_url = "https://educationdata.urban.org/api/v1/school-districts/ccd/directory/2024/?fips=34"
    rows = []
    url = ccd_url
    while url:
        content, _, retrieved = acquire(url)
        page = json.loads(content)
        rows.extend({"state_leaid": r["state_leaid"], "nces_dist": str(r["leaid"]).zfill(7)}
                    for r in page["results"])
        url = page.get("next")
    rows = sorted({(r["state_leaid"], r["nces_dist"]) for r in rows})
    if len({r[0] for r in rows}) != len(rows):
        raise ValueError("Ambiguous CCD state_leaid")
    with (ROOT / "inst/extdata/crosswalk/nj_ccd_state_leaid_2024.csv").open("w") as stream:
        writer = csv.writer(stream, lineterminator="\n")
        writer.writerow(["state_leaid", "nces_dist"])
        writer.writerows(rows)
    print(f"CCD 2024: {len(rows)} exact state LEA identifiers")
