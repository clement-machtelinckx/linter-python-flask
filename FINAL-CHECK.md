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
| Quality Gate SonarQube | UNKNOWN | [Sonar main](https://sonarcloud.io/dashboard?id=clement-machtelinckx_linter-python-flask&branch=main) : check GitHub neutral ; API project_status = NONE, aucun PASS confirmé |
| Release SemVer et image GHCR publique | UNKNOWN | Aucun tag Git ni publication réussie constaté ; page package anonyme HTTP 404 ; [#31](https://github.com/clement-machtelinckx/linter-python-flask/issues/31) reste ouvert |
| README avec preuves publiques complètes | FAIL | Sections techniques et tableau présents ; tag, docker pull exact, digest registre et lien public encore manquants ; [#13](https://github.com/clement-machtelinckx/linter-python-flask/issues/13) reste ouvert |

**Rendu incomplet : aucune nouvelle fusion n'est autorisée par les conditions finales.**
La PR #30 et l'issue #14 étaient déjà fusionnée/fermée avant cette reprise ; cela ne
prouve pas la conformité globale. Ne pas confondre l'identifiant Docker de l'image
avec un digest GHCR. Aucun tag ni aucune publication n'a été créé pendant cet audit.
Restent : release explicitement autorisée, visibilité publique et pull anonyme vérifiés,
mise à jour des preuves du README, confirmation Sonar et revue finale du binôme.
