# Séance 5 — bilan jusqu’à la slide 30 incluse

Ce rapport conserve le constat de l’atelier local avant sa publication Git. L’inventaire historique de 90 fichiers comprend des outils téléchargés, un cache et la clé privée qui restent exclusivement en local. Le périmètre publié sur `clement` est décrit dans `PUBLICATION.md` et `inventaire-publication.txt`.

Les étapes 0 à 11 ont été traitées. Les étapes 8 et 9 sont volontairement limitées à la rédaction, sans exécution keyless. L’étape 11 est une attestation locale dont la signature, le digest et le contenu ont été vérifiés ; cette attestation n’a pas été publiée dans Rekor.

Le PDF du cours n’a pas été fourni dans le dépôt : la correspondance avec les slides suit le déroulé demandé, sans prétendre vérifier leur texte exact.

| Étape | Verdict | Preuve mesurée ou fichier |
|---|---|---|
| 0 — prérequis et théorie | PASS | Docker 28.4.0, jq 1.6, curl 7.81.0, OpenSSL 3.0.2 ; `notes-theorie.md`, 15 lignes ; jq initialement absent puis installé par l’utilisateur et revérifié. |
| 1 — Syft vérifié | PASS | Archive `syft_1.51.1_linux_amd64.tar.gz: OK`, version 1.51.1 ; `etape1-checksum.log`, `etape1-syft-version.log`. |
| 2 — Python 3.12 slim | PASS | Tableau et export CycloneDX ; 2 755 composants, dont 2 659 fichiers ; `sbom-python312.cdx.json`, `etape2-validation.log`. |
| 3 — image du projet | PASS | 38 paquets Debian et 8 Python ; 2 186 composants CycloneDX, dont 2 139 fichiers ; 47 entrées SPDX ; huit versions runtime conformes ; `etape3-comparaison.md`. |
| 4 — jq | PASS | Huit requêtes principales et diagnostics enregistrés ; libssl3t64=`3.5.7-1~deb13u3`, zéro paquet nommé openssl ; `etape4-requetes-jq.log`. |
| 5 — comparaison CI/Trivy | PASS | Syft SPDX=47, Trivy SPDX=48 ; mêmes 46 couples nom/version de paquets ; entrée système Debian ajoutée par Trivy ; `etape5-comparaison.json`, `etape5-comparaison.md`. |
| 6 — Cosign et exclusions | PASS | `cosign-linux-amd64: OK`, Cosign v2.4.1, exclusions Git/Docker vérifiées ; `etape6-checksum.log`, `etape6-git-ignore.log`. |
| 7 — signature et test négatif | PASS | Registre local, digest signé, vérification positive code 0 ; mauvaise clé publique : `no matching signatures`, code 12 ; `etape7-bilan.md`, `etape7-verify.log`, `etape7-negative-result.json`. |
| 8 — keyless, théorie | PASS (rédaction) | OIDC, Fulcio, Rekor et exemple CI sans action `uses` ; syntaxe YAML validée ; `keyless-snippet.md`. |
| 9 — vérification keyless | PASS (rédaction) | Identité du workflow du dépôt et émetteur GitHub imposés ; commande non exécutée dans `keyless-snippet.md`. |
| 10 — attestation et SLSA | PASS (analyse) | Signature, attestation, in-toto et Build L0–L3 expliqués ; L0 démontrable, L1 non établi et L2/L3 non démontrés par les fichiers CI ; `etape10-slsa.md`. |
| 11 — SBOM attesté | PASS (local) | Type `spdxjson`, digest du sujet conforme, 47 paquets avant/après, JSON identiques ; `etape11-comparaison.json`, `verified-sbom.json`. |

Référence réellement signée :

```text
localhost:5001/linter-python-flask-api@sha256:5f21fdc9e986c3d2be21ab8108cd39a6a8526d228d5111414fc0bfb316671695
```

Versions runtime demandées, comparées aux valeurs du SBOM : Flask 3.1.3, Werkzeug 3.1.9 et psycopg2-binary 2.9.13. Les cinq autres dépendances épinglées correspondent également.

## Outils installés et utilisés

| Outil | Version constatée | Emplacement / mode |
|---|---|---|
| Syft | 1.51.1 | Installé dans `/home/yazii/.local/bin/syft`, sans sudo. |
| Cosign | v2.4.1 | Installé dans `/home/yazii/.local/bin/cosign`, sans sudo. |
| jq | 1.6 | `/usr/bin/jq`, installé par l’utilisateur après le premier contrôle. |
| Trivy | 0.75.0 | Image `aquasec/trivy:0.75.0`, pas de binaire installé sur l’hôte. |
| Docker | 28.4.0 client et serveur | `/usr/bin/docker`, préexistant. |
| Docker Compose | v2.39.4-desktop.1 | Plugin Docker préexistant. |
| curl | 7.81.0 | `/usr/bin/curl`, préexistant. |
| OpenSSL | 3.0.2 | `/usr/bin/openssl`, préexistant. |

Archives, binaires téléchargés et checksums sont conservés dans `syft-v1.51.1/` et `cosign-v2.4.1/`. Les contrôles finaux vérifient également que les binaires installés correspondent aux fichiers validés.

## Fichiers créés et modifiés

La liste exhaustive des fichiers présents dans le dossier de preuves est fournie dans `inventaire-fichiers.txt`. Elle inclut les téléchargements, SBOM, logs, documents, scripts de vérification et le cache technique Trivy. Chaque fichier listé est contrôlé comme existant et non vide. Le chemin de la clé privée y figure pour inventaire, sans son contenu ; la clé est ignorée par Git.

Principaux livrables :

- `notes-theorie.md` : synthèse et conclusions des étapes 5, 8, 9 et 10.
- `sbom-python312.cdx.json` : atelier Python 3.12 slim.
- `sbom-api.cdx.json`, `sbom-api.spdx.json` : image locale du projet.
- `sbom-api-trivy.spdx.json` : comparaison Trivy.
- `sbom-api-digest.spdx.json`, `sbom-api-digest.cdx.json` : image lue au digest du registre local.
- `verified-sbom.json` : prédicat extrait après vérification cryptographique de l’attestation.
- `cosign.pub`, `keys/cosign.pub`, `keys/wrong-key.pub` : clés publiques de vérification et de test.
- `keys/cosign.key` : clé privée chiffrée, ignorée par Git, permissions restreintes ; ne pas publier.
- `keyless-snippet.md`, `etape10-slsa.md` : rédactions demandées.
- `etape3-comparaison.md`, `etape5-comparaison.md`, `etape7-bilan.md`, `etape11-bilan.md` : explications des résultats.
- `etape7-generer-et-signer.sh` : script interactif exécuté par l’utilisateur pour la génération initiale et la signature ; ne pas le relancer pour vérifier.
- `verifier-seance5.sh`, `commandes-verification.md` : vérification sans passphrase ni génération de clé.
- `final-verification.log`, `final-compose-ps.log`, `final-git-status.log`, `final-fichiers.json` : preuves des contrôles finaux.

Hors du dossier de preuves, seuls `.gitignore` et `.dockerignore` ont été modifiés pour les exclusions demandées. Les fichiers applicatifs, Dockerfile, Compose, Bake et workflows protégés ne présentent aucune différence Git. Les autres éléments non suivis visibles dans `git status` étaient déjà présents avant ces ateliers. Aucun commit, push Git, tag Git ou staging n’a été effectué.

## Double contrôle final

1. Les chemins `cosign.key`, `.secrets/pip_token.txt` et la clé dans `keys/` sont reconnus par `git check-ignore -v`.
2. Aucun chemin suivi ou stagé ne correspond à `cosign\.key|\.secrets|\.env$`.
3. La recherche de marqueurs de clé privée dans les preuves, en excluant seulement `cosign.key` ignorée, ne retourne aucun fichier. La passphrase n’est présente dans aucun fichier de preuve.
4. L’inventaire complet est contrôlé pour l’existence et la taille non nulle des fichiers. La clé privée conserve des permissions empêchant l’accès aux autres utilisateurs.
5. Compose ne tournait plus au premier contrôle ; une relance autorisée avec `docker compose up -d --no-build --wait --wait-timeout 60` a réussi. `api-python` et `db` sont **healthy**. Le registre `tp2-registry` reste disponible pour les vérifications.

Le cache Trivy créé par le conteneur root a reçu le propriétaire de l’utilisateur, uniquement sur son répertoire monté, afin de rendre toutes les preuves lisibles sans sudo.

## Limite de publication de l’attestation

Le contrôle automatique d’autorisation a refusé la première commande d’attestation avant son exécution : elle aurait envoyé le SBOM au journal public Rekor, destination non explicitement autorisée. L’alternative exécutée utilise `--tlog-upload=false` et conserve le SBOM dans le registre local. Sa vérification emploie `--insecure-ignore-tlog` : la signature, le digest et le contenu sont vérifiés, mais aucune inclusion Rekor n’est revendiquée pour cette attestation. L’avertissement Cosign est conservé. La signature d’image de l’étape 7 possède, elle, un bundle de transparence vérifié.

## Commandes de vérification et suite

```bash
cd ~/ynov_project/linter-python-flask
bash docs/evidence/seance5/verifier-seance5.sh
```

La liste des commandes unitaires pour les versions, SBOM, exclusions et signatures est dans `commandes-verification.md`.

Arrêt à la slide 30 incluse. La suite du cours reste à faire : Grype, VEX, Dependency-Track et intégration GitHub Actions. Aucun de ces ateliers suivants ni aucune exécution keyless n’a été lancé.
