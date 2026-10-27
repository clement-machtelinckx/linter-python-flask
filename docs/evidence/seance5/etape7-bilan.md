# Étape 7 — signature et vérifications

Verdict : **PASS**.

Le registre `tp2-registry` a été créé avec `registry:2`, sur le port local 5001. L’image du projet y a été taguée et poussée. Aucun commit, push Git ni tag Git n’a été créé.

Digest obtenu réellement par `docker buildx imagetools inspect` :

```text
localhost:5001/linter-python-flask-api@sha256:5f21fdc9e986c3d2be21ab8108cd39a6a8526d228d5111414fc0bfb316671695
```

L’utilisateur a exécuté le script interactif de génération et signature. Ses logs ont été constatés sur disque. Une tentative ultérieure de relancer ce script s’est arrêtée volontairement parce qu’une clé existait déjà ; aucun écrasement n’a été effectué.

`cosign sign --key keys/cosign.key --yes --allow-http-registry <image@digest>` a signé le digest. L’option `--allow-http-registry` est documentée dans le `--help` réel de Cosign v2.4.1 ; elle permet le protocole HTTP du registre de test. Elle ne désactive pas la vérification cryptographique des signatures.

La vérification avec `cosign verify --allow-http-registry --key docs/evidence/seance5/keys/cosign.pub <image@digest>` est terminée avec le code 0. Cosign confirme la vérification des déclarations, de leur présence dans le journal de transparence via le bundle hors ligne, et de la signature avec la clé publique fournie.

Le test négatif a créé une autre clé publique EC P-256 ; la clé privée jetable a seulement transité dans un pipe OpenSSL, sans affichage ni écriture sur disque. La vérification du même digest avec `keys/wrong-key.pub` échoue réellement avec `no matching signatures`, code **12**. L’échec attendu constitue un test négatif réussi.

La clé principale `keys/cosign.key` est ignorée par Git. La clé publique est également copiée dans `cosign.pub`. Aucune passphrase n’est écrite dans les preuves.

Preuves : `etape7-registry.log`, `etape7-push.log`, `etape7-image-inspect.log`, `etape7-keypair.log`, `etape7-sign.log`, `etape7-verify.log`, `etape7-verify.json`, `etape7-negative.log`, `etape7-negative-result.json`.
