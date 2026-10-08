# Flask / PostgreSQL hardening report

Master 2 graded practical assignment, Benoît Bremaud and Clément Machtelinckx.
This report follows sections A-G and the seven reporting sections of the assignment.
Snapshot: **2026-10-08**, main commit
`3c74e98c7b5b6504cfb4217c9b8296358bb0ffec` (merged [PR #27](https://github.com/clement-machtelinckx/linter-python-flask/pull/27)).
The compliance matrix is provisional until the release and final cross-review are complete.

## 1. Public GHCR packages and execution

**Publication is not yet verified.** [Issue #12](https://github.com/clement-machtelinckx/linter-python-flask/issues/12)
is open. No public package URL, released SemVer tag or confirmed `docker pull` command
is claimed. The inherited publisher still targets another owner's package with `latest`;
it must not be treated as this project's validated release.

The local composition builds this repository's API instead of using that inherited image:

```bash
cp .env.example .env
# Set a fresh DB_PASSWORD in .env before proceeding; do not commit .env.
docker compose config --quiet
docker compose up --build --wait --wait-timeout 90
curl -fsS http://localhost:5000/health
curl -fsS http://localhost:5000/dbtest
```

Expected JSON: `{"status":"ok"}` and `{"db_connection":"successful"}`.
The API publishes port 5000; PostgreSQL publishes no host port. Choose another API
host port with a Compose override if 5000 is already occupied.
`docker compose down` stops this local composition without deleting database data.
CI uses temporary databases and additionally removes its own volumes during teardown.

## 2. Before / after measurements

Measurements use Linux amd64 and scans performed on 2026-10-08 with Trivy 0.75.0
and Dive 0.13.1. MB means decimal megabytes; image size is Docker's `.Size`,
not registry download size. Findings count package/CVE occurrences; distinct CVE IDs
are shown separately to avoid confusing the two metrics.

| API metric | Before: retained baseline | After: validated main image |
| --- | --- | --- |
| Docker image size | 148.28 MB (148,283,873 bytes) | 73.82 MB (73,817,990 bytes) |
| Execution user | UID 0 | UID/GID 65532:65532 |
| Shell | `/bin/sh` present | Checked shell paths absent |
| Build/package tools | General-purpose Python slim runtime | Checked compiler/package-manager paths absent; no pip or pytest module |
| Trivy findings, all severities | 185 occurrences / 92 distinct CVEs | 159 occurrences / 67 distinct CVEs |
| HIGH findings | 47 occurrences | 30 occurrences, no fixed version reported |
| CRITICAL findings | 0 | 0 |
| Fixable HIGH/CRITICAL | 3 | 0 |
| Python package findings | 20 occurrences, including bundled tooling | 0 |
| Dive efficiency | 97.3558% | 99.7821% |

Baseline image ID: `sha256:4738d877b71159d1fc40432b831513afbe74643f9543884fad2f292b54028c6e`.
Its `app.py` SHA256 is `cf6f28551581cc25a3f96e432b58148bcaf248f016e8e80e463b1aa2788de733`,
identical to the source at `b9c1bf2`. Its manifest contains Flask 2.3.2, Werkzeug
2.3.3, pytest 7.4.0 and unpinned psycopg2-binary. This is a **retrospective scan
of a retained baseline**, not a reconstructed claim about every historical deployment.
The original `python:3.10-slim` tag and unpinned dependency prevent exact historical reproduction.

Final image ID: `sha256:80dc0218bfcf8ec7acddf501b336654db5d7b9250915451ae8fc2975a78cfbbd`.
It was downloaded from the validated-image artifact of
[main run 37785679351](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/37785679351),
then its archive checksum, source commit and runtime were checked locally.
The size reduction is approximately 50.22% for these two measured images.
The full final report includes 74 MEDIUM, 53 LOW and two UNKNOWN findings alongside
30 HIGH findings. A passing security threshold **does not mean zero system CVEs**.

## 3. Architecture and base-image choices

```mermaid
flowchart LR
    Client -->|HTTP :5000| API[Flask / Distroless / UID 65532]
    API -->|private database network :5432| DB[Chainguard PostgreSQL / UID 70]
    DB --> Volume[Dedicated PostgreSQL 18 volume]
```

[Dockerfile](Dockerfile) separates dependency installation from runtime:
`python:3.13.16-slim-trixie` installs the eight pinned packages in
[requirements-runtime.txt](requirements-runtime.txt) under `/opt/python`.
Only those packages and `app.py` are copied into `gcr.io/distroless/python3-debian13:nonroot`.
The full builder and runtime SHA256 references are recorded in the Dockerfile;
PostgreSQL's digest is recorded in [docker-compose.yml](docker-compose.yml).

The builder and runtime share CPython 3.13 ABI, Debian 13 and amd64.
The tested final runtime reports Python 3.13.5; it is not claimed to have the builder's
3.13.16 patch version. Binary psycopg2 wheels avoid leaving native build tools in the
runtime. Compatibility is demonstrated by imports, real PostgreSQL queries and tests.
The base image supplies `/usr/bin/python3.13` as its entrypoint, so the JSON `CMD`
contains `/app/app.py`.

Digest pinning fixes the base-image inputs. Runtime dependency versions are pinned;
quality CI additionally uses a hashed manifest. The runtime wheel installation is not
hash-locked, so byte-for-byte reproducibility is not claimed. Updating a base digest,
Python minor version or architecture requires repeating the build and integration checks.

[.dockerignore](.dockerignore) excludes environment files, credentials, Git metadata,
tests, caches, local virtual environments, reports, infrastructure, logs and archives.
Explicit `COPY` instructions keep these files out of the runtime.

The PostgreSQL image is Chainguard, pinned by digest, running as UID/GID 70:70 with
all capabilities dropped and `no-new-privileges`. It only joins an internal database
network. Both services receive credentials through required environment variables;
an empty password is rejected by Compose. `.env.example` has no real password.

The new `db-data-pg18` volume is mounted at `/var/lib/postgresql`, with PGDATA
`/var/lib/postgresql/18/data`. It preserves the old PostgreSQL 14 volume by using a
different name; **it does not migrate its data**. A production migration is outside
this practical assignment's verified execution.

## 4. Healthchecks without a shell

The API probe uses exec-list `CMD`, `/usr/bin/python3.13` and `urllib.request` from the
standard library to request `/health`, require HTTP 200 and close the response.
The HTTP timeout is two seconds; the container probe timeout is three seconds,
with a ten-second interval, three retries and a ten-second startup period.
No shell, curl or additional Python package is required inside the API.

The database probe uses exec-list `CMD` and the image's `pg_isready`, targeting
127.0.0.1 with the configured database/user. Its interval is ten seconds, timeout
five seconds, five retries and startup period thirty seconds.
`depends_on: condition: service_healthy` prevents the API from starting before the
DB probe succeeds. Probe readiness alone is insufficient: `/dbtest` and pytest also
execute a real `SELECT 1` using psycopg2.

CI startup uses `docker compose up --no-build --wait --wait-timeout 90` against
the already validated API image. Both services must become healthy. A bounded
HTTP retry loop and fatal `curl -fsS` checks follow. Pytest runs in a separate Python
container on the private DB network, preserving the minimal API runtime.
Teardown uses `if: always()` and `down --volumes --remove-orphans`.

## 5. Dependency and quality remediation

| Component | Initial manifest | Current manifest | Reason |
| --- | --- | --- | --- |
| Flask | 2.3.2 | 3.1.3 | Remove scanner-reported affected versions |
| Werkzeug | 2.3.3 | 3.1.9 | Remove scanner-reported affected versions |
| pytest | 7.4.0 | 9.1.1 | Update test tooling; excluded from API runtime |
| psycopg2-binary | Unpinned | 2.9.13 | Pin and verify the retained psycopg2 API |
| Runtime transitives | Implicit | Eight runtime packages explicitly pinned | Make dependency inputs inspectable |

The retrospective baseline scan identifies Flask CVE-2026-27205, pytest
CVE-2025-71176, and these Werkzeug CVEs: CVE-2023-46136, CVE-2024-34069,
CVE-2024-49766, CVE-2024-49767, CVE-2025-66221, CVE-2026-102598,
CVE-2026-21860 and CVE-2026-27199. Other baseline Python findings concern bundled
tooling; they are included in the baseline total and are not attributed to Flask.
The final image scan detects no Python package vulnerabilities. This is a
scanner result at the recorded date, not a guarantee against future advisories.

The initial Flake8 audit already passed with the supplied configuration. No invented
lint violation or weakened rule is reported: [.flake8](.flake8) remains unchanged.
[PR #21](https://github.com/clement-machtelinckx/linter-python-flask/pull/21)
strengthened exact JSON assertions, added useful success/failure database tests,
registered the integration marker and removed internal DB errors from HTTP responses.
There are five database-independent test cases and one real-DB integration test.

[.hadolint.yaml](.hadolint.yaml) sets failure threshold `warning`, restricts registries
to docker.io, gcr.io, cgr.dev and ghcr.io, and raises DL3002, DL3007 and DL4006 to
`error`. The current Dockerfile passes this configuration, uses JSON startup,
explicit multi-stage copies and no-cache installation.

A fresh pip-audit 2.10.1 scan of `requirements.txt` found zero known vulnerabilities
in the 20 applicable packages, with no skipped package. The command used `--no-deps`
and `--disable-pip` because the manifest already pins the declared dependency set;
this advisory lookup does not replace installation or runtime compatibility tests.

The older [dependency report](security-dependencies.md) describes evidence files and
hash-locked manifests absent from this snapshot. Those missing links are not accepted
as proof here. Current claims rely on the manifests and newly collected scanner results.

## 6. CI/CD security and pending release

[quality.yml](.github/workflows/quality.yml) runs Flake8, unit tests and configured
Hadolint on pushes and pull requests targeting main, with `contents: read` and
external actions pinned to full commit SHAs.
[image-security.yml](.github/workflows/image-security.yml) builds using BuildKit,
requires Dive efficiency at least 80%, saves a full Trivy report including unfixed
findings, and enforces `--severity HIGH,CRITICAL --ignore-unfixed --exit-code 1`.
This matches the assignment's detailed rule for **fixable** HIGH/CRITICAL findings.

After security passes, it exports the image archive, checksum, source SHA, tag and
image ID. The reusable [integration workflow](.github/workflows/multi-container.yml)
is chained with `needs: image-security`, verifies those values, loads the image,
and prevents API rebuild/pull. Its PostgreSQL digest remains pullable on a fresh runner.

Two verified gaps remain at this snapshot:

- Quality and image-security are independent workflows: lint is blocking within
  quality, but does not yet prevent the image build from starting concurrently.
  The assignment requires quality before containerization.
- Legacy workflows, including the inherited publisher and deployment workflows,
  still contain actions pinned by tags. The assignment's all-actions SHA rule
  cannot be claimed for the whole `.github/workflows` directory.

Issue #12 must provide a release conditioned on all gates for the same source commit,
using the native `GITHUB_TOKEN`, default read-only permissions, `packages: write`
only for publication, controlled SemVer tags and immutable actions. The final report
must then add the actual public package URL, exact pull command, digest and verified
release run. No release or SemVer behavior is claimed as completed here.

## 7. Execution evidence and compliance matrix

The [quality main run](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/37785678874)
and [security/integration main run](https://github.com/clement-machtelinckx/linter-python-flask/actions/runs/37785679351)
completed successfully for source commit `3c74e98c7b5b6504cfb4217c9b8296358bb0ffec`.
Named security artifact: `image-security-3c74e98c7b5b6504cfb4217c9b8296358bb0ffec`;
validated image artifact: `validated-image-3c74e98c7b5b6504cfb4217c9b8296358bb0ffec`.
Artifacts have seven-day retention; download them before expiry for the final submission.

| Actual check | Result / exit status | Evidence |
| --- | --- | --- |
| `flake8 --config=.flake8 .` | No violations / 0 | Quality job `python-quality` |
| `pytest -m "not integration"` | Five cases pass / 0 | Quality job `python-quality` |
| Hadolint with `.hadolint.yaml` | No violations / 0 | Quality job `hadolint` |
| BuildKit build/check | Successful / 0 | Security job `Build final image` |
| Dive with `.dive-ci` | 99.7821%, threshold 80% / 0 | Artifact `dive.txt` |
| Full Trivy scan | 159 occurrences; Python 0 / 0 | Artifact `trivy-full.json` |
| `pip-audit -r requirements.txt --no-deps --disable-pip --format json` | 20 applicable packages, zero known vulnerabilities, no skips / 0 | Local `dependencies-final.json`, pip-audit 2.10.1 |
| Trivy fixable HIGH/CRITICAL gate | No matching findings / 0 | Artifact `trivy-gate.txt` |
| Archive verification | `image.tar: OK`; commit/tag/ID match / 0 | Integration job `Verify and load validated image` |
| Compose startup and HTTP checks | Both healthy; `/health` and `/dbtest` succeed / 0 | Integration job log |
| `pytest -v -m integration` | One passed, five deselected / 0 | Integration job log |
| Teardown | Both containers, both networks and DB volume removed / 0 | Integration job log |
| GHCR publication / SemVer pull | NOT VERIFIED | Issue #12 |

Representative actual output:

```text
efficiency: 99.7821 %
PASS: lowestEfficiency
image.tar: OK
{"db_connection":"successful"}
1 passed, 5 deselected in 0.13s
```

Local supplementary evidence was collected under `/tmp/task013-evidence`: baseline
Trivy JSON, baseline Dive log, downloaded main artifacts, image archive and runtime
checks. Earlier positive/negative checks under `/tmp/task008-evidence` and
`/tmp/task011-evidence` cover all six tests, wrong credentials, empty test selection,
unhealthy DB blocking API startup, corrupted artifact metadata and cleanup.
These temporary paths are working evidence, not persistent repository links.

### Provisional requirement coverage

IDs follow the issue backlog's REQ-001 through REQ-019 mapping. Requirements are
counted equally; the percentage measures evidenced coverage, not a grade or a risk score.
An unresolved requirement is not counted as PASS, even when its issue is closed.

| ID | Requirement / assignment section | Status | Proof or remaining gap |
| --- | --- | --- | --- |
| REQ-001 | Supplied Flake8 configuration / A | PASS | Unchanged `.flake8`, quality main run |
| REQ-002 | Dependency remediation / E | PASS | Pinned manifest, final dependency audit and image scan |
| REQ-003 | Multi-stage build and dependency cache / C | PASS | Dockerfile, successful BuildKit job |
| REQ-004 | Distroless runtime without shell/build tooling / C | PASS | Pinned base, checked validated image runtime |
| REQ-005 | Dedicated non-root API user / C | PASS | Validated image UID 65532 |
| REQ-006 | Filtered build context / D | PASS | `.dockerignore`, explicit Dockerfile copies |
| REQ-007 | Strict Hadolint governance / B | PASS | Configuration and successful Hadolint job |
| REQ-008 | Dive efficiency at least 80% / D | PASS | 99.7821%, `dive.txt` |
| REQ-009 | Fatal fixable HIGH/CRITICAL gate / E | PASS | Zero matching findings; full unfixed report retained |
| REQ-010 | Chainguard PostgreSQL pinned by digest / F | PASS | Compose digest and healthy integration DB |
| REQ-011 | Native exec API probe / F | PASS | Python stdlib probe and healthy API |
| REQ-012 | Hardened DB isolation and configuration / F | PASS | UID 70, private network, no host DB port, required credentials |
| REQ-013 | Exec DB probe and healthy dependency / F | PASS | `pg_isready`, `service_healthy`, negative startup test |
| REQ-014 | Real endpoints and pytest integration / F | PASS | Main integration job, real `SELECT 1` |
| REQ-015 | Bounded startup and teardown / pipeline 5 | PASS | Wait timeout 90, successful unconditional cleanup |
| REQ-016 | Blocking quality before build / A, pipeline 1-4 | FAIL | Quality and image build start independently |
| REQ-017 | All external actions immutable, least permissions / G | FAIL | New workflows pinned; legacy tag references remain |
| REQ-018 | Gated SemVer GHCR distribution / G, pipeline 6 | FAIL | Inherited publisher remains; no verified release |
| REQ-019 | Complete seven-section report with public release proof / report | NOT VERIFIED | This draft covers seven sections; public release and final signatures pending |

**Provisional evidenced coverage: 15 / 19 = 78.95%** (15 PASS, three FAIL,
one NOT VERIFIED). Final validation belongs to
[issue #14](https://github.com/clement-machtelinckx/linter-python-flask/issues/14)
after #12 and #13 are finalized. Both reviewers' final sign-off is pending.

### Pair contributions

Clément's merged contributions: initial audit (#17), dependencies (#19), API image
(#20), build hygiene/Hadolint (#22), layer/security gates (#23), quality CI (#25).
Benoît's merged contributions: PostgreSQL hardening (#18), Flask quality/tests (#21),
exec healthcheck (#24), actual-image Compose integration (#26), validated artifact
integration (#27). This report is prepared by Benoît for Clément's review.
The release and final compliance sign-off remain open work.
