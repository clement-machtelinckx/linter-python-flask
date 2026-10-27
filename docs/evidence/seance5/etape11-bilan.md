# Étape 11 — attestation SBOM du digest signé

Verdict : **PASS pour l’attestation locale**, sans preuve d’inclusion Rekor de cette attestation.

Les SBOM SPDX et CycloneDX ont été générés réellement depuis le registre au digest déjà signé, avec `--platform linux/amd64`. L’option Syft utilisée pour le registre HTTP est `SYFT_REGISTRY_INSECURE_USE_HTTP=true`, confirmée par `syft config`.

Le `cosign attest --help` de v2.4.1 annonce notamment `spdx`, `spdxjson` et `cyclonedx`. Le prédicat est un document SPDX JSON 2.3 : le type choisi est **`spdxjson`**.

La première tentative d’attestation a été refusée avant exécution par le contrôle automatique d’autorisation : le comportement par défaut aurait aussi publié le contenu du SBOM dans le journal public Rekor, destination non explicitement autorisée. L’alternative exécutée conserve le SBOM dans le registre local en utilisant `--tlog-upload=false`.

Commande exécutée :

```bash
cosign attest --allow-http-registry \
  --key docs/evidence/seance5/keys/cosign.key --yes --tlog-upload=false \
  --predicate docs/evidence/seance5/sbom-api-digest.spdx.json --type spdxjson \
  "$(cat docs/evidence/seance5/etape7-image-reference.txt)"
```

Vérification exécutée :

```bash
cosign verify-attestation --allow-http-registry --insecure-ignore-tlog \
  --key docs/evidence/seance5/keys/cosign.pub --type spdxjson \
  "$(cat docs/evidence/seance5/etape7-image-reference.txt)" \
  > docs/evidence/seance5/etape11-verify-attestation.json \
  2> docs/evidence/seance5/etape11-verify-attestation.log
jq -r '.payload' docs/evidence/seance5/etape11-verify-attestation.json \
  | base64 -d | tee docs/evidence/seance5/etape11-statement.json \
  | jq .predicate > docs/evidence/seance5/verified-sbom.json
```

`--insecure-ignore-tlog` omet seulement la vérification d’inclusion au journal de transparence, indisponible pour cette attestation locale ; Cosign affiche un avertissement conservé dans le log. Les signatures et déclarations restent vérifiées par Cosign. La signature d’image de l’étape 7 a, elle, un bundle Rekor vérifié.

Résultats mesurés : **47 paquets d’origine, 47 paquets extraits ; JSON sémantiquement identiques**. Le type de prédicat est `https://spdx.dev/Document`. Le SHA256 du sujet de la déclaration correspond au digest signé ; cette égalité a été vérifiée en plus du simple comptage.

Preuves : `etape11-syft-digest.log`, `etape11-attest-command.txt`, `etape11-attest.log`, `etape11-verify-attestation.json`, `etape11-verify-attestation.log`, `etape11-statement.json`, `etape11-comparaison.json`, `verified-sbom.json`, `etape11-autorisation.log`.

Arrêt au contenu de la slide 30. Aucun atelier Grype, VEX ou Dependency-Track n’a été exécuté.
