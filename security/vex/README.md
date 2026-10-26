# Politique VEX

Aucune exception n'est approuvée. Le gate TP1 reste strict : toute HIGH/CRITICAL
avec correctif est bloquante. Les secrets détectés sont également bloquants.
Le rapport `trivy-full-ARCH.json` conserve toutes les vulnérabilités, y compris
sans correctif. Le rapport `trivy-after-vex-ARCH.json` est produit séparément ;
sans exception, les ensembles de vulnérabilités doivent être identiques.

Une future exception doit être un document [OpenVEX](https://github.com/openvex/spec),
revu dans une PR, contenant une CVE réellement détectée, le produit exact par digest,
un statut standard et sa justification technique. La preuve, la personne qui valide,
la date de validation et la date limite de réexamen doivent accompagner le document.
Un statut `not_affected` exige une preuve de non-applicabilité. Une absence de correctif
n'est pas une preuve de non-applicabilité.

Modèle documentaire non opérationnel, à compléter uniquement avec des faits vérifiés :

| Champ | Contenu requis |
| --- | --- |
| `@context` | Contexte OpenVEX versionné |
| `@id`, `author`, `timestamp`, `version` | Identité et version du document |
| `statements[].vulnerability.name` | CVE réelle du rapport brut |
| `statements[].products[].@id` | Identifiant du produit au digest contrôlé |
| `statements[].status` | Statut standard justifié |
| `statements[].justification`, `impact_statement` | Analyse et preuve reproductible |
| Revue associée | Validateur humain, date, échéance et lien vers preuve |

Aucun fichier d'exception actif n'est fourni. La CI refuse l'ajout silencieux de JSON
dans ce dossier ; l'activation future demandera une modification revue du validateur
et du gate, ainsi qu'un test de l'effet exact de `trivy image --vex fichier.json`.
L'option `--vex` est contrôlée sur la version épinglée ; cela ne prouve pas à lui seul
le traitement d'une exception réelle.
