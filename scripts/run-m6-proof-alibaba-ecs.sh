#!/usr/bin/env bash
# M6-EXI-03 Alibaba ECS thin adapter.
#
# Alternate hosted-proof path on the measured Alibaba Cloud ECS instance. This
# adapter validates the exact Alibaba ECS provenance, a distinct one-shot Human
# run authorization bound to the approved proof SHA, performs the minimum host
# bootstrap needed to make Docker usable, and then invokes the provider-neutral
# semantic core:
#
#   scripts/run-m6-proof-core.sh
#
# The core owns every semantic Gate 2 requirement. This adapter performs no
# semantic weakening and no provider identity spoofing.
#
# WRITE-ONLY PATCH: this file is authored and statically checked. It MUST NOT
# be executed as part of the M6-EXI-03 harness repair. Hosted execution is not
# authorized yet, and semantic hosted proof remains ABSENT.
#
# Never run this without a separate Human approval of the exact proof commit.
set -Eeuo pipefail

readonly PROOF_ROOT="$(git rev-parse --show-toplevel)"
readonly CORE="$PROOF_ROOT/scripts/run-m6-proof-core.sh"
readonly EVIDENCE="${M6_PROOF_EVIDENCE_DIR:-$PROOF_ROOT/proof-artifacts}"
export M6_PROOF_EVIDENCE_DIR="$EVIDENCE"

# Host-persistent, untracked state lives outside the git worktree.
readonly HOST_STATE="${M6_PROOF_HOST_STATE:-$HOME/.local/state/linguagraph-m6-proof}"
readonly SPENT_DIR="$HOST_STATE/spent"
readonly ARCHIVE_DIR="$HOST_STATE/artifacts"

# Alibaba ECS IMDS. Tokenless access must be rejected (403); token mode must work.
readonly IMDS_BASE='http://100.100.100.200/latest'
readonly IMDS_TOKEN_URL="$IMDS_BASE/api/token"
readonly IMDS_TTL='21600'

# Exact measured Alibaba ECS provenance.
readonly EXPECTED_INSTANCE_ID='i-j6c13vpnkuq6xbbhyxzw'
readonly EXPECTED_REGION_ID='cn-hongkong'
readonly EXPECTED_ZONE_ID='cn-hongkong-d'
readonly EXPECTED_INSTANCE_TYPE='ecs.g9i.xlarge'
readonly EXPECTED_IMAGE_ID='ubuntu_24_04_x64_20G_alibase_20260828.vhd'

# EXI-03 authorization namespace bound to the approved proof SHA prefix.
readonly RUN_AUTH_NAMESPACE_DESCRIPTION='M6-EXI-03-RUN-<approved-proof-sha-prefix>-<nonce>'

IMDS_TOKEN=''
core_rc=0

die() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
expect() { [[ "$1" == "$2" ]] || die "Mismatch: $3 (expected $2; got $1)"; }
record() { printf '%s=%s\n' "$1" "$2" >> "$EVIDENCE/provenance.txt"; }

# Preserve artifacts on both PASS and FAIL, then preserve the proof exit status.
finalize() {
  local exit_code=$? archive_name='' archive=''
  trap - EXIT
  mkdir -p "$EVIDENCE"
  if [[ ! -e "$EVIDENCE/outcome.txt" ]]; then
    printf 'FAIL adapter_exit=%s\n' "$exit_code" > "$EVIDENCE/outcome.txt"
  fi
  if ! ( cd "$EVIDENCE" && find . -type f ! -name artifact-manifest.sha256 -print0 | sort -z | xargs -0 -r sha256sum > artifact-manifest.sha256 ); then
    printf 'FAIL: artifact manifest could not be written\n' >&2
    exit_code=1
  fi
  mkdir -p "$ARCHIVE_DIR" || exit_code=1
  if [[ -d "$ARCHIVE_DIR" ]]; then
    archive_name="m6-proof-artifacts-${APPROVED_PROOF_SHA:-unknown}.tar.gz"
    archive="$ARCHIVE_DIR/$archive_name"
    if tar --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 --numeric-owner \
         -C "$PROOF_ROOT" -cf - proof-artifacts | gzip -n > "$archive"; then
      ( cd "$ARCHIVE_DIR" && sha256sum "$archive_name" > "$archive_name.sha256" ) || exit_code=1
    else
      printf 'FAIL: deterministic artifact archive failed\n' >&2
      rm -f "$archive"
      exit_code=1
    fi
  fi
  exit "$exit_code"
}
trap finalize EXIT

# ---------------------------------------------------------------------------
# 1. CircleCI anti-spoof guard.
# ---------------------------------------------------------------------------
guard_no_circleci() {
  local v
  for v in CIRCLE_PROJECT_USERNAME CIRCLE_PROJECT_REPONAME CIRCLE_BRANCH \
           CIRCLE_SHA1 CIRCLE_WORKFLOW_ID CIRCLE_BUILD_NUM; do
    [[ -z "${!v:-}" ]] || die "CircleCI identity variable $v is set; Alibaba execution must not be obtained by spoofing CircleCI"
  done
}

# ---------------------------------------------------------------------------
# 2. Proof SHA guard (before any evidence creation).
# ---------------------------------------------------------------------------
guard_proof_sha() {
  [[ "${APPROVED_PROOF_SHA:-}" =~ ^[0-9a-f]{40}$ ]] || die 'APPROVED_PROOF_SHA must be a full 40-character SHA'
  expect "$(git -C "$PROOF_ROOT" rev-parse --abbrev-ref HEAD)" 'main' proof_branch
  expect "$(git -C "$PROOF_ROOT" rev-parse HEAD)" "$APPROVED_PROOF_SHA" approved_proof_head
  expect "$(git -C "$PROOF_ROOT" ls-remote origin refs/heads/main | awk '{print $1}')" "$APPROVED_PROOF_SHA" approved_proof_remote_main
  [[ -z "$(git -C "$PROOF_ROOT" status --porcelain=v1 --untracked-files=all)" ]] || die 'Dirty proof worktree before evidence creation'
}

# ---------------------------------------------------------------------------
# 3. One-shot EXI-03 run authorization. The raw token is never recorded; only
#    its SHA-256 is recorded. A reused token fails closed.
# ---------------------------------------------------------------------------
guard_run_authorization() {
  local token="${M6_PROOF_RUN_AUTHORIZATION:-}"
  [[ -n "$token" ]] || die "Missing one-shot Human run authorization ($RUN_AUTH_NAMESPACE_DESCRIPTION)"
  local prefix=''
  if [[ "$token" =~ ^M6-EXI-03-RUN-([A-Fa-f0-9]{7,40})-[A-Za-z0-9_-]+$ ]]; then
    prefix="${BASH_REMATCH[1]}"
  else
    die "Run authorization must match $RUN_AUTH_NAMESPACE_DESCRIPTION"
  fi
  local lower_prefix="${prefix,,}"
  expect "${APPROVED_PROOF_SHA:0:${#lower_prefix}}" "$lower_prefix" authorization_proof_sha_prefix
  local token_hash
  token_hash=$(printf '%s' "$token" | sha256sum | cut -d' ' -f1)
  mkdir -p "$SPENT_DIR"
  if ! mkdir "$SPENT_DIR/$token_hash" 2>/dev/null; then
    die "Run authorization was already spent ($token_hash); a rerun requires fresh Human authorization"
  fi
  record proof_provider alibaba-ecs
  record authorization_namespace M6-EXI-03
  record authorization_sha256 "$token_hash"
  record approved_proof_sha "$APPROVED_PROOF_SHA"
  record date_utc "$(date -u +%FT%TZ)"
}

# ---------------------------------------------------------------------------
# 4. Exact Alibaba ECS provenance guard and evidence capture.
# ---------------------------------------------------------------------------
imds_plain() { curl --silent --output /dev/null --write-out '%{http_code}' --max-time 5 "$IMDS_BASE/$1"; }
imds_request_token() {
  curl --fail --silent --show-error --max-time 5 -X PUT \
    -H "X-aliyun-ecs-metadata-token-ttl-seconds: $IMDS_TTL" "$IMDS_TOKEN_URL"
}
imds_get() {
  curl --fail --silent --show-error --max-time 5 \
    -H "X-aliyun-ecs-metadata-token: $IMDS_TOKEN" "$IMDS_BASE/$1"
}

capture_imds() {
  local rel=$1 out=$2 value=''
  if value=$(imds_get "$rel" 2>/dev/null) && [[ -n "$value" ]]; then
    printf '%s\n' "$value" > "$EVIDENCE/$out"
  else
    printf 'unavailable\n' > "$EVIDENCE/$out"
  fi
}

guard_and_capture_imds() {
  local code instance_id region zone itype image mac
  code=$(imds_plain meta-data/instance-id)
  expect "$code" '403' imds_tokenless_instance_id_http_status
  IMDS_TOKEN=$(imds_request_token) || die 'Alibaba IMDS token mode request failed'
  [[ -n "$IMDS_TOKEN" ]] || die 'Alibaba IMDS token mode returned an empty token'
  instance_id=$(imds_get meta-data/instance-id) || die 'Alibaba IMDS token-mode instance-id request failed'
  region=$(imds_get meta-data/region-id)
  zone=$(imds_get meta-data/zone-id)
  if ! itype=$(imds_get meta-data/instance/instance-type 2>/dev/null); then
    itype=$(imds_get meta-data/instance-type)
  fi
  image=$(imds_get meta-data/image-id)
  expect "$instance_id" "$EXPECTED_INSTANCE_ID" imds_instance_id
  expect "$region" "$EXPECTED_REGION_ID" imds_region_id
  expect "$zone" "$EXPECTED_ZONE_ID" imds_zone_id
  expect "$itype" "$EXPECTED_INSTANCE_TYPE" imds_instance_type
  expect "$image" "$EXPECTED_IMAGE_ID" imds_image_id

  capture_imds meta-data/instance-id instance-id.txt
  capture_imds meta-data/instance/instance-name instance-name.txt
  capture_imds meta-data/hostname hostname.txt
  capture_imds meta-data/region-id region-id.txt
  capture_imds meta-data/zone-id zone-id.txt
  capture_imds meta-data/instance/instance-type instance-type.txt
  capture_imds meta-data/image-id image-id.txt
  capture_imds meta-data/serial-number serial-number.txt
  capture_imds meta-data/vpc-id vpc-id.txt
  capture_imds meta-data/vswitch-id vswitch-id.txt
  capture_imds meta-data/private-ipv4 private-ipv4.txt
  capture_imds meta-data/public-ipv4 public-ipv4.txt
  capture_imds meta-data/eipv4 eipv4.txt
  capture_imds meta-data/mac primary-mac.txt
  mac=$(cat "$EVIDENCE/primary-mac.txt" 2>/dev/null || printf '')
  if [[ -n "$mac" && "$mac" != 'unavailable' ]]; then
    capture_imds "meta-data/network/interfaces/macs/$mac/network-interface-id" primary-eni.txt
    capture_imds "meta-data/network/interfaces/macs/$mac/primary-ip-address" primary-eni-private-ipv4.txt
  else
    printf 'unavailable\n' > "$EVIDENCE/primary-eni.txt"
    printf 'unavailable\n' > "$EVIDENCE/primary-eni-private-ipv4.txt"
  fi
  if ! imds_get dynamic/instance-identity/document > "$EVIDENCE/instance-identity-document.json" 2>/dev/null; then
    printf 'unavailable\n' > "$EVIDENCE/instance-identity-document.json"
  fi
  if ! imds_get dynamic/instance-identity/pkcs7 > "$EVIDENCE/instance-identity-pkcs7.txt" 2>/dev/null; then
    printf 'unavailable\n' > "$EVIDENCE/instance-identity-pkcs7.txt"
  fi
  sha256sum "$EVIDENCE/instance-identity-document.json" | cut -d' ' -f1 > "$EVIDENCE/instance-identity-document.sha256"
  sha256sum "$EVIDENCE/instance-identity-pkcs7.txt" | cut -d' ' -f1 > "$EVIDENCE/instance-identity-pkcs7.sha256"

  {
    printf 'os_release:\n'
    cat /etc/os-release
    printf '\nuname:\n'
    uname -a
    printf '\narchitecture=%s\n' "$(uname -m)"
    printf 'cpu_count=%s\n' "$(nproc)"
    grep MemTotal /proc/meminfo
    printf 'boot_time_local=%s\n' "$(uptime -s 2>/dev/null || printf unavailable)"
    printf 'boot_timestamp_utc=%s\n' "$(date -u -d "@$(awk '{print int($1)}' /proc/uptime)" +%FT%TZ 2>/dev/null || printf unavailable)"
  } > "$EVIDENCE/host-facts.txt"

  {
    printf 'imds_endpoint=%s\n' "$IMDS_BASE"
    printf 'imds_tokenless_instance_id_http_status=403\n'
    printf 'imds_token_mode=successful\n'
    printf 'instance_id=%s\n' "$instance_id"
    printf 'region_id=%s\n' "$region"
    printf 'zone_id=%s\n' "$zone"
    printf 'instance_type=%s\n' "$itype"
    printf 'image_id=%s\n' "$image"
    printf 'observed_public_ip=%s\n' "$(cat "$EVIDENCE/public-ipv4.txt" 2>/dev/null || printf unavailable)"
    printf 'observed_eipv4=%s\n' "$(cat "$EVIDENCE/eipv4.txt" 2>/dev/null || printf unavailable)"
    printf 'note=public IP, kernel patch version, boot timestamp and runtime-assigned network observations are recorded but are not immutable execution identity\n'
  } > "$EVIDENCE/alibaba-ecs-provenance.txt"
}

# ---------------------------------------------------------------------------
# 5. Alibaba host bootstrap. Docker is the only host prerequisite installed
#    here; the pinned uv/Python/Node runtimes and PostgreSQL 18 are installed by
#    the common core. No docker-group mutation, no socket chmod, no relogin.
# ---------------------------------------------------------------------------
bootstrap_host() {
  if command -v docker >/dev/null 2>&1 && { docker info >/dev/null 2>&1 || sudo -n docker info >/dev/null 2>&1; }; then
    printf 'docker_already_usable=true\n' > "$EVIDENCE/alibaba-bootstrap.txt"
    return 0
  fi
  sudo -n true 2>/dev/null || die 'passwordless sudo -n is required for Alibaba host bootstrap'
  printf 'docker_already_usable=false\n' > "$EVIDENCE/alibaba-bootstrap.txt"
  sudo -n env DEBIAN_FRONTEND=noninteractive apt-get update
  sudo -n env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends docker.io
  if ! sudo -n docker info >/dev/null 2>&1; then
    sudo -n systemctl start docker >/dev/null 2>&1 || sudo -n service docker start >/dev/null 2>&1 || true
  fi
  sudo -n docker info >/dev/null 2>&1 || die 'Docker did not become usable after bootstrap'
  {
    printf 'docker_io_version=%s\n' "$(dpkg-query -W -f='${Version}' docker.io 2>/dev/null || printf unavailable)"
    sudo -n docker --version
  } >> "$EVIDENCE/alibaba-bootstrap.txt"
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
guard_no_circleci
guard_proof_sha
case "$HOST_STATE" in
  "$PROOF_ROOT"/*) die 'Host state directory must be outside the git worktree' ;;
esac
mkdir -p "$EVIDENCE"
guard_run_authorization
guard_and_capture_imds
bootstrap_host

bash "$CORE" || core_rc=$?
exit "$core_rc"
