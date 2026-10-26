# TP2 — Étape 1 : exigences

Industrialisation du build, étanchéité des secrets et multi-architecture du microservice
Flask / PostgreSQL durci au TP1.

## A. Cache persistant hors couches

- Syntaxe BuildKit étendue activée en tête du `Dockerfile`.
- L'installation des dépendances Python de l'étage `builder` utilise un montage de cache
  persistant géré par BuildKit : le cache n'est plus ni purgé ni embarqué dans la couche.
- La modification d'une dépendance ne retélécharge pas les paquets déjà en cache.
- L'image finale ne contient aucun fichier de cache.

## B. Secret de build en mémoire vive

- L'étage `builder` consomme un jeton secret simulant un serveur de paquets interne,
  sans instruction `ARG` ni variable `ENV`.
- Le secret est monté en mémoire temporaire pendant la seule instruction concernée,
  vérifié par le build, puis démonté automatiquement.
- Ni `docker history --no-trunc` ni un scanner de secrets ne révèlent le jeton.
- Le fichier local du secret est exclu du contexte de build et du suivi de version.

## C. Multi-plateforme et configuration déclarative

- Une configuration HCL à la racine du dépôt remplace les commandes impératives.
- Elle définit des variables (registre, étiquettes de version), cible `linux/amd64` et
  `linux/arm64`, lie le secret de build et importe/exporte le cache externe en mode complet.
- Le registre expose un index unifié, déployable sur les deux familles de processeurs.

## Cadre de réalisation

- Travail en local : le registre de test local tient lieu de registre distant.
- Les preuves citées dans le rapport proviennent de commandes exécutées par nous.
- Hors périmètre de l'étape 1 : inventaire logiciel (SBOM), qualification des vulnérabilités
  non exploitables, intégrité et provenance de l'image, traités dans les étapes suivantes.
