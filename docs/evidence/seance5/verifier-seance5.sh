#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.."
evidence=docs/evidence/seance5

printf '\nVersions des outils\n'
syft version
cosign version
jq --version
curl --version
openssl version
docker version --format 'Client={{.Client.Version}} Server={{.Server.Version}}'
docker compose version
docker run --rm aquasec/trivy:0.75.0 --version

printf '\nEmpreintes des binaires issus des téléchargements vérifiés\n'
binary_checksums="$PWD/$evidence/outils-binaires.sha256"
(
  cd "$HOME/.local/bin"
  sha256sum --check "$binary_checksums"
)

printf '\nExclusions et fichiers protégés\n'
git check-ignore -v cosign.key .secrets/pip_token.txt "$evidence/keys/cosign.key"
git diff --check -- .gitignore .dockerignore
git diff --exit-code -- Dockerfile app.py test_app.py docker-compose.yml docker-bake.hcl .github/workflows
python3 - <<'PY'
import json
from pathlib import Path
import re
import subprocess

root = Path('docs/evidence/seance5')
tracked = subprocess.check_output(['git', 'ls-files'], text=True).splitlines()
sensitive = [name for name in tracked if re.search(r'cosign\.key|\.secrets|\.env$', name)]
assert not sensitive, 'FAIL : chemin sensible suivi ou stagé : ' + ', '.join(sensitive)
private_key = root / 'keys/cosign.key'
if private_key.exists():
    assert private_key.stat().st_mode & 0o077 == 0, 'FAIL : permissions de clé privée trop larges'
else:
    print('Clé privée absente : état attendu dans le dépôt publié ; vérifications avec la clé publique.')
original = json.loads((root / 'sbom-api-digest.spdx.json').read_text())
verified = json.loads((root / 'verified-sbom.json').read_text())
assert original == verified and len(original['packages']) > 0, 'FAIL : le SBOM extrait diffère de l’original'
negative = json.loads((root / 'etape7-negative-result.json').read_text())
assert negative['verdict'] == 'PASS' and negative['exit_code'] != 0 and negative['no_matching_signatures'], 'FAIL : test négatif non établi'
print('PASS : aucun fichier sensible suivi ; permissions privées ; SBOM original et extrait identiques ; test négatif établi.')
print('Comptages : Python 3.12 CycloneDX=%s ; API CycloneDX=%s ; Syft SPDX=%s ; Trivy SPDX=%s ; SBOM certifié SPDX=%s.' % (
    len(json.loads((root / 'sbom-python312.cdx.json').read_text())['components']),
    len(json.loads((root / 'sbom-api.cdx.json').read_text())['components']),
    len(json.loads((root / 'sbom-api.spdx.json').read_text())['packages']),
    len(json.loads((root / 'sbom-api-trivy.spdx.json').read_text())['packages']),
    len(verified['packages']),
))
inventory = root / 'inventaire-publication.txt'
if not inventory.is_file():
    inventory = root / 'inventaire-fichiers.txt'
if inventory.is_file():
    files = inventory.read_text().splitlines()
    missing = [name for name in files if not Path(name).is_file() or Path(name).stat().st_size == 0]
    assert not missing, 'FAIL : fichiers listés absents ou vides : ' + ', '.join(missing)
    print(f'PASS : {len(files)} fichiers de l’inventaire existent et sont non vides.')
PY

printf '\nRecherche de clés privées hors cosign.key ignorée\n'
if secret_paths=$(grep -rIlE --exclude=cosign.key 'BEGIN (ENCRYPTED )?(COSIGN|PRIVATE)' "$evidence"); then
  printf '%s\n' 'FAIL : marqueur de clé privée trouvé dans les fichiers suivants :' "$secret_paths" >&2
  exit 1
else
  grep_status=$?
  if [[ "$grep_status" -ne 1 ]]; then
    printf '%s\n' 'FAIL : la recherche de clés privées n’a pas pu se terminer.' >&2
    exit "$grep_status"
  fi
fi
printf '%s\n' 'PASS : aucun marqueur de clé privée hors fichier cosign.key ignoré.'

printf '\nVérification de signature\n'
image_ref=$(cat "$evidence/etape7-image-reference.txt")
cosign verify --allow-http-registry --key "$evidence/cosign.pub" "$image_ref" > /dev/null

printf '\nVérification de l’attestation locale (sans inclusion Rekor)\n'
cosign verify-attestation --allow-http-registry --insecure-ignore-tlog \
  --key "$evidence/cosign.pub" --type spdxjson "$image_ref" \
  | jq -r '.payload' | base64 -d | python3 -c '
import json, pathlib, sys
root = pathlib.Path("docs/evidence/seance5")
statement = json.load(sys.stdin)
digest = (root / "etape7-image-reference.txt").read_text().strip().split("@sha256:")[1]
assert any(s.get("digest", {}).get("sha256") == digest for s in statement["subject"]), "Sujet différent du digest signé"
assert statement["predicateType"] == "https://spdx.dev/Document", "Type de prédicat inattendu"
assert statement["predicate"] == json.loads((root / "sbom-api-digest.spdx.json").read_text()), "SBOM différent"
print("PASS : attestation signée, digest et prédicat vérifiés ; %s paquets." % len(statement["predicate"]["packages"]))
'

printf '\nServices Compose\n'
compose_directory=${SEANCE5_COMPOSE_DIRECTORY:-$PWD}
docker compose --project-directory "$compose_directory" ps
running_services=$(docker compose --project-directory "$compose_directory" ps --status running --services)
printf '%s\n' "$running_services" | grep -Fx api-python
printf '%s\n' "$running_services" | grep -Fx db
printf '\nPASS : vérifications de la séance 5 terminées.\n'
