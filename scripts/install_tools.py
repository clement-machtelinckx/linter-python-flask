"""Installe les binaires Linux AMD64 vérifiés par SHA256."""
import hashlib
import io
import json
from pathlib import Path
import sys
import tarfile
import urllib.request


def install(destination, names):
    lock = json.loads(Path(__file__).with_name("tools.lock.json").read_text())
    destination.mkdir(parents=True, exist_ok=True)
    for name in names or lock:
        spec = lock[name]
        with urllib.request.urlopen(spec["url"], timeout=120) as response:
            data = response.read()
        if hashlib.sha256(data).hexdigest() != spec["sha256"]:
            raise ValueError(f"SHA256 mismatch: {name}")
        if spec["archive"]:
            with tarfile.open(fileobj=io.BytesIO(data)) as archive:
                data = archive.extractfile(name).read()
        target = destination / name
        target.write_bytes(data)
        target.chmod(0o755)
        print(f"Verified {name} {spec['version']}")


if __name__ == "__main__":
    install(Path(sys.argv[1]), sys.argv[2:])
