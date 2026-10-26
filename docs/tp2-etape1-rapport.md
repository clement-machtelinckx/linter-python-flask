# TP2 — Étape 1 : rapport

Exigences : [tp2-etape1-exigences.md](tp2-etape1-exigences.md). Travail réalisé en local :
le registre `tp2-registry:5000` (image `registry:2`) tient lieu de registre distant, le builder
Buildx `ci-builder` (pilote `docker-container`) est rattaché au réseau Docker `tp2-net`, et
l'émulation arm64 est fournie par QEMU (`tonistiigi/binfmt`).

## A. Cache persistant hors couches

**Mise en œuvre** — `# syntax=docker/dockerfile:1` en tête du `Dockerfile` ; l'installation pip
de l'étage `builder` monte `--mount=type=cache,target=/root/.cache/pip`. Le cache vit dans
BuildKit, hors des couches de l'image.

**Preuves**

| Mesure | Résultat |
|---|---|
| Build à froid (`A1-froid.log`) | 26,5 s, 20 lignes `Downloading` : 10 wheels et leurs métadonnées (les wheels pure Python, téléchargées une fois, sont réutilisées par la 2ᵉ architecture via le cache partagé) |
| Rebuild sans changement (`A3-cache-couches.log`) | 3,16 s, 13 étapes `CACHED` (cache de couches) |
| Rebuild après modification du manifeste, retrait d'`itsdangerous` (`A2-chaud.log`) | l'étape pip est rejouée sur les deux architectures : 0 `Downloading`, 32 `Using cached` |
| Fichiers de l'image finale (`A-fichiers-image.txt`) | 3000 entrées, dont 29 fichiers de `opt/python/flask/` ; 0 chemin `.cache/`, `__pycache__` ou `.pyc` |

**Constat** — le cache supprime tous les retéléchargements, mais la durée totale ne baisse pas
(29,9 s contre 26,5 s) : l'étape arm64 exécutée sous QEMU domine le temps de build
(18,8 s → 26,6 s). Les durées totales sont mesurées par `time` sur la commande `bake` ; les
durées d'étape viennent des logs BuildKit. Le gain du cache de montage porte sur le réseau, pas sur le CPU émulé.

## B. Secret de build en mémoire vive

**Mise en œuvre** — `--mount=type=secret,id=pip_token,required=true` sur la seule instruction
`RUN` d'installation. Le jeton est monté en tmpfs sous `/run/secrets/pip_token`, son format est
vérifié (`grep -Eq '^tok_[0-9a-f]{48}$'`), puis il est démonté à la fin de l'instruction. Aucun
`ARG` ni `ENV` portant le jeton. Bake fournit le fichier local `secrets/pip_token.txt` (chemin
utilisé pour toutes les preuves). Compose (`build.secrets`) et la CI (jeton éphémère généré dans
`$RUNNER_TEMP`) sont configurés de la même façon, mais leur build n'a pas été exécuté ici.
Seul le build exige le fichier secret : `docker compose config` et `up --no-build`, utilisés
par la CI multi-conteneurs, fonctionnent sans lui.

**Preuves** (le jeton n'est jamais affiché : seules les occurrences sont comptées avec
`grep -cFf secrets/pip_token.txt`)

| Contrôle | Résultat |
|---|---|
| `docker history --no-trunc` + `inspect`, images amd64 et arm64 | 0 occurrence |
| `docker history --no-trunc` de l'étage `builder` seul (`B-builder-history.txt`) | 0 occurrence |
| Trivy 0.75.0, règle dédiée `trivy-secret.yaml`, images `tp2:amd64`, `tp2:arm64`, `tp2:builder` | aucun secret |
| Contrôle positif Trivy, dossier contenant le jeton | détecté, CRITICAL 1 |
| Contrôle positif Trivy, image piège `tp2:piege` (jeton copié par `COPY`) | détecté, CRITICAL 1 sur `/app/leak.txt` |
| Exclusion du suivi Git | `.gitignore:192` `secrets/` ; 0 fichier suivi sous `secrets/` |
| Exclusion du contexte de build | `.dockerignore:22` `**/secrets` ; contexte transféré : 46 o |

Les contrôles positifs montrent que la règle Trivy détecte bien ce jeton dans un fichier comme
dans une couche d'image : son silence sur les trois images est donc une preuve d'absence.
L'étage `builder`, qui a consommé le secret, ne le contient pas davantage.

## C. Multi-plateforme et configuration déclarative

**Mise en œuvre** — `docker-bake.hcl` à la racine : variables `REGISTRY`, `IMAGE`, `TAGS`
(`list(string)`) et `CACHE_REF` ; cible `api` pour `linux/amd64` et `linux/arm64` ; secret
`pip_token` ; cache registre importé et exporté en `mode=max` ; sortie `type=registry`.
Lancement : `docker buildx bake -f docker-bake.hcl` (le `-f` est nécessaire, sinon Bake lit
`docker-compose.yml` en priorité).

**Preuves**

| Contrôle | Résultat |
|---|---|
| Index publié (`C-index.txt`) | `sha256:4096e726…` : manifeste amd64 `ebe6272b…`, manifeste arm64 `1b415067…`, plus 2 manifestes d'attestation (`unknown/unknown`) |
| Exécution arm64 (`C-arm64-runtime.txt`) | `platform.machine()` renvoie `aarch64` |
| Runner éphémère simulé : builder Buildx neuf, sans cache local (`C-runner-ephemere-2.log`) | cache importé depuis le registre : 12 étapes `CACHED`, 0 `Downloading` |

**Constat** — le cache `mode=max` du registre remplace le cache local perdu d'un runner
éphémère. Il ne contient que des couches : le contenu d'un `--mount=type=cache` n'est jamais
exporté. Un premier essai (`C-runner-ephemere.log`) a retéléchargé les paquets arm64, car un
build partiel (étage `builder`, amd64 seul) avait juste avant réécrit la même référence
`:buildcache`. Un build partiel ne doit donc pas exporter vers la référence de cache partagée.

## Écarts et limites

- Registre local au lieu de GHCR, faute de publication distante pour ce TP.
- Le build multi-architecture ne peut pas être chargé avec `--load` : les images de vérification
  `tp2:amd64` et `tp2:arm64` sont tirées du registre local, exposé sur l'hôte en
  `localhost:5001` (`tp2:amd64` porte le digest de l'index `sha256:4096e726…`).
- Les preuves brutes sont conservées dans `~/tp2-preuves/`, hors dépôt.
