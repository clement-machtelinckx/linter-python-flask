# Contrôle final — TASK-014

Énoncé officiel fourni par Clément ; contrôle du 8 octobre 2026.
Référence auditée : `83659230ccc2d74b514aaabf62f381cd468dcdb4` sur `main`.
Les résultats existants de ce commit sont réutilisés, sans relancer les scans.

Preuves : [qualité](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/37789597550),
[sécurité et intégration](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/37789598329),
[corrections CI fusionnées](https://github.com/clement-machtelinckx/linter-python-flask/pull/30).
Artefact sécurité : `image-security-83659230ccc2d74b514aaabf62f381cd468dcdb4` (rétention 7 jours).

| Exigence | Statut | Preuve / correctif restant |
| --- | --- | --- |
| Livrables présents sur main | PASS | Dockerfile, Compose, manifestes, filtres, politique Hadolint, README et workflows |
| API multi-stage Distroless, non-root, sans outils de build | PASS | [Dockerfile](Dockerfile), UID/GID 65532 ; inspection historique décrite dans le README, Dockerfile inchangé |
| PostgreSQL Chainguard par digest, isolation réseau | PASS | [Compose](docker-compose.yml), UID 70, réseau interne ; intégration saine |
| Healthchecks exec, démarrage conditionnel et timeout | PASS | Compose : Python stdlib et pg_isready ; service_healthy ; attente CI de 90 s |
| Filtrage du contexte et politique Hadolint | PASS | [.dockerignore](.dockerignore), [.hadolint.yaml](.hadolint.yaml), job Hadolint réussi |
| Dépendances Python corrigées | PASS | Versions épinglées ; zéro vulnérabilité Python dans trivy-full.json ; pip check réussi en CI |
| Flake8 et tests unitaires bloquants avant build | PASS | Qualité réussie ; image-security dépend du job quality ; cinq tests unitaires réussis |
| BuildKit, Dive ≥ 80 % | PASS | Build réussi ; dive.txt : 99,7821 %, code 0 |
| Trivy HIGH/CRITICAL corrigibles bloquant | PASS | Zéro résultat corrigible ; gate code 0 ; rapport complet conservé |
| Vulnérabilités résiduelles visibles | PASS | 159 occurrences sans correctif : 30 HIGH, 74 MEDIUM, 53 LOW, 2 UNKNOWN ; aucune CRITICAL |
| HTTP /health, /dbtest et PostgreSQL réel | PASS | Deux conteneurs sains ; réponses attendues ; Pytest : 1 PASS, 5 deselected ; nettoyage réussi |
| CI push/PR, actions SHA, permissions minimales | PASS | Workflows épinglés ; contents: read ; packages: write limité au job de publication ; EC2 manuel uniquement |
| GitHub Actions sur le main audité | PASS | Les deux runs ci-dessus et tous leurs jobs obligatoires ont réussi |
| Quality Gate SonarQube de la PR | PASS | [Sonar PR #33](https://sonarcloud.io/dashboard?id=clement-machtelinckx_linter-python-flask&pullRequest=33) : OK, Security Rating A ; check GitHub success pour c30a334. Sur main, le statut historique NONE/check neutral ne constitue pas un PASS |
| Release SemVer et image GHCR publique | PASS | [Release v1.0.0](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/37795286678) réussie pour le même SHA ; page publique HTTP 200 ; manifeste et pull anonymes vérifiés |
| README avec preuves publiques complètes | PASS | Sept sections, tableau historique conservé, preuves actuelles, package public, commandes exactes et digest vérifié |

Digest GHCR vérifié : `sha256:63b1a427ca8a14ae0d81031085ab3bbd9aa7129c08b733653c384185cd33cb3c`.
Configuration image : `sha256:1df3dc6cd2e69ae022e7bc92d5f964bd9b270cf2717a55daef772483a4d4f30d`,
identique à la métadonnée du scan. Pull avec une configuration Docker vide : code 0 ;
imports Flask/psycopg2, UID 65532, absence des modules pip/pytest/flake8/setuptools/wheel : code 0.
La publication a eu lieu pendant l'audit, dans une autre session ; cet audit n'a créé aucun tag.

**Fusion finale suspendue : attendre les contrôles du dernier commit et la revue de Benoît.**
La PR #30 et l'issue #14 étaient déjà fusionnée/fermée avant cette reprise ; leurs
statuts ne remplacent pas ces conditions. Les scans et l'intégration existants sont
réutilisés car la configuration du registre correspond exactement à l'image testée.
