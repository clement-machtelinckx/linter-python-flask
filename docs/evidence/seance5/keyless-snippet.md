# Étapes 8 et 9 — keyless : rédaction uniquement

Ce document est un exemple pour un futur fichier `.github/workflows/keyless-sign.yml`. Aucun workflow du dépôt n’a été modifié ; aucune commande keyless n’a été exécutée.

Le job GitHub Actions reçoit l’autorisation `id-token: write` pour demander un jeton OIDC identifiant le workflow. Cosign crée une clé éphémère ; Fulcio lie la clé publique à cette identité dans un certificat de courte durée ; Rekor enregistre les éléments publics de signature. La vérification doit contrôler l’émetteur OIDC et l’identité exacte attendue, en plus de la signature.

Le chemin CI décrit ici n’est pas disponible dans notre terminal local, qui ne dispose pas du jeton OIDC de ce job. Cela ne signifie pas que tous les modes keyless interactifs sont impossibles en local ; ils restent hors de cet atelier et ne sont pas exécutés.

Cet exemple signe une image déjà publiée sur GHCR, fournie par son digest réel. Il ne reconstruit pas l’image. Il utilise uniquement des commandes `run`, sans action `uses` : aucun SHA d’action à résoudre. Cosign est épinglé à v2.4.1 et son checksum est vérifié.

```yaml
name: Keyless signing example

on:
  workflow_dispatch:
    inputs:
      digest:
        description: Digest SHA256 réel de l'image déjà publiée
        required: true
        type: string

permissions:
  contents: read

jobs:
  sign:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write
    env:
      IMAGE: ghcr.io/clement-machtelinckx/linter-python-flask
      IMAGE_DIGEST: ${{ inputs.digest }}
    steps:
      - name: Validate immutable image reference
        shell: bash
        run: |
          set -euo pipefail
          [[ "$IMAGE_DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]]

      - name: Install verified Cosign v2.4.1
        shell: bash
        run: |
          set -euo pipefail
          mkdir -p "$RUNNER_TEMP/cosign-tools"
          cd "$RUNNER_TEMP/cosign-tools"
          curl --proto '=https' --proto-redir '=https' -fsSLO \
            https://github.com/sigstore/cosign/releases/download/v2.4.1/cosign-linux-amd64
          curl --proto '=https' --proto-redir '=https' -fsSLO \
            https://github.com/sigstore/cosign/releases/download/v2.4.1/cosign_checksums.txt
          sha256sum --ignore-missing -c cosign_checksums.txt
          install -m 0755 cosign-linux-amd64 cosign
          printf '%s\n' "$RUNNER_TEMP/cosign-tools" >> "$GITHUB_PATH"
          ./cosign version

      - name: Authenticate to GHCR
        shell: bash
        env:
          GHCR_TOKEN: ${{ github.token }}
        run: |
          set -euo pipefail
          printf '%s' "$GHCR_TOKEN" | docker login ghcr.io \
            --username "$GITHUB_ACTOR" --password-stdin

      - name: Sign the published digest using GitHub OIDC
        shell: bash
        run: |
          set -euo pipefail
          cosign sign --yes "$IMAGE@$IMAGE_DIGEST"

      - name: Logout
        if: always()
        run: docker logout ghcr.io
```

Commande de vérification demandée à l’étape 9, rédigée mais non exécutée :

```bash
IMAGE='ghcr.io/clement-machtelinckx/linter-python-flask'
DIGEST='sha256:REMPLACER_PAR_LE_DIGEST_REEL_PUBLIE'
cosign verify \
  --certificate-identity-regexp '^https://github\.com/clement-machtelinckx/linter-python-flask/\.github/workflows/keyless-sign\.yml@refs/heads/main$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  "$IMAGE@$DIGEST"
```

L’identité correspond au chemin et à la branche du workflow d’exemple. Si le nom du fichier change, l’identité attendue doit changer aussi. Le digest du registre local ne doit pas être supposé publié sur GHCR.

Sources : [Sigstore : fonctionnement, Fulcio et Rekor](https://docs.sigstore.dev/about/overview/), [GitHub : OpenID Connect](https://docs.github.com/en/actions/concepts/security/openid-connect).
