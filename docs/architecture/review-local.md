# Local review — linter-python-flask (TP 2 supply chain)

- Date: 2026-10-29
- Commit: 2cf750c (findings raised on 097de49, fixed in 10c97f0 and 2cf750c)
- Scope: branch diff `main...feat/34-tp2-buildkit-supply-chain` (7 commits: SBOM, Grype/VEX, release workflow, secret leak gate, README, review fixes)
- Checks run: design · docs · tests · containers · security · correctness
- Verdict: ship (all Must Have resolved)  ·  Must 4 (fixed) · Should 8 (7 fixed, 1 follow-up) · Nice 4 (fixed)

## Pre-merge gate (head SHA 2cf750c)
| Step | Result |
|---|---|
| 1 Tests | ✅ 5 unit (pytest, `-m "not integration"`) · ✅ compose smoke `/health` + `/dbtest` · actionlint, hadolint, trivy config, bake `--print`, leak gate replay (0 leaks, positive control exit 1 naming the rule) |
| 2 Coverage | ⚠️ not re-measured: no application code changed (CI, policy files, docs only); last measured value on main stands · docs: every new workflow step and policy file carries a WHY comment |
| 3 SonarQube | ⚠️ not run locally; SonarCloud analyses the PR on push (no Python change in this branch) |
| 4 Secrets | ✅ gitleaks clean (`origin/main..HEAD`, 7 commits) · no tracked `.env` · diff read: the only token is a random throw-away generated at run time, never persisted |
| 5 QA pass | ✅ smoke (tooling/docs diff): compose stack up, both endpoints 200, image tp2:a3 rebuilt with the secret and verified secret-free |
- Gate: **GREEN for push and PR** — the merge gate is re-run on the PR head once CI (image-security, release dry-run impossible before tag) and SonarCloud have reported.

## 🔴 Must Have
- `.github/workflows/publish_to_ghcr.yml:17` `[correctness|containers]` · workflow-level `env.IMAGE` (full reference) overrode the bare `IMAGE` variable Bake reads, so the pushed tags would have been `ghcr.io/…/ghcr.io/…` (the local test did not export `IMAGE`, hence the false green) · **fixed**: renamed to `IMAGE_REF`, Bake step sets `IMAGE: linter-python-flask`, `bake --print` re-verified with both exported.
- `security.vex.json:22` `[security|docs]` · impact statement claimed the app "never imports ssl"; Werkzeug imports `ssl` conditionally, so the claim was false even though the exemption is sound · **fixed**: justification now rests on "no `SSLContext`, hence no SNI callback is ever created" (VEX + README 9.2).
- `.github/workflows/publish_to_ghcr.yml:165` `[correctness]` · commit tag used the full 40-char sha through an expression, inconsistent with the documented `sha-<12>` convention · **fixed**: `sha-${COMMIT_SHA:0:12}` computed in shell.
- `README.md:228` `[docs]` · section 6 still described the PR #28 "publish without rebuilding" design as current while TP 2 rebuilds with Bake · **fixed**: marked superseded, validation rules noted unchanged.

## 🟡 Should Have
- `publish_to_ghcr.yml` (SBOM/attest steps) `[security|design]` · the attested SBOM was generated from the amd64 build only and attached to the index digest, and the fresh release build was signed without a Grype gate · **fixed (option A, owner decision)**: per-platform SBOM from the registry, Grype gate before signing, signature on index + both manifests, one attestation per manifest, admission verifies all of them.
- `image-security.yml:81` `[correctness]` · `docker image save | tar -xO 2>/dev/null` hid tar errors and scanned layer tars, not the resulting filesystem · **fixed**: `docker create` + `docker export`.
- `publish_to_ghcr.yml` bake step `[security]` · throw-away token written under the checkout (`secrets/pip_token.txt`) · **fixed**: `$RUNNER_TEMP/pip_token`, `--set api.secret=…`, removed by `trap … EXIT`, rationale commented.
- `.trivy-secret.yaml`, `.hadolint.yaml`, `image-security.yml` `[docs]` · policy files without WHY · **fixed**: header comments, per-rule reasons, full-report override explained.
- `README.md:485,512` `[docs]` · "≈ 90" licence identifiers and "TLS terminé en amont" stated as fact · **fixed**: exact 86; TLS claim softened to "no TLS exposed by the container".
- `image-security.yml:162` `[docs]` · stale "TASK-012" comment · **fixed**: names the integration job.
- `image-security.yml` `[containers]` · no misconfiguration scan next to Hadolint · **fixed**: `trivy config --misconfig-scanners dockerfile` (legacy `aws/` Terraform excluded on purpose: 4 HIGH/CRITICAL findings there are out of the image gate's scope).
- `.github/dependabot.yml` `[containers]` · no `docker` / `github-actions` ecosystems for the pinned actions and tool versions · **follow-up issue** (not in this PR's scope).

## 🔵 Nice to Have
- `publish_to_ghcr.yml:19` `[security]` · identity regexp accepted any `v*` tag · **fixed**: SemVer-strict regexp (workflow + README 10.2).
- `publish_to_ghcr.yml` admission `[correctness]` · subject check did not assert `predicateType` · **fixed**: `select(.predicateType == "https://cyclonedx.org/bom")`.
- `image-security.yml:85` `[tests]` · positive control only checked the exit code · **fixed**: must also name `simulated-pip-token`.
- `publish_to_ghcr.yml` `[design]` · digests passed through `$(cat …)` chains · **fixed** where cheap (step `env: DIGEST`); per-platform digests stay in files shared between steps.

## ⚪ Disagree / Intentional
- `sbom.cdx.json`, `sbom.spdx.json` at repo root `[design]` · "generated files should not be committed" · intentional: the TP asks for the SBOM in the deliverable; CI artifacts carry the per-commit versions (README 9).
- `security.vex.json` covers `arch=arm64` PURLs although CI only scans the amd64 build `[security]` · intentional: the release gate now scans both platforms, so both PURLs must be exempted.
- keyless signing instead of a stored key pair `[security]` · intentional (owner decision, MCDA): no repo admin for secrets, Fulcio/Rekor gives a stronger provenance than a long-lived key.

## Per-dimension summary
- Design: proportional — two workflows, one policy file per tool, no abstraction added; the per-platform loop is the only repetition and it is explicit.
- Docs: README sections 8–10 (French, grader override) plus WHY comments on every policy; 10.1 digest rows wait for release v1.1.0.
- Tests: no app code touched; the gates themselves are tested by positive controls (secret rule) and local replays (bake print, leak gate, cosign with a throw-away key).
- Containers: BuildKit secret/cache mounts, Bake multi-arch, Hadolint policy, Trivy secret + config, Dive — Dependabot ecosystems are the remaining gap (follow-up).
- Security: Must 1 was a real release-breaking bug caught before any push; VEX justification now accurate; signatures and attestations bound to immutable digests only.
- Correctness: actionlint clean on both workflows; every shell step `set -e` by default (`bash` shell), pipes guarded.
