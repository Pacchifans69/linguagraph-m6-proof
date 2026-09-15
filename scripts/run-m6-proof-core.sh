#!/usr/bin/env bash
# LinguaGraph M6 provider-neutral semantic proof core.
#
# This file holds the complete semantic proof surface for the frozen M6
# product candidate. It is intentionally provider-neutral: it performs NO
# CircleCI, Alibaba ECS, or other provider identity check. Those checks live in
# the thin provider adapters that invoke this core:
#
#   scripts/run-m6-proof.sh              CircleCI M6-EXI-01 / M6-EXI-02
#   scripts/run-m6-proof-alibaba-ecs.sh  Alibaba ECS M6-EXI-03
#
# The core is fail-closed: any semantic deviation, missing evidence, failed
# cleanup, or integrity break fails the run and preserves failure artifacts.
#
# Never run this without a separate Human approval of the exact proof commit.
set -Eeuo pipefail

readonly PROOF_ROOT="$(git rev-parse --show-toplevel)"
readonly EVIDENCE="${M6_PROOF_EVIDENCE_DIR:-$PROOF_ROOT/proof-artifacts}"
readonly CANDIDATE="$PROOF_ROOT/candidate"

# ---------------------------------------------------------------------------
# Frozen Product binding (MUST NOT CHANGE)
# ---------------------------------------------------------------------------
readonly APP_BRANCH='m6-mode-oriented-workbench-information-architecture'
readonly APP_SHA='2054c844ea3488b43459903f64f063b1d541f8a2'
readonly APP_TREE='efd303a2aaf4f32dec14346ac4c644a8717a0ffa'
readonly APP_PARENT='f2a9ef458b234d826e22d55a6a4740b3b0e7a0ec'
readonly MAIN_SHA='cb61725fe9f05c704a6f80b67c6343f49ade9234'
readonly ALEMBIC_HEAD='0006'
readonly APP_URL='https://github.com/Pacchifans69/LinguaGraph.git'

readonly POSTGRES_CONTAINER='linguagraph-m6-proof-postgres'
readonly DB_URL='postgresql+psycopg://postgres:postgres@127.0.0.1:5432/postgres'

mkdir -p "$EVIDENCE"
completed=0
DOCKER_MODE=''

die() { printf 'FAIL: %s\n' "$*" >&2; return 1; }
expect() { [[ "$1" == "$2" ]] || die "Mismatch: $3 (expected $2; got $1)"; }
record() { printf '%s=%s\n' "$1" "$2" >> "$EVIDENCE/provenance.txt"; }

# ---------------------------------------------------------------------------
# Docker access. Docker is a host/provider prerequisite. The core must work
# with a directly usable `docker` client or with passwordless `sudo -n docker`,
# without mutating group membership, the socket, or requiring a new login.
# ---------------------------------------------------------------------------
probe_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    die 'docker client is absent from PATH'
    return 1
  fi
  if docker info >/dev/null 2>&1; then
    DOCKER_MODE=direct
  elif sudo -n docker info >/dev/null 2>&1; then
    DOCKER_MODE=sudo
  else
    die 'Docker is unusable without interactive elevation (need direct access or passwordless sudo -n)'
    return 1
  fi
  printf '%s' "$DOCKER_MODE"
}

docker_run() {
  if [[ -z "$DOCKER_MODE" ]]; then
    probe_docker >/dev/null || return 1
  fi
  if [[ "$DOCKER_MODE" == direct ]]; then
    docker "$@"
  else
    sudo -n docker "$@"
  fi
}

# ---------------------------------------------------------------------------
# Evidence lifecycle. Cleanup failure fails closed.
# ---------------------------------------------------------------------------
finish() {
  local exit_code=$? cleanup_code=0
  trap - EXIT
  if [[ -e "$EVIDENCE/docker-owned-marker" ]]; then
    if [[ -z "$DOCKER_MODE" ]]; then
      probe_docker >/dev/null 2>&1 || cleanup_code=1
    fi
    if (( cleanup_code == 0 )); then
      docker_run rm -f "$POSTGRES_CONTAINER" >/dev/null 2>&1 || cleanup_code=1
    fi
  fi
  if [[ "$cleanup_code" != 0 ]]; then
    printf 'FAIL: PostgreSQL container cleanup failed\n' >&2
    (( exit_code == 0 )) && exit_code=1
  fi
  if [[ -d "$CANDIDATE" ]] && git -C "$CANDIDATE" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$CANDIDATE" status --porcelain=v1 --untracked-files=all > "$EVIDENCE/candidate-final-status.txt" || true
  fi
  if [[ "$completed" == 1 && "$exit_code" == 0 ]]; then
    printf 'PASS\n' > "$EVIDENCE/outcome.txt"
  else
    printf 'FAIL exit=%s cleanup=%s\n' "$exit_code" "$cleanup_code" > "$EVIDENCE/outcome.txt"
  fi
  ( cd "$EVIDENCE" && find . -type f ! -name artifact-manifest.sha256 -print0 | sort -z | xargs -0 -r sha256sum > artifact-manifest.sha256 ) || exit_code=1
  exit "$exit_code"
}
trap finish EXIT

stage() {
  local name=$1; shift
  local safe=${name//[^a-zA-Z0-9_-]/_} rc=0 tee_rc=0
  printf '\n--- %s ---\n' "$name"
  printf '%s started=%s\n' "$name" "$(date -u +%FT%TZ)" >> "$EVIDENCE/stages.txt"
  set +e
  (set -Eeuo pipefail; "$@") 2>&1 | tee "$EVIDENCE/${safe}.log"
  local -a statuses=("${PIPESTATUS[@]}")
  rc=${statuses[0]}
  tee_rc=${statuses[1]}
  set -e
  (( tee_rc == 0 )) || die "Evidence log for $name could not be stored"
  printf '%s finished=%s exit=%s\n' "$name" "$(date -u +%FT%TZ)" "$rc" >> "$EVIDENCE/stages.txt"
  (( rc == 0 )) || die "Stage $name failed with exit $rc"
}

# ---------------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------------
guard_candidate_config() {
  expect "${EXPECTED_CANDIDATE_SHA:-$APP_SHA}" "$APP_SHA" configured_candidate_sha
  expect "${EXPECTED_CANDIDATE_TREE:-$APP_TREE}" "$APP_TREE" configured_candidate_tree
  expect "${EXPECTED_CANDIDATE_PARENT:-$APP_PARENT}" "$APP_PARENT" configured_candidate_parent
  expect "${EXPECTED_FROZEN_MAIN:-$MAIN_SHA}" "$MAIN_SHA" configured_frozen_main
  expect "${EXPECTED_ALEMBIC_HEAD:-$ALEMBIC_HEAD}" "$ALEMBIC_HEAD" configured_alembic_head
}

guard_approved_proof() {
  [[ "${APPROVED_PROOF_SHA:-}" =~ ^[0-9a-f]{40}$ ]] || die 'Missing separately approved proof commit'
  expect "$(git -C "$PROOF_ROOT" rev-parse HEAD)" "$APPROVED_PROOF_SHA" approved_proof_checkout
  [[ -z "$(git -C "$PROOF_ROOT" status --porcelain=v1 --untracked-files=all)" ]] || die 'Dirty proof source'
}

guard_core() {
  guard_candidate_config
  guard_approved_proof
  probe_docker >/dev/null
  record proof_sha "$APPROVED_PROOF_SHA"
  record proof_tree "$(git -C "$PROOF_ROOT" rev-parse HEAD^{tree})"
  record candidate_sha "$APP_SHA"
  record candidate_tree "$APP_TREE"
  record candidate_parent "$APP_PARENT"
  record frozen_main "$MAIN_SHA"
  record alembic_head "$ALEMBIC_HEAD"
  record docker_mode "$DOCKER_MODE"
  record date_utc "$(date -u +%FT%TZ)"
}

guard_remote() {
  local app_remote main_remote
  app_remote=$(git ls-remote "$APP_URL" "refs/heads/$APP_BRANCH")
  main_remote=$(git ls-remote "$APP_URL" refs/heads/main)
  expect "${app_remote%%[[:space:]]*}" "$APP_SHA" candidate_remote_ref
  expect "${main_remote%%[[:space:]]*}" "$MAIN_SHA" frozen_main_remote_ref
}

fetch_candidate() {
  [[ ! -e "$CANDIDATE" ]] || die 'Candidate checkout path already exists'
  git init -q "$CANDIDATE"
  git -C "$CANDIDATE" remote add origin "$APP_URL"
  git -C "$CANDIDATE" fetch --no-tags origin \
    "refs/heads/$APP_BRANCH:refs/remotes/origin/$APP_BRANCH" \
    'refs/heads/main:refs/remotes/origin/main'
  expect "$(git -C "$CANDIDATE" rev-parse "refs/remotes/origin/$APP_BRANCH")" "$APP_SHA" fetched_branch
  expect "$(git -C "$CANDIDATE" rev-parse refs/remotes/origin/main)" "$MAIN_SHA" fetched_main
  git -C "$CANDIDATE" checkout --detach -q "$APP_SHA"
  expect "$(git -C "$CANDIDATE" rev-parse HEAD)" "$APP_SHA" candidate_checkout
  expect "$(git -C "$CANDIDATE" rev-parse HEAD^{tree})" "$APP_TREE" candidate_tree
  expect "$(git -C "$CANDIDATE" rev-list --parents -n 1 HEAD)" "$APP_SHA $APP_PARENT" candidate_unique_parent
  expect "$(git -C "$CANDIDATE" merge-base "$APP_SHA" "$MAIN_SHA")" "$MAIN_SHA" frozen_main_ancestor
  [[ ! -e "$CANDIDATE/.circleci/config.yml" ]] || die 'Candidate carries proof configuration'
  [[ -z "$(git -C "$CANDIDATE" status --porcelain=v1 --untracked-files=all)" ]] || die 'Dirty candidate checkout'
  git -C "$CANDIDATE" diff --check "$MAIN_SHA" "$APP_SHA"
  git -C "$CANDIDATE" diff --name-status "$MAIN_SHA" "$APP_SHA" > "$EVIDENCE/candidate-file-scope.txt"
}

install_runtimes() {
  [[ "$(. /etc/os-release; printf '%s' "$ID:$VERSION_ID")" == 'ubuntu:24.04' ]] || die 'Hosted Linux must be Ubuntu 24.04'
  (( $(nproc) >= 4 )) || die 'Hosted resource has fewer than four CPUs'
  (( $(awk '/MemTotal:/ {print $2}' /proc/meminfo) >= 15000000 )) || die 'Hosted resource has less than ~16 GB RAM'
  [[ -n "$DOCKER_MODE" ]] || probe_docker >/dev/null
  curl --fail --location --silent --show-error https://astral.sh/uv/0.12.10/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  uv python install 3.13
  curl --fail --location --silent --show-error https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  source "$NVM_DIR/nvm.sh"
  nvm install 24.17.0
  nvm use 24.17.0
  docker_run pull postgres:18
  [[ -z "$(docker_run ps -aq --filter "name=^/${POSTGRES_CONTAINER}$")" ]] || die 'Proof container name already in use'
  docker_run run -d --name "$POSTGRES_CONTAINER" -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres -p 127.0.0.1:5432:5432 postgres:18
  : > "$EVIDENCE/docker-owned-marker"
  for _ in $(seq 1 60); do
    if docker_run exec "$POSTGRES_CONTAINER" pg_isready -q -U postgres; then break; fi
    sleep 2
  done
  docker_run exec "$POSTGRES_CONTAINER" pg_isready -q -U postgres || die 'PostgreSQL not ready'
  [[ "$(docker_run exec "$POSTGRES_CONTAINER" psql -At -U postgres -d postgres -c 'SHOW server_version_num')" == 18* ]] || die 'PostgreSQL is not major 18'
  expect "$(uv --version)" 'uv 0.12.10' pinned_uv_version
  expect "$(node --version)" 'v24.17.0' pinned_node_version
  { uname -a; cat /etc/os-release; nproc; grep MemTotal /proc/meminfo; uv --version; uv python find 3.13; node --version; npm --version; printf 'docker_mode=%s\n' "$DOCKER_MODE"; docker_run image inspect postgres:18 --format '{{json .RepoDigests}}'; docker_run exec "$POSTGRES_CONTAINER" psql -At -U postgres -d postgres -c 'SELECT version()'; } > "$EVIDENCE/runtime.txt"
}

activate_runtimes() {
  export PATH="$HOME/.local/bin:$PATH" NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  source "$NVM_DIR/nvm.sh"
  nvm use 24.17.0 >/dev/null
}

backend() {
  activate_runtimes
  export DATABASE_URL="$DB_URL" TEST_DATABASE_URL="$DB_URL"
  cd "$CANDIDATE/apps/api"
  uv sync --frozen
  [[ "$(uv run --frozen python --version)" == Python\ 3.13.* ]] || die 'Python is not 3.13'
  local before after current
  before=$(docker_run exec "$POSTGRES_CONTAINER" psql -At -U postgres -d postgres -c "SELECT count(*) FROM pg_tables WHERE schemaname='public'")
  expect "$before" 0 empty_migration_database
  uv run alembic upgrade head
  current=$(uv run alembic current)
  [[ "$current" == *"$ALEMBIC_HEAD (head)"* ]] || die "Alembic head mismatch: $current"
  after=$(docker_run exec "$POSTGRES_CONTAINER" psql -At -U postgres -d postgres -c "SELECT version_num FROM alembic_version")
  expect "$after" "$ALEMBIC_HEAD" database_revision
  uv run alembic check
  uv run pytest -q 2>&1 | tee "$EVIDENCE/pytest-raw.log"
  grep -Eq '587 passed' "$EVIDENCE/pytest-raw.log" || die 'Expected 587 passed pytest summary'
  ! grep -Eiq 'skipped|xfailed|xpassed|deselected' "$EVIDENCE/pytest-raw.log" || die 'Backend tests skipped/filtered'
}

frontend() {
  activate_runtimes
  cd "$CANDIDATE/apps/web"
  npm ci
  npm run lint
  npm run typecheck
  npm run test 2>&1 | tee "$EVIDENCE/vitest-raw.log"
  grep -Eq '502 passed' "$EVIDENCE/vitest-raw.log" || die 'Expected 502 passed Vitest summary'
  ! grep -Eiq 'Tests.*(skipped|todo|failed)' "$EVIDENCE/vitest-raw.log" || die 'Vitest incomplete'
  npm run build
}

browser_e2e() {
  activate_runtimes
  export DATABASE_URL="$DB_URL" TEST_DATABASE_URL="$DB_URL" CI=1
  cd "$CANDIDATE/apps/web"
  npx playwright install --with-deps chromium
  npx playwright test \
    e2e/golden-path.spec.ts e2e/unicode.spec.ts \
    e2e/segmentation.spec.ts e2e/token-segmentation.spec.ts \
    e2e/lemma-annotation.spec.ts e2e/pos-annotation.spec.ts \
    e2e/workbench-information-architecture.spec.ts --retries=0 2>&1 | tee "$EVIDENCE/playwright-raw.log"
  grep -Eq '26 passed' "$EVIDENCE/playwright-raw.log" || die 'Expected all 26 Playwright paths'
  ! grep -Eiq '[1-9][0-9]* (skipped|flaky|failed)' "$EVIDENCE/playwright-raw.log" || die 'Playwright skipped/flaky/failed'
}

hash_manifest() {
  local path=$1 rel=$2
  printf '%s  %s\n' "$(sha256sum "$path" | cut -d' ' -f1)" "$rel"
}

dependency_hashes() {
  local label=$1 path
  for path in apps/api/pyproject.toml apps/api/uv.lock apps/web/package.json apps/web/package-lock.json; do
    hash_manifest "$CANDIDATE/$path" "$path"
  done > "$EVIDENCE/deps-${label}.sha256"
}

integrity() {
  local path committed now
  dependency_hashes post
  cmp "$EVIDENCE/deps-pre.sha256" "$EVIDENCE/deps-post.sha256" || die 'Dependency hashes changed'
  for path in apps/api/pyproject.toml apps/api/uv.lock apps/web/package.json apps/web/package-lock.json; do
    committed=$(git -C "$CANDIDATE" rev-parse "HEAD:$path")
    now=$(git hash-object "$CANDIDATE/$path")
    expect "$now" "$committed" "committed blob $path"
  done
  [[ -z "$(git -C "$CANDIDATE" status --porcelain=v1 --untracked-files=all)" ]] || die 'Candidate worktree modified'
  expect "$(git -C "$CANDIDATE" rev-parse HEAD^{tree})" "$APP_TREE" final_candidate_tree
  git -C "$CANDIDATE" diff --check
  local leftovers
  leftovers=$(docker_run exec "$POSTGRES_CONTAINER" psql -At -U postgres -d postgres -c "SELECT datname FROM pg_database WHERE datname LIKE 'linguagraph_%' ORDER BY datname")
  printf '%s\n' "$leftovers" > "$EVIDENCE/disposable-db-residual.txt"
  [[ -z "$leftovers" ]] || die 'Disposable PostgreSQL databases remain'
  guard_remote
}

stage guard_core guard_core
stage guard_remote guard_remote
stage fetch_candidate fetch_candidate
stage deps_pre dependency_hashes pre
stage install_runtimes install_runtimes
stage backend backend
stage frontend frontend
stage playwright browser_e2e
stage integrity integrity
completed=1
