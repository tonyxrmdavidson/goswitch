load 'helpers.bash'

setup() {
  setup_path_with_mocks
  source_goswitch_libs
}

@test "--which fails with clear error when no 'go' on PATH" {
  # Keep coreutils for bats-assert (cat, printf), keep env for shebang.
  # Do NOT include directories that might contain a real `go`.
  export PATH="/usr/bin:/bin:$TEST_BIN_DIR"

  run_goswitch --which
  assert_failure
  assert_output --partial "go not found on PATH."
}

@test "--which shows Homebrew-style go binary path and version" {
  hb_bin="${BATS_TEST_TMPDIR}/homebrew/bin"
  mkdir -p "$hb_bin"
  cat >"${hb_bin}/go" <<'EOF'
echo "go version go1.24.6 darwin/arm64"
EOF
  chmod +x "${hb_bin}/go"

  export PATH="${hb_bin}:$PATH"
  run_goswitch --which
  assert_success
  assert_output --partial "Go binary: ${hb_bin}/go"
  assert_output --partial "go version go1.24.6"
}

@test "--which shows asdf shim path and version" {
  shims="${BATS_TEST_TMPDIR}/asdf/shims"
  mkdir -p "$shims"
  cat >"${shims}/go" <<'EOF'
echo "go version go1.19.13 darwin/arm64"
EOF
  chmod +x "${shims}/go"

  export PATH="${shims}:$PATH"
  run_goswitch --which
  assert_success
  assert_output --partial "Go binary: ${shims}/go"
  assert_output --partial "go version go1.19.13"
}
