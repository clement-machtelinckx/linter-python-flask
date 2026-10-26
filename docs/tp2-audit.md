# Audit initial TP2

Base : `f0f40579b265da20bad0c8a097b30631100890ea`. Cahier des charges : [issue #34](https://github.com/clement-machtelinckx/linter-python-flask/issues/34).
L'étape 1 A/B/C est normative ; les modalités SBOM, VEX et signature sont les choix techniques proposés dans le ticket.

| Besoin | Constat initial | Modification prévue | Validation / preuve attendue |
| --- | --- | --- | --- |
| Cache pip | Installation sans cache | Cache mount BuildKit, manifeste avant code | Deux builds, manifeste modifié, logs et durées |
| Secret de build | Aucun secret requis | Secret fichier requis, exclusions et injection Bake/Compose/CI | Absence/valeur vide refusées ; historique et couches inspectés |
| Multiarchitecture | Image AMD64 exportée par la CI | Bake local AMD64 et archive OCI AMD64/ARM64 | Bake print, imports binaires sous chaque architecture, index et digests |
| Cache externe | Aucun backend | Cache registry paramétrable, export mode=max ; override gha en CI | Import/export effectifs ; distinction avec cache mount pip |
| SBOM | Aucun inventaire normalisé | CycloneDX par manifeste, schéma officiel et composants attendus | JSON Schema, Flask/Werkzeug/psycopg2-binary, mapping digest |
| VEX | Aucun format | Politique OpenVEX, aucune exception active sans preuve | Rapport brut et rapport traité conservés, gate strict |
| Intégrité | Aucune signature | Cosign OIDC, index signé, SBOM et provenance par digest | Vérification issuer/identité/sujets après publication autorisée |
| Qualité | Flake8/pytest/Hadolint existants | Préserver et compléter les règles Hadolint | Jobs réutilisés et tests locaux |
| Secret runtime | Mot de passe en environnement Compose | DB_PASSWORD_FILE et mécanisme PostgreSQL vérifié | Démarrage DB/API, inspection configuration, tests positifs/négatifs |
| Release | Artefact AMD64 validé, SemVer non écrasable | Artefact OCI multiarch validé puis copié sans rebuild | Conservation des digests, gates source main, signature |
| Documentation | README anglais, preuves historiques | README français, résultats TP2 distincts de TP1 | Commandes reproductibles et rapport de validation |

## Chemins de build et périmètre

- `Dockerfile` racine : Compose local, `image-security.yml`, puis artefact chargé dans `multi-container.yml` et `publish_to_ghcr.yml`.
- `multi-container.yml` construit aussi un runner de tests Python indépendant : il n'utilise pas le Dockerfile applicatif.
- `aws/main.tf`, le playbook Ansible et le workflow EC2 manuel référencent le Compose racine sans provisionner les fichiers applicatifs/secrets. Ces anciens déploiements étaient déjà incomplets (variables requises, contexte absent). Leur remise en service exige de provisionner le dépôt et les fichiers secrets selon le README ; Terraform et ces workflows restent hors périmètre.
- Render consomme une ancienne image distante ; aucun build applicatif dans le Terraform racine.
- Les huit dépendances runtime sont épinglées. `psycopg2-binary` et MarkupSafe nécessitent des wheels CPython 3.13 compatibles avec chacune des architectures. Une configuration multiarch seule ne prouve pas cette compatibilité.
- Builder Python Debian 13 et runtime Distroless Debian 13 partagent l'ABI CPython 3.13 ; leurs versions patch diffèrent. Conserver les digests existants tant que leur contrôle et les scans ne justifient pas une mise à jour.
- Les références d'actions existantes sont des SHA complets ; les nouveaux outils doivent être vérifiés avant intégration.

Le cache externe exporte les couches et métadonnées de build ; `mode=max` ne garantit pas l'export du contenu du cache mount pip. Un builder persistant est nécessaire pour mesurer ce dernier.
