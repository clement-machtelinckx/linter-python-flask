"""Vérifie les blobs OCI, les deux plateformes et leur provenance BuildKit."""
import hashlib
import json
from pathlib import Path
import sys
import tarfile


def inspect(archive_path, destination):
    destination.mkdir(parents=True, exist_ok=True)
    with tarfile.open(archive_path) as archive:
        def read(descriptor):
            algorithm, value = descriptor["digest"].split(":", 1)
            if algorithm != "sha256":
                raise ValueError("Only SHA256 OCI descriptors are accepted")
            data = archive.extractfile(f"blobs/sha256/{value}").read()
            actual = hashlib.sha256(data).hexdigest()
            if len(data) != descriptor["size"] or actual != value:
                raise ValueError("Corrupt OCI descriptor")
            return data

        raw = archive.extractfile("index.json").read()
        root = json.loads(raw)
        descriptors = root["manifests"]
        if len(descriptors) == 1 and "index" in descriptors[0]["mediaType"]:
            raw = read(descriptors[0])
            root = json.loads(raw)
        platforms = {}
        attestations = {}
        for descriptor in root["manifests"]:
            manifest = json.loads(read(descriptor))
            read(manifest["config"])
            for layer in manifest["layers"]:
                read(layer)
            platform = descriptor.get("platform", {})
            arch = platform.get("architecture")
            if platform.get("os") == "linux" and arch in {"amd64", "arm64"}:
                if arch in platforms:
                    raise ValueError("Duplicate platform manifest")
                platforms[arch] = descriptor["digest"]
            else:
                annotations = descriptor.get("annotations", {})
                subject = annotations.get("vnd.docker.reference.digest")
                for layer in manifest["layers"]:
                    statement = json.loads(read(layer))
                    predicate_type = statement.get("predicateType", "")
                    if predicate_type.startswith("https://slsa.dev/provenance/"):
                        subjects = statement.get("subject", [])
                        digests = {"sha256:" + s.get("digest", {}).get("sha256", "")
                                   for s in subjects}
                        if subject not in digests:
                            raise ValueError("Provenance subject mismatch")
                        attestations[subject] = statement
        if set(platforms) != {"amd64", "arm64"}:
            raise ValueError("Expected both linux/amd64 and linux/arm64")
        for arch, digest in platforms.items():
            statement = attestations.get(digest)
            if not statement:
                raise ValueError(f"Missing BuildKit provenance: {arch}")
            (destination / f"provenance-{arch}.json").write_text(
                json.dumps(statement["predicate"], indent=2) + "\n")
            type_path = destination / f"provenance-type-{arch}.txt"
            type_path.write_text(statement["predicateType"])
        mapping = {"index": "sha256:" + hashlib.sha256(raw).hexdigest(),
                   "platforms": platforms}
        (destination / "digests.json").write_text(json.dumps(mapping, indent=2) + "\n")
        (destination / "index.json").write_bytes(raw)
        print(json.dumps(mapping, indent=2))
        return mapping


if __name__ == "__main__":
    inspect(Path(sys.argv[1]), Path(sys.argv[2]))
