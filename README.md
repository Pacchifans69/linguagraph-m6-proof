# LinguaGraph M6 external proof preparation

This independent repository contains proof infrastructure only. It is scoped to
the M6 external-infrastructure checkpoints and the exact LinguaGraph candidate
SHA/tree frozen below. It does not alter the LinguaGraph repository.

Two provider paths exist and must not be conflated:

```text
M6-EXI-01 / M6-EXI-02   CircleCI hosted path (historical / pre-step)
M6-EXI-03               Alibaba ECS alternate hosted path
```

## Candidate binding (current)

This proof repository binds the selected M6 product candidate for hosted
verification:

```text
product repository: Pacchifans69/LinguaGraph
branch:             m6-mode-oriented-workbench-information-architecture
SHA:                2054c844ea3488b43459903f64f063b1d541f8a2
tree:               efd303a2aaf4f32dec14346ac4c644a8717a0ffa
unique parent:      f2a9ef458b234d826e22d55a6a4740b3b0e7a0ec
frozen main:        cb61725fe9f05c704a6f80b67c6343f49ade9234
Alembic head:       0006
```

These pins are identical in the CircleCI adapter, the Alibaba ECS adapter and
the provider-neutral semantic core. They are not weakened by this repair.

Historical provenance only — an earlier binding was candidate
`40f7fc98bed0a0261ef67451077b04dbbd1281b3`, tree
`32e2a5cd0d7e84c6eaf4e9400568026ae2fdbe3e`, parent
`c9ce3732e546900a068b1e8b4cbb0764e311ed4b`. It is **not** an active binding
anywhere in this repository.

## Harness architecture

```text
scripts/run-m6-proof-core.sh              provider-neutral semantic core
scripts/run-m6-proof.sh                   CircleCI thin adapter (EXI-01 / EXI-02)
scripts/run-m6-proof-alibaba-ecs.sh       Alibaba ECS thin adapter (EXI-03)
.circleci/config.yml                      historical CircleCI configuration
```

The semantic core owns every Gate 2 requirement: candidate remote refs, exact
detached candidate checkout, tree, unique parent, frozen-main ancestry, candidate
configuration exclusion, runtime pins, migration integrity, the full backend and
frontend suites, Playwright, dependency integrity, cleanup, `outcome.txt` and
`artifact-manifest.sha256`. It performs **no** provider identity check.

The CircleCI adapter retains the historical EXI-01 authorization namespace
`^M6-EXI-01-RUN-[A-Za-z0-9_-]+$`. It is deliberately **not** converted to the
EXI-03 namespace. The Alibaba ECS adapter requires a distinct one-shot EXI-03
authorization.

The historical `.circleci/config.yml` remains byte-identical and is not modified
by this repair.

## Authorization state

M6-EXI-03 hosted execution has now **actually been invoked exactly once**, under
a separate Human one-shot authorization, and that invocation **FAILED** in the
proof harness itself. The former "EXI-03 hosted execution is NOT authorized"
wording described the state before Run #1 and is superseded by the historical
record below; it is **not** a statement that EXI-03 was never executed.

```text
M6-EXI-03 Run #1 (historical):  EXECUTED / FAIL
Run #1 failure evidence:        RETAINED LOCALLY / INDEPENDENTLY VERIFIED
Run #1 authorization token:     SPENT / MUST NOT REUSE

current future execution
authorization:                  NONE

semantic hosted proof:          ABSENT
G2-X01:                         OPEN / EXTERNAL
Gate 2:                         NOT PASS
PR / merge:                     NOT AUTHORIZED
```

A new EXI-03 rerun requires **all three** of:

```text
a new Human-reviewed proof SHA
AND
a fresh distinct one-shot EXI-03 authorization
AND
a restored clean-host baseline
```

Writing or repairing the EXI-03 adapter does not run it, does not reserve an
execution slot, and does not produce proof. No semantic hosted proof exists
until a separately authorized run completes **and** its failure-or-success
artifacts are independently verified.

## M6-EXI-03 Run #1 — executed / FAIL (historical record)

Deterministic, durable record of the single EXI-03 hosted invocation performed
so far. It is recorded here as **fact**, not as semantic proof.

### Run identity

```text
M6-EXI-03 Run #1:        EXECUTED / FAIL

approved proof SHA:      6c51170a393c4c06b2dbaf54fd28e68539534d58
approved proof tree:     fe28d04817fc20f31d1f7124188451f99efb91d3

Product candidate:       2054c844ea3488b43459903f64f063b1d541f8a2
Product candidate tree:  efd303a2aaf4f32dec14346ac4c644a8717a0ffa
frozen main:             cb61725fe9f05c704a6f80b67c6343f49ade9234
```

### Stage facts

```text
guard_core        PASS
guard_remote      PASS
fetch_candidate   PASS
deps_pre          PASS
install_runtimes  FAIL
```

The failure occurred at the pinned-uv-version check inside
`install_runtimes`:

```text
expected:  uv 0.12.10
observed:  uv 0.12.10 (x86_64-unknown-linux-gnu)
```

### Failure classification

```text
failure class:  PROOF-HARNESS CORRECTNESS DEFECT

not:            Product semantic failure
not:            ECS/provider identity failure
```

The host reported the correct uv semantic version `0.12.10`; the harness guard
wrongly required byte equality with the full human-display string. The guard was
the defect, not the Product and not the provider.

### Not reached

```text
backend pytest:            NOT REACHED
frontend / Vitest:         NOT REACHED
Playwright:                NOT REACHED

semantic hosted proof:     ABSENT
G2-X01:                    OPEN / EXTERNAL
Gate 2:                    NOT PASS
PR / merge:                NOT AUTHORIZED
```

### Runtime / bootstrap observations from Run #1

Recorded as **bootstrap observations only**. None of the following is a
semantic proof PASS:

```text
Docker bootstrap completed before failure
uv 0.12.10 installed
Python 3.13.15 installed
Node 24.17.0 installed
PostgreSQL 18 image pulled / proof-owned container created
cleanup=0
```

### Authorization provenance

```text
M6-EXI-03-RUN-6c51170a-6EF25A7993542351
```

```text
status: SPENT / MUST NOT REUSE
```

This identifier is recorded because it is a Human-visible **historical
authorization identifier**, not a secret, and it is not a credential. It is
spent, it must never be reused as a credential or token, and it must never be
presented again as an authorization for any future run. It is deliberately not
written into any machine evidence artifact; the adapter records only the
authorization token's SHA-256, never the raw token.

### Retained failure evidence

```text
Run #1 failure artifacts:  RETAINED LOCALLY / INDEPENDENTLY VERIFIED
```

Deterministic Run #1 archive:

```text
m6-proof-artifacts-6c51170a393c4c06b2dbaf54fd28e68539534d58.tar.gz
```

```text
archive SHA-256:                      4640be6a092bc67a72099d0dcaf8af7b404b314fd220352966bf07b6fb90ab21
internal artifact-manifest.sha256:    2abc3d208b4258b3a5f60b54337e35d1e481c4835be89747e7c33f47c7209d36
```

The Human independently downloaded and reconstructed the exact archive and
verified:

```text
archive SHA-256:            MATCH
artifact-manifest SHA-256:  MATCH
every manifest entry:       MATCH
final:                      ALL ARTIFACTS VERIFIED
```

This independent verification establishes **failure-evidence integrity only**.
It does **not** establish, and must not be read as, any semantic proof result,
any Product verdict, or any Gate 2 outcome.

## M6-EXI-01 / M6-EXI-02 — CircleCI historical / pre-step path

Every hosted attempt on this path so far was rejected by the scheduler **before
any repository-defined step ran**. No semantic proof was obtained on this path.

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

R0, R1 and pipeline #2 terminal facts: the executor did not start
(`start_time = null`); the repository-defined checkout did not run;
`scripts/run-m6-proof.sh` did not run; no proof artifacts existed (the job
artifact endpoint returned 404).

R2 preparation was a single-variable resource-generation experiment
(`large.gen2` -> `large.gen3`). It has not produced semantic proof.

The historical EXI-01 run identifiers below are consumed and must never be
reused:

```text
M6-EXI-01-RUN-U:            SPENT / MUST NOT REUSE
M6-EXI-01-RUN-R0-4FB193A:   SPENT / MUST NOT REUSE
M6-EXI-01-RUN-R1-848E19C:   SPENT / MUST NOT REUSE
```

The EXI-01/EXI-02 manifest excludes only
`.circleci/config.yml` semantics changes: CircleCI provenance, workflow
identity and job identity are still validated by the CircleCI adapter.

### CircleCI interpretation discipline

R0 and R1 reproduced the same pre-step `invalid-resource-class` class of failure
while changing only the Ubuntu 24.04 image tag. This materially weakens the
hypothesis that the blocker is unique to `ubuntu-2404:2026.05.1`.

The root cause remains **UNDETERMINED**. Nothing here is proven to be a CircleCI
bug, an account defect, a Free-plan defect, a `large.gen2` entitlement defect, a
scheduler routing bug, an image-registry defect, or a backend defect. Those
remain hypotheses only.

For project setup, leave all VCS push, PR, schedule, and custom webhook triggers
disabled at the CircleCI project level. A skipped workflow is not a substitute
for verifying project-level triggers are disabled.

## M6-EXI-03 — Alibaba ECS alternate hosted path

The EXI-03 adapter is the alternate hosted-proof path on a measured Alibaba
Cloud ECS instance. It binds the same frozen Product candidate and the same
semantic core as the CircleCI path. It exists because the CircleCI path has
never reached a repository-defined step.

The EXI-03 adapter does **not** waive any Gate 2 requirement, including:

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

### Measured EXI-03 infrastructure provenance

Observed before this repair, and recorded here as measurement (not as pinned
execution identity):

```text
instance:     i-j6c13vpnkuq6xbbhyxzw
region:       cn-hongkong
zone:         cn-hongkong-d
type:         ecs.g9i.xlarge
image:        ubuntu_24_04_x64_20G_alibase_20260828.vhd

OS observed:  Ubuntu 24.04.4 LTS
architecture: x86_64
CPU:          4
memory:       15952376 kB observed MemTotal

system disk:  d-j6c13vpnkuq6xbbjtrb7
              60 GiB
              cloud_essd
              PL0
              DeleteWithInstance=true

snapshots:    0
RAM role:     none

effective IMDS:
              tokenless HTTP 403
              token mode available

security group:
              sg-j6c13vpnkuq6xbbg9p2z
```

Clean-ECS baseline measurement:

```text
Docker ABSENT
Node ABSENT
npm ABSENT
uv ABSENT
psql ABSENT
system Python 3.12.3
sudo -n available
```

### Ingress (factual)

```text
TCP/22 <- 106.47.210.98/32
TCP/22 <- 100.104.0.0/16
no other observed ingress rules
```

The public IP is a runtime-assigned observation, **not** immutable execution
identity. The ECS adapter records public IP, kernel patch version, boot
timestamp and runtime-assigned network observations, but does not hard-fail
solely because they change.

### EXI-03 provenance guard

The adapter uses Alibaba ECS IMDS at `http://100.100.100.200/latest` and
requires all of the following exactly:

```text
tokenless instance-id request HTTP status = 403
token-mode request = successful

instance-id:    i-j6c13vpnkuq6xbbhyxzw
region-id:      cn-hongkong
zone-id:        cn-hongkong-d
instance-type:  ecs.g9i.xlarge
image-id:       ubuntu_24_04_x64_20G_alibase_20260828.vhd
```

It also captures instance-id, instance-name, hostname, region, zone, instance
type, image ID, serial number, VPC, vSwitch, private IPv4, effective public /
EIPv4 when available, primary MAC, primary ENI, OS release, `uname`,
architecture, CPU count, MemTotal, boot time, the instance identity document,
the instance identity PKCS#7 response, and the SHA-256 of both identity objects
into `proof-artifacts/`.

No repository-pinned Alibaba certificate is required by this repair.

### EXI-03 CircleCI anti-spoof guard

The adapter fails if **any** of the following is nonempty:

```text
CIRCLE_PROJECT_USERNAME
CIRCLE_PROJECT_REPONAME
CIRCLE_BRANCH
CIRCLE_SHA1
CIRCLE_WORKFLOW_ID
CIRCLE_BUILD_NUM
```

Alibaba execution must never be obtained by spoofing CircleCI identity.

### EXI-03 host bootstrap (defined, not executed)

The adapter defines the future formal-run bootstrap. When Docker is absent it:

1. runs `sudo -n env DEBIAN_FRONTEND=noninteractive apt-get update`;
2. installs only the minimum host prerequisite required to make Docker usable
   (`docker.io`, `--no-install-recommends`);
3. starts Docker without enabling unnecessary persistent services;
4. records the installed package version and `docker --version`.

It does **not** add the ECS user to the `docker` group, does **not** `chmod` the
Docker socket, and does **not** require logout/relogin. The core works through
either directly usable `docker` or passwordless `sudo -n docker`. The pinned
uv/Python/Node runtimes and PostgreSQL 18 are installed by the core, not by the
host bootstrap.

## Future EXI-03 run requirements

A future EXI-03 run requires **all three** of:

1. `APPROVED_PROOF_SHA` set to the exact full 40-character proof commit that a
   Human has reviewed; and
2. a new, distinct, one-shot Human run authorization of the form

   ```text
   M6-EXI-03-RUN-<approved-proof-sha-prefix>-<nonce>
   ```

3. a restored clean-host baseline (see below).

The authorization prefix must match the leading characters of
`APPROVED_PROOF_SHA`. Do not embed an actual Human authorization token, API
token, or password in this repository. The Run #1 authorization
`M6-EXI-03-RUN-6c51170a-6EF25A7993542351` is spent and cannot satisfy this
requirement.

The Run #1 proof SHA `6c51170a393c4c06b2dbaf54fd28e68539534d58` (tree
`fe28d04817fc20f31d1f7124188451f99efb91d3`) is the SHA that Run #1 executed and
that this bounded correction repairs. It is **not** automatically approved for a
rerun: any future EXI-03 execution requires a new Human-reviewed proof SHA, and
this correction does not constitute that review. The adapter deliberately does
not hardcode the not-yet-known future proof SHA.

### Clean-host baseline requirement

Run #1 modified the ECS system disk through the approved bootstrap: Docker
bootstrap, installed uv / Python / Node runtimes, and a pulled PostgreSQL 18
image with a proof-owned container. That disk state is **not** the original
clean-host baseline measured earlier in this README.

```text
A future formal rerun must not treat the post-Run-#1 disk state as the original
clean-host baseline.

Restoration / reinitialization of a clean baseline is a separate
Human/provider operation and is NOT authorized by this correction.
```

This repository makes **no** claim that any provider action has occurred. In
particular, this correction does **not** assert that the system disk has been
reinitialized, that the instance has been stopped, that an image has been
reinstalled, or that any other provider-side state change has taken place. No
such operation is performed or verified here; the clean-host baseline remains
**NOT RESTORED / unverified**.

### Run token spent semantics

```text
PASS                                    => SPENT
test FAIL                               => SPENT
bootstrap FAIL                          => SPENT
provider/runtime FAIL after invocation  => SPENT
cleanup FAIL                            => SPENT
```

Once a syntactically valid authorized invocation begins, the adapter marks the
authorization token spent in a host-persistent, untracked marker directory
outside the git worktree:

```text
$HOME/.local/state/linguagraph-m6-proof/spent/
```

The marker is created **before** provider, bootstrap and semantic execution. A
reused token fails closed. A rerun requires a fresh Human authorization. This
mechanism is defense-in-depth; the Human procedural semantics above remain
binding regardless of the marker.

The raw authorization token is never written to evidence. Only its SHA-256 is
recorded.

## Artifact handling and retrieval

The Alibaba ECS adapter preserves artifacts on both PASS and FAIL:

1. it writes `proof-artifacts/outcome.txt` and a full
   `proof-artifacts/artifact-manifest.sha256`;
2. it builds a deterministic archive of `proof-artifacts/`;
3. it stores the archive's SHA-256 outside the archive, under
   `$HOME/.local/state/linguagraph-m6-proof/artifacts/`;
4. it exits with the proof's failure status preserved.

It does **not** upload artifacts to another provider automatically. Human
retrieval happens separately via SCP after a future authorized run.

An independent reviewer must download every artifact and run
`sha256sum -c artifact-manifest.sha256` in the downloaded artifact directory.
The manifest excludes itself; record its own SHA-256 outside the archive. A
proof exit 0 without accessible, independently verified artifacts is
insufficient evidence for Human Gate 2 review.

The instance should **not** be released until artifacts have been retrieved and
independently verified.

## What the proof verifies

The core checks exact app remote refs, detached checkout SHA/tree/unique
parent/ancestor, and the approved proof SHA before installing any runtime. It
records Python 3.13, Node 24, PostgreSQL 18 and the container digest; runs
frozen backend dependencies, empty database to Alembic `0006`/current/check, the
complete 587 backend tests with zero skips, frozen frontend dependencies, lint,
typecheck, all 502 Vitest tests and build, Chromium installation and all seven
real-API/disposable-DB Playwright specs with 26 passed and no retry. Finally it
checks four dependency hashes against pre-run and committed blobs, the exact
tracked tree, zero residual disposable databases, and unchanged remote refs.
Any stage failure leaves the job failed and attempts container cleanup. Cleanup
failure fails the run closed.

Seven exact Playwright specs:

```text
e2e/golden-path.spec.ts
e2e/unicode.spec.ts
e2e/segmentation.spec.ts
e2e/token-segmentation.spec.ts
e2e/lemma-annotation.spec.ts
e2e/pos-annotation.spec.ts
e2e/workbench-information-architecture.spec.ts
```

## Human review boundary

The proof repository binds the selected candidate for hosted verification.
Human review/acceptance provenance is external to this repository and is not
established merely by this README.

This README does not record, prove, or imply any Human HSDR/HRA verdict. A
future proof SHA created by this repair still requires separate Human review,
and Gate 2 remains NOT PASS until a separately authorized hosted run produces
retained, independently verified evidence and a Human accepts it.
