"""Vérifie un jeton sans jamais en afficher la valeur."""
import argparse
import gzip
import io
from pathlib import Path
import tarfile


def check(data, secret):
    if secret in data:
        raise ValueError("Build secret found in image metadata or layer")
    if data.startswith(b"\x1f\x8b"):
        check(gzip.decompress(data), secret)
    elif tarfile.is_tarfile(io.BytesIO(data)):
        with tarfile.open(fileobj=io.BytesIO(data)) as archive:
            for member in archive:
                if member.isfile():
                    check(archive.extractfile(member).read(), secret)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("secret", type=Path)
    parser.add_argument("files", nargs="+", type=Path)
    args = parser.parse_args()
    value = args.secret.read_bytes().strip()
    if len(value) < 16:
        raise SystemExit("Comparison token must contain at least 16 bytes")
    for path in args.files:
        check(path.read_bytes(), value)
    print("PASS: build token absent from inspected metadata and layers")
