# Local review — linter-python-flask (branch claude/buildkit-buildx-advanced-db6540)

- Date: 2026-10-26
- Commit: a813571
- Scope: branch diff main...HEAD (8 files: Dockerfile, docker-bake.hcl, docker-compose.yml, .dockerignore, .gitignore, image-security.yml, docs/tp2-etape1-*.md)
- Checks run: containers · security · correctness · docs (no Python code changed: design/tests dimensions not applicable)
- Verdict: ship (pre-push) · Must 0 · Should 3 · Nice 3

## Pre-merge gate (head SHA a813571)
| Step | Result |
|---|---|
| 1 Tests | 5/6 pytest pass; `test_dbtest` fails locally (needs PostgreSQL, covered by the multi-container CI job); `app.py` unchanged |
| 2 Coverage | ⚠️ not measured (pytest-cov not configured in this repo) |
| 3 SonarQube | ⚠️ not run (no SonarQube project for this repo) |
| 4 Secrets | ✅ gitleaks clean on main..HEAD and docs/ · only `.env.example` tracked · diff read: no token, `secrets/` ignored |
| 5 QA pass | skipped (pre-push mode); build/runtime evidence in docs/tp2-etape1-rapport.md |
- Hadolint (CI-pinned v2.15.1 + .hadolint.yaml): ✅ exit 0 on branch and main.
- Gate: **pre-push GREEN** · merge waits on CI + reviewer (Clément).

## 🔴 Must Have
_None._

## 🟡 Should Have
- `README.md:46-50,156` `[docs][correctness]` · `docker compose up --build` / `docker build .` now fail on a fresh clone without `secrets/pip_token.txt` (required=true), README does not say so · add a setup step: `mkdir -p secrets && printf 'tok_%s\n' "$(openssl rand -hex 24)" > secrets/pip_token.txt`, plus a short Bake paragraph linking docs/tp2-etape1-rapport.md.
- `docker-bake.hcl:3-6` `[containers]` · default `tp2-registry:5000` needs a docker-container builder on network `tp2-net` with an http/insecure buildkitd.toml · document it in the header comment.
- `docs/tp2-etape1-rapport.md:44-45` `[docs]` · Compose path: `docker compose config` and `up --no-build` verified to work without the secret file (docker-auditor); wording can state that only the build path needs it.

## 🔵 Nice to Have
- `image-security.yml:41-44` `[containers]` · CI build has no `--cache-from/--cache-to` (type=gha), so the cache mount brings nothing on ephemeral runners · optional.
- `.github/dependabot.yml` (absent) and Dockerfile HEALTHCHECK `[containers]` · pre-existing, outside this diff · follow-up.
- `docker-bake.hcl:31` `[docs]` · state "run from the repo root" (secret `src` is relative).

## ⚪ Disagree / Intentional
- `Dockerfile:1` `[containers]` · floating `# syntax=docker/dockerfile:1` · required explicitly by TP2 step 1 A; the `1` channel is Docker's documented recommendation.
- `docker-bake.hcl:33` `[containers]` · two platforms / single-target Bake · TP2 deliverable.

## Per-dimension summary
- Containers: conformant, secret mount correct, no build path in CI broken.
- Security: no leak path (umask 077, $RUNNER_TEMP, no echo/set -x), gitleaks clean.
- Correctness: CI token matches the Dockerfile regex (48 hex chars); bake syntax valid.
- Docs: report consistent with code; README lacks secret setup.
