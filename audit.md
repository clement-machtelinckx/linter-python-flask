# Audit initial DevSecOps — Flask / PostgreSQL

## 1. Résumé exécutif

Collecte en cours pour TASK-001. Flake8 7.3.0 : PASS, aucune violation. Pytest 7.4.0 sans PostgreSQL : FAIL, 2 tests réussis et 1 échec d’intégration. Tests hors intégration : PASS. Build baseline : PASS après isolement temporaire du gestionnaire d’identifiants WSL ; premier essai : FAIL. Hadolint 2.15.1 par défaut : PASS ; politique `.hadolint.yaml` absente.

## 2. Informations et périmètre de l'audit

Commit audité : `632c75c6cdd3a359b71be6a248c108e20db17459`. Branche : `feat/task-001`. Audit commencé le 2026-10-08 à 08:49 UTC. `main` local et distant concordent. Le PDF du sujet n’était pas accessible ; référence : prompt et issue GitHub #1. Aucun hardening autorisé ; seul `audit.md` est créé.

## 3. Environnement et versions des outils

Ubuntu 22.04.5 LTS, WSL2, linux/amd64. Python hôte 3.10.12, Docker client/serveur 28.4.0, Compose 2.39.4-desktop.1, BuildKit 0.24.0. Venv isolé dans `/tmp/task-001-audit-tvya0all`.

## 4. Inventaire du dépôt

18 fichiers versionnés, dont 7 workflows, `app.py`, `test_app.py`, `requirements.txt`, `Dockerfile`, `docker-compose.yml`, `.flake8` et configurations Terraform/Ansible.

## 5. Architecture initiale

Flask expose `/health`, `/hello`, `/dbtest`. Compose référence une image GHCR externe et PostgreSQL `14-alpine`. Aucun `build:` dans Compose.

## 6. Audit de qualité Python — Flake8

`flake8 --config=.flake8 .` : code 0, 0 violation.

## 7. Audit des tests — Pytest

`python -m pytest -v` : code 1, 2 PASS et 1 FAIL ; `/dbtest` retourne 500 sans DB. `python -m pytest -v -m "not integration"` : code 0, 2 PASS, 1 désélectionné. Marque `integration` non enregistrée.

## 8. Audit des dépendances Python

Flask 2.3.2, Werkzeug 2.3.3, Pytest 7.4.0 imposés ; psycopg2-binary non verrouillé, résolu à 2.9.13. `pip check` : code 0. Pas de modification du manifeste.

## 9. Audit du Dockerfile

Un stage `python:3.10-slim`, `COPY . .`, pas de `USER` ni de `.dockerignore`, démarrage `python app.py`. Build mesuré avant création de ce rapport.

## 10. Audit de Docker Compose et PostgreSQL

`docker compose config` : code 0. Identifiants en clair expurgés du rapport ; ports 5000 et 5432 publiés ; volume nommé ; healthcheck DB en `CMD-SHELL`, `depends_on: service_healthy`, absence de healthcheck API.

## 11. Images Docker et métriques initiales

Mesures en cours ; aucune valeur non mesurée n’est validée.

## 12. Audit Hadolint

`docker run --rm -i hadolint/hadolint:v2.15.1 hadolint - < Dockerfile` : code 0, aucune violation. `.hadolint.yaml` absent : conformité à la politique du TP non démontrée.

## 13. Audit Dive

Collecte en cours.

## 14. Audit Trivy et registre des CVE

Collecte en cours ; aucune CVE ni absence de CVE n’est encore déclarée.

## 15. Audit GitHub Actions et GHCR

GitHub confirme des runs qualité et intégration réussis sur le commit audité et un échec de publication GHCR ; la validité de l’intégration de l’image locale reste à examiner. Aucune publication déclenchée par cet audit.

## 16. Matrice de conformité au sujet

À consolider après la collecte ; le PDF officiel n’était pas accessible.

## 17. Registre des risques et non-conformités

FAIT VÉRIFIÉ : identifiants en clair, références mutables, absence de gouvernance Hadolint et de contrôles Dive/Trivy en CI. Aucun correctif effectué.

## 18. Commandes exécutées et preuves

Résultats enregistrés immédiatement dans un journal temporaire expurgé, puis intégrés à ce livrable lors de sa finalisation.

## 19. Contrôles non exécutés et blocages

Premier accès Docker refusé par le sandbox, résolu par accès autorisé. Premier build échoué sur le gestionnaire WSL, résolu par configuration Docker temporaire. `pip inspect` indisponible dans pip 22.0.2.

## 20. Recommandations pour les tickets suivants

TASK-002 : tests ; TASK-003 : dépendances ; TASK-004 : image minimale non-root ; TASK-005 : `.dockerignore` et Hadolint ; TASK-006 : PostgreSQL Chainguard ; TASK-007 à TASK-014 : probes, intégration, sécurité, CI, release et documentation.

## 21. Conclusion et état de la baseline

Document en cours de consolidation. Les sources et configurations existantes restent inchangées.
