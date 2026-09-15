#!/usr/bin/env bash
# M6-EXI-01 / M6-EXI-02 CircleCI thin adapter.
#
# Historical / pre-step CircleCI hosted-proof path. This adapter validates the
# CircleCI provider identity, the CircleCI commit, and the distinct Human run
# authorization in the EXI-01 namespace. It records provider/workflow/job
# provenance and then invokes the provider-neutral semantic core:
#
#   scripts/run-m6-proof-core.sh
#
# The core owns every semantic Gate 2 requirement (candidate pins, runtimes,
# migrations, backend/frontend tests, Playwright, integrity, cleanup, outcome
# and artifact manifest). This adapter performs no semantic weakening.
#
# This EXI-01 authorization namespace is deliberately retained. This file does
# NOT convert CircleCI execution to the M6-EXI-03 namespace.
#
# The historical .circleci/config.yml must remain byte-identical; this adapter
# is invoked by that unmodified configuration as `bash scripts/run-m6-proof.sh`.
#
# Never run this without a separate Human approval of the exact proof commit.
set -Eeuo pipefail

readonly PROOF_ROOT="$(git rev-parse --show-toplevel)"
readonly CORE="$PROOF_ROOT/scripts/run-m6-proof-core.sh"
readonly EVIDENCE="${M6_PROOF_EVIDENCE_DIR:-$PROOF_ROOT/proof-artifacts}"
export M6_PROOF_EVIDENCE_DIR="$EVIDENCE"

# Frozen Product binding, mirrored here only to validate the configured values.
readonly APP_SHA='2054c844ea3488b43459903f64f063b1d541f8a2'
readonly APP_TREE='efd303a2aaf4f32dec14346ac4c644a8717a0ffa'
readonly APP_PARENT='f2a9ef458b234d826e22d55a6a4740b3b0e7a0ec'
readonly MAIN_SHA='cb61725fe9f05c704a6f80b67c6343f49ade9234'
readonly RUN_AUTH_NAMESPACE='^M6-EXI-01-RUN-[A-Za-z0-9_-]+$'

mkdir -p "$EVIDENCE"

die() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
expect() { [[ "$1" == "$2" ]] || die "Mismatch: $3 (expected $2; got $1)"; }
record() { printf '%s=%s\n' "$1" "$2" >> "$EVIDENCE/provenance.txt"; }

# If the adapter fails before the core produces an outcome, still leave a
# fail-closed outcome and a self-consistent artifact manifest.
finalize() {
  local exit_code=$?
  trap - EXIT
  if [[ ! -e "$EVIDENCE/outcome.txt" ]]; then
    printf 'FAIL adapter_exit=%s\n' "$exit_code" > "$EVIDENCE/outcome.txt"
  fi
  if [[ ! -e "$EVIDENCE/artifact-manifest.sha256" ]]; then
    ( cd "$EVIDENCE" && find . -type f ! -name artifact-manifest.sha256 -print0 | sort -z | xargs -0 -r sha256sum > artifact-manifest.sha256 ) || exit_code=1
  fi
  exit "$exit_code"
}
trap finalize EXIT

guard_adapter() {
  expect "${CIRCLE_PROJECT_USERNAME:-}" 'Pacchifans69' proof_owner
  expect "${CIRCLE_PROJECT_REPONAME:-}" 'linguagraph-m6-proof' proof_repository
  expect "${CIRCLE_BRANCH:-}" 'main' proof_branch
  expect "${EXPECTED_CANDIDATE_SHA:-}" "$APP_SHA" configured_candidate_sha
  expect "${EXPECTED_CANDIDATE_TREE:-}" "$APP_TREE" configured_candidate_tree
  expect "${EXPECTED_CANDIDATE_PARENT:-}" "$APP_PARENT" configured_candidate_parent
  expect "${EXPECTED_FROZEN_MAIN:-}" "$MAIN_SHA" configured_frozen_main
  [[ "${CIRCLE_SHA1:-}" =~ ^[0-9a-f]{40}$ ]] || die 'Missing CircleCI proof commit'
  expect "$(git -C "$PROOF_ROOT" rev-parse HEAD)" "$CIRCLE_SHA1" proof_checkout
  expect "${APPROVED_PROOF_SHA:-}" "$CIRCLE_SHA1" separately_approved_proof_commit
  [[ "${M6_PROOF_RUN_AUTHORIZATION:-}" =~ $RUN_AUTH_NAMESPACE ]] || die 'Missing distinct Human run authorization'
  [[ -z "$(git -C "$PROOF_ROOT" status --porcelain=v1 --untracked-files=all)" ]] || die 'Dirty proof source'
  [[ -n "${CIRCLE_WORKFLOW_ID:-}" && -n "${CIRCLE_BUILD_NUM:-}" ]] || die 'Missing hosted workflow/job identity'
  record proof_provider circleci
  record proof_project "${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"
  record proof_sha "$CIRCLE_SHA1"
  record proof_tree "$(git -C "$PROOF_ROOT" rev-parse HEAD^{tree})"
  record candidate_sha "$APP_SHA"
  record candidate_tree "$APP_TREE"
  record candidate_parent "$APP_PARENT"
  record frozen_main "$MAIN_SHA"
  record proof_workflow "$CIRCLE_WORKFLOW_ID"
  record proof_job "$CIRCLE_BUILD_NUM"
  record date_utc "$(date -u +%FT%TZ)"
}

guard_adapter

core_rc=0
bash "$CORE" || core_rc=$?
exit "$core_rc"
