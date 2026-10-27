# Commandes pour vérifier la séance 5

Les ateliers jusqu’à la slide 30 ont été exécutés ; ces commandes permettent de les vérifier à nouveau. Elles ne génèrent pas de clés et ne demandent pas de passphrase.

Depuis le terminal du projet :

```bash
cd ~/ynov_project/linter-python-flask
bash docs/evidence/seance5/verifier-seance5.sh
```

Ce script contrôle les versions, les empreintes des binaires issus des téléchargements vérifiés, les exclusions, les fichiers sensibles suivis, les marqueurs de clé privée, l’inventaire publié, la signature, l’attestation et les services Compose. Les archives et binaires téléchargés ne sont pas versionnés. La clé privée n’est pas nécessaire aux vérifications. Le registre `tp2-registry` doit tourner pour vérifier les signatures ; il est laissé en fonctionnement après l’atelier.

Si la composition tourne depuis un autre worktree, conserver sa configuration et ses secrets sur place :

```bash
SEANCE5_COMPOSE_DIRECTORY=/chemin/du/projet/local bash docs/evidence/seance5/verifier-seance5.sh
```

Commandes unitaires utiles :

```bash
syft version
cosign version
jq --version
curl --version
openssl version
docker version
docker compose version
docker run --rm aquasec/trivy:0.75.0 --version

jq '.components | length' docs/evidence/seance5/sbom-api.cdx.json
jq '.packages | length' docs/evidence/seance5/sbom-api.spdx.json
jq '.packages | length' docs/evidence/seance5/sbom-api-trivy.spdx.json
jq '.packages | length' docs/evidence/seance5/verified-sbom.json
jq '.components[] | select(.name == "libssl3t64") | {name, version}' docs/evidence/seance5/sbom-api.cdx.json

git status --short
git check-ignore -v cosign.key .secrets/pip_token.txt docs/evidence/seance5/keys/cosign.key
git ls-files | grep -E 'cosign\.key|\.secrets|\.env$'
grep -rIlE --exclude=cosign.key 'BEGIN (ENCRYPTED )?(COSIGN|PRIVATE)' docs/evidence/seance5
docker compose ps
```

Les deux dernières recherches de fichiers sensibles doivent ne rien afficher et renvoyer le code 1, qui signifie « aucune correspondance » pour `grep`. L’option `-l` affiche seulement les noms de fichiers en cas de problème, jamais le contenu d’une clé.

Vérification de la signature d’image :

```bash
cosign verify --allow-http-registry \
  --key docs/evidence/seance5/cosign.pub \
  "$(cat docs/evidence/seance5/etape7-image-reference.txt)"
```

Vérification de l’attestation conservée dans le registre local :

```bash
cosign verify-attestation --allow-http-registry --insecure-ignore-tlog \
  --key docs/evidence/seance5/cosign.pub --type spdxjson \
  "$(cat docs/evidence/seance5/etape7-image-reference.txt)"
```

L’avertissement sur l’absence de vérification Rekor est attendu uniquement pour cette attestation locale ; voir `etape11-bilan.md`. Aucune commande keyless de `keyless-snippet.md` n’a été exécutée.
