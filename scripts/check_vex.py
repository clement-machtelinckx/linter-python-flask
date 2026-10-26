"""Préserve la politique stricte tant qu'aucune exception n'est approuvée."""
import json
from pathlib import Path
import sys


def findings(report):
    return {(result.get("Target"), item["VulnerabilityID"], item["PkgName"],
             item.get("InstalledVersion"), item.get("FixedVersion"),
             item.get("Severity"))
            for result in report.get("Results", [])
            for item in result.get("Vulnerabilities", [])}


def check(before, after):
    if list(Path("security/vex").glob("*.json")):
        raise ValueError("No active VEX exception has been approved")
    if findings(before) != findings(after):
        raise ValueError("Vulnerability findings changed without an approved VEX")
    print("PASS: no approved VEX, no suppressed vulnerabilities")


if __name__ == "__main__":
    check(*(json.loads(Path(path).read_text()) for path in sys.argv[1:]))
