# LinguaGraph M6 external proof preparation

This independent repository contains proof infrastructure only. It is scoped to
M6-EXI-01 / M6-EXI-02 and the exact LinguaGraph candidate SHA/tree in
`.circleci/config.yml`. It does not alter the LinguaGraph repository.

## Candidate binding (current)

This proof preparation is bound to the final M6 product candidate that has
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

Historical provenance only — an earlier binding was candidate
`40f7fc98bed0a0261ef67451077b04dbbd1281b3`, tree
`32e2a5cd0d7e84c6eaf4e9400568026ae2fdbe3e`, parent
`c9ce3732e546900a068b1e8b4cbb0764e311ed4b`. It is **not** an active binding
anywhere in this repository.

## Authorization state

**HOLD — R2 execution is NOT authorized.** `run_proof` defaults to `false`, and
the workflow selects only proof `main` when the parameter is explicitly `true`.

All three run identifiers are consumed and must never be reused:

```text
M6-EXI-01-RUN-U:            SPENT / MUST NOT REUSE
M6-EXI-01-RUN-R0-4FB193A:   SPENT / MUST NOT REUSE
M6-EXI-01-RUN-R1-848E19C:   SPENT / MUST NOT REUSE
```

After the M6-EXI-02 guard retirement the project-level guard variables are
absent again:

```text
APPROVED_PROOF_SHA:          ABSENT
M6_PROOF_RUN_AUTHORIZATION:  ABSENT
```

Any future R2 execution requires BOTH:

1. a new, Human-reviewed proof SHA, and
2. a new, distinct, one-shot Human run authorization.

Before a separately approved execution, CircleCI's project configuration must
provide `APPROVED_PROOF_SHA` set to the exact Human-reviewed proof commit and
`M6_PROOF_RUN_AUTHORIZATION` set to a distinct Human approval identifier in
the form `M6-EXI-01-RUN-<identifier>`. Those values are deliberately absent
here; without them the job fails closed. Do not embed API tokens or passwords
in the project repository.

## Hosted attempt history (factual)

Three hosted attempts have been made against this proof setup. Every one of them
was rejected by the scheduler **before any repository-defined step ran**.

Pipeline #2 — proof SHA `d668429b6411170fdd1becbc838cf8e31d51f390`:

```text
rejection:  invalid-resource-class
message:    Job was rejected because resource class large.gen2,
            image ubuntu-2404:2026.05.1 is not a valid resource class
```

R0 / pipeline #3 — proof SHA `4fb193af2dbe165a5a6c3efaddbd368d3ca20291`:

```text
pipeline #:     3
pipeline UUID:  3bad39a1-272c-4f96-afeb-54a32549a544
workflow UUID:  a9b0cddf-9de9-4399-8e8f-ccee7468aa62
job #:          2
job UUID:       c39ab4c7-cb02-4a1c-9888-3bb790415368
rejection:      invalid-resource-class
message:        Job was rejected because resource class large.gen2,
                image ubuntu-2404:2026.05.1 is not a valid resource class
```

R0 terminal facts:

- the executor did not start (`start_time = null`);
- the repository-defined checkout did not run;
- `scripts/run-m6-proof.sh` did not run;
- no proof artifacts existed (the job artifact endpoint returned 404);
- **semantic hosted proof was not obtained**.

R1 / pipeline #4 — proof SHA `848e19cc83eae4e7a347b4a8abf8a5dff502b679`;
executor tuple `ubuntu-2404:2025.09.1` + `large.gen2`:

```text
pipeline #:     4
pipeline UUID:  52d593c8-6b8d-496c-a43f-a0a8b2368c2c
workflow UUID:  541fa976-85e9-48c8-b188-a280cc89ceb8
job #:          3
job UUID:       c1e984ea-d1df-411d-9738-4e8980a892af
rejection:      invalid-resource-class
message:        Job was rejected because resource class large.gen2,
                image ubuntu-2404:2025.09.1 is not a valid resource class
```

R1 terminal facts: the executor did not start (`start_time = null`); the
repository-defined checkout did not run; `scripts/run-m6-proof.sh` did not run;
no proof artifacts existed (the job artifact endpoint returned 404);
**semantic hosted proof was absent**.

## Interpretation discipline

R0 and R1 reproduced the same pre-step `invalid-resource-class` class of failure
while changing only the Ubuntu 24.04 image tag. This materially weakens the
hypothesis that the blocker is unique to `ubuntu-2404:2026.05.1`.

The root cause remains **UNDETERMINED**. Nothing here is proven to be a CircleCI
bug, an account defect, a Free-plan defect, a `large.gen2` entitlement defect, a
scheduler routing bug, an image-registry defect, or a backend defect. Those
remain hypotheses only.

For project setup, leave all VCS push, PR, schedule, and custom webhook
triggers disabled at the CircleCI project level. A skipped workflow is not a
substitute for verifying project-level triggers are disabled. Human must review
the exact proof commit/tree first.

## M6-EXI-02 — Human-approved M6-specific External Infrastructure Exception

`M6-EXI-02` is a **new M6-specific External Infrastructure Exception**. Its sole
purpose is to attempt a **controlled CircleCI Gen3 hosted-proof path** in
response to the pre-step `invalid-resource-class` blocker already reproduced by
R0 and R1, staying inside the same CircleCI provider.

The exception **does NOT waive** any Gate 2 requirement, including:

```text
exact candidate / tree / base provenance
clean hosted Linux execution
Python 3.13
Node 24
PostgreSQL 18
frozen dependency installation
Alembic integrity
587 backend tests / zero skips
lint
typecheck
502 Vitest
production build
26 Playwright paths / zero skipped / flaky / failed
cleanup
dependency hash equality
tracked-tree integrity
artifact integrity and independent artifact review
```

## R2 hypothesis and single-variable change

R2 preparation is a **single-variable resource-generation experiment**:

```text
R1 (observed):   image = ubuntu-2404:2025.09.1   resource = large.gen2
R2 (prepared):   image = ubuntu-2404:2025.09.1   resource = large.gen3
```

The only intended execution-semantic variable is the resource generation,
Gen2 -> Gen3. The CPU/RAM envelope is intended to remain the same:

```text
4 vCPU
16 GiB
```

Public CircleCI documentation currently classifies `large.gen3` as a Cloud
resource class with 4 vCPU / 16 GiB and marks Gen3 as **Open Beta**.

> Public CircleCI documentation lists `large.gen3` as a Cloud Gen3 resource
> class. This documentation-level availability does not prove that this
> specific project can provision it; R2 has not run.

Everything else is deliberately held constant: the machine image
(`ubuntu-2404:2025.09.1`), all product pins, all runtime pins, the test surface,
the workflow semantics, and `scripts/run-m6-proof.sh` (byte-identical to R1).

This proof does not enable `docker_layer_caching`, so no configuration or script
change is made in response to any Gen3 DLC known issue.

This repository change does not trigger, request or authorize any run.
Availability is not verified by running a pipeline here; that belongs to a
separately authorized R2 execution.

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
fact: the credit balance, `large.gen3` provisioning entitlement for this
project, exact availability of the pinned image (`ubuntu-2404:2025.09.1`), and
effective artifact retention. Capture the observed values in the Human review
record. The project exists and pipelines #2, #3 and #4 are on record, but its
effective settings, entitlements, image availability and retention still must
be observed and recorded before any run authorization.
