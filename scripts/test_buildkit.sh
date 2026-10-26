#!/usr/bin/env bash
set -euo pipefail
builder=${BUILDER:-tp2-builder}
reports=${REPORT_DIR:-security-evidence/buildkit}
mkdir -p "$reports"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp Dockerfile app.py requirements-runtime.txt .dockerignore "$work/"
(umask 077; openssl rand -hex 32 > "$work/token")
if docker buildx build --builder "$builder" --no-cache --progress plain "$work" > "$reports/missing-secret.log" 2>&1; then
  echo 'FAIL: build succeeded without secret' >&2
  exit 1
fi
grep -q 'secret build_token: not found' "$reports/missing-secret.log"
: > "$work/empty"
if docker buildx build --builder "$builder" --no-cache --secret "id=build_token,src=$work/empty" "$work" > "$reports/empty-secret.log" 2>&1; then
  echo 'FAIL: empty secret accepted' >&2
  exit 1
fi
grep -q 'Empty build token' "$reports/empty-secret.log"
nonce=$(date +%s%N)
sed -i "s/id=flask-pip/id=flask-pip-test-$nonce/" "$work/Dockerfile"
printf "\n# Cache measurement %s\n" "$nonce" >> "$work/requirements-runtime.txt"
: > "$reports/durations.txt"
for pass in cold warm; do
  if [[ $pass == warm ]]; then
    printf '\n# Validation du cache pip persistant\n' >> "$work/requirements-runtime.txt"
  fi
  start=$(date +%s)
  docker buildx build --builder "$builder" --load --progress plain \
    --secret "id=build_token,src=$work/token" --tag flask-tp2:cache "$work" \
    > "$reports/$pass.log" 2>&1
  printf '%s %s seconds\n' "$pass" "$(( $(date +%s) - start ))" >> "$reports/durations.txt"
done
grep -q 'Using cached' "$reports/warm.log"
docker history --no-trunc flask-tp2:cache > "$reports/history.txt"
docker save flask-tp2:cache -o "$work/image.tar"
python3 scripts/check_secret.py "$work/token" "$reports/history.txt" "$work/image.tar"
docker run --rm --entrypoint /usr/bin/python3.13 flask-tp2:cache -c \
 'from pathlib import Path; import flask, psycopg2; import os; assert os.getuid() == 65532; assert not Path("/run/secrets/build_token").exists(); assert not Path("/bin/sh").exists()'
docker run --rm --user 0 --entrypoint /usr/bin/python3.13 flask-tp2:cache -c \
 'from pathlib import Path; assert not Path("/root/.cache/pip").exists()'
printf 'PASS: missing/empty secrets rejected; pip cache reused; runtime checked\n'
