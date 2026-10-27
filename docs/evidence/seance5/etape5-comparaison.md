# Étape 5 — comparaison des inventaires Syft et Trivy

Image demandée aux deux outils : `linter-python-flask-api:local`.

Trivy n’est pas installé dans le PATH ; utilisation de l’image Docker `aquasec/trivy:0.75.0`.

Commande exécutée depuis la racine du projet :

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$(pwd)/docs/evidence/seance5:/out" aquasec/trivy:0.75.0 image --cache-dir /out/trivy-cache --image-src docker --format spdx-json --output /out/sbom-api-trivy.spdx.json linter-python-flask-api:local 2>&1 | tee docs/evidence/seance5/etape5-trivy.log
```

Le processus s’est terminé avec le code 0. Le cache Trivy est placé dans le dossier de preuves.

| Inventaire SPDX 2.3 | Syft 1.51.1 | Trivy 0.75.0 |
|---|---:|---:|
| `.packages \| length` | 47 | 48 |
| Paquets PURL Debian | 38 | 38 |
| Paquets PURL Python | 8 | 8 |
| Entrée image OCI | 1 | 1 |
| Entrée système sans PURL (`debian`, version `13.7`) | 0 | 1 |

Les 46 couples nom/version des paquets Debian et Python correspondent après normalisation des noms (casse et séparateurs). Les références OCI sont conservées telles que produites par chaque outil dans `etape5-comparaison.json`.

L’écart de +1 est l’entrée du système Debian ajoutée par Trivy. Il faut distinguer ces entrées SPDX du nombre de fichiers inclus comme composants dans le CycloneDX de Syft.

Lecture de la CI :

- `quality.yml` installe les dépendances avec leurs hashes et exécute Flake8, pytest et Hadolint.
- `image-security.yml` dépend de cette qualité, construit l’image et lance Dive avec un seuil d’efficacité de 80 %.
- Trivy 0.75.0 y produit un rapport de vulnérabilités JSON et un contrôle bloquant pour les vulnérabilités HIGH/CRITICAL ayant un correctif ; ces commandes ne génèrent pas de SBOM.
- Les rapports et l’image validée sont exportés comme artefacts ; le job d’intégration utilise cette image.
- Le test local demandé génère uniquement le SBOM SPDX : le log Trivy confirme que ce format désactive la recherche de vulnérabilités par défaut. Les contrôles CI de vulnérabilités n’ont pas été exécutés pendant cette étape.

Vérification des workflows : `git diff --exit-code -- .github/workflows` a retourné 0, sans différence.

Verdict étape 5 : PASS.
