# TASK-003 — Audit et correction des dépendances Python

## État retrouvé et traçabilité

Reprise le 2026-10-08 de `feat/task-003`, issue [#3](https://github.com/clement-machtelinckx/linter-python-flask/issues/3). Responsable : Clément ; relecteur : Benoît.

Au démarrage, HEAD était `b9c1bf27b9c8dc9c1ba2c7c800eee6cd54f060e9`, identique à `origin/main` (confirmé aussi par `git ls-remote`). Aucun commit TASK-003 ni PR TASK-003 n’existait. `requirements.txt` était modifié et `requirements.in` non suivi : les versions, dépendances transitives et hashes étaient déjà présents. Ils ont été conservés **à l’identique**, comparés aux copies retrouvées, puis validés. `security-dependencies.md` et les résultats TASK-003 n’étaient pas récupérables ; les contrôles affectés ont donc été exécutés pendant la reprise. L’audit TASK-001 dans `audit.md` est conservé ; il n’a pas été relancé.

Commit des manifestes audités : **`fe1c41bd18e8333ee78b418dd4313cd855a8bf10`**. Les octets de `requirements.txt`, `requirements.in`, `app.py`, `test_app.py` et `.flake8` ont été comparés à ce commit ; leurs SHA256 figurent dans [provenance.json](security-evidence/task-003/provenance.json). Les commits suivants ne livrent que ce rapport et ses preuves.

SHA256 de `requirements.txt` : `a0a093dbad3a2dce0e1f057d69879c66410be0bd93f6d568654d99fcd8415212`.

## Inventaire initial et final

Le manifeste de référence imposait Flask 2.3.2, Werkzeug 2.3.3 et Pytest 7.4.0 ; `psycopg2-binary` n’était pas verrouillé. L’état historique exact des transitives n’est pas reconstructible sans ancien verrou. La colonne initiale ci-dessous désigne la **résolution effectuée le 2026-10-08 du manifeste initial**, soit 15 packages ; elle ne prétend pas décrire tous les anciens déploiements. TASK-001 documentait déjà psycopg2-binary 2.9.13.

Le verrou final contient 22 packages. `requirements.in` distingue trois dépendances directes runtime, deux outils de test/qualité et deux outils de construction. Les liens `Requires-Dist`, marqueurs Python, artefacts et hashes sont conservés dans [inventory.json](security-evidence/task-003/inventory.json). Le champ `direct` final se réfère à `requirements.in` ; `requested_by_pip` reflète le verrou intégral passé à pip.

| Package | Initial (résolu lors de la reprise) | Final | Rôle |
| --- | --- | --- | --- |
| blinker | 1.9.0 | 1.9.0 | Transitif (voir graphe JSON) |
| click | 8.5.0 | 8.5.0 | Transitif (voir graphe JSON) |
| exceptiongroup | 1.3.1 | 1.3.1 | Transitif (voir graphe JSON) |
| flake8 | Non déclaré | 7.3.0 | Qualité direct |
| mccabe | Non déclaré | 0.7.0 | Transitif (voir graphe JSON) |
| pycodestyle | Non déclaré | 2.14.0 | Transitif (voir graphe JSON) |
| pyflakes | Non déclaré | 3.4.0 | Transitif (voir graphe JSON) |
| Flask | 2.3.2 | 3.1.3 | Runtime direct |
| iniconfig | 2.3.1 | 2.3.1 | Transitif (voir graphe JSON) |
| itsdangerous | 2.2.0 | 2.2.0 | Transitif (voir graphe JSON) |
| Jinja2 | 3.1.6 | 3.1.6 | Transitif (voir graphe JSON) |
| MarkupSafe | 3.0.4 | 3.0.4 | Transitif (voir graphe JSON) |
| packaging | 26.3 | 26.3 | Transitif (voir graphe JSON) |
| pluggy | 1.6.0 | 1.6.0 | Transitif (voir graphe JSON) |
| psycopg2-binary | Non épinglé → 2.9.13 | 2.9.13 | Runtime direct |
| Pygments | Non déclaré | 2.21.0 | Transitif (voir graphe JSON) |
| pytest | 7.4.0 | 9.1.1 | Test direct |
| tomli | 2.5.0 | 2.5.0 | Transitif (voir graphe JSON) |
| typing_extensions | 4.16.0 | 4.16.0 | Transitif (voir graphe JSON) |
| Werkzeug | 2.3.3 | 3.1.9 | Runtime direct |
| wheel | Non déclaré | 0.48.0 | Construction direct |
| setuptools | Non déclaré | 84.0.0 | Construction direct |

Graphe runtime : Flask → Werkzeug, Jinja2, ItsDangerous, Click, Blinker ; Werkzeug et Jinja2 → MarkupSafe. psycopg2-binary n’a pas de dépendance Python transitive. Pytest → Pluggy, Packaging, Iniconfig, Pygments, ExceptionGroup et Tomli sur Python 3.10 ; ExceptionGroup → Typing Extensions. Flake8 → Pycodestyle, Pyflakes, McCabe ; Wheel → Packaging. Les extras non utilisés ne sont pas installés.

## Vulnérabilités confirmées et exposition

`pip-audit` initial : code **1**, 19 entrées dans 3 packages. Les doublons PYSEC/CVE et leurs alias correspondent à **10 avis GHSA distincts** : un HIGH, huit MEDIUM, un LOW, aucun CRITICAL. Le JSON brut est conservé dans [audit-initial.json](security-evidence/task-003/audit-initial.json) et les plages/corrections/sévérités GitHub dans [advisories.json](security-evidence/task-003/advisories.json). Les dix versions initiales concernées appartiennent aux plages affectées. L’applicabilité au package est distincte de l’exposition actuelle des routes : aucune exception de version vulnérable n’est conservée.

| CVE / source | Sévérité GitHub | Plage affectée → première correction | Conditions et exposition actuelle |
| --- | --- | --- | --- |
| CVE-2026-27199 / [GHSA-29vq-49wr-vm6x](https://github.com/advisories/GHSA-29vq-49wr-vm6x) | MEDIUM | werkzeug < 3.1.6 → 3.1.6 | Windows uniquement ; non exploitable sur Linux, package corrigé également. |
| CVE-2024-34069 / [GHSA-2g68-c3qc-8985](https://github.com/advisories/GHSA-2g68-c3qc-8985) | HIGH | Werkzeug < 3.0.3 → 3.0.3 | Débogueur interactif activé ; app.py ne l’active pas. |
| CVE-2026-27205 / [GHSA-68rp-wp8r-4726](https://github.com/advisories/GHSA-68rp-wp8r-4726) | LOW | flask < 3.1.3 → 3.1.3 | Session + cache partagé ; aucune session utilisée dans app.py. |
| CVE-2025-71176 / [GHSA-6w46-j5rx-g56g](https://github.com/advisories/GHSA-6w46-j5rx-g56g) | MEDIUM | pytest < 9.0.3 → 9.0.3 | Attaquant local UNIX et répertoires temporaires Pytest ; package installé. |
| CVE-2026-21860 / [GHSA-87hc-h4r5-73f7](https://github.com/advisories/GHSA-87hc-h4r5-73f7) | MEDIUM | Werkzeug < 3.1.5 → 3.1.5 | Windows uniquement ; non exploitable sur Linux, package corrigé également. |
| CVE-2024-49766 / [GHSA-f9vj-2wh5-fj8j](https://github.com/advisories/GHSA-f9vj-2wh5-fj8j) | MEDIUM | Werkzeug <= 3.0.5 → 3.0.6 | Windows uniquement ; non exploitable sur Linux, package corrigé également. |
| CVE-2026-102598 / [GHSA-g6x2-hccm-hh4m](https://github.com/advisories/GHSA-g6x2-hccm-hh4m) | MEDIUM | Werkzeug < 3.1.9 → 3.1.9 | Windows uniquement ; non exploitable sur Linux, package corrigé également. |
| CVE-2025-66221 / [GHSA-hgf8-39gv-g3f2](https://github.com/advisories/GHSA-hgf8-39gv-g3f2) | MEDIUM | werkzeug < 3.1.4 → 3.1.4 | Windows uniquement ; non exploitable sur Linux, package corrigé également. |
| CVE-2023-46136 / [GHSA-hrfv-mqp8-q5rw](https://github.com/advisories/GHSA-hrfv-mqp8-q5rw) | MEDIUM | werkzeug >= 3.0.0, < 3.0.1 → 3.0.1; werkzeug >= 2.0.0rc1, < 2.3.8 → 2.3.8 | Parseur multipart exposé à des données hostiles ; aucune route de formulaire actuelle. |
| CVE-2024-49767 / [GHSA-q34m-jh98-gwm2](https://github.com/advisories/GHSA-q34m-jh98-gwm2) | MEDIUM | Werkzeug >= 2.0.0rc1, <= 3.0.5 → 3.0.6 | Parseur multipart exposé ; aucune route de formulaire actuelle. |

Les avis Windows sont enregistrés pour expliquer les résultats du scanner ; leur scénario ne s’applique pas à l’environnement Linux testé. Les scénarios de session, débogueur et multipart ne sont pas démontrés comme exploitables par les routes actuelles. Les bibliothèques restent mises à jour pour supprimer ces vulnérabilités latentes. La CVE de Pytest concerne l’outil de test, même si aucun fixture tmpdir n’est utilisé dans les trois tests actuels.

Aucune CVE de Jinja2 ou psycopg2-binary n’est attribuée à une version historique inconnue. La résolution initiale actuelle utilise déjà Jinja2 3.1.6 et psycopg2-binary 2.9.13, sans avis dans ce scan.

## Justification des versions et reproductibilité

- [Flask 3.1.3](https://pypi.org/project/Flask/3.1.3/) corrige GHSA-68rp-wp8r-4726. Ses métadonnées exigent notamment Werkzeug >=3.1.0 ; Werkzeug 3.1.9 satisfait cette contrainte. Les [notes Flask](https://flask.palletsprojects.com/en/stable/changes/) confirment la correction.
- [Werkzeug 3.1.9](https://pypi.org/project/Werkzeug/3.1.9/) inclut les corrections jusqu’à GHSA-g6x2-hccm-hh4m, publiées le 2026-09-27 selon les [notes officielles](https://werkzeug.palletsprojects.com/en/stable/changes/). Revenir à 3.1.8 laisserait un avis corrigible dans le scan.
- [Pytest 9.1.1](https://pypi.org/project/pytest/9.1.1/) est une version publiée postérieure à la correction 9.0.3, compatible CPython >=3.10 et validée par les tests existants.
- [psycopg2-binary 2.9.13](https://pypi.org/project/psycopg2-binary/2.9.13/) verrouille la version déjà résolue avant l’interruption. L’import `psycopg2` et la connexion restent compatibles.
- Les autres versions retrouvées sont conservées : publications et hashes vérifiés sur PyPI, absence d’avis dans le scan final et résolution cohérente. Flake8 est inclus pour préserver la commande CI existante `pip install -r requirements.txt flake8`. Setuptools/Wheel sont verrouillés comme outils de construction ; leur retrait du runtime est transmis à TASK-004. Cette décision ne constitue pas un audit de la base Docker actuelle.

[pypi-verification.json](security-evidence/task-003/pypi-verification.json) atteste les **22 versions publiées**, `Requires-Python`, tous les hashes du verrou, les fichiers et statuts yanked. Tous les hashes correspondent à PyPI et aucune de ces versions n’est entièrement retirée. Les métadonnées finales ne contiennent aucun avis de vulnérabilité.

Cible validée : **CPython 3.10.12, Ubuntu 22.04, Linux x86_64**, même version mineure que la CI et le Dockerfile actuels. Tous les `Requires-Python` acceptent 3.10. Le verrou a été compilé sur Python 3.10 ; aucune validation des autres versions/OS/architectures n’est revendiquée. Changer de cible exige une nouvelle résolution et validation des marqueurs et wheels.

`pip-tools 7.6.2` recompile le verrou dans une copie temporaire : versions, annotations des dépendances et hashes identiques ; seul l’en-tête de commande reflète le chemin temporaire. Installation avec `--require-hashes` et `--only-binary=:all:` : aucun sdist ni téléchargement de dépendance de compilation non verrouillée dans l’environnement validé. Les hashes garantissent les artefacts Python, pas la reproductibilité bit à bit d’une image ou d’une compilation native.

Procédure de reproduction, depuis la racine du dépôt (les dossiers ci-dessous doivent être neufs) :

```bash
python3 -m venv /tmp/task003-tools
/tmp/task003-tools/bin/python -m pip install --index-url https://pypi.org/simple \
  pip==26.2.1 pip-audit==2.10.1 pip-tools==7.6.2
python3 -m venv --without-pip /tmp/task003-final
/tmp/task003-tools/bin/python -m pip --python /tmp/task003-final/bin/python install \
  --index-url https://pypi.org/simple --require-hashes --only-binary=:all: \
  -r requirements.txt
/tmp/task003-tools/bin/python -m pip --python /tmp/task003-final/bin/python check
DB_HOST=127.0.0.1 /tmp/task003-final/bin/python -m pytest -v
/tmp/task003-final/bin/flake8 --config=.flake8 .
/tmp/task003-tools/bin/pip-audit \
  --path /tmp/task003-final/lib/python3.10/site-packages --format json
```

Pour la DB, fournir `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` selon l’environnement de test. Les valeurs locales par défaut préexistantes n’ont pas été changées. Aucun nouveau secret n’est enregistré. pip et pip-audit restent dans un venv d’outillage séparé ; le venv final est créé sans pip embarqué. L’équivalent de `python -m pip check` est exécuté avec le pip externe et `--python`, afin de contrôler précisément ce venv.

Pour régénérer le verrou sur la même cible :

```bash
/tmp/task003-tools/bin/pip-compile --allow-unsafe --generate-hashes \
  --no-emit-index-url --no-emit-trusted-host \
  --output-file=requirements.txt requirements.in
```

La régénération réutilise le verrou existant. Toute actualisation volontaire des versions transitives doit être revue et suivie d’une nouvelle installation, des tests et du scan. `--allow-unsafe` est le nom historique de l’option pip-tools autorisant le verrouillage de Setuptools ; aucun avis de sécurité n’est ignoré par cette option.

## Commandes exécutées et résultats

Les commandes **exactes**, heures UTC, environnement, codes et sorties intégrales sont dans [commands.json](security-evidence/task-003/commands.json). Les sources des trois scripts de collecte temporaire sont embarquées dans `provenance.json`, pour rendre les preuves exploitables même après disparition de `/tmp`. Outillage : pip 26.2.1, pip-audit 2.10.1, pip-tools 7.6.2 ; tests : Pytest 9.1.1, Pluggy 1.6.0, Flake8 7.3.0, Pycodestyle 2.14.0, Pyflakes 3.4.0, McCabe 0.7.0.

| Contrôle (label du journal) | Commande principale réellement exécutée | Code | Résultat |
| --- | --- | --- | --- |
| `install` | `/tmp/task003-tools/bin/python -m pip --python /tmp/task003-final/bin/python install --index-url https://pypi.org/simple --require-hashes --only-binary=:all: --report /tmp/task003-install.json -r requirements.txt` | 0 | 22 packages installés dans un venv neuf |
| `pip-check` | `/tmp/task003-tools/bin/python -m pip --python /tmp/task003-final/bin/python check` | 0 | Aucun conflit |
| `pytest-unit` | `/tmp/task003-final/bin/python -m pytest -v -m 'not integration'` | 0 | 2 PASS, 1 désélectionné |
| `pytest-full` | `DB_HOST=127.0.0.1 /tmp/task003-final/bin/python -m pytest -v` | 0 | 3 PASS, 0 échec, PostgreSQL réel |
| `flake8` | `/tmp/task003-final/bin/flake8 --config=.flake8 .` | 0 | Aucune violation |
| `audit-initial` | `/tmp/task003-tools/bin/pip-audit -r /tmp/task003-initial-pinned.txt --no-deps --disable-pip --format json --output security-evidence/task-003/audit-initial.json` | 1 | 19 entrées / 10 avis distincts, constat initial attendu |
| `audit-installed` | `/tmp/task003-tools/bin/pip-audit --path /tmp/task003-final/lib/python3.10/site-packages --format json --output security-evidence/task-003/audit-final.json` | 0 | 22 packages, 0 vulnérabilité connue, aucun package ignoré |
| `pypi-verification` / `advisories` | Collecteurs Python conservés dans `provenance.json` | 0 | Publications, hashes, plages GHSA et corrections confirmés |
| `recompile` / `compare-lock` | pip-compile vers `/tmp/task003-recompiled.txt`, puis comparaison du contenu hors en-tête | 0 | Verrou reproduit sans modifier l’original |
| `ci-install` | `/tmp/task003-tools/bin/python -m pip --python /tmp/task003-final/bin/python install --dry-run -r requirements.txt flake8` | 0 | La commande CI accepte le verrou et Flake8 déjà épinglé |
| `database-server` | Connexion directe avec la valeur par défaut `DB_HOST=db` depuis l’hôte | 1 | Nom Compose non résolu ; erreur d’environnement conservée |
| `database-server-localhost` | Même connexion avec `DB_HOST=127.0.0.1` | 0 | PostgreSQL 14.24, SELECT 1, fermeture du curseur/connexion : PASS |
| `native-libraries` | Interrogation de psycopg2/libpq et `OpenSSL_version` du wheel installé | 0 | libpq 17.11 (`170011`), OpenSSL 3.5.8 |
| `final-review` | Vérification des preuves, octets du commit, Markdown, périmètre et `git diff --check` | 0 | PASS (voir journal) |

Les avertissements Pytest sur le marqueur `integration` non enregistré sont préexistants et restent visibles ; aucun test n’est supprimé ou masqué. `app.py` et `test_app.py` ne nécessitent aucune adaptation. L’accès réseau et Docker a d’abord été refusé dans le sandbox ; l’exécution autorisée a permis installation, scan et tests PostgreSQL. Le premier bootstrap d’outils n’a pas pu résoudre PyPI et n’a installé aucun package. Aucune version de cet essai n’est retenue dans les manifestes. Les avertissements pip sur le cache non inscriptible n’affectent pas l’installation.

## Scan final et risques résiduels

[audit-final.json](security-evidence/task-003/audit-final.json) : **0 vulnérabilité connue sur les 22 distributions Python réellement installées**, service d’avis PyPI, pip-audit 2.10.1, 2026-10-08. Aucun identifiant ignoré, aucune exception HIGH/CRITICAL acceptée. Le manifeste final, l’installation et le scan contiennent exactement les mêmes noms/versions.

Cette conclusion porte sur les distributions Python. pip-audit ne scanne pas le système, l’interpréteur CPython, les bibliothèques C embarquées, l’image GHCR existante ni les images PostgreSQL. Aucun « zéro CVE de l’image » n’est revendiqué. Les mises à jour OS/libpq/OpenSSL et le scan de l’image finale sont à effectuer dans TASK-004. Les outils de test et de construction restent présents dans le manifeste compatible avec le Dockerfile existant et devront être séparés du runtime.

La validation GitHub Actions est **UNKNOWN / non exécutée pour cette livraison** : le workflow `main.yml` réagit à chaque push, puis `publish_to_ghcr.yml` réagit à sa fin sans filtre de branche ou de succès. Pour respecter l’interdiction de publication GHCR sans modifier les workflows, le commit de documentation porte `[skip ci]`, conformément à la [documentation GitHub](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs). La suppression de ce marqueur lors d’un push ultérieur doit attendre que l’exécution des publications soit autorisée ou encadrée. Les checks requis peuvent rester Pending ; la revue locale est prouvée, la CI verte ne l’est pas. Aucun workflow n’a été lancé manuellement.

## Compatibilité PostgreSQL et contraintes pour TASK-004

`import psycopg2` est conservé. `get_db_connection()` utilise toujours `psycopg2.connect(...)` ; connexion réelle à PostgreSQL 14.24, SELECT 1 et route `/dbtest` vérifiés. La PR #18 (TASK-006) n’est pas modifiée ; aucune validation PostgreSQL 18 n’est revendiquée ici.

La [documentation Psycopg](https://www.psycopg.org/docs/install.html) recommande la distribution source pour la production. `psycopg2-binary==2.9.13` est conservé dans TASK-003 pour permettre l’installation avec le Dockerfile actuel, sans introduire de compilation non préparée. Son wheel contient sa propre libpq et libssl : une mise à jour des bibliothèques OS ne les met pas à jour ; des conflits libssl peuvent aussi survenir en concurrence.

Pour TASK-004, conserver l’API psycopg2 et choisir explicitement entre ce wheel validé et `psycopg2==2.9.13` compilé. En cas de compilation : builder avec compilateur C, headers Python, `libpq-dev` et `pg_config` dans PATH ; runtime avec `libpq`/`libpq5` et bibliothèques dynamiques compatibles, sans compilateur ni headers. Builder/runtime doivent partager architecture, ABI CPython et libc. Les versions libpq des headers et du runtime doivent être cohérentes ; elles n’ont pas à correspondre au majeur du serveur PostgreSQL. Vérifier les liaisons avec `ldd`.

Retenir un CPython maintenu avec correctifs à jour ; 3.10.12 est la version de test, pas une recommandation de patch de production. Tout changement de version mineure impose la régénération/validation du verrou. Séparer runtime, tests et outils de build. Pour `psycopg2` source, verrouiller son sdist/hashes ainsi que le backend PEP 517 et ses dépendances de compilation, produire le wheel dans le builder, puis installer ce wheel sans résolution réseau dans le runtime. Ne pas installer simultanément `psycopg2` et `psycopg2-binary`, qui fournissent le même module. La compilation source n’a pas été exécutée dans TASK-003. Le scan OS/natif de l’image finale demeure nécessaire.

## Critères d’acceptation

| Critère du prompt | Statut | Preuve |
| --- | --- | --- |
| Dépendances initiales et transitives identifiées | PASS | Manifeste initial et résolution actuelle de 15 packages, limites historiques explicites, inventory.json |
| Vulnérabilités documentées avec sources fiables | PASS | 10 avis GHSA vérifiés, audit-initial.json et advisories.json |
| Packages corrigés et compatibles | PASS | Versions PyPI, pip check et tests Flask/DB |
| Verrouillage reproductible | PASS | Versions/hashes complets, installation et recompile identique |
| Installation dans un environnement Python propre | PASS | Venv sans pip, 22 packages installés |
| pip check sans conflit | PASS | Code 0 |
| Compatibilité Flask/Werkzeug | PASS | Requires-Dist, pip check, routes /health et /hello |
| Import et fonctionnement psycopg2 préservés | PASS | Import, connexion, SELECT 1 et /dbtest avec PostgreSQL 14.24 |
| Tests pertinents sans régression introduite | PASS | 3 PASS, avertissement préexistant documenté |
| Scan final et vulnérabilités restantes documentés | PASS | 0 avis Python, limites OS/natives explicites |
| Aucun HIGH/CRITICAL corrigible accepté silencieusement | PASS | HIGH initial corrigé, aucune exception Python |
| security-dependencies.md complet | PASS | Rapport et sept artefacts JSON versionnés |
| Contraintes TASK-004 explicites | PASS | ABI, compilation, libpq, PEP 517, installation runtime |
| Périmètre TASK-003 respecté | PASS | Deux manifestes, rapport et preuves ; Docker/Compose/workflows inchangés |
| Aucun secret/affaiblissement de sécurité introduit | PASS | Aucun changement applicatif ni des contrôles ; CI différée pour respecter l’interdiction GHCR, revue requise |

Issue #3 : **AC-01 PASS** (installation reproductible, tests locaux, scan et registre) ; **AC-02 PASS** (périmètre/absence de secret) ; **AC-03 PASS** (SHA et preuves persistantes). Definition of Done distante : revue de Benoît et CI verte **UNKNOWN / en attente**. Aucune fusion effectuée. La modification utilisateur de `.gitignore` apparue pendant la reprise est conservée dans le workspace et exclue des commits TASK-003.
