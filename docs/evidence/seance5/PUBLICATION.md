# Publication de l’atelier existant sur clement

À la demande finale de l’utilisateur, cette branche publie le travail déjà réalisé jusqu’à la slide 30. Elle n’ajoute pas de développement Grype, VEX, Dependency-Track ou de nouveau pipeline GitHub Actions. Aucun PDF n’a été fourni ; aucune conformité aux 55 pages n’est revendiquée.

La branche `clement` a été créée depuis `origin/main` au commit `7371c8005e4fad1d39ea1ee45efbbb3216156c88`, après `git fetch origin`, puis publiée avec `git push -u origin clement` avant toute modification des livrables. Le worktree de publication est séparé du dossier local d’origine : ses modifications du README et ses autres travaux non commités n’ont été ni écrasés ni supprimés.

Les livrables publiés comprennent les SBOM CycloneDX et SPDX, les comparaisons Syft/Trivy, les preuves publiques de signature et d’attestation, les clés publiques, les scripts et la documentation française. Les logs retenus ont été contrôlés pour exclure les marqueurs de clé privée et les formats de jeton de build/GitHub. Aucune clé privée, aucun fichier `.env`, aucun dossier de secrets, cache, archive ou binaire téléchargé n’est publié.

`inventaire-publication.txt` liste les fichiers publiés. `inventaire-fichiers.txt` et `final-fichiers.json` sont les constats historiques de l’atelier local, dont le périmètre comprend des fichiers volontairement non publiés.

Le script de vérification a uniquement été adapté à cette publication : il vérifie les empreintes des binaires installés sans nécessiter les archives, contrôle les permissions privées si une clé existe localement, vérifie l’inventaire public et permet de désigner la composition d’un autre worktree. Les empreintes de `outils-binaires.sha256` proviennent des binaires extraits dont les checksums officiels ont été revérifiés avant publication.

Les attestations restent attachées au registre local `localhost:5001`. Les fichiers de preuve sont publiés dans Git ; cela ne rend pas l’image et ses attestations disponibles dans un registre distant. Une vérification directe Cosign nécessite ce registre local. L’attestation SBOM conserve la limite documentée d’absence d’inclusion Rekor ; aucune garantie supplémentaire n’est revendiquée.

Les versions épinglées restent Syft 1.51.1, Cosign 2.4.1 et Trivy 0.75.0. Les Dockerfile, sources Flask, tests applicatifs, configuration Compose/Bake et workflows existants ne sont pas modifiés par cette publication.

Vérifications réellement exécutées avant le commit :

- PASS : pytest dans l’image locale de tests, Python 3.13.16 / pytest 9.1.1 : **5 passed, 1 deselected** ; le test d’intégration PostgreSQL est exclu de cette commande.
- PASS : Flake8 avec la configuration existante, code de retour 0 et aucune sortie.
- PASS : syntaxe Bash des deux scripts ; absence de différence dans les fichiers applicatifs et workflows protégés.
- PASS : `verifier-seance5.sh` depuis le worktree de publication, avec `SEANCE5_COMPOSE_DIRECTORY` désignant la composition d’origine : empreintes binaires, inventaire, absence de secrets, signature, attestation et services Compose vérifiés.
- NON TESTÉ dans cette publication : nouveau run GitHub Actions et nouveau test pytest d’intégration. Les workflows existants restent inchangés ; aucune réussite CI distante n’est inventée.

Sorties conservées dans `publication-pytest.log`, `publication-flake8.log` et `publication-verifications.log`.
