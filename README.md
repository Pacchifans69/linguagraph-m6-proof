# LinguaGraph M6 external proof preparation

This independent repository contains proof infrastructure only. It is scoped to
M6-EXI-01 and the exact LinguaGraph candidate SHA/tree in `.circleci/config.yml`.
It does not alter the LinguaGraph repository.

**HOLD — no proof run authorized.** `run_proof` defaults to `false`, and the
workflow selects only proof `main` when the parameter is explicitly `true`.
For project setup, leave all VCS push, PR, schedule, and custom webhook
triggers disabled at the CircleCI project level. A skipped workflow is not a
substitute for verifying project-level triggers are disabled. Do not connect
a new CircleCI project if its creation automatically enables a trigger or
executes a pipeline. Human must review the exact proof commit/tree first.

Before a separately approved execution, CircleCI's project configuration must
provide `APPROVED_PROOF_SHA` set to the exact Human-reviewed proof commit and
`M6_PROOF_RUN_AUTHORIZATION` set to a distinct Human approval identifier in
the form `M6-EXI-01-RUN-<identifier>`.
Those values are deliberately absent here; without them the job fails closed.
Do not embed API tokens or passwords in the project repository.

The requested hosted executor is the fixed `ubuntu-2404:2026.05.1` CircleCI
machine image and `large.gen2` resource class. Verify that the organization's
plan provisions this combination and that artifact retention is 30 days before
authorizing the one exact proof run; otherwise stop for Human review. Capture
the project's actual CircleCI slug, workflow ID, job number, artifact list, and
the independent download/re-hash report. If long-term retention is required,
Human must separately designate and authorize a controlled archive.

The script checks exact app remote refs, detached checkout SHA/tree/unique
parent/ancestor, and reviewed proof SHA before installing any runtime. It
records Python 3.13, Node 24, PostgreSQL 18 and the container digest; runs
frozen backend dependencies, empty database to Alembic 0006/current/check,
the complete 587-test PostgreSQL suite with zero skips, frozen frontend
dependencies, lint, typecheck, all 495 Vitest tests and build, Chromium
installation and all seven real-API/disposable-DB Playwright specs with
26 passed and no retry. Finally, it checks four dependency hashes against
pre-run and committed blobs, exact tracked tree, zero residual disposable
databases, and unchanged remote refs. Any stage failure leaves the job failed
and attempts container cleanup.

All evidence, including failed stage logs, belongs to `proof-artifacts/` in the
CircleCI job. An independent reviewer must download every file and run
`sha256sum -c artifact-manifest.sha256` in the downloaded artifact directory.
The manifest excludes itself; record its own SHA-256 outside CircleCI. A proof
job exit 0 without accessible, independently verified artifacts is insufficient
evidence for Human Gate 2 review. M5 proof and local M6 tests never substitute
for this exact candidate's hosted execution.

Before a separate run authorization, verify the Free-plan credit balance,
`large.gen2` entitlement, exact pinned image availability, and effective
artifact retention in this new project. Capture the observed values in the
Human review record. A documentation-level default does not establish the
effective setting of a project that does not yet exist.
