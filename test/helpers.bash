# test/helpers.bash
load 'vendor/bats-support/load'
load 'vendor/bats-assert/load'

setup_path_with_mocks() {
  export PATH_ORIG="$PATH"

  # temp bin for dynamic mocks
  export TEST_BIN_DIR="${BATS_TEST_TMPDIR}/bin"
  mkdir -p "$TEST_BIN_DIR"

  # writable mock root for fake trees
  export MOCK_ROOT="${BATS_TEST_TMPDIR}/mock"
  mkdir -p "$MOCK_ROOT"

  # prepend (do NOT replace) so /usr/bin/env is still found
  export PATH="$TEST_BIN_DIR:$PATH"
}

teardown() {
  [ -n "${PATH_ORIG:-}" ] && export PATH="$PATH_ORIG"
}

# write a mock into TEST_BIN_DIR
mock_cmd() {
  local name="$1"; shift
  : "${TEST_BIN_DIR:?call setup_path_with_mocks first}"
  local f="$TEST_BIN_DIR/$name"
  cat >"$f" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
SH
  cat >>"$f"
  chmod +x "$f"
}

# Source project libs (functions like _gs_mm available to tests)
source_goswitch_libs() {
  export REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
  . "$REPO_ROOT/lib/common.sh"
  . "$REPO_ROOT/lib/brew.sh"
  . "$REPO_ROOT/lib/asdf.sh"
  . "$REPO_ROOT/lib/tarball.sh"
}

# IMPORTANT: run through Bats' `run` so $status/$output are set
run_goswitch() {
  run "$REPO_ROOT/cmd/goswitch" "$@"
}
