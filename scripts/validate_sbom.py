"""Valide CycloneDX 1.7 et l'inventaire Flask/PostgreSQL attendu."""
import hashlib
import json
from pathlib import Path
import sys
import urllib.request

import jsonschema
from referencing import Registry, Resource


def load_schemas(cache):
    cache.mkdir(parents=True, exist_ok=True)
    lock = json.loads(Path(__file__).with_name("schemas.lock.json").read_text())
    schemas = {}
    for name, spec in lock.items():
        path = cache / name
        if not path.exists():
            with urllib.request.urlopen(spec["url"], timeout=30) as response:
                path.write_bytes(response.read())
        data = path.read_bytes()
        if hashlib.sha256(data).hexdigest() != spec["sha256"]:
            raise ValueError(f"Schema digest mismatch: {name}")
        schemas[name] = json.loads(data)
    return schemas


def validate(document, schemas):
    if document.get("specVersion") != "1.7":
        raise ValueError("Expected CycloneDX 1.7")
    registry = Registry()
    for name, schema in schemas.items():
        resource = Resource.from_contents(schema)
        registry = registry.with_resource(name, resource)
        uri = f"http://cyclonedx.org/schema/{name}"
        registry = registry.with_resource(uri, resource)
    jsonschema.Draft7Validator(
        schemas["bom-1.7.schema.json"], registry=registry,
        format_checker=jsonschema.FormatChecker(),
    ).validate(document)
    expected = {"flask", "werkzeug", "psycopg2-binary", "jinja2", "markupsafe",
                "click", "itsdangerous", "blinker"}
    found = {component["name"].lower(): component
             for component in document.get("components", [])}
    if expected - found.keys():
        missing = sorted(expected - found.keys())
        raise ValueError(f"Missing runtime packages: {missing}")
    requirements = Path("requirements-runtime.txt").read_text().splitlines()
    versions = dict(line.split("==") for line in requirements if "==" in line)
    for name in expected:
        component = found[name]
        if component.get("version") != versions[name]:
            raise ValueError(f"Unexpected version: {name}")
        if not component.get("purl", "").startswith("pkg:pypi/"):
            raise ValueError(f"Missing Python PURL: {name}")
    print("PASS: CycloneDX schema, eight runtime packages, versions and PURLs")


if __name__ == "__main__":
    validate(json.loads(Path(sys.argv[1]).read_text()), load_schemas(Path(sys.argv[2])))
