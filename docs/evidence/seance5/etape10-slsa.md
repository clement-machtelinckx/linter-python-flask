# Étape 10 — signature, attestation et SLSA

Une signature permet de vérifier qu’un détenteur de clé a signé un contenu donné et que ce contenu n’a pas changé. Une attestation ajoute une déclaration structurée liée à un artefact : par exemple sa composition SBOM ou sa provenance de construction. Signer une déclaration ne garantit pas à lui seul que toutes ses affirmations sont vraies.

Une déclaration in-toto lie un ou plusieurs sujets identifiés par digest à un type de prédicat et à son contenu. Cosign peut signer cette déclaration dans une enveloppe DSSE. Dans notre étape 11, le prédicat est un SBOM SPDX ; ce n’est pas une provenance de construction SLSA.

| Niveau SLSA Build | Idée principale |
|---|---|
| L0 | Aucune garantie SLSA démontrée. |
| L1 | La construction génère automatiquement une provenance décrivant le producteur, le procédé et les entrées ; cette provenance est distribuée aux consommateurs. |
| L2 | Les exigences L1 sont complétées par une provenance authentifiée produite par la plateforme de build hébergée, puis vérifiée par le consommateur. |
| L3 | La plateforme durcit l’isolation des constructions et protège la production de provenance contre les étapes définies par l’utilisateur. |

Évaluation prudente du dépôt, à partir des fichiers présents : **niveau démontrable L0 ; L1 non établi, L2 et L3 non démontrés**. Cette lecture n’est pas une certification ni une vérification de runs GitHub distants.

- `quality.yml` exécute Flake8, pytest et Hadolint ; ces contrôles ne constituent pas une provenance.
- `image-security.yml` construit l’image, conserve le SHA Git et l’heure, exécute Dive et Trivy puis exporte l’image avec son SHA256 et son identifiant. Ce sont des éléments de traçabilité utiles.
- `publish_to_ghcr.yml` vérifie les runs de qualité et de sécurité du même commit, récupère l’artefact validé, contrôle le checksum et l’identifiant puis publie sans reconstruire l’image.
- Ces fichiers ne démontrent pas que les consommateurs reçoivent une provenance de construction satisfaisant les exigences L1 : les notes de commit, l’ID d’image et le checksum du tar ne suffisent pas à établir cela.
- Aucun générateur de provenance signé par la plateforme ni vérificateur SLSA n’est explicitement configuré. Utiliser GitHub Actions et épingler des actions ne donne pas automatiquement L2 ou L3.
- L’image locale contient un descripteur BuildKit `attestation-manifest`, visible dans `etape7-image-inspect.log`. Sa présence seule ne prouve pas le contenu, la distribution et les garanties de provenance du pipeline CI actuel ; elle ne justifie donc pas de relever le niveau déclaré.

La signature et l’attestation SBOM locales de cette séance ne relèvent pas automatiquement le niveau SLSA du pipeline.

Sources : [SLSA v1.2, niveaux Build](https://slsa.dev/spec/v1.2/build-track-basics), [structure d’une déclaration in-toto](https://github.com/in-toto/attestation/blob/main/spec/v1/statement.md).
