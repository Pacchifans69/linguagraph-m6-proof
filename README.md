# LinguaGraph M6 external proof preparation

This independent repository contains proof infrastructure only. It is scoped to
M6-EXI-01 and the exact LinguaGraph candidate SHA/tree in `.circleci/config.yml`.
It does not alter the LinguaGraph repository.

## Candidate binding (current)

This proof preparation is repinned to the final M6 product candidate that has
passed Human Static Diff Review and Human Runtime Acceptance:

```text
product repository: Pacchifans69/LinguaGraph
branch:             m6-mode-oriented-workbench-information-architecture
SHA:                2054c844ea3488b43459903f64f063b1d541f8a2
tree:               efd303a2aaf4f32dec14346ac4c644a8717a0ffa
unique parent:      f2a9ef458b234d826e22d55a6a4740b3b0e7a0ec
frozen main:        cb61725fe9f05c704a6f80b67c6343f49ade9234
Alembic head:       0006
```

Historical provenance only — the previous binding was candidate
`40f7fc98bed0a0261ef67451077b04dbbd1281b3`, tree
`32e2a5cd0d7e84c6eaf4e9400568026ae2fdbe3e`, parent
`c9ce3732e546900a068b1e8b4cbb0764e311ed4b`. It is **not** an active binding
anywhere in this repository.

## Authorization state

**HOLD — no proof run authorized.** `run_proof` defaults to `false`, and the
workflow selects only proof `main` when the parameter is explicitly `true`.

`M6-EXI-01-RUN-U` is **spent / MUST NOT be reused**. This repin authorizes no
proof execution. Any future execution requires BOTH:

1. a new, Human-reviewed proof SHA, and
2. a fresh, distinct, one-shot Human run authorization.

Before a separately approved execution, CircleCI's project configuration must
provide `APPROVED_PROOF_SHA` set to the exact Human-reviewed proof commit and
`M6_PROOF_RUN_AUTHORIZATION` set to a distinct Human approval identifier in
the form `M6-EXI-01-RUN-<identifier>`.
Those values are deliberately absent here; without them the job fails closed.
Do not embed API tokens or passwords in the project repository.

## Current CircleCI state (factual)

The CircleCI project for this repository exists and has already produced a
first hosted proof attempt, which the scheduler rejected **before any
repository-defined step ran**:

```text
pipeline:            #2
proof SHA:           d668429b6411170fdd1becbc838cf8e31d51f390
rejection:           invalid-resource-class
message:             Job was rejected because resource class large.gen2,
                     image ubuntu-2404:2026.05.1 is not a valid resource class
```

Careful reading of that fact:

- it was a **pre-step scheduler/executor rejection**;
- **no** checkout, **no** proof script and **no** repository-defined job step
  executed;
- it is **not** evidence of a product or test failure;
- the root cause remains **undetermined**;
- it does **not** establish a CircleCI bug, a Free-plan entitlement limit, or
  any specific backend defect, and must not be described as any of those.

For project setup, leave all VCS push, PR, schedule, and custom webhook
triggers disabled at the CircleCI project level. A skipped workflow is not a
substitute for verifying project-level triggers are disabled. Human must review
the exact proof commit/tree first.

## R0 intent

This repin prepares a **same-executor / same-image / same-resource `R0`
recovery attempt**. The scheduler-facing pair is deliberately left unchanged so
that a controlled exact retry keeps its diagnostic value:

```text
machine image:   ubuntu-2404:2026.05.1
resource class:  large.gen2
```

This repository change does not trigger, request or authorize that run.

## What the proof verifies

The script checks exact app remote refs, detached checkout SHA/tree/unique
parent/ancestor, and reviewed proof SHA before installing any runtime. It
records Python 3.13, Node 24, PostgreSQL 18 and the container digest; runs
frozen backend dependencies, empty database to Alembic 0006/current/check,
the complete 587 backend tests with zero skips, frozen frontend
dependencies, lint, typecheck, all 502 Vitest tests and build, Chromium
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

Before a separate run authorization, independently confirm the **actual**
project configuration instead of treating a documentation-level default as
fact: the Free-plan credit balance, `large.gen2` entitlement, exact pinned
image availability, and effective artifact retention for this existing
CircleCI project. Capture the observed values in the Human review record. The
project exists and pipeline #2 is on record, but its effective settings,
entitlements and retention still must be observed and recorded before any run
authorization.
