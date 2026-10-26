"""Tests des refus critiques de la chaîne d'approvisionnement."""
from copy import deepcopy
import gzip
import json
from pathlib import Path

import pytest

from scripts.check_secret import check as check_secret
from scripts.check_vex import check as check_vex
from scripts.validate_sbom import validate


def test_secret_detected_in_compressed_layer():
    token = b"ephemeral-test-token-no-credential"
    with pytest.raises(ValueError, match="Build secret found"):
        check_secret(gzip.compress(b"prefix " + token), token)
    check_secret(gzip.compress(b"no secret here"), token)


def test_vex_cannot_suppress_without_approval():
    # CVE réelle ; rapport synthétique exclusivement destiné au test du refus.
    before = {"Results": [{"Target": "unit-fixture", "Vulnerabilities": [
        {"VulnerabilityID": "CVE-2024-34069", "PkgName": "werkzeug",
         "InstalledVersion": "3.0.2", "FixedVersion": "3.0.3", "Severity": "HIGH"}
    ]}]}
    check_vex(before, deepcopy(before))
    with pytest.raises(ValueError, match="changed without an approved VEX"):
        check_vex(before, {"Results": []})


def test_sbom_rejects_missing_runtime_package():
    # Schéma minimal de test ; le schéma officiel est validé sur les SBOM réels en CI.
    schemas = {"bom-1.7.schema.json": {
        "$schema": "http://json-schema.org/draft-07/schema#", "type": "object"}}
    with pytest.raises(ValueError, match="Missing runtime packages"):
        validate({"specVersion": "1.7", "components": []}, schemas)


def test_sbom_rejects_wrong_schema_version():
    with pytest.raises(ValueError, match="Expected CycloneDX 1.7"):
        validate({"specVersion": "1.6"}, {})


def test_no_active_vex_and_tools_pinned():
    assert not list(Path("security/vex").glob("*.json"))
    lock = json.loads(Path("scripts/tools.lock.json").read_text())
    for tool in lock.values():
        assert len(tool["sha256"]) == 64
        assert f"/v{tool['version']}/" in tool["url"]
