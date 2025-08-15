load 'vendor/bats-support/load'
load 'vendor/bats-assert/load'

setup_path_with_mocks() {
  export PATH_ORIG="$PATH"

  # temp bin for dynamic mocks
  export TEST_BIN_DIR="${BATS_TEST_TMPDIR}/bin"
  mkdir -p "$TEST_BIN_DIR"

  # a writable mock root for fake file trees
  export MOCK_ROOT="${BATS_TEST_TMPDIR}/mock"
  mkdir -p "$MOCK_ROOT"

  # IMPORTANT: prepend, don't replace, so /usr/bin/env can find bash
  export PATH="$TEST_BIN_DIR:$PATH"
}

teardown() {
  # restore PATH after each test
  [ -n "${PATH_ORIG:-}" ] && export PATH="$PATH_ORIG"
}

# Write a mock command into TEST_BIN_DIR
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

# Source the libs so helper functions like _gs_mm are available
source_goswitch_libs() {
  export REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
  . "$REPO_ROOT/lib/common.sh"
  . "$REPO_ROOT/lib/brew.sh"
  . "$REPO_ROOT/lib/asdf.sh"
  . "$REPO_ROOT/lib/tarball.sh"
}

# Run the real CLI
run_goswitch() {
  "$REPO_ROOT/cmd/goswitch" "$@"
}
