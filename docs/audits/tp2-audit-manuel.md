# Audit manuel final — TP2 DevSecOps

## 1. Informations générales

- Début : 29 octobre 2026, 12:54 UTC (13:54 à Paris).
- Consolidation : 2026-10-29 13:13 UTC.
- Dépôt : https://github.com/clement-machtelinckx/linter-python-flask
- État audité : `origin/main`, `bb6f32c7b7b421d499c27e979102d80cd9e1cb0f`, après `git fetch origin` réussi.
- Branche du rapport : `audit/tp2-conformite-finale` ; worktree : `/tmp/tp2-audit-conformite`.
- Les fichiers non suivis `.secrets/` et `docs/evidence/` du répertoire initial sont préservés et ne constituent pas des preuves versionnées.
- Référentiel : exigences intégralement reproduites dans la mission ; aucun PDF trouvé dans le dépôt et le répertoire de projet lors de la recherche initiale.

### Périmètre et versions réellement consultées ou exécutées

| Outil | Version / usage réel |
|---|---|
| Git / gh / jq | 2.34.1 / 2.4.0 / 1.6 ; Git, API et artefacts |
| Docker client et serveur | 28.4.0 ; accès spécifique au socket autorisé |
| Buildx / Compose locaux | v0.28.0-desktop.1 / v2.39.4-desktop.1 |
| Buildx de la release | v0.38.1, lu dans les logs de publication |
| BuildKit du builder d’audit | image `moby/buildkit@sha256:cec9f139f45e93c5c69c60f8b07cfad9f43f4ef6b6a6cd917527fea5ff2e3dea` ; même image que release |
| Cosign local | v2.4.1 ; signatures et attestations indépendantes |
| Syft | 1.42.0 déclaré dans les SBOM et exécuté en CI ; 1.51.1 local seulement interrogé par `version` |
| Grype local et CI | 0.108.0 ; binaire local téléchargé dans /tmp et checksum officiel vérifié |
| Trivy local et CI | 0.75.0 ; local en conteneur, CI rapports vulnérabilités/config/secret |
| Dive | 0.13.1 en CI uniquement, rapport téléchargé |
| Hadolint | 2.15.1 local et CI, image par digest |
| Python | hôte 3.10.12 ; tests 3.13.16 ; runtime publié 3.13.5 |
| Pytest / Flake8 | 9.1.1 / 7.3.0, exécutés localement en conteneur et en CI |
| Validation | PyYAML 5.4.1 ; jsonschema 3.2.0 Draft7 ; jsonschema 4.23.0 Draft2020-12 isolé dans /tmp |

L’image de tests locale préexistante est `flask-tp2-tests:latest`, ID exact `sha256:a93e1c487f9c87053752af6c0f7c3ccb2d414dc6b3f00632a0816f2fc690fa86`. Elle fournit seulement les outils ; les fichiers du SHA audité sont montés en lecture seule. Pour reproduire ailleurs, construire une image d’outils sur la base Python épinglée du Dockerfile et y installer `.github/requirements-ci.txt` avec `--require-hashes` ; les versions utilisées ici sont indiquées ci-dessus.

La release publique vérifiée est **v1.1.1**, issue de `2381039ddea4924fe11f9f7b89176fe2324ef8d6`, et non du SHA main audité. Le diff entre ce commit et main concerne uniquement le README. Aucun nouveau tag/release n’a été créé. L’ancienne **v1.1.0** reste invalide pour l’admission : job de signature échoué et aucune signature publique trouvée pour son index.

L’environnement autorise les commandes Git/Docker/réseau au moyen d’accès spécifiques ; aucun identifiant n’est affiché. Le conteneur API et la base préexistants n’ont pas été arrêtés ou utilisés pour attribuer un résultat à main.

## 2. Résumé exécutif

Le TP2 vise à rendre la construction reproductible, à inventorier et qualifier les dépendances, puis à authentifier les images OCI publiées. L’audit a contrôlé le dernier main, les formats, les huit workflows, les logs et artefacts réels de GitHub Actions, puis GHCR et les signatures indépendamment. Les constructions isolées, le cache après modification, les tests négatifs de secret, le scan de couches, les six tests Flask/PostgreSQL et l’exécution des deux architectures ont réussi. Le fonctionnement technique principal est démontré ; la conformité intégrale reste **NON DÉMONTRÉE** à cause de la traçabilité incomplète du SBOM versionné et de réserves sur les preuves du README. Il reste 170 correspondances Grype après quatre exemptions VEX et 174 occurrences Trivy dans la CI actuelle, sans HIGH/CRITICAL corrigible ; ces gates ne certifient donc pas une absence de vulnérabilités.

## 3. Matrice de conformité intégrale

Les 78 lignes couvrent tous les identifiants officiels, les huit contrôles CI complémentaires et quatorze points de non-régression TP1. Les livrables et les étapes se recoupent volontairement : ce décompte n’est pas une note ni un pourcentage de sécurité.

**PASS LOCAL** désigne une propriété vérifiée directement (commande ou lecture structurée), uniquement pour le périmètre indiqué. **PASS CI** renvoie à une exécution réelle dont les liens figurent en T06/T17. **PARTIEL** indique une réserve de preuve ou de documentation ; **FAIL** une absence ou un échec pertinent ; **NON TESTÉ** une vérification insuffisante. Un échec attendu d’un test négatif est un PASS du contrôle, pas un FAIL du projet.

| ID | Exigence officielle | Fichier / workflow | Contrôle effectué | Résultat | Statut |
|---|---|---|---|---|---|
| L1 | Dockerfile BuildKit, cache, secret, Hadolint, runtime minimal non-root sans shell | Dockerfile ; .hadolint.yaml | T02, T19–T23, T31–T34, T37–T38 | Build et contrôles réussis ; UID 65532 sur les deux plateformes ; chemins shell/outils contrôlés absents. | PASS LOCAL |
| L2 | Bake racine, tags variables, deux plateformes, secret, cache externe max et index | docker-bake.hcl ; release | T24, T39, T42, T43 | HCL résolu ; index GHCR réel ; cache publié. Surcharge api.secret incompatible avec Buildx local 0.28, réussie en CI 0.38.1. | PASS LOCAL |
| L3 | Deux SBOM racine valides, complets, générés/archivés et reliés à l’image | sbom.cdx.json ; sbom.spdx.json | T07, T14–T16 | 47 paquets, 8 Python, schémas et graphes valides ; source racine 8df539d2… sans association Git/publication documentée. | PARTIEL |
| L4 | Grype sur SBOM, HIGH+ corrigibles bloquants et OpenVEX justifié | .grype.yaml ; security.vex.json | T17–T18, T25–T28 | Schéma OpenVEX valide ; CVE réelle ; quatre exemptions ciblées et observées ; aucune exclusion globale. | PASS LOCAL |
| L5 | Identité Cosign publique OIDC ou clé publique, sans clé privée | README §10 ; release | T08–T13, T41 | Keyless : identité exacte v1.1.1 et émetteur vérifiés ; aucune clé publique requise ; zéro marqueur de clé privée suivi. | PASS LOCAL |
| L6 | Workflows de qualité, sécurité, intégration, publication, signature et admission | .github/workflows/ | T03, T06, T17, T41 | Six phases exécutées ; dépendances bloquantes ; permissions limitées ; 24 références externes à SHA complet. Déploiements manuels historiques non exécutés. | PASS CI |
| L7 | Dossier français : performance, secret, multi-arch, SBOM, VEX et preuves publiques | README §8–§10 | T16, T43 ; vérifications publiques | Sections présentes et publication vérifiée ; mesures mêlant périmètres et références historiques à contextualiser. | PARTIEL |
| A1 | Syntaxe étendue BuildKit en tête du Dockerfile | Dockerfile | T02, T31 | # syntax=docker/dockerfile:1 reconnu. | PASS LOCAL |
| A2 | Montage de cache persistant dédié à pip dans le builder | Dockerfile | T02, T21–T22 | type=cache,target=/root/.cache/pip ; huit wheels réutilisées. | PASS LOCAL |
| A3 | Cache sans purge systématique et hors couches finales | Dockerfile | T02, T21–T22, T32 | Pas de --no-cache-dir ni purge pip ; montage hors couches ; aucun chemin cache pip exporté. | PASS LOCAL |
| A4 | Modification mineure réutilisant les téléchargements | Dockerfile | T21–T22 | Manifeste copié modifié par commentaire : 8 Downloading → 0 ; 0 Using cached → 8. | PASS LOCAL |
| A5 | Image finale sans cache résiduel | Dockerfile | T32 | Zéro chemin .cache/pip, __pycache__ ou .pyc dans le système de fichiers final. | PASS LOCAL |
| B1 | Jeton externe consommé par le builder | Dockerfile ; ignore ; Compose/Bake | T19–T22 | Fichier fourni via --secret ; format lu dans RUN ; aucun service privé réel requis par le sujet. | PASS LOCAL |
| B2 | Aucune transmission du jeton par ARG ou ENV | Dockerfile ; ignore ; Compose/Bake | T02 | Secret déclaré uniquement par le montage BuildKit ; ENV runtime sans jeton. | PASS LOCAL |
| B3 | Montage temporaire en mémoire pendant RUN | Dockerfile ; ignore ; Compose/Bake | T02, T19–T22 | type=secret required=true ; build valide uniquement avec secret au format attendu. | PASS LOCAL |
| B4 | Présence/format du jeton vérifié | Dockerfile ; ignore ; Compose/Bake | T19–T20 | Sans secret : code 1 ; format invalide : code 1 ; tests non cachés. | PASS LOCAL |
| B5 | Secret démonté après instruction | Dockerfile ; ignore ; Compose/Bake | T32 | Zéro fichier /run/secrets/pip_token dans builder exporté et runtime. | PASS LOCAL |
| B6 | Aucune valeur sensible dans docker history --no-trunc | Dockerfile ; ignore ; Compose/Bake | T32 | Zéro occurrence du jeton éphémère dans history/inspect des deux étages. | PASS LOCAL |
| B7 | Scanner sans détection du jeton dans l’image | Dockerfile ; ignore ; Compose/Bake | T33–T34 | Trivy image : code 0, zéro secret ; contrôle positif : code 1 et règle attendue. | PASS LOCAL |
| B8 | Source du jeton exclue de Git et du contexte Docker | Dockerfile ; ignore ; Compose/Bake | T02, T35, T41 | secrets/ ignoré par Git ; **/secrets exclu de Docker ; fichier fourni hors contexte pour les essais. | PASS LOCAL |
| C1 | HCL déclaratif à la racine | docker-bake.hcl ; publish_to_ghcr.yml | T02, T39 | docker-bake.hcl parsé sans modification. | PASS LOCAL |
| C2 | Registre et versionnement dynamiques | docker-bake.hcl ; publish_to_ghcr.yml | T39 | REGISTRY, IMAGE, TAGS et CACHE_REF effectivement résolus ; deux tags CSV. | PASS LOCAL |
| C3 | Cibles linux/amd64 et linux/arm64 simultanées | docker-bake.hcl ; publish_to_ghcr.yml | T39, T42 | Deux plateformes Bake et deux manifestes du même index distant. | PASS LOCAL |
| C4 | Secret BuildKit lié au build | docker-bake.hcl ; publish_to_ghcr.yml | T02, T39 | id=pip_token,src=secrets/pip_token.txt ; surcharge CI vers RUNNER_TEMP. | PASS LOCAL |
| C5 | Cache externe importé/exporté | docker-bake.hcl ; publish_to_ghcr.yml | T06, T43 | Import GHCR et export prouvés dans les logs publish ; manifeste cache distant lu. | PASS LOCAL |
| C6 | Cache complet exporté en mode=max | docker-bake.hcl ; publish_to_ghcr.yml | T39, T43 | mode=max résolu ; cache GHCR à config BuildKit, 116 couches lors de cet audit. | PASS LOCAL |
| C7 | Index OCI unifié réellement publié à distance | docker-bake.hcl ; publish_to_ghcr.yml | T42 | v1.1.1 : index d4218560…, manifestes 4b6f11e2… et a18b70c9…. | PASS LOCAL |
| D1 | Extraction statique sans exécution du conteneur | SBOM ; image-security.yml ; release | T03, T06–T07 | syft scan docker: en CI main ; registry: pour chaque manifeste de release. | PASS CI |
| D2 | Inventaire système et bibliothèques applicatives | SBOM ; image-security.yml ; release | T15–T16 | 46 libraries + 1 operating-system ; dont 8 paquets Python Flask/PostgreSQL. | PASS LOCAL |
| D3 | CycloneDX JSON et SPDX JSON | SBOM ; image-security.yml ; release | T14 | 8 documents validés : Git, main CI et deux plateformes de release. | PASS LOCAL |
| D4 | Comptage exact des composants | SBOM ; image-security.yml ; release | T15–T16 | 47 paquets dans chaque format ; CycloneDX Git/amd64 2186 composants dont 2139 fichiers ; arm64 2185 dont 2138 fichiers. | PASS LOCAL |
| D5 | Extraction programmable des PURL | SBOM ; image-security.yml ; release | T15 | 46 PURL distincts dans le SBOM Git ; OS sans PURL. | PASS LOCAL |
| D6 | Extraction des licences consolidées | SBOM ; image-security.yml ; release | T15 | 4 valeurs SPDX licenseConcluded ; 86 identifiants de licence CycloneDX en incluant les fichiers. | PASS LOCAL |
| D7 | Génération et archivage automatiques CI | SBOM ; image-security.yml ; release | T06–T07, T14, T16 | Artefacts SBOM main et release téléchargés ; durée 90 jours. | PASS CI |
| E1 | Grype corrèle directement le SBOM | .grype.yaml ; security.vex.json ; CI | T25–T28 | Argument sbom:sbom.cdx.json ; pas de rescan d’image Grype. | PASS LOCAL |
| E2 | HIGH/CRITICAL corrigibles bloquants | .grype.yaml ; security.vex.json ; CI | T17, T27–T28 | fail-on-severity high + only-fixed true ; gate réel code 0 ; seuil sans filtre vérifié code 2. Cas corrigible positif non injecté. | PASS LOCAL |
| E3 | Qualification OpenVEX du chemin non pertinent | .grype.yaml ; security.vex.json ; CI | T18, T25–T26 | CVE réelle CPython ssl/SNI ; chemin absent dans le serveur HTTP actuel. | PASS LOCAL |
| E4 | Justification normalisée pour chaque exemption | .grype.yaml ; security.vex.json ; CI | T18 | Unique déclaration not_affected avec vulnerable_code_not_in_execute_path ; huit PURL précis. | PASS LOCAL |
| E5 | Document VEX effectivement pris en compte | .grype.yaml ; security.vex.json ; CI | T25–T26 | 174 → 170 correspondances ; quatre Critical dans ignoredMatches namespace vex. | PASS LOCAL |
| E6 | Exceptions auditées, sans masquage silencieux | .grype.yaml ; security.vex.json ; CI | T17, T25–T26 | Rapport complet, ignoredMatches consultables ; autres 170 vulnérabilités visibles ; pas de ignore global. | PASS LOCAL |
| F1 | Publication réelle multi-architecture GHCR | publish_to_ghcr.yml ; GHCR | T42 | Index et deux manifestes lus publiquement. | PASS LOCAL |
| F2 | Signature par digest SHA256 immuable | publish_to_ghcr.yml ; GHCR | T08–T10 | Trois signatures vérifiées sur index et manifestes, pas seulement sur le tag. | PASS LOCAL |
| F3 | Clé sécurisée ou identité keyless GitHub OIDC | publish_to_ghcr.yml ; GHCR | T08–T13 | Workflow exact @refs/tags/v1.1.1 ; issuer token.actions.githubusercontent.com ; fausse identité rejetée code 12. | PASS LOCAL |
| F4 | Attestation SBOM signée attachée au manifeste distant | publish_to_ghcr.yml ; GHCR | T11–T12, T16 | Deux attestations vérifiées ; prédicats égaux aux artefacts de leurs plateformes. | PASS LOCAL |
| F5 | Prédicat normalisé encapsulé dans une attestation | publish_to_ghcr.yml ; GHCR | T11–T12, T14 | predicateType=https://cyclonedx.org/bom ; subject.digest égal au manifeste ; prédicat CycloneDX valide. | PASS LOCAL |
| F6 | Gate indépendant interrogeant le registre | publish_to_ghcr.yml ; GHCR | T06 | Job admission après validate et publish, sans image/attestation fournie par artefact local. | PASS CI |
| F7 | Vérification cryptographique bloquante signature et attestation | publish_to_ghcr.yml ; GHCR | T06, T08–T13 | Admission réussie ; vérifications publiques indépendantes ; test négatif d’identité fatal. | PASS LOCAL |
| P1 | Qualité et gouvernance : Flake8, Python, Hadolint strict | .github/workflows/quality.yml ; image-security.yml ; multi-container.yml ; publish_to_ghcr.yml | T06, T29–T31 | Succès CI et local ; BuildKit build --check exécuté en CI. | PASS LOCAL |
| P2 | BuildKit isolé, secret, Dive >80 %, détection de fuite | .github/workflows/quality.yml ; image-security.yml ; multi-container.yml ; publish_to_ghcr.yml | T06, T17, T19–T23, T32–T34 | 99.7821 % en CI ; builder d’audit neuf ; contrôle de fuite et contrôle positif réussis. | PASS CI |
| P3 | Deux SBOM, artefacts, Trivy, Grype/VEX et gates HIGH+ | .github/workflows/quality.yml ; image-security.yml ; multi-container.yml ; publish_to_ghcr.yml | T06–T07, T17, T25–T28 | Étapes CI réelles réussies, rapports complets lus et Grype reproduit. | PASS CI |
| P4 | Intégration Compose sans shell, PostgreSQL, santé et nettoyage | .github/workflows/quality.yml ; image-security.yml ; multi-container.yml ; publish_to_ghcr.yml | T35–T38 | Deux services healthy, six tests réussis, endpoints 200 ; nettoyage ciblé réussi. | PASS LOCAL |
| P5 | Bake multi-arch, SemVer, cache distribué, signature et SBOM attesté | .github/workflows/quality.yml ; image-security.yml ; multi-container.yml ; publish_to_ghcr.yml | T06, T08–T12, T42–T43 | Release 40871325590 réussie au SHA 2381039 ; index et SBOM authentifiés. | PASS CI |
| P6 | Admission indépendante après publication, distante et fatale | .github/workflows/quality.yml ; image-security.yml ; multi-container.yml ; publish_to_ghcr.yml | T06, T13 | Job 123440915746 success ; trois signatures et deux attestations ; aucune tolérance d’échec. | PASS CI |
| CI1 | Toutes les actions externes épinglées par SHA complet | .github/workflows/ | T41 | 24 occurrences vérifiées, 0 référence flottante. | PASS LOCAL |
| CI2 | Permissions minimales et contents:read lorsque suffisant | .github/workflows/ | T03, T41 | Huit workflows contents:read par défaut ; validate ajoute actions:read pour ses lectures. | PASS LOCAL |
| CI3 | packages:write limité aux jobs de publication | .github/workflows/ | T41 | publish seul ; admission packages:read. | PASS LOCAL |
| CI4 | id-token:write limité au besoin OIDC | .github/workflows/ | T41 | publish seul ; pas d’OIDC en qualité/intégration/admission. | PASS LOCAL |
| CI5 | Aucune publication non maîtrisée depuis une PR ordinaire | .github/workflows/ | T03, T41 | push tags uniquement ; contrôle type d’événement, SemVer et SHA main. | PASS LOCAL |
| CI6 | Release conditionnée aux contrôles qualité/sécurité/intégration | .github/workflows/ | T06, T41 | validate exige les deux workflows main réussis et leurs jobs requis au SHA exact. | PASS LOCAL |
| CI7 | Aucun contournement critique continue-on-error ou équivalent | .github/workflows/ | T03, T41 | Pas de continue-on-error ; bash pipefail sur les gates avec tee ; rapports informatifs distingués des gates. | PASS LOCAL |
| CI8 | Intégration sur l’image validée et liée au commit | .github/workflows/ | T03, T06 | Artefact tar vérifié par checksum, SHA Git et image ID avant Compose --no-build ; nettoyage always. | PASS LOCAL |
| R1 | README : comparatif froid/modification, cache, secret, manifeste distant | README §8 et §10 | T21–T23, T32–T34, T42–T43 | Éléments présents ; tableau mêlant bi-arch et étape pip, preuves brutes anciennes hors dépôt et scénarios divergents. | PARTIEL |
| R2 | README : requêtes JSON, nombres, PURL/licences et analyse Grype/VEX | README §9 | T15–T18, T25–T28, T43 | Requêtes et qualification valides ; résultats historiques datés, sans association précise à l’image racine/artefact qui les a produits. | PARTIEL |
| R3 | README : tag/digest GHCR, signature, attestation et extraction certifiée | README §10 | T08–T13, T40, T42 | Digests exacts ; commandes vérifiées avec Cosign 2.4.1 ; extraction de deux SBOM certifiés réussie. | PASS LOCAL |
| TP1-01 | Runtime minimal et utilisateur non-root | Dockerfile ; Compose ; Python ; CI | T32, T37–T38 | Distroless ; UID/GID 65532 sur les deux plateformes. | PASS LOCAL |
| TP1-02 | Absence de shell dans l’image finale | Dockerfile ; Compose ; Python ; CI | T37–T38 | Chemins usuels sh/bash/dash/busybox vérifiés absents ; entrée Python directe. | PASS LOCAL |
| TP1-03 | Dépendances Python verrouillées | Dockerfile ; Compose ; Python ; CI | T02, T21–T22 | Huit dépendances runtime à version exacte, hashes de wheels amd64/arm64 ; --require-hashes exécuté. | PASS LOCAL |
| TP1-04 | PostgreSQL durci et épinglé par digest | Dockerfile ; Compose ; Python ; CI | T02, T35 | Chainguard digest a1b4ecd0…, UID 70, cap_drop ALL, no-new-privileges, réseau interne ; démarrage réel réussi. | PASS LOCAL |
| TP1-05 | Endpoint Flask /health | Dockerfile ; Compose ; Python ; CI | T29, T35 | HTTP 200, JSON status=ok ; healthcheck exec Python. | PASS LOCAL |
| TP1-06 | Endpoint Flask /dbtest | Dockerfile ; Compose ; Python ; CI | T35 | HTTP 200 et SELECT 1 réel ; branches d’échec testées. | PASS LOCAL |
| TP1-07 | Tests unitaires | Dockerfile ; Compose ; Python ; CI | T29 | 5 passed, 1 deselected. | PASS LOCAL |
| TP1-08 | Tests d’intégration | Dockerfile ; Compose ; Python ; CI | T35–T36 | 6 tests au total dont 1 intégration réelle ; stack de test supprimée. | PASS LOCAL |
| TP1-09 | Flake8 | Dockerfile ; Compose ; Python ; CI | T30 | Code 0 sur la configuration du dépôt. | PASS LOCAL |
| TP1-10 | Hadolint | Dockerfile ; Compose ; Python ; CI | T31 | 2.15.1, seuil warning, code 0. | PASS LOCAL |
| TP1-11 | Dive | Dockerfile ; Compose ; Python ; CI | T17 | 0.13.1, efficacité 99.7821 %, lowestEfficiency PASS. | PASS CI |
| TP1-12 | Trivy | Dockerfile ; Compose ; Python ; CI | T17, T34 | CI : 174 occurrences, 0 HIGH/CRITICAL corrigible ; secret local sans détection. | PASS CI |
| TP1-13 | Absence de fuite du secret | Dockerfile ; Compose ; Python ; CI | T32–T34 | History, inspect, exports et scan propres ; contrôle positif détecté. | PASS LOCAL |
| TP1-14 | Compatibilité montages BuildKit avec Compose et CI | Dockerfile ; Compose ; Python ; CI | T06, T19–T23, T35, T39 | Builds effectifs avec --secret ; build.secrets Compose résolu ; CI réutilise l’image validée sans rebuild. | PASS LOCAL |

## 4. Journal des vérifications, étape par étape

### Test T01 — Identification et isolation Git

**Objectif :** auditer le dernier main sans modifier le travail existant.

**Exigence liée :** règles Git et traçabilité.

**Prérequis :** Git et accès au distant.

**Commande réellement exécutée :**

```bash
pwd
git remote -v
git status --short --branch
git fetch origin
git log -1 --oneline origin/main
git rev-parse origin/main
git worktree add -b audit/tp2-conformite-finale /tmp/tp2-audit-conformite origin/main
```

**Résultat observé :**

```text
origin https://github.com/clement-machtelinckx/linter-python-flask.git
## main...origin/main
?? .secrets/
?? docs/evidence/
bb6f32c Merge pull request #41 from clement-machtelinckx/docs/40-readme-v111-digests
Preparing worktree (new branch 'audit/tp2-conformite-finale')
HEAD is now at bb6f32c Merge pull request #41 from clement-machtelinckx/docs/40-readme-v111-digests
```

**Code de retour :** première tentative de fetch : erreur d’écriture sur `.git/FETCH_HEAD` ; nouvelle exécution autorisée : 0 ; création du worktree : 0.

**Interprétation :** le bon dépôt et le SHA de main sont établis ; aucun fichier existant n’est écrasé. Les accès Git nécessitant l’écriture dans `.git` utilisent l’autorisation spécifique de l’environnement.

**Statut :** PASS LOCAL.

**Preuve ou source :** commit `bb6f32c7b7b421d499c27e979102d80cd9e1cb0f`.

### Test T02 — Lecture du Dockerfile, des politiques et des chemins de build

**Objectif :** Identifier cache, secret, runtime et règles de sécurité.

**Exigence liée :** L1, L2, L4, A1–A3, B1–B5, B8, C1–C6, E1–E6, TP1.

**Prérequis :** Lecture des fichiers suivis.

**Commande réellement exécutée :**

```bash
cat Dockerfile docker-bake.hcl .dockerignore .gitignore .grype.yaml security.vex.json docker-compose.yml
cat .hadolint.yaml .dive-ci .trivy-secret.yaml app.py test_app.py requirements-runtime.txt
```

**Résultat observé :**

```text
Dockerfile : syntax=docker/dockerfile:1 ; cache target=/root/.cache/pip ; secret pip_token required=true.
Validation du format par grep -Eq ; aucune valeur de jeton via ARG/ENV.
Runtime distroless Python Debian 13 épinglé ; USER 65532:65532.
Bake : deux plateformes, cache registre import/export mode=max, sortie type=registry.
Grype : fail-on-severity high ; only-fixed true ; vex-documents security.vex.json.
OpenVEX : une déclaration not_affected, CVE-2026-19445, huit PURL précis amd64/arm64.
Compose : PostgreSQL Chainguard épinglé ; UID 70 ; réseau DB interne ; healthchecks exec.
Hadolint : failure-threshold warning, aucun ignore ; Dive lowestEfficiency 0.80.
Runtime : huit dépendances épinglées avec hashes de wheels.
```

**Code de retour :** 0.

**Interprétation :** Les mécanismes sont effectivement présents. Le jeton simulé est lu et validé ; aucun serveur privé n’est utilisé. La lecture statique ne démontre ni étanchéité exécutée, ni efficacité mesurée, ni authenticité de la CVE. Ces preuves sont traitées séparément.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T03 — Lecture de tous les workflows

**Objectif :** Examiner permissions, ordre et portes bloquantes.

**Exigence liée :** L6, P1–P6, obligations CI, F2–F7.

**Prérequis :** Lecture de .github/workflows.

**Commande réellement exécutée :**

```bash
cat .github/workflows/*.yml
```

**Résultat observé :**

```text
8 workflows examinés. quality → image-security → integration (workflow réutilisable).
Release : validate → publish → admission ; publication seulement sur push tags v*.
validate exige tag SemVer, SHA identique à main et succès des jobs qualité/sécurité/intégration.
publish seul : packages:write et id-token:write. admission : contents:read et packages:read.
Signatures de l’index et des deux manifestes ; attestations CycloneDX par plateforme.
Admission relit le registre, vérifie signatures et attestations puis predicateType/subject.digest.
Pas de continue-on-error dans les workflows critiques.
Déploiements manuels historiques : StrictHostKeyChecking=no ; typo « chwon » ; Compose non accompagné de son contexte de build.
```

**Code de retour :** 0.

**Interprétation :** L’orchestration critique est présente et le pipefail est fourni par shell: bash pour les portes utilisant tee. Les workflows de déploiement historiques doivent être distingués des six phases du TP2 ; leur succès n’est pas inféré. Les contrôles critiques seront confrontés à des exécutions réelles.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T04 — Inventaire des outils et accès Docker

**Objectif :** Établir les limites et éviter toute altération des ressources existantes.

**Exigence liée :** Méthode, P2, TP1.

**Prérequis :** Outils locaux.

**Commande réellement exécutée :**

```bash
docker version
docker buildx version
docker compose version
cosign version
syft version
python3 --version
gh --version
jq --version
git --version
docker info --format '{{json .ServerVersion}}'
docker buildx ls
docker ps --format '{{.Names}} {{.Image}}'
```

**Résultat observé :**

```text
Docker client/serveur 28.4.0 ; Buildx v0.28.0-desktop.1 ; Compose v2.39.4-desktop.1.
Cosign v2.4.1 ; Syft local 1.51.1 ; Python hôte 3.10.12 ; jq 1.6 ; Git 2.34.1 ; gh 2.4.0.
pytest, flake8, flask, psycopg2 absents de Python hôte ; PyYAML 5.4.1, jsonschema 3.2.0 présents.
grype, trivy, dive, hadolint absents du PATH ; images Trivy 0.75.0 et Hadolint 2.15.1 présentes.
Démon refusé en sandbox ; lecture réussie après autorisation spécifique.
Deux conteneurs préexistants du projet ; ils ne sont pas utilisés comme preuves du SHA audité.
```

**Code de retour :** 0 pour commandes de version et lecture Docker autorisée ; accès initial au socket refusé.

**Interprétation :** Docker peut être testé avec des ressources propres à l’audit. Aucun cache, volume, conteneur ou builder préexistant n’est supprimé. La version Syft installée localement diffère de celle des fichiers SBOM (1.42.0).

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T05 — Résolution Bake sur clone sans secret

**Objectif :** Vérifier le comportement réel de la commande du sujet.

**Exigence liée :** L2, C1–C6, B8.

**Prérequis :** Buildx et HCL.

**Commande réellement exécutée :**

```bash
docker buildx bake -f docker-bake.hcl --print
```

**Résultat observé :**

```text
ERROR: failed to stat secrets/pip_token.txt: stat secrets/pip_token.txt: no such file or directory
```

**Code de retour :** 1 pour la commande Bake.

**Interprétation :** Le clone isolé ne possède pas le fichier ignoré, conformément à la protection du secret. Le README indique sa création préalable ; ce prérequis ne constitue pas un défaut de Bake. La validation avec un fichier temporaire sera réalisée séparément.

**Statut :** PARTIEL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T06 — État des PR et des exécutions GitHub

**Objectif :** Revérifier les références historiques et main.

**Exigence liée :** L6, P1–P6, F1–F7, R3.

**Prérequis :** Connecteur GitHub et gh ; API GitHub en lecture.

**Commande réellement exécutée :**

```bash
gh api repos/clement-machtelinckx/linter-python-flask/actions/runs/40871325590 --jq '{id,event,status,conclusion,head_branch,head_sha,run_attempt,created_at,updated_at,html_url}'
gh api 'repos/clement-machtelinckx/linter-python-flask/actions/runs?branch=main&per_page=20' --jq '.workflow_runs[]|{id,name,head_sha,conclusion,event,html_url}'
# Complément via connecteur GitHub : fetch_pr (35, 37, 39, 41), fetch_workflow_run_jobs (40871325590, 40875267932, 40875268066), fetch_workflow_job_logs.
```

**Résultat observé :**

```text
PR 35 fusionnée : 7371c8005e4fad1d39ea1ee45efbbb3216156c88.
PR 37 fusionnée : 1fe603fcff4a31f9b27c96edb0c9f27185ccb353.
PR 39 fusionnée : 2381039ddea4924fe11f9f7b89176fe2324ef8d6.
PR 41 fusionnée : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.
Release 40871325590 : push v1.1.1, SHA 2381039ddea4924fe11f9f7b89176fe2324ef8d6, success.
Jobs validate 123438835268, publish 123438882455, admission 123440915746 : success.
Main bb6f32c : quality 40875267932 et image-security 40875268066 : success.
Qualité : 5 passed, 1 deselected ; intégration : 1 passed, 5 deselected.
Compose CI : deux services Healthy ; /dbtest successful ; conteneurs, réseaux et volume de test Removed.
Validation release : quality 40870584995 et image security 40870585138 au SHA 2381039.
Logs publish : import cache GHCR, étapes amd64/arm64 CACHED, export cache registre.
Admission : trois signatures vérifiées ; deux attestations, chacune 47 paquets.
```

**Code de retour :** 0 (gh après autorisation réseau), connecteur sans erreur.

**Interprétation :** La release est antérieure à main : elle ne doit pas être présentée comme un build de bb6f32c. Les résultats CI de main sont vérifiés séparément. Les statuts et logs réels prouvent l’exécution des phases ; ils ne remplacent pas une vérification publique Cosign indépendante.

**Statut :** PASS CI.

**Preuve ou source :** [Release](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/40871325590), [qualité main](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/40875267932), [sécurité/intégration main](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/40875268066).

### Test T07 — Existence et conservation des artefacts CI

**Objectif :** Vérifier la publication des deux formats et des rapports.

**Exigence liée :** L3, D7, E6.

**Prérequis :** API artefacts GitHub.

**Commande réellement exécutée :**

```bash
# Connecteur GitHub : fetch_workflow_run_artifacts pour 40871325590 et 40875268066.
```

**Résultat observé :**

```text
release-sbom-v1.1.1 : ID 12896073136, 873653 octets, non expiré, échéance 2027-01-27.
sbom-bb6f32c… : ID 12898225938, 436678 octets, non expiré, échéance 2027-01-27.
image-security-bb6f32c… : ID 12897828078, 176448 octets, non expiré, échéance 2026-11-05.
validated-image-bb6f32c… : ID 12897753187, 76392783 octets, non expiré, échéance 2026-11-05.
```

**Code de retour :** sans erreur API.

Les archives ont ensuite été téléchargées réellement par ces commandes (le connecteur ne renvoie qu’un lien temporaire, non conservé dans ce rapport) :

```bash
gh run download 40871325590 --repo clement-machtelinckx/linter-python-flask --name release-sbom-v1.1.1 --dir /tmp/tp2-audit-data/release
gh run download 40875268066 --repo clement-machtelinckx/linter-python-flask --name image-security-bb6f32c7b7b421d499c27e979102d80cd9e1cb0f --dir /tmp/tp2-audit-data/security
gh run download 40875268066 --repo clement-machtelinckx/linter-python-flask --name sbom-bb6f32c7b7b421d499c27e979102d80cd9e1cb0f --dir /tmp/tp2-audit-data/main-sbom
```

Les trois téléchargements se terminent avec le code 0. Ils nécessitent une session GitHub autorisée à lire les artefacts ; les vérifications GHCR/Cosign ont, elles, été exécutées avec un `DOCKER_CONFIG` temporaire contenant `{"auths":{}}`.

**Interprétation :** Les artefacts sont effectivement présents, pas simplement déclarés dans le YAML. La rétention des rapports détaillés et de l’image n’est que de sept jours ; les liens CI ne garantissent pas leur disponibilité après expiration.

**Statut :** PASS CI.

**Preuve ou source :** [Artefacts main](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/40875268066), [artefact release](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/40871325590/artifacts/12896073136).

### Test T08 — Vérification Cosign publique — index

**Objectif :** Vérifier cryptographiquement le digest depuis GHCR sans session de registre.

**Exigence liée :** L5, F2, F3, F7, R3.

**Prérequis :** Cosign 2.4.1 ; accès réseau ; DOCKER_CONFIG temporaire vide.

**Commande réellement exécutée :**

```bash
cosign verify --certificate-identity-regexp '^https://github\.com/clement-machtelinckx/linter-python-flask/\.github/workflows/publish_to_ghcr\.yml@refs/tags/v1\.1\.1$' --certificate-oidc-issuer https://token.actions.githubusercontent.com ghcr.io/clement-machtelinckx/linter-python-flask@sha256:d42185600d94df2717e26af1cd98fb360d3790142eeff61421cef601aeffe136
```

**Résultat observé :**

```text
Verification for ghcr.io/clement-machtelinckx/linter-python-flask@sha256:d42185600d94df2717e26af1cd98fb360d3790142eeff61421cef601aeffe136 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
Signatures: 1 ; subject digest: ['sha256:d42185600d94df2717e26af1cd98fb360d3790142eeff61421cef601aeffe136']
```

**Code de retour :** 0.

**Interprétation :** Le certificat, l’identité exacte du tag, l’émetteur et la transparence sont vérifiés sans désactivation. Signature authentique vérifiée pour ce digest.

**Statut :** PASS LOCAL.

**Preuve ou source :** ghcr.io/clement-machtelinckx/linter-python-flask@sha256:d42185600d94df2717e26af1cd98fb360d3790142eeff61421cef601aeffe136

### Test T09 — Vérification Cosign publique — amd64

**Objectif :** Vérifier cryptographiquement le digest depuis GHCR sans session de registre.

**Exigence liée :** L5, F2, F3, F7, R3.

**Prérequis :** Cosign 2.4.1 ; accès réseau ; DOCKER_CONFIG temporaire vide.

**Commande réellement exécutée :**

```bash
cosign verify --certificate-identity-regexp '^https://github\.com/clement-machtelinckx/linter-python-flask/\.github/workflows/publish_to_ghcr\.yml@refs/tags/v1\.1\.1$' --certificate-oidc-issuer https://token.actions.githubusercontent.com ghcr.io/clement-machtelinckx/linter-python-flask@sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b
```

**Résultat observé :**

```text
Verification for ghcr.io/clement-machtelinckx/linter-python-flask@sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
Signatures: 1 ; subject digest: ['sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b']
```

**Code de retour :** 0.

**Interprétation :** Le certificat, l’identité exacte du tag, l’émetteur et la transparence sont vérifiés sans désactivation. Signature authentique vérifiée pour ce digest.

**Statut :** PASS LOCAL.

**Preuve ou source :** ghcr.io/clement-machtelinckx/linter-python-flask@sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b

### Test T10 — Vérification Cosign publique — arm64

**Objectif :** Vérifier cryptographiquement le digest depuis GHCR sans session de registre.

**Exigence liée :** L5, F2, F3, F7, R3.

**Prérequis :** Cosign 2.4.1 ; accès réseau ; DOCKER_CONFIG temporaire vide.

**Commande réellement exécutée :**

```bash
cosign verify --certificate-identity-regexp '^https://github\.com/clement-machtelinckx/linter-python-flask/\.github/workflows/publish_to_ghcr\.yml@refs/tags/v1\.1\.1$' --certificate-oidc-issuer https://token.actions.githubusercontent.com ghcr.io/clement-machtelinckx/linter-python-flask@sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e
```

**Résultat observé :**

```text
Verification for ghcr.io/clement-machtelinckx/linter-python-flask@sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
Signatures: 1 ; subject digest: ['sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e']
```

**Code de retour :** 0.

**Interprétation :** Le certificat, l’identité exacte du tag, l’émetteur et la transparence sont vérifiés sans désactivation. Signature authentique vérifiée pour ce digest.

**Statut :** PASS LOCAL.

**Preuve ou source :** ghcr.io/clement-machtelinckx/linter-python-flask@sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e

### Test T11 — Attestation CycloneDX publique — amd64

**Objectif :** Vérifier la signature de l’attestation et son lien au manifeste.

**Exigence liée :** F4, F5, F7, R3.

**Prérequis :** Cosign 2.4.1, Python JSON/base64.

**Commande réellement exécutée :**

```bash
cosign verify-attestation --type cyclonedx --certificate-identity-regexp '^https://github\.com/clement-machtelinckx/linter-python-flask/\.github/workflows/publish_to_ghcr\.yml@refs/tags/v1\.1\.1$' --certificate-oidc-issuer https://token.actions.githubusercontent.com ghcr.io/clement-machtelinckx/linter-python-flask@sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b
# Décodage Python de payload et assertions predicateType/subject.digest.sha256.
```

**Résultat observé :**

```text
Verification for ghcr.io/clement-machtelinckx/linter-python-flask@sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
Certificate subject: https://github.com/clement-machtelinckx/linter-python-flask/.github/workflows/publish_to_ghcr.yml@refs/tags/v1.1.1
Certificate issuer URL: https://token.actions.githubusercontent.com
GitHub Workflow Trigger: push
GitHub Workflow SHA: 2381039ddea4924fe11f9f7b89176fe2324ef8d6
GitHub Workflow Name: Release to GHCR
GitHub Workflow Repository: clement-machtelinckx/linter-python-flask
GitHub Workflow Ref: refs/tags/v1.1.1
predicateType=https://cyclonedx.org/bom ; subject.digest validé ; paquets=47
```

**Code de retour :** 0.

**Interprétation :** Le SBOM est extrait uniquement après vérification cryptographique réussie. La sortie JSON est décodée par `json.loads(base64.b64decode(envelope["payload"]))`, puis le script exige `statement["predicateType"] == "https://cyclonedx.org/bom"` et `any(subject["digest"]["sha256"] == digest.removeprefix("sha256:") for subject in statement["subject"])`. La portée est le manifeste amd64, pas l’index multi-architecture.

**Statut :** PASS LOCAL.

**Preuve ou source :** ghcr.io/clement-machtelinckx/linter-python-flask@sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b

### Test T12 — Attestation CycloneDX publique — arm64

**Objectif :** Vérifier la signature de l’attestation et son lien au manifeste.

**Exigence liée :** F4, F5, F7, R3.

**Prérequis :** Cosign 2.4.1, Python JSON/base64.

**Commande réellement exécutée :**

```bash
cosign verify-attestation --type cyclonedx --certificate-identity-regexp '^https://github\.com/clement-machtelinckx/linter-python-flask/\.github/workflows/publish_to_ghcr\.yml@refs/tags/v1\.1\.1$' --certificate-oidc-issuer https://token.actions.githubusercontent.com ghcr.io/clement-machtelinckx/linter-python-flask@sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e
# Décodage Python de payload et assertions predicateType/subject.digest.sha256.
```

**Résultat observé :**

```text
Verification for ghcr.io/clement-machtelinckx/linter-python-flask@sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
Certificate subject: https://github.com/clement-machtelinckx/linter-python-flask/.github/workflows/publish_to_ghcr.yml@refs/tags/v1.1.1
Certificate issuer URL: https://token.actions.githubusercontent.com
GitHub Workflow Trigger: push
GitHub Workflow SHA: 2381039ddea4924fe11f9f7b89176fe2324ef8d6
GitHub Workflow Name: Release to GHCR
GitHub Workflow Repository: clement-machtelinckx/linter-python-flask
GitHub Workflow Ref: refs/tags/v1.1.1
predicateType=https://cyclonedx.org/bom ; subject.digest validé ; paquets=47
```

**Code de retour :** 0.

**Interprétation :** Le SBOM est extrait uniquement après vérification cryptographique réussie. La sortie JSON est décodée par `json.loads(base64.b64decode(envelope["payload"]))`, puis le script exige `statement["predicateType"] == "https://cyclonedx.org/bom"` et `any(subject["digest"]["sha256"] == digest.removeprefix("sha256:") for subject in statement["subject"])`. La portée est le manifeste arm64, pas l’index multi-architecture.

**Statut :** PASS LOCAL.

**Preuve ou source :** ghcr.io/clement-machtelinckx/linter-python-flask@sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e

### Test T13 — Rejet d’une identité Cosign étrangère

**Objectif :** Prouver que la contrainte d’identité est bloquante.

**Exigence liée :** F3, F7, P6.

**Prérequis :** Même image signée que T08.

**Commande réellement exécutée :**

```bash
cosign verify --certificate-identity-regexp '^https://github.com/foreign/repository/.*$' --certificate-oidc-issuer https://token.actions.githubusercontent.com ghcr.io/clement-machtelinckx/linter-python-flask@sha256:d42185600d94df2717e26af1cd98fb360d3790142eeff61421cef601aeffe136
```

**Résultat observé :**

```text
Error: no matching signatures: none of the expected identities matched what was in the certificate, got subjects [https://github.com/clement-machtelinckx/linter-python-flask/.github/workflows/publish_to_ghcr.yml@refs/tags/v1.1.1] with issuer https://token.actions.githubusercontent.com
main.go:69: error during command execution: no matching signatures: none of the expected identities matched what was in the certificate, got subjects [https://github.com/clement-machtelinckx/linter-python-flask/.github/workflows/publish_to_ghcr.yml@refs/tags/v1.1.1] with issuer https://token.actions.githubusercontent.com
```

**Code de retour :** 12.

**Interprétation :** Un rejet avec erreur de certificat prouve le contrôle négatif ; un simple problème réseau ne le prouverait pas.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T14 — Validation des SBOM contre les schémas officiels

**Objectif :** Vérifier les vrais standards JSON des fichiers Git, CI et release.

**Exigence liée :** L3, D3.

**Prérequis :** jsonschema 3.2.0 Draft7, schémas officiels téléchargés.

**Commande réellement exécutée :**

```bash
python3 /tmp/tp2-audit-data/validate_sbom.py
```

**Résultat observé :**

```text
Git cdx: VALIDE
Git spdx: VALIDE
main CI cdx: VALIDE
main CI spdx: VALIDE
release amd64 cdx: VALIDE
release amd64 spdx: VALIDE
release arm64 cdx: VALIDE
release arm64 spdx: VALIDE
```

**Code de retour :** 0.

**Interprétation :** Les huit fichiers ont été validés contre CycloneDX 1.6 et SPDX 2.3, références locales de schémas incluses. Le script utilise exactement `Draft7Validator(schema, resolver=RefResolver.from_schema(schema, store=store), format_checker=FormatChecker()).iter_errors(document)` ; `store` associe les `$id` HTTP et HTTPS aux schémas locaux `bom-1.6.schema.json`, `spdx.schema.json`, `jsf-0.82.schema.json` et `spdx-2.3.json`. Les documents sont ceux de la racine, de `main-sbom/` et de `release/sbom/` pour amd64 et arm64. Schémas complémentaires téléchargés depuis `https://cyclonedx.org/schema/spdx.schema.json` et `https://cyclonedx.org/schema/jsf-0.82.schema.json`. Une conformité de schéma ne garantit pas l’exhaustivité du graphe de dépendances.

**Statut :** PASS LOCAL.

**Preuve ou source :** [CycloneDX 1.6](https://cyclonedx.org/schema/bom-1.6.schema.json), [SPDX 2.3](https://github.com/spdx/spdx-spec/blob/v2.3/schemas/spdx-schema.json).

### Test T15 — Comptages, PURL, licences et graphe

**Objectif :** Quantifier précisément le contenu et les dépendances.

**Exigence liée :** D2, D4, D5, D6, R2.

**Prérequis :** JSON des deux SBOM à la racine.

**Commande réellement exécutée :**

```bash
jq '[.components[] | select(.type != "file")] | length' sbom.cdx.json
jq '.packages | length' sbom.spdx.json
jq -r '.components[] | select(.purl != null) | .purl' sbom.cdx.json
jq -r '[.packages[].licenseConcluded] | unique[]' sbom.spdx.json
# Analyse complémentaire Python des types, relations et références dans validate_sbom.py.
```

**Résultat observé :**

```text
CycloneDX types : {'library': 46, 'operating-system': 1, 'file': 2139}
CycloneDX non-file : 47 ; SPDX packages : 47.
PURL : 46 ; uniques : 46 ; composants non-file sans PURL : 1.
Licences CycloneDX uniques : 86 ; SPDX licenseConcluded uniques : 4.
Licences SPDX : BSD-3-Clause, LicenseRef-5a5e7ca0e9f3f9679977e3a3e9ede45ad92885a3297ea78e766979f9866c5a16, MIT, NOASSERTION
Graphe CycloneDX : 34 entrées ; 76 arêtes ; références inconnues : 0.
Relations SPDX : 2299 ; types : {'CONTAINS': 2091, 'DEPENDENCY_OF': 76, 'OTHER': 131, 'DESCRIBES': 1}.
Python : blinker@1.9.0 ; click@8.5.0 ; flask@3.1.3 ; itsdangerous@2.2.0 ; jinja2@3.1.6 ; markupsafe@3.0.4 ; psycopg2-binary@2.9.13 ; werkzeug@3.1.9
```

**Code de retour :** 0.

**Interprétation :** Les paquets Python et système sont présents. Les fichiers expliquent la différence entre total de composants et nombre de paquets. Les champs de licences peuvent contenir NOASSERTION et des LicenseRef. Le détail des arêtes applicatives est examiné séparément.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

Préparation des builds T19–T23 : le script d’essai a exécuté les opérations Python suivantes (valeur du jeton jamais affichée), puis la création du builder ci-dessous. Pour rejouer ailleurs, choisir un nom de builder neuf et un répertoire temporaire propres à l’essai.

```python
from pathlib import Path
import shutil, secrets
repo = Path("/tmp/tp2-audit-conformite")
root = Path("/tmp/tp2-audit-data")
ctx = root / "build-context"
ctx.mkdir(exist_ok=True)
for name in ["Dockerfile", ".dockerignore", "requirements-runtime.txt", "app.py"]:
    shutil.copy2(repo / name, ctx / name)
secret = root / "simulated-token"
secret.write_text("tok_" + secrets.token_hex(24) + "\n")
secret.chmod(0o600)
bad = root / "invalid-token"
bad.write_text("invalid\n")
bad.chmod(0o600)
```

```bash
docker buildx create --name tp2-audit-bb6f32c --driver docker-container --driver-opt image=moby/buildkit@sha256:cec9f139f45e93c5c69c60f8b07cfad9f43f4ef6b6a6cd917527fea5ff2e3dea
```

Entre T21 et T22, le script ajoute uniquement `# Audit cache : modification mineure du manifeste.` à la copie temporaire de `requirements-runtime.txt`. Les durées sont mesurées avec `time.monotonic()` autour de chaque commande ; `Downloading` et `Using cached` sont comptés dans sa sortie, `CACHED` sur les lignes `#<nombre> CACHED`. Les sources de jetons ont été supprimées après les essais ; elles doivent être recréées pour une reproduction.

### Test T19 — Build sans secret

**Objectif :** Mesurer le cache pip et vérifier les préconditions du secret.

**Exigence liée :** A2–A5, B1, B3–B5, R1.

**Prérequis :** Builder docker-container neuf ; contexte copié depuis le SHA audité ; jeton simulé éphémère.

**Commande réellement exécutée :**

```bash
docker buildx build --builder tp2-audit-bb6f32c --platform linux/amd64 --progress=plain --load --tag tp2-audit-bb6f32c:t19 --no-cache /tmp/tp2-audit-data/build-context
```

**Résultat observé :**

```text
{"test": "T19", "duration": 21.157, "exit": 1, "Downloading": 0, "Using_cached": 0, "CACHED": 0}
#1 DONE 5.4s
#2 DONE 0.1s
#3 DONE 2.1s
#4 DONE 1.6s
#5 DONE 1.1s
#6 DONE 1.6s
#7 DONE 0.0s
#8 DONE 0.1s
#9 DONE 0.8s
#10 DONE 7.0s
#10 DONE 8.8s
#10 DONE 8.8s
#11 DONE 0.2s
#12 DONE 0.0s
#13 ERROR: secret pip_token: not found
ERROR: failed to build: failed to solve: secret pip_token: not found
```

**Code de retour :** 1.

**Interprétation :** Chronométrage monotone réel. Builder propre à l’audit, aucun prune. Échec attendu de la précondition, avec cache de couches explicitement désactivé.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T20 — Build avec secret invalide

**Objectif :** Mesurer le cache pip et vérifier les préconditions du secret.

**Exigence liée :** A2–A5, B1, B3–B5, R1.

**Prérequis :** Builder docker-container neuf ; contexte copié depuis le SHA audité ; jeton simulé éphémère.

**Commande réellement exécutée :**

```bash
docker buildx build --builder tp2-audit-bb6f32c --platform linux/amd64 --progress=plain --load --tag tp2-audit-bb6f32c:t20 --no-cache --secret id=pip_token,src=/tmp/tp2-audit-data/invalid-token /tmp/tp2-audit-data/build-context
```

**Résultat observé :**

```text
{"test": "T20", "duration": 1.216, "exit": 1, "Downloading": 0, "Using_cached": 0, "CACHED": 2}
#1 DONE 0.0s
#2 DONE 0.3s
#3 CACHED
#4 DONE 0.0s
#5 DONE 0.0s
#6 DONE 0.0s
#7 DONE 0.0s
#8 DONE 0.0s
#9 CACHED
#10 DONE 0.0s
#12 ERROR: process "/bin/sh -c grep -Eq '^tok_[0-9a-f]{48}$' /run/secrets/pip_token     && python -m pip install --no-compile --only-binary=:all: --require-hashes     --target=/opt/python -r requirements-runtime.txt     && rm -rf /opt/python/bin" did not complete successfully: exit code: 1
ERROR: failed to build: failed to solve: process "/bin/sh -c grep -Eq '^tok_[0-9a-f]{48}$' /run/secrets/pip_token     && python -m pip install --no-compile --only-binary=:all: --require-hashes     --target=/opt/python -r requirements-runtime.txt     && rm -rf /opt/python/bin" did not complete successfully: exit code: 1
```

**Code de retour :** 1.

**Interprétation :** Chronométrage monotone réel. Builder propre à l’audit, aucun prune. Échec attendu de la précondition, avec cache de couches explicitement désactivé.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T21 — Build froid isolé

**Objectif :** Mesurer le cache pip et vérifier les préconditions du secret.

**Exigence liée :** A2–A5, B1, B3–B5, R1.

**Prérequis :** Builder docker-container neuf ; contexte copié depuis le SHA audité ; jeton simulé éphémère.

**Commande réellement exécutée :**

```bash
docker buildx build --builder tp2-audit-bb6f32c --platform linux/amd64 --progress=plain --load --tag tp2-audit-bb6f32c:t21 --secret id=pip_token,src=/tmp/tp2-audit-data/simulated-token /tmp/tp2-audit-data/build-context
```

**Résultat observé :**

```text
{"test": "T21", "duration": 8.722, "exit": 0, "Downloading": 8, "Using_cached": 0, "CACHED": 3}
#1 DONE 0.0s
#2 DONE 0.3s
#3 CACHED
#4 DONE 0.0s
#5 DONE 0.0s
#6 DONE 0.0s
#7 DONE 0.0s
#8 DONE 0.0s
#9 CACHED
#10 CACHED
#11 DONE 2.6s
#11 DONE 2.7s
#11 DONE 2.9s
#11 DONE 3.3s
#12 3.359   Downloading flask-3.1.3-py3-none-any.whl (103 kB)
#11 DONE 3.6s
#12 3.495   Downloading werkzeug-3.1.9-py3-none-any.whl (228 kB)
#11 DONE 3.7s
#11 DONE 3.8s
#12 3.784   Downloading psycopg2_binary-2.9.13-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.whl (4.3 MB)
#11 DONE 3.9s
#11 DONE 4.1s
#11 DONE 4.2s
#11 DONE 4.7s
#12 4.270   Downloading blinker-1.9.0-py3-none-any.whl (8.5 kB)
#12 4.339   Downloading click-8.5.0-py3-none-any.whl (125 kB)
#12 4.410   Downloading itsdangerous-2.2.0-py3-none-any.whl (16 kB)
#12 4.483   Downloading jinja2-3.1.6-py3-none-any.whl (134 kB)
#12 4.599   Downloading markupsafe-3.0.4-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl (23 kB)
#11 DONE 4.9s
#11 DONE 5.1s
#11 DONE 5.1s
#13 DONE 0.1s
#12 DONE 5.4s
#14 DONE 0.1s
#15 DONE 0.0s
#16 DONE 2.1s
#17 DONE 0.0s
```

**Code de retour :** 0.

**Interprétation :** Chronométrage monotone réel. Builder propre à l’audit, aucun prune. Comparaison limitée à amd64. Le commentaire modifie seulement le manifeste copié dans /tmp, jamais le fichier du dépôt.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T22 — Build chaud après modification mineure

**Objectif :** Mesurer le cache pip et vérifier les préconditions du secret.

**Exigence liée :** A2–A5, B1, B3–B5, R1.

**Prérequis :** Builder docker-container neuf ; contexte copié depuis le SHA audité ; jeton simulé éphémère.

**Commande réellement exécutée :**

```bash
docker buildx build --builder tp2-audit-bb6f32c --platform linux/amd64 --progress=plain --load --tag tp2-audit-bb6f32c:t22 --secret id=pip_token,src=/tmp/tp2-audit-data/simulated-token /tmp/tp2-audit-data/build-context
```

**Résultat observé :**

```text
{"test": "T22", "duration": 4.863, "exit": 0, "Downloading": 0, "Using_cached": 8, "CACHED": 5}
#1 DONE 0.0s
#2 DONE 0.3s
#3 CACHED
#4 DONE 0.0s
#5 DONE 0.0s
#6 DONE 0.0s
#7 DONE 0.0s
#8 DONE 0.0s
#9 CACHED
#10 DONE 0.0s
#11 DONE 0.1s
#12 1.447   Using cached flask-3.1.3-py3-none-any.whl (103 kB)
#12 1.477   Using cached werkzeug-3.1.9-py3-none-any.whl (228 kB)
#12 1.619   Using cached psycopg2_binary-2.9.13-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.whl (4.3 MB)
#12 1.681   Using cached blinker-1.9.0-py3-none-any.whl (8.5 kB)
#12 1.690   Using cached click-8.5.0-py3-none-any.whl (125 kB)
#12 1.695   Using cached itsdangerous-2.2.0-py3-none-any.whl (16 kB)
#12 1.703   Using cached jinja2-3.1.6-py3-none-any.whl (134 kB)
#12 1.740   Using cached markupsafe-3.0.4-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl (23 kB)
#12 DONE 2.2s
#13 CACHED
#14 CACHED
#15 CACHED
#16 DONE 1.3s
#17 DONE 0.0s
```

**Code de retour :** 0.

**Interprétation :** Chronométrage monotone réel. Builder propre à l’audit, aucun prune. Comparaison limitée à amd64. Le commentaire modifie seulement le manifeste copié dans /tmp, jamais le fichier du dépôt.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T23 — Rebuild sans modification

**Objectif :** Mesurer le cache pip et vérifier les préconditions du secret.

**Exigence liée :** A2–A5, B1, B3–B5, R1.

**Prérequis :** Builder docker-container neuf ; contexte copié depuis le SHA audité ; jeton simulé éphémère.

**Commande réellement exécutée :**

```bash
docker buildx build --builder tp2-audit-bb6f32c --platform linux/amd64 --progress=plain --load --tag tp2-audit-bb6f32c:t23 --secret id=pip_token,src=/tmp/tp2-audit-data/simulated-token /tmp/tp2-audit-data/build-context
```

**Résultat observé :**

```text
{"test": "T23", "duration": 2.406, "exit": 0, "Downloading": 0, "Using_cached": 0, "CACHED": 7}
#1 DONE 0.0s
#2 DONE 0.3s
#3 CACHED
#4 DONE 0.0s
#5 DONE 0.0s
#6 DONE 0.0s
#7 DONE 0.0s
#8 DONE 0.0s
#9 DONE 0.0s
#10 CACHED
#11 CACHED
#12 CACHED
#13 CACHED
#14 CACHED
#15 CACHED
#16 DONE 1.2s
#17 DONE 0.0s
```

**Code de retour :** 0.

**Interprétation :** Chronométrage monotone réel. Builder propre à l’audit, aucun prune. Comparaison limitée à amd64. Le commentaire modifie seulement le manifeste copié dans /tmp, jamais le fichier du dépôt.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T16 — Correspondance Git / CI / release / attestations

**Objectif :** Distinguer architectures et images effectivement inventoriées.

**Exigence liée :** L3, D2, D7, F4, F5, R2.

**Prérequis :** Artefacts téléchargés et prédicats certifiés T11/T12.

**Commande réellement exécutée :**

```bash
python3 /tmp/tp2-audit-data/compare_sbom.py
```

**Résultat observé :**

```text
Git: 2186 composants, 47 paquets ; source sha256:8df539d2a749256476f8b0a8b11548356b950be9f20d332019198bfc5f13c039
main CI: 2186 composants, 47 paquets ; source sha256:3058b6797ddfa05773d778e73a69b10f4cec0011193c0c379101dce2f42ee11f
release amd64: 2186 composants, 47 paquets ; source sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b
release arm64: 2185 composants, 47 paquets ; source sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e
PURL Git = main CI = release amd64 : True
PURL amd64 = arm64 : False
Prédicat certifié amd64 identique au SBOM CycloneDX de l’artefact : True
Prédicat certifié arm64 identique au SBOM CycloneDX de l’artefact : True
flask dépend de blinker, click, itsdangerous, jinja2, markupsafe, werkzeug
jinja2 dépend de markupsafe
werkzeug dépend de markupsafe
Syft déclaré dans tous les SBOM : 1.42.0. 47 paquets sur chaque plateforme ; nombres de fichiers distincts.
```

**Code de retour :** 0.

**Interprétation :** Le contenu certifié correspond exactement aux artefacts de release. La comparaison est une égalité des objets JSON décodés : `json.load(statement)["predicate"] == json.load(sbom_release)` pour chaque plateforme ; les PURL sont comparés sous forme d’ensembles des champs `purl` des composants. Elle ne compare donc pas seulement les nombres. Les PURL amd64 sont équivalents, mais les documents complets ne sont pas identiques : provenance, horodatage et composants fichiers diffèrent. La racine Git identifie 8df539d2…, qui n’est ni le manifeste publié ni l’image CI actuelle. Le README dit « commit courant » sans fournir de lien reproductible entre cet ID local et un SHA Git : réserve de traçabilité documentaire.

**Statut :** PARTIEL.

**Preuve ou source :** [Release](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/40871325590), [main](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/40875268066).

### Test T17 — Analyse des rapports de sécurité actuels

**Objectif :** Lire les résultats réels et les vulnérabilités résiduelles.

**Exigence liée :** L4, E2, E5, E6, P2, P3, TP1.

**Prérequis :** Artefact image-security de main.

**Commande réellement exécutée :**

```bash
cat /tmp/tp2-audit-data/security/tools.txt
cat /tmp/tp2-audit-data/security/dive.txt
cat /tmp/tp2-audit-data/security/trivy-secret.txt
cat /tmp/tp2-audit-data/security/trivy-config.txt
cat /tmp/tp2-audit-data/security/grype-gate.txt
# Lecture JSON et comptage de grype-full.json et trivy-full.json dans compare_sbom.py.
```

**Résultat observé :**

```text
Grype 0.108.0 : 170 correspondances actives ; 4 ignorées via VEX.
Sévérités actives : {'High': 41, 'Medium': 66, 'Negligible': 49, 'Low': 14}.
États de correction : {'wont-fix': 120, 'not-fixed': 50}.
Base Grype : 2026-10-29T06:23:34Z ; valide=True.
CVE-2026-19445 : quatre paquets CPython, état wont-fix, règle namespace=vex/vex-status=not_affected.
Grype gate : No vulnerabilities found ; étape success.
Trivy 0.75.0 : 174 occurrences ; {'MEDIUM': 88, 'LOW': 53, 'UNKNOWN': 7, 'HIGH': 26}.
Trivy HIGH/CRITICAL avec FixedVersion : 0.
Dive 0.13.1 : 99.7821 %, 321630 octets gaspillés, règle lowestEfficiency PASS.
Trivy config Dockerfile : 0 mauvaise configuration HIGH/CRITICAL ; secret image : aucune détection ; contrôle positif de la règle réussi (étape globale success).
```

**Code de retour :** 0.

**Interprétation :** Les portes n’annoncent pas une image sans vulnérabilités : elles excluent les défauts sans correctif et Grype applique une qualification contextuelle ciblée. Les chiffres historiques du README (168 Grype et 159 Trivy dans une autre section) ne sont pas ceux de cette CI actuelle. Les rapports complets actuels restent disponibles seulement sept jours.

**Statut :** PASS CI.

**Preuve ou source :** [Sécurité main, job 123452475987](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/40875268066/job/123452475987).

### Test T18 — Validation formelle et justification OpenVEX

**Objectif :** Vérifier le format et la réalité de la vulnérabilité exemptée.

**Exigence liée :** L4, E3, E4, E6.

**Prérequis :** jsonschema 4.23.0 isolé, schéma officiel, source Debian.

**Commande réellement exécutée :**

```bash
# Téléchargement du schéma : URL du tag v0.2.0 en 404, puis fichier officiel main.
curl -fLsS https://raw.githubusercontent.com/openvex/spec/main/openvex_json_schema.json -o /tmp/tp2-audit-data/schemas/openvex.json
# Validation : Draft202012Validator(schema, format_checker=FormatChecker()).iter_errors(document)
curl -fLsS https://security-tracker.debian.org/tracker/CVE-2026-19445 -o /tmp/tp2-audit-data/debian-cve.html
```

**Résultat observé :**

```text
OpenVEX 0.2.0 : 0 erreur(s) de schéma Draft 2020-12.

CVE réelle : CPython ssl, use-after-free côté serveur avec callback SNI et changement de contexte.
Debian trixie python3.13 3.13.5-2+deb13u5 : vulnerable ; annotation no-dsa (Minor issue).
Déclaration : huit PURL versionnés/architecturés, un seul identifiant CVE ; statut not_affected ; justification vulnerable_code_not_in_execute_path.
app.py : serveur HTTP sans ssl_context ; aucune création de SSLContext ni sni_callback.
```

**Code de retour :** 0.

**Interprétation :** L’exemption est justifiée pour le chemin HTTP de ce conteneur. Ajouter un serveur TLS Python utilisant SNI, modifier le point d’entrée ou les bibliothèques concernées impose sa réévaluation. Le document est valide sans subcomponents : les paquets précis figurent directement dans products. « wont-fix » est un état de la base Grype ; Debian publie la nuance no-dsa, pas une garantie de non-correction définitive.

**Statut :** PASS LOCAL.

**Preuve ou source :** [Schéma OpenVEX au commit 61b5f885d0f481f48683c93345e49ef1a6e9fdff](https://github.com/openvex/spec/blob/61b5f885d0f481f48683c93345e49ef1a6e9fdff/openvex_json_schema.json), [Debian](https://security-tracker.debian.org/tracker/CVE-2026-19445), [analyse amont CPython](https://github.com/python/cpython/issues/156293).

### Test T29 — Pytest unitaire

**Objectif :** Rejouer la qualité sur les fichiers actuels montés en lecture seule.

**Exigence liée :** P1, L1, TP1.

**Prérequis :** Conteneurs outils existants ; pytest 9.1.1 et flake8 7.3.0 ; Python 3.13.16.

**Commande réellement exécutée :**

```bash
docker run --rm --network none --read-only --tmpfs /tmp --mount type=bind,src=/tmp/tp2-audit-conformite,dst=/work,readonly --workdir /work --env PYTHONDONTWRITEBYTECODE=1 flask-tp2-tests:latest python -m pytest -m "not integration" -p no:cacheprovider
```

**Résultat observé :**

```text
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0
rootdir: /work
configfile: pytest.ini
collected 6 items / 1 deselected / 5 selected

test_app.py .....                                                        [100%]

======================= 5 passed, 1 deselected in 0.84s ========================
```

**Code de retour :** 0.

**Interprétation :** La première tentative Pytest sur système entièrement read-only a échoué faute de répertoire temporaire ; l’ajout de /tmp en tmpfs permet l’exécution. Les cinq tests sélectionnés incluent /health et les branches /dbtest simulées, pas une connexion PostgreSQL réelle.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T30 — Flake8

**Objectif :** Rejouer la qualité sur les fichiers actuels montés en lecture seule.

**Exigence liée :** P1, L1, TP1.

**Prérequis :** Conteneurs outils existants ; pytest 9.1.1 et flake8 7.3.0 ; Python 3.13.16.

**Commande réellement exécutée :**

```bash
docker run --rm --network none --read-only --tmpfs /tmp --mount type=bind,src=/tmp/tp2-audit-conformite,dst=/work,readonly --workdir /work --env PYTHONDONTWRITEBYTECODE=1 flask-tp2-tests:latest python -m flake8 --config=.flake8 .
```

**Résultat observé :**

```text
(aucune sortie)
```

**Code de retour :** 0.

**Interprétation :** La configuration .flake8 existante est conservée.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T31 — Hadolint strict

**Objectif :** Rejouer la qualité sur les fichiers actuels montés en lecture seule.

**Exigence liée :** P1, L1, TP1.

**Prérequis :** Conteneurs outils existants ; pytest 9.1.1 et flake8 7.3.0 ; Python 3.13.16.

**Commande réellement exécutée :**

```bash
docker run --rm --network none --read-only --tmpfs /tmp --mount type=bind,src=/tmp/tp2-audit-conformite,dst=/work,readonly --workdir /work --env PYTHONDONTWRITEBYTECODE=1 hadolint/hadolint:v2.15.1@sha256:32dac94127fd60b7b7e3fbfc65e1383b9b5e25c9bfd7b8536de7a539fe68a12d hadolint --config .hadolint.yaml Dockerfile
```

**Résultat observé :**

```text
(aucune sortie)
```

**Code de retour :** 0.

**Interprétation :** Application de la configuration du dépôt, sans fichier modifié et sans réseau. Hadolint est au seuil warning et aucun ignore n’est déclaré. Le cache BuildKit est reconnu par Hadolint 2.15.1.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T24 — Bake paramétré avec secret temporaire

**Objectif :** Valider HCL et expansion des variables sans construire.

**Exigence liée :** L2, C1–C6.

**Prérequis :** Buildx 0.28 ; source temporaire du secret hors dépôt.

**Commande réellement exécutée :**

```bash
REGISTRY=ghcr.io/audit-example IMAGE=sample TAGS=v9.8.7,latest CACHE_REF=ghcr.io/audit-example/sample:cache docker buildx bake -f docker-bake.hcl --set api.secret=id=pip_token,src=/tmp/tp2-audit-data/simulated-token --print
```

**Résultat observé :**

```text
#1 [internal] load local bake definitions
#1 reading docker-bake.hcl 1.41kB / 1.41kB done
#1 DONE 0.0s
ERROR: unknown key: secret
```

**Code de retour :** 1.

**Interprétation :** La commande échoue sur « unknown key: secret » avec Buildx local 0.28. Ce résultat ne valide aucune expansion. Il expose une limite de compatibilité du flag --set du workflow avec cet outil local ; la résolution sans surcharge est rejouée en T39 et l’exécution du workflow récent est prouvée en CI.

**Statut :** PARTIEL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T32 — Étanchéité réelle et résidus de cache

**Objectif :** Chercher le jeton simulé dans les métadonnées et systèmes de fichiers.

**Exigence liée :** A5, B5, B6, B8, L1, TP1.

**Prérequis :** Images issues des builds T21 et étage builder exporté.

**Commande réellement exécutée :**

```bash
docker history --no-trunc tp2-audit-bb6f32c:t21
docker image inspect tp2-audit-bb6f32c:t21
# Mêmes commandes sur tp2-audit-bb6f32c:builder ; capture interne et comptage sans affichage.
# Pour chaque image : docker create ; docker export --output /tmp/tp2-audit-data/<image>-filesystem.tar <id> ; docker rm <id>.
# Lecture du tar Python, recherche des octets du jeton et des chemins de cache.
```

**Résultat observé :**

```text
final: occurrences jeton history=0, inspect=0, filesystem=0 ; fichier monté résiduel=0 ; chemins cache Python/pip=0
builder: occurrences jeton history=0, inspect=0, filesystem=0 ; fichier monté résiduel=0 ; chemins cache Python/pip=581
```

**Code de retour :** 0.

**Interprétation :** La valeur du jeton n’est jamais affichée. Le fichier du montage est absent après RUN, y compris dans le builder. L’export aplatit le système de fichiers final ; l’analyse de chaque couche est complétée par Trivy. Les 581 chemins __pycache__ du builder (dont 483 .pyc) proviennent de son environnement Python ; aucun chemin .cache/pip n’y est exporté et aucun de ces chemins ne subsiste dans le runtime final. Ces essais utilisent un jeton de simulation propre à l’audit, pas les secrets du développeur.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T33 — Contrôle positif Trivy Secret

**Objectif :** Vérifier que le scanner détecte le jeton et reste silencieux sur l’image.

**Exigence liée :** B7, L1, P2, TP1.

**Prérequis :** Trivy 0.75.0, règle du dépôt, archive image et jeton éphémère.

**Commande réellement exécutée :**

```bash
docker run --rm --network none --tmpfs /tmp --mount type=bind,src=/tmp/tp2-audit-data,dst=/audit,readonly --mount type=bind,src=/tmp/tp2-audit-conformite/.trivy-secret.yaml,dst=/secret-config.yaml,readonly aquasec/trivy:0.75.0 --cache-dir /tmp/trivy --quiet fs --scanners secret --secret-config /secret-config.yaml --exit-code 1 --format json /audit/simulated-token
```

**Résultat observé :**

```text
Code=1 ; secrets détectés=1 ; règles=['simulated-pip-token']. Valeurs et extraits sensibles supprimés.
```

**Code de retour :** 1.

**Interprétation :** Le contrôle positif doit produire une détection de la règle attendue ; aucun extrait contenant le jeton n’est conservé dans le rapport. Le scan image traite les couches de l’archive Docker, sans exécution de l’application.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T34 — Trivy Secret sur les couches de l’image

**Objectif :** Vérifier que le scanner détecte le jeton et reste silencieux sur l’image.

**Exigence liée :** B7, L1, P2, TP1.

**Prérequis :** Trivy 0.75.0, règle du dépôt, archive image et jeton éphémère.

**Commande réellement exécutée :**

```bash
docker run --rm --network none --tmpfs /tmp --mount type=bind,src=/tmp/tp2-audit-data,dst=/audit,readonly --mount type=bind,src=/tmp/tp2-audit-conformite/.trivy-secret.yaml,dst=/secret-config.yaml,readonly aquasec/trivy:0.75.0 --cache-dir /tmp/trivy --quiet image --input /audit/image-audit.tar --scanners secret --secret-config /secret-config.yaml --exit-code 1 --format json
```

**Résultat observé :**

```text
Code=0 ; secrets détectés=0 ; règles=[]. Valeurs et extraits sensibles supprimés.
```

**Code de retour :** 0.

**Interprétation :** Le contrôle positif doit produire une détection de la règle attendue ; aucun extrait contenant le jeton n’est conservé dans le rapport. Le scan image traite les couches de l’archive Docker, sans exécution de l’application.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T35 — Intégration Compose isolée et six tests Pytest

**Objectif :** Vérifier le vrai chemin Flask/PostgreSQL et préserver la stack existante.

**Exigence liée :** P4, TP1, B8.

**Prérequis :** Image construite T21 ; PostgreSQL Chainguard du Compose ; projet et volume propres à l’audit.

**Commande réellement exécutée :**

```bash
docker compose --project-name tp2-audit-bb6f32c --file /tmp/tp2-audit-conformite/docker-compose.yml --file /tmp/tp2-audit-data/compose.override.yml config --quiet
docker compose --project-name tp2-audit-bb6f32c --file /tmp/tp2-audit-conformite/docker-compose.yml --file /tmp/tp2-audit-data/compose.override.yml up --no-build --wait --wait-timeout 90 api-python db
# GET /health et /dbtest par urllib.request sur le port dynamique retourné par compose port.
docker run --rm --network tp2-audit-bb6f32c_database --read-only --tmpfs /tmp --mount type=bind,src=/tmp/tp2-audit-conformite,dst=/work,readonly --workdir /work --env PYTHONDONTWRITEBYTECODE=1 --env DB_HOST=db --env DB_PORT=5432 --env DB_USER --env DB_PASSWORD --env DB_NAME flask-tp2-tests:latest python -m pytest -v -p no:cacheprovider
```

**Résultat observé :**

```text
compose config --quiet exit=0
compose up exit=0
/health : HTTP 200 {"status":"ok"}
/dbtest : HTTP 200 {"db_connection":"successful"}
api-python: healthy
db: healthy
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /usr/local/bin/python
rootdir: /work
configfile: pytest.ini
collecting ... collected 6 items

test_app.py::test_health PASSED                                          [ 16%]
test_app.py::test_hello PASSED                                           [ 33%]
test_app.py::test_dbtest PASSED                                          [ 50%]
test_app.py::test_dbtest_connection_failure PASSED                       [ 66%]
test_app.py::test_dbtest_query_result[result0-200-expected_body0] PASSED [ 83%]
test_app.py::test_dbtest_query_result[None-500-expected_body1] PASSED    [100%]

============================== 6 passed in 0.46s ===============================
```

**Code de retour :** 0.

**Interprétation :** Les tests utilisent le code courant en lecture seule et une base réelle. Le port est attribué dynamiquement sur 127.0.0.1. Les identifiants aléatoires passent par l’environnement, sans affichage. --no-build ne nécessite pas la source locale du secret de build ; la compatibilité du build lui-même est vérifiée par T19–T23 et la résolution Compose.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T36 — Nettoyage ciblé de l’intégration

**Objectif :** Vérifier la suppression des seules ressources de test créées.

**Exigence liée :** P4, règles Git/Docker.

**Prérequis :** Projet Compose nommé tp2-audit-bb6f32c.

**Commande réellement exécutée :**

```bash
docker compose --project-name tp2-audit-bb6f32c --file /tmp/tp2-audit-conformite/docker-compose.yml --file /tmp/tp2-audit-data/compose.override.yml down --volumes --remove-orphans
docker ps -a --filter label=com.docker.compose.project=tp2-audit-bb6f32c --format '{{.Names}}'
docker volume ls --filter label=com.docker.compose.project=tp2-audit-bb6f32c --format '{{.Name}}'
```

**Résultat observé :**

```text
Container tp2-audit-bb6f32c-api-python-1  Stopping
 Container tp2-audit-bb6f32c-api-python-1  Stopped
 Container tp2-audit-bb6f32c-api-python-1  Removing
 Container tp2-audit-bb6f32c-api-python-1  Removed
 Container tp2-audit-bb6f32c-db-1  Stopping
 Container tp2-audit-bb6f32c-db-1  Stopped
 Container tp2-audit-bb6f32c-db-1  Removing
 Container tp2-audit-bb6f32c-db-1  Removed
 Volume tp2-audit-bb6f32c_db-data-pg18  Removing
 Network tp2-audit-bb6f32c_default  Removing
 Network tp2-audit-bb6f32c_database  Removing
 Volume tp2-audit-bb6f32c_db-data-pg18  Removed
 Network tp2-audit-bb6f32c_default  Removed
 Network tp2-audit-bb6f32c_database  Removed

Conteneurs propres à l’audit restants=False ; volumes propres à l’audit restants=False.
```

**Code de retour :** 0.

**Interprétation :** Les volumes et caches préexistants ne sont jamais ciblés. La suppression de volumes concerne seulement le projet temporaire de cet audit.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T37 — Runtime public amd64

**Objectif :** Contrôler le runtime réellement publié, UID et chemins de shell/outils.

**Exigence liée :** L1, C7, F1, TP1.

**Prérequis :** Docker et émulation arm64 préexistante ; image par manifeste immuable.

**Commande réellement exécutée :**

```bash
docker run --rm --platform linux/amd64 --network none --read-only ghcr.io/clement-machtelinckx/linter-python-flask@sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b -c "import os,sys,platform,importlib.util,json
paths=['/bin/sh','/bin/bash','/bin/dash','/usr/bin/sh','/usr/bin/bash','/usr/bin/dash','/busybox/sh','/bin/busybox','/usr/bin/apt','/usr/bin/apt-get','/usr/bin/gcc','/usr/bin/cc','/usr/bin/make','/run/secrets/pip_token','/root/.cache/pip','/opt/python/bin']
result={'uid':os.getuid(),'gid':os.getgid(),'python':platform.python_version(),'machine':platform.machine(),'present_checked_paths':[p for p in paths if os.path.lexists(p)],'pip':importlib.util.find_spec('pip') is not None,'pytest':importlib.util.find_spec('pytest') is not None}
print(json.dumps(result));assert result['uid']==65532 and not result['present_checked_paths'] and not result['pip'] and not result['pytest']
"
```

**Résultat observé :**

```text
{"uid": 65532, "gid": 65532, "python": "3.13.5", "machine": "x86_64", "present_checked_paths": [], "pip": false, "pytest": false}
Unable to find image 'ghcr.io/clement-machtelinckx/linter-python-flask@sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b' locally
ghcr.io/clement-machtelinckx/linter-python-flask@sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b: Pulling from clement-machtelinckx/linter-python-flask
705775bc491d: Pulling fs layer
88cccb8947a5: Pulling fs layer
4f2a19bb0c8c: Pulling fs layer
705775bc491d: Download complete
88cccb8947a5: Download complete
88cccb8947a5: Pull complete
4f2a19bb0c8c: Download complete
4f2a19bb0c8c: Pull complete
705775bc491d: Pull complete
Digest: sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b
Status: Downloaded newer image for ghcr.io/clement-machtelinckx/linter-python-flask@sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b
```

**Code de retour :** 0.

**Interprétation :** La commande exécute Python directement, sans shell. Les chemins explicitement listés sont vérifiés et les modules pip/pytest sont absents. Le contrôle ARM64 utilise l’émulation disponible ; il ne mesure pas les performances sur matériel ARM natif.

**Statut :** PASS LOCAL.

**Preuve ou source :** ghcr.io/clement-machtelinckx/linter-python-flask@sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b

### Test T38 — Runtime public arm64

**Objectif :** Contrôler le runtime réellement publié, UID et chemins de shell/outils.

**Exigence liée :** L1, C7, F1, TP1.

**Prérequis :** Docker et émulation arm64 préexistante ; image par manifeste immuable.

**Commande réellement exécutée :**

```bash
docker run --rm --platform linux/arm64 --network none --read-only ghcr.io/clement-machtelinckx/linter-python-flask@sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e -c "import os,sys,platform,importlib.util,json
paths=['/bin/sh','/bin/bash','/bin/dash','/usr/bin/sh','/usr/bin/bash','/usr/bin/dash','/busybox/sh','/bin/busybox','/usr/bin/apt','/usr/bin/apt-get','/usr/bin/gcc','/usr/bin/cc','/usr/bin/make','/run/secrets/pip_token','/root/.cache/pip','/opt/python/bin']
result={'uid':os.getuid(),'gid':os.getgid(),'python':platform.python_version(),'machine':platform.machine(),'present_checked_paths':[p for p in paths if os.path.lexists(p)],'pip':importlib.util.find_spec('pip') is not None,'pytest':importlib.util.find_spec('pytest') is not None}
print(json.dumps(result));assert result['uid']==65532 and not result['present_checked_paths'] and not result['pip'] and not result['pytest']
"
```

**Résultat observé :**

```text
{"uid": 65532, "gid": 65532, "python": "3.13.5", "machine": "aarch64", "present_checked_paths": [], "pip": false, "pytest": false}
Unable to find image 'ghcr.io/clement-machtelinckx/linter-python-flask@sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e' locally
ghcr.io/clement-machtelinckx/linter-python-flask@sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e: Pulling from clement-machtelinckx/linter-python-flask
e2bacf04b6ec: Pulling fs layer
9f09cb54ab6d: Pulling fs layer
aaf0cacc83a3: Pulling fs layer
e2bacf04b6ec: Download complete
9f09cb54ab6d: Download complete
9f09cb54ab6d: Pull complete
aaf0cacc83a3: Download complete
aaf0cacc83a3: Pull complete
e2bacf04b6ec: Pull complete
Digest: sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e
Status: Downloaded newer image for ghcr.io/clement-machtelinckx/linter-python-flask@sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e
```

**Code de retour :** 0.

**Interprétation :** La commande exécute Python directement, sans shell. Les chemins explicitement listés sont vérifiés et les modules pip/pytest sont absents. Le contrôle ARM64 utilise l’émulation disponible ; il ne mesure pas les performances sur matériel ARM natif.

**Statut :** PASS LOCAL.

**Preuve ou source :** ghcr.io/clement-machtelinckx/linter-python-flask@sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e

### Test T25 — Grype sur SBOM — full-vex

**Objectif :** Reproduire le scan SBOM, les exemptions et les codes retour.

**Exigence liée :** E1, E2, E5, E6, P3.

**Prérequis :** Grype 0.108.0 dans /tmp ; base isolée ; SBOM Git.

**Commande réellement exécutée :**

```bash
/tmp/tp2-audit-data/bin/grype sbom:/tmp/tp2-audit-conformite/sbom.cdx.json --config /tmp/tp2-audit-data/full-vex.yaml --output json --file /tmp/tp2-audit-data/grype-full-vex.json
# GRYPE_DB_CACHE_DIR=/tmp/tp2-audit-data/grype-db ; config de comparaison :
only-fixed: false
vex-documents:
  - /tmp/tp2-audit-conformite/security.vex.json
check-for-app-update: false
```

**Résultat observé :**

```text
{"active": 170, "ignored": 4, "severities": {"High": 41, "Medium": 66, "Negligible": 49, "Low": 14}, "fix_states": {"wont-fix": 120, "not-fixed": 50}, "db": "2026-10-29T06:23:34Z"}
```

**Code de retour :** 0.

**Interprétation :** Le scan reçoit directement sbom:… . La base et les options déterminent le périmètre ; le gate only-fixed ne signifie pas absence de vulnérabilités.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T26 — Grype sur SBOM — full-no-vex

**Objectif :** Reproduire le scan SBOM, les exemptions et les codes retour.

**Exigence liée :** E1, E2, E5, E6, P3.

**Prérequis :** Grype 0.108.0 dans /tmp ; base isolée ; SBOM Git.

**Commande réellement exécutée :**

```bash
/tmp/tp2-audit-data/bin/grype sbom:/tmp/tp2-audit-conformite/sbom.cdx.json --config /tmp/tp2-audit-data/full-no-vex.yaml --output json --file /tmp/tp2-audit-data/grype-full-no-vex.json
# GRYPE_DB_CACHE_DIR=/tmp/tp2-audit-data/grype-db ; config de comparaison :
only-fixed: false
check-for-app-update: false
```

**Résultat observé :**

```text
{"active": 174, "ignored": 0, "severities": {"High": 41, "Critical": 4, "Medium": 66, "Negligible": 49, "Low": 14}, "fix_states": {"wont-fix": 124, "not-fixed": 50}, "db": "2026-10-29T06:23:34Z"}
```

**Code de retour :** 0.

**Interprétation :** Le scan reçoit directement sbom:… . La base et les options déterminent le périmètre ; le gate only-fixed ne signifie pas absence de vulnérabilités.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T27 — Grype sur SBOM — gate

**Objectif :** Reproduire le scan SBOM, les exemptions et les codes retour.

**Exigence liée :** E1, E2, E5, E6, P3.

**Prérequis :** Grype 0.108.0 dans /tmp ; base isolée ; SBOM Git.

**Commande réellement exécutée :**

```bash
/tmp/tp2-audit-data/bin/grype sbom:/tmp/tp2-audit-conformite/sbom.cdx.json --config /tmp/tp2-audit-conformite/.grype.yaml --output json --file /tmp/tp2-audit-data/grype-gate.json
# GRYPE_DB_CACHE_DIR=/tmp/tp2-audit-data/grype-db ; config de comparaison :
# Grype policy for the SBOM audit (TP2 step 2-E): fail on fixable HIGH/CRITICAL,
# unfixable findings stay visible in the full report, and every exemption is an
# OpenVEX statement in security.vex.json (auditable, never a silent ignore).
fail-on-severity: high
only-fixed: true
vex-documents:
  - security.vex.json
check-for-app-update: false
```

**Résultat observé :**

```text
{"active": 0, "ignored": 174, "severities": {}, "fix_states": {}, "db": "2026-10-29T06:23:34Z"}
```

**Code de retour :** 0.

**Interprétation :** Le scan reçoit directement sbom:… . La base et les options déterminent le périmètre ; le gate only-fixed ne signifie pas absence de vulnérabilités.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T28 — Grype sur SBOM — negative-high

**Objectif :** Reproduire le scan SBOM, les exemptions et les codes retour.

**Exigence liée :** E1, E2, E5, E6, P3.

**Prérequis :** Grype 0.108.0 dans /tmp ; base isolée ; SBOM Git.

**Commande réellement exécutée :**

```bash
/tmp/tp2-audit-data/bin/grype sbom:/tmp/tp2-audit-conformite/sbom.cdx.json --config /tmp/tp2-audit-data/negative-high.yaml --output json --file /tmp/tp2-audit-data/grype-negative-high.json
# GRYPE_DB_CACHE_DIR=/tmp/tp2-audit-data/grype-db ; config de comparaison :
only-fixed: false
fail-on-severity: high
check-for-app-update: false
```

**Résultat observé :**

```text
[0001] ERROR discovered vulnerabilities at or above the severity threshold
{"active": 174, "ignored": 0, "severities": {"High": 41, "Critical": 4, "Medium": 66, "Negligible": 49, "Low": 14}, "fix_states": {"wont-fix": 124, "not-fixed": 50}, "db": "2026-10-29T06:23:34Z"}
```

**Code de retour :** 2.

**Interprétation :** Le scan reçoit directement sbom:… . Le refus attendu sur les véritables vulnérabilités HIGH/CRITICAL non corrigées démontre le seuil du moteur, sans fausse CVE. Ce test modifie le périmètre de la politique ; il ne simule pas une vulnérabilité corrigible sous la politique only-fixed.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T39 — Validation Bake dans une copie conforme avec sa source secrète

**Objectif :** Distinguer syntaxe HCL et compatibilité du flag --set local.

**Exigence liée :** C1–C6, L2.

**Prérequis :** Copie HCL identique octet pour octet ; secret simulé sous le chemin attendu ; Buildx 0.28.

**Commande réellement exécutée :**

```bash
# Copie inchangée de docker-bake.hcl et placement du jeton éphémère dans secrets/pip_token.txt hors dépôt.
cd /tmp/tp2-audit-data/bake-context
REGISTRY=ghcr.io/audit-example IMAGE=sample TAGS=v9.8.7,latest CACHE_REF=ghcr.io/audit-example/sample:cache docker buildx bake -f docker-bake.hcl --print
```

**Résultat observé :**

```text
{
  "group": {
    "default": {
      "targets": [
        "api"
      ]
    }
  },
  "target": {
    "api": {
      "context": ".",
      "dockerfile": "Dockerfile",
      "tags": [
        "ghcr.io/audit-example/sample:v9.8.7",
        "ghcr.io/audit-example/sample:latest"
      ],
      "cache-from": [
        {
          "ref": "ghcr.io/audit-example/sample:cache",
          "type": "registry"
        }
      ],
      "cache-to": [
        {
          "mode": "max",
          "ref": "ghcr.io/audit-example/sample:cache",
          "type": "registry"
        }
      ],
      "secret": [
        {
          "id": "pip_token",
          "src": "secrets/pip_token.txt"
        }
      ],
      "platforms": [
        "linux/amd64",
        "linux/arm64"
      ],
      "output": [
        {
          "type": "registry"
        }
      ]
    }
  }
}
#1 [internal] load local bake definitions
#1 reading docker-bake.hcl 1.41kB / 1.41kB done
#1 DONE 0.0s
```

**Code de retour :** 0.

**Interprétation :** Le HCL original se résout avec les tags CSV et le cache paramétré. La commande --set api.secret de T24 est incompatible avec Buildx local 0.28 ; son succès dans la CI de release est établi séparément. Aucun build ni push n’est effectué par --print.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T40 — Ancienne v1.1.0 non admise

**Objectif :** Éviter de présenter la release en échec comme valide.

**Exigence liée :** F3, F7, R3.

**Prérequis :** Cosign public ; métadonnées/logs GitHub du run 40844848852.

**Commande réellement exécutée :**

```bash
cosign verify --certificate-identity-regexp '^https://github\.com/clement-machtelinckx/linter-python-flask/\.github/workflows/publish_to_ghcr\.yml@refs/tags/v1\.1\.0$' --certificate-oidc-issuer https://token.actions.githubusercontent.com ghcr.io/clement-machtelinckx/linter-python-flask@sha256:ca52ce9bc5dc371296404c486cd2ce24c15304b8fc81e1c73cc0bc5ac65b9643
```

**Résultat observé :**

```text
Error: no signatures found
main.go:69: error during command execution: no signatures found
```

**Code de retour :** 10.

**Interprétation :** Le run 40844848852 échoue à la signature (cannot specify service URLs and use signing config) ; attestations et admission sont skipped. La vérification publique actuelle confirme l’absence de signature pour ce digest. Ce défaut historique n’est pas attribué à la release corrigée v1.1.1.

**Statut :** PASS LOCAL.

**Preuve ou source :** [Ancienne release invalide](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/40844848852).

### Test T41 — Validation YAML, épinglage des actions et permissions

**Objectif :** Contrôler exhaustivement les fichiers CI et l’absence de clé privée versionnée.

**Exigence liée :** L5, L6, obligations CI, P1–P6.

**Prérequis :** PyYAML 5.4.1 et Git.

**Commande réellement exécutée :**

```bash
# Parcours Python : yaml.safe_load de chaque .github/workflows/*.yml.
# Pour chaque uses externe : re.fullmatch(r'[^@]+@[0-9a-f]{40}', reference).
rg -n 'uses:|permissions:|continue-on-error|pull_request_target' .github/workflows
# Recherche de marqueurs PEM/OpenSSH privés dans git ls-files, publication du nombre uniquement.
```

**Résultat observé :**

```text
8 YAML parsés ; 24 références externes ; 0 référence sans SHA complet.
Aucun continue-on-error/pull_request_target dans les workflows critiques.
Marqueurs de clé privée dans les fichiers suivis : 0.
Default contents:read ; validate actions:read ; publish seul packages:write/id-token:write ; admission packages:read.
Déclencheur release push.tags=[v*] ; garde du SHA courant de main et de la CI main au même SHA.
Workflows manuels non exécutés : provide_aws, render-development, deploy_docker_compose, deploy_ec2_ansible.
```

**Code de retour :** 0.

**Interprétation :** La validation YAML est syntaxique, pas une validation de schéma GitHub Actions. PyYAML YAML 1.1 lit on comme booléen ; les déclencheurs sont aussi contrôlés textuellement et dans les exécutions GitHub. La recherche de marqueurs n’est pas un audit de tous les anciens commits ni un scan exhaustif de tous les secrets.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

### Test T42 — Index OCI distant et digests de plateformes

**Objectif :** Vérifier que les plateformes sont publiées sous un seul index.

**Exigence liée :** C7, F1, L2, R1.

**Prérequis :** Buildx imagetools ; GHCR public.

**Commande réellement exécutée :**

```bash
docker buildx imagetools inspect ghcr.io/clement-machtelinckx/linter-python-flask:v1.1.1
docker buildx imagetools inspect ghcr.io/clement-machtelinckx/linter-python-flask:v1.1.1 --raw > /tmp/tp2-audit-data/index.json
```

**Résultat observé :**

```text
Digest index : sha256:d42185600d94df2717e26af1cd98fb360d3790142eeff61421cef601aeffe136
mediaType=application/vnd.oci.image.index.v1+json
linux/amd64 sha256:4b6f11e2aa9d218bb1068e70dab1628cabfc4bdeb8321058f90dea0b5559824b
linux/arm64 sha256:a18b70c9a61d4890751dfe967e705007c1062c15ab5ec4ed1c36fa6de9febc4e
unknown/unknown sha256:c817c213afc12f104905da3472656006314c9bb3c47d42318d1f72c535a1a5a6
unknown/unknown sha256:3e5ea199fc4bfe9ec24034479b43f796080ae9b21f0f60b8f52aeb3fa38f5fa2
```

**Code de retour :** 0.

**Interprétation :** amd64 et arm64 sont deux manifestes d’un même index OCI ; les deux entrées unknown/unknown sont des manifestes d’attestation BuildKit, pas des architectures exécutables supplémentaires. Les attestations Cosign certifiées sont contrôlées séparément.

**Statut :** PASS LOCAL.

**Preuve ou source :** ghcr.io/clement-machtelinckx/linter-python-flask:v1.1.1

### Test T43 — Cohérence du README et du cache externe

**Objectif :** Distinguer preuves actuelles, historiques et reproductibles.

**Exigence liée :** L3, L7, C5, C6, R1, R2, R3.

**Prérequis :** Lecture du README, rapport Étape 1, manifeste GHCR de cache et diff Git.

**Commande réellement exécutée :**

```bash
rg -n 'froid|chaud|Étape 1|À compléter|à compléter|TODO|v1.1.0|commit courant|tmp/|feat/34|168|172|159|99.7821|A2-chaud|1,2 s|TAGS=' README.md docs/tp2-etape1-rapport.md docker-bake.hcl
git rev-parse 'v1.1.1^{}'
git diff --stat 'v1.1.1^{}' origin/main
docker buildx imagetools inspect ghcr.io/clement-machtelinckx/linter-python-flask:buildcache --raw > /tmp/tp2-audit-data/cache-manifest.json
```

**Résultat observé :**

```text
v1.1.1 pointe sur 2381039ddea4924fe11f9f7b89176fe2324ef8d6.
Diff release → main : README.md seulement (11 lignes, 8 ajouts et 3 retraits).
Cache GHCR : OCI image manifest ; config application/vnd.buildkit.cacheconfig.v0 ; 116 couches.
README §8 : 26,5 s froid bi-arch contre 1,2 s étape pip chaude ; périmètres à distinguer.
Rapport Étape 1 : retrait d’itsdangerous, 32 Using cached ; README : commentaire, 8 Using cached.
README §9 : SBOM déclaré « commit courant », source Git 8df539d2… sans association Git précise.
README §9 : base du 2026-10-28, 172→168 ; essai actuel même outil, base du 29 : 174→170.
Références locales 127.0.0.1:5001, branche feat/34…, chemins temporaires et registre présenté « tant que v1.1.0 n’est pas publiée » subsistent.
§10 : digests v1.1.1 exacts ; commandes publiques réussies ici ; ancien échec v1.1.0 explicité.
```

**Code de retour :** 0.

**Interprétation :** Le dossier technique français est substantiel et la publication est désormais démontrée. Les anciennes mesures sont des instantanés historiques, pas des résultats actuels. Le cache pip des téléchargements (montage) ne s’exporte pas avec le cache externe des couches ; les logs CI montrent réellement import, CACHED et export. Aucune purge du développeur n’a été effectuée pendant cet audit. Les références historiques doivent être contextualisées et l’association du SBOM racine à l’image doit être précisée.

**Statut :** PARTIEL.

**Preuve ou source :** [README audité](https://github.com/clement-machtelinckx/linter-python-flask/blob/bb6f32c7b7b421d499c27e979102d80cd9e1cb0f/README.md), [release](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/40871325590).

### Test T44 — Intégrité finale du rapport et préservation des ressources

**Objectif :** Contrôler l’exhaustivité, les statuts et l’absence de modification hors rapport.

**Exigence liée :** Règles de mission et matrice complète.

**Prérequis :** Rapport consolidé et Git.

**Commande réellement exécutée :**

```bash
# Contrôle Python exécuté : 78 IDs uniques (L/A/B/C/D/E/F/P/CI/R/TP1),
# 43 tests avant ce dernier contrôle, neuf champs par test, statuts recomptés,
# recherche de jetons tok_ de 48 caractères hexadécimaux et de clés privées,
# blocs Markdown équilibrés et absence de section encore « en cours ».
git status --short --branch
git diff --stat
docker buildx stop tp2-audit-bb6f32c
docker ps --format '{{.Names}} {{.Image}}'
# Suppression Python des seuls fichiers simulated-token, invalid-token et bake-context/secrets/pip_token.txt créés par les essais.
```

**Résultat observé :**

```text
Matrice : 78 identifiants attendus, uniques et complets.
PASS LOCAL 64 ; PASS CI 10 ; PARTIEL 4 ; FAIL 0 ; NON TESTÉ 0.
Journal avant ce contrôle final : T01 à T43, neuf champs obligatoires chacun.
Marqueurs de jeton/clé privée : 0 ; blocs Markdown équilibrés.
Aucun fichier suivi applicatif, Docker ou CI modifié.
## audit/tp2-conformite-finale...origin/main
?? docs/audits/
Deux conteneurs initiaux toujours présents ; builder d’audit arrêté avec cache conservé.
Sources éphémères de jetons supprimées sans affichage de valeur.
```

**Code de retour :** 0.

**Interprétation :** Les seuls changements à commiter sont le rapport. Les scripts, archives, outils et preuves temporaires restent hors dépôt. L’état Git initial non suivi est préservé ; les opérations de publication suivantes concernent uniquement la branche d’audit.

**Statut :** PASS LOCAL.

**Preuve ou source :** État audité : bb6f32c7b7b421d499c27e979102d80cd9e1cb0f.

## 5. Résultats des tests de sécurité

| Contrôle | Résultat réellement obtenu | Origine et portée |
|---|---|---|
| Hadolint | Code 0, seuil warning, aucune règle ignorée | T31 local et jobs de main réussis |
| Trivy vulnérabilités | 174 occurrences : 26 HIGH, 88 MEDIUM, 53 LOW, 7 UNKNOWN ; 0 CRITICAL ; 0 HIGH/CRITICAL avec correctif | Rapport CI main bb6f32c, T17 ; pas de nouveau scan vulnérabilités local |
| Trivy configuration | 0 mauvaise configuration HIGH/CRITICAL Dockerfile | Artefact main et étape CI réussie, T17 |
| Grype complet avec VEX | 170 actives : 41 High, 66 Medium, 49 Negligible, 14 Low ; 0 Critical | T25 reproduit localement ; même résultat dans CI main |
| Grype sans VEX | 174 actives, dont 4 Critical ; 124 wont-fix et 50 not-fixed | T26, même SBOM et même base |
| Grype gate officiel | Code 0, 0 active et 174 ignorées par les politiques VEX/only-fixed | T27 ; ne signifie pas 174 exemptions VEX |
| Grype seuil négatif | Code 2 avec les vulnérabilités réelles HIGH+ et only-fixed désactivé | T28 ; valide le seuil, pas un cas corrigible injecté |
| OpenVEX | Schéma 0.2.0 valide ; 1 déclaration, 4 correspondances retirées par architecture | T18/T25–T26 ; produits exactement versionnés |
| Secret | History/inspect/exports : 0 occurrence ; Trivy image : 0 secret, code 0 | T32/T34 sur image construite localement |
| Contrôle positif secret | 1 secret, règle simulated-pip-token, code 1 | T33 ; aucune valeur sensible publiée |
| Dive | 99.7821 %, 321630 octets gaspillés ; gate >80 % satisfait | T17, CI uniquement |
| Multi-architecture | Index OCI unique ; amd64 et arm64 lus publiquement et exécutés | T37/T38/T42 ; ARM64 sous émulation |
| Cosign | 3 signatures valides ; identité étrangère rejetée code 12 | T08–T13, session GHCR vide |
| Attestations | 2 prédicats CycloneDX certifiés, 47 paquets chacun ; sujets égaux aux manifestes | T11/T12/T16 |
| Admission finale | Job indépendant réussi après publication ; 3 signatures et 2 attestations vérifiées | [job admission](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/40871325590/job/123440915746) |

La base Grype utilisée ici et en CI a été construite le **2026-10-29 à 06:23:34 UTC**. Après VEX, les 170 actives se répartissent en **120 wont-fix et 50 not-fixed**, sans correctif disponible selon cette base pour Debian 13. Cela n’implique ni inexploitabilité des autres vulnérabilités, ni absence de futur correctif. Les rapports Trivy et Grype ont des moteurs et bases différents ; leurs occurrences ne s’additionnent pas en un nombre de CVE distinctes.

L’unique exemption concerne **CVE-2026-19445**, défaut réel de durée de vie d’un contexte TLS CPython. Grype signale les quatre paquets Debian `libpython3.13-minimal`, `libpython3.13-stdlib`, `python3.13-minimal`, `python3.13-venv`, version `3.13.5-2+deb13u5`. Le chemin vulnérable implique un serveur TLS utilisant un callback SNI qui change de contexte et permet la libération du contexte d’origine. L’API auditée écoute en HTTP, sans `ssl_context`, et ne crée pas ce callback : l’exemption `vulnerable_code_not_in_execute_path` est cohérente avec ce fonctionnement. Ajouter TLS/SNI dans le conteneur, changer de point d’entrée ou de version doit déclencher une nouvelle évaluation. Les huit PURL du document couvrent précisément les quatre paquets sur amd64 et arm64 ; aucune CVE factice ni joker général n’est utilisé. Le statut Grype `wont-fix` doit être distingué de l’annotation Debian `no-dsa (Minor issue)`. Sources : [Debian](https://security-tracker.debian.org/tracker/CVE-2026-19445), [analyse amont CPython](https://github.com/python/cpython/issues/156293).

Les artefacts de release sont authentifiés par les attestations : le prédicat de chaque plateforme est identique au fichier CycloneDX téléchargé. Les SBOM Git/CI/release ne sont pas déclarés identiques : source et dates diffèrent, les PURL Debian incluent l’architecture et ARM64 possède un fichier de moins.

## 6. Résultats des tests fonctionnels

| Essai | Résultat | Source |
|---|---|---|
| Pytest unitaire local | 5 passed, 1 deselected, 0.84 s | T29, fichiers de main montés read-only |
| Pytest complet avec PostgreSQL réel | 6 passed, 0.46 s ; dont un test marqué integration | T35 ; base propre à l’audit |
| `/health` sur le conteneur construit | HTTP 200, `{"status":"ok"}` | T35, requête réseau réelle |
| `/dbtest` sur le conteneur construit | HTTP 200, `{"db_connection":"successful"}` | T35, connexion/SELECT 1 réels |
| Compose | API et DB healthy ; PostgreSQL Chainguard par digest ; port dynamique localhost | T35 |
| Nettoyage | Conteneurs, réseaux et volume du seul projet d’audit supprimés | T36 ; stack préexistante conservée |
| Pytest CI main | 5 passed, 1 deselected (qualité) ; 1 passed, 5 deselected (intégration) | [qualité](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/40875267932), [intégration](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/40875268066/job/123453337421) |
| Runtime AMD64 publié | UID/GID 65532, Python 3.13.5, machine x86_64 ; chemins shell/outils vérifiés absents | T37 |
| Runtime ARM64 publié | UID/GID 65532, Python 3.13.5, machine aarch64 ; mêmes chemins absents | T38, émulation préexistante |

La suite complète appelle aussi `/hello`, teste les réponses d’échec de `/dbtest` et vérifie fermeture du curseur/de la connexion dans les branches simulées. Le test marqué integration utilise réellement PostgreSQL, tandis que les autres branches DB utilisent des doubles de test.

Les durées BuildKit mesurées sur le **même builder neuf dédié**, en AMD64, sont :

| Essai | Durée totale | Downloading | Using cached | CACHED (couches) |
|---|---:|---:|---:|---:|
| Premier pip valide, T21 | 8.722 s | 8 | 0 | 3 |
| Manifeste modifié par commentaire, T22 | 4.863 s | 0 | 8 | 5 |
| Sans nouvelle modification, T23 | 2.406 s | 0 | 0 | 7 |

Le premier essai valide est froid pour **les téléchargements pip** : le builder est neuf et les essais négatifs précédents échouent avant pip. Il n’est pas froid pour tous les téléchargements de base : T19 avait déjà résolu et tiré des couches. Le gain constaté après modification porte sur la réutilisation du montage de cache pip, distincte des couches marquées CACHED. Le cache registre des couches est démontré par les logs de release ; son contenu ne transporte pas le montage de cache pip. Les tests ne comparent pas du matériel ARM natif à AMD64.

## 7. Analyse des écarts

**Bloquant :** aucun défaut bloquant du chemin technique TP2 n’a été constaté sur v1.1.1 ou main. L’ancienne v1.1.0 échoue effectivement à l’admission cryptographique ; elle est explicitement remplacée dans la documentation et ne constitue pas la release retenue.

| Gravité | Écart et fichier | Conséquence | Correction précise proposée, non appliquée |
|---|---|---|---|
| Important | `sbom.cdx.json` / `sbom.spdx.json` racine : référence 8df539d2… ; README §9.1 dit « commit courant » sans SHA source ni lien de génération associé | L’identité exacte de l’image versionnée ne peut pas être reliée à une publication à partir du dossier ; égalité des PURL ne suffit pas à prouver l’identité des images | Documenter le SHA Git, la plateforme, le type de digest (config ou manifeste), la commande et le run de génération ; ou remplacer explicitement ces fichiers par les SBOM de la release choisie, puis vérifier le lien au manifeste. |
| Important | README §8.1 et rapport Étape 1 : froid bi-arch 26,5 s, chaud 1,2 s sur l’étape pip ; scénarios commentaire/retrait d’itsdangerous et comptes 8/32 divergents | Comparatif historique insuffisamment homogène et preuves brutes citées hors dépôt | Publier un tableau par architecture/scénario avec durées totale et pip séparées, SHA exact, méthode sans purge globale et liens permanents vers les extraits. Les mesures T21–T23 de cet audit fournissent un scénario homogène AMD64. |
| Mineur | README §8/§9 et sections TP1 : ancien registre local, branche feat/34…, chemins /tmp et nombres historiques 172→168 ou 159 | Le lecteur peut confondre instantané historique et état actuel (174→170 Grype, 174 Trivy) | Étiqueter clairement chaque instantané avec son image, sa base de vulnérabilités et son run ; pointer la synthèse actuelle et conserver l’historique comme tel. |
| Mineur | `publish_to_ghcr.yml` : surcharge `--set api.secret` non reconnue par Buildx local 0.28, mais exécutée avec 0.38.1 en CI | Reproduction locale de cette commande de release impossible avec l’outil livré ici | Documenter la version Buildx compatible et la distinguer de la résolution HCL simple, qui réussit en T39. Aucun changement de workflow n’est requis par cet audit. |
| Mineur | `.github/workflows/deploy_docker_compose.yml` et `deploy_ec2_ansible.yml` historiques : `chwon`, contexte de build/secret non livré, vérification SSH désactivée | Les chemins de déploiement manuels ne démontrent pas un déploiement TP2 fiable ; ils ne participent pas aux six phases auditées | Corriger la commande de propriété, déployer une image par digest vérifié avec les fichiers nécessaires et configurer les clés hôtes SSH ; examiner séparément les deux déploiements avant usage. |
| Mineur | Rapports sécurité/image validée : rétention sept jours | Perte rapide de l’accès aux JSON détaillés, même si les logs/attestations restent consultables | Archiver durablement des synthèses et les rapports utiles à la remise, sans jeton ni identifiant sensible. |

Les réserves importantes concernent la preuve et la traçabilité documentaire ; elles empêchent d’affirmer une conformité intégrale du dossier demandé. Aucune correction applicative, Docker ou CI n’a été réalisée.

## 8. Limites et tests non effectués

- PDF officiel non disponible dans le dépôt ni le répertoire de projet exploré ; la matrice suit exclusivement les exigences reproduites dans la mission. La conformité ne porte pas sur d’éventuelles consignes non transmises.
- Aucun nouveau scan Dive local ni nouveau scan Trivy vulnérabilités local : leurs résultats proviennent des artefacts réels du main audité, téléchargés et analysés. Grype et Trivy Secret ont été réellement rejoués localement.
- Syft n’a pas été relancé localement : la génération CI, les huit fichiers, leurs métadonnées et leurs schémas ont été examinés. La version locale 1.51.1 n’est pas attribuée aux SBOM produits par 1.42.0.
- Cosign **2.4.1** a été testé ici. La revendication README sur Cosign 3.0.6 n’a pas été reproduite localement ; le workflow corrigé et son admission ont bien réussi en CI. Les mécanismes de validation du certificat, de l’identité, de l’émetteur et de la transparence sont restés activés.
- Aucun tag, release, merge, déploiement AWS/Render ou signature supplémentaire n’a été créé. Les workflows manuels d’infrastructure n’ont pas été exécutés.
- Le test négatif Grype prouve l’échec du seuil sur de vraies vulnérabilités non corrigées. Il n’injecte pas artificiellement une CVE corrigible pour tester only-fixed ; la configuration effective et le succès sur le périmètre réel sont vérifiés.
- Pas de test de rejet d’attestation avec un mauvais digest en CI, ni de forçage d’échec d’un run de release. Le sujet des deux attestations authentiques et le rejet d’une mauvaise identité ont été testés indépendamment.
- La build multi-architecture distante et le cache externe sont prouvés par la release et les lectures du registre. Les builds chronométrés locaux couvrent AMD64 ; l’exécution ARM64 publiée est testée sous émulation, pas sur machine ARM native.
- Les contrôles sans shell examinent les chemins et modules explicitement indiqués en T37/T38 et les bases distroless épinglées ; ils ne constituent pas une analyse exhaustive de tous les exécutables possibles.
- Aucun audit de tout l’historique Git à la recherche d’anciens secrets ; recherche de marqueurs privés dans les fichiers suivis et tests précis de fuite du jeton simulé seulement. Les secrets préexistants du développeur n’ont pas été ouverts.
- Les preuves temporaires sont sous `/tmp/tp2-audit-data` et ne sont pas des livrables Git. Les jetons simulés ont été supprimés après les essais. Les liens CI/artefacts et digests publics permettent de retrouver les preuves ; la durée de rétention limite les anciens artefacts.
- Le builder neuf de l’audit a été arrêté en conservant son cache. Aucun prune, reset, clean, stash, force-push, suppression de branche ou suppression de volume préexistant n’a été effectué.

## 9. Bilan final

- **PASS LOCAL : 64** exigence(s).
- **PASS CI : 10** exigence(s).
- **PARTIEL : 4** exigence(s).
- **FAIL : 0** exigence(s).
- **NON TESTÉ : 0** exigence(s).

Total : **78 exigences synthétiques** dans la matrice. Le journal contient les tests T01 à T43, auxquels s’ajoute le contrôle final d’intégrité T44 ; il ne s’agit pas de 78 tests indépendants. Les lignes PARTIEL ne sont pas converties en PASS au motif que les mécanismes techniques fonctionnent.

Le chemin technique principal du TP2 est prouvé : BuildKit et secret étanche, deux architectures, SBOM valides et attestés, VEX réel et ciblé, gates Grype/Trivy, signature keyless et admission distante indépendante. Les acquis TP1 ciblés restent vérifiés, avec six tests réussis sur une vraie base. Les réserves portent sur la chaîne documentaire du SBOM racine et l’homogénéité des preuves README.

Avant remise :

1. Relier explicitement les SBOM versionnés à un SHA Git, une plateforme et un digest d’image vérifiable.
2. Harmoniser les mesures BuildKit et leur méthode ; distinguer les données historiques du résultat actuel.
3. Conserver les rapports détaillés nécessaires avant leur expiration et faire référencer les preuves finales par le README.

**Le TP2 satisfait-il toutes les exigences obligatoires du sujet ? NON DÉMONTRÉ.** Les fonctionnalités et vérifications techniques critiques ont réussi ; la traçabilité du SBOM versionné et certaines preuves documentaires obligatoires restent partielles. Aucun défaut technique bloquant de v1.1.1 n’a été observé, mais ces réserves empêchent une réponse OUI intégrale.

Le rapport a été préparé avec une assistance automatisée à la lecture, à l’exécution des commandes et à la rédaction. Les sorties rapportées proviennent d’essais réels ; aucune preuve ni contribution humaine n’est simulée. La déclaration éventuellement exigée par le cours reste à joindre selon ses règles.
