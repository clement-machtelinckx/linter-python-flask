#!/usr/bin/env bash
set +x
set -euo pipefail
umask 077

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
image_ref=$(cat etape7-image-reference.txt)
if [[ ! "$image_ref" =~ ^localhost:5001/linter-python-flask-api@sha256:[0-9a-f]{64}$ ]]; then
  printf '%s\n' 'FAIL : référence au digest invalide.' >&2
  exit 1
fi
if [[ -e keys/cosign.key || -e keys/cosign.pub ]]; then
  printf '%s\n' 'Une clé existe déjà : arrêt pour éviter tout écrasement. Signaler cet état à l’agent.' >&2
  exit 1
fi
git check-ignore -q keys/cosign.key
git check-ignore -q ../../../.secrets/pip_token.txt
mkdir -p keys
chmod 700 keys

trap 'unset COSIGN_PASSWORD COSIGN_PASSWORD_CONFIRM' EXIT
if [[ -z ${COSIGN_PASSWORD:-} ]]; then
  if [[ ! -t 0 ]]; then
    printf '%s\n' 'Exécuter ce script dans un terminal interactif pour saisir la passphrase.' >&2
    exit 1
  fi
  IFS= read -r -s -p 'Passphrase Cosign (saisie masquée) : ' COSIGN_PASSWORD
  printf '\n'
  IFS= read -r -s -p 'Confirmer la passphrase : ' COSIGN_PASSWORD_CONFIRM
  printf '\n'
  if [[ -z "$COSIGN_PASSWORD" || "$COSIGN_PASSWORD" != "$COSIGN_PASSWORD_CONFIRM" ]]; then
    printf '%s\n' 'FAIL : passphrase vide ou confirmation différente. Aucune clé générée.' >&2
    exit 1
  fi
  unset COSIGN_PASSWORD_CONFIRM
fi
export COSIGN_PASSWORD

cosign generate-key-pair --output-key-prefix keys/cosign 2>&1 | tee etape7-keypair.log
cosign sign --key keys/cosign.key --yes --allow-http-registry "$image_ref" 2>&1 | tee etape7-sign.log
printf '%s\n' 'Signature terminée. Revenir dans le chat pour les vérifications et le test négatif.'
