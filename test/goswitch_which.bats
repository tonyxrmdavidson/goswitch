load 'helpers.bash'

setup() {
  setup_path_with_mocks
  source_goswitch_libs
}

@test "--which fails with clear error when no 'go' on PATH" {
  # Hide system go by removing /usr/bin, but provide required tools via TEST_BIN_DIR.
  export PATH="/bin:$TEST_BIN_DIR"

  # Symlink the minimal external utilities goswitch uses from /usr/bin
  for cmd in dirname uname tr grep sed head sort tail awk cut; do
    [ -x "/usr/bin/$cmd" ] && ln -sf "/usr/bin/$cmd" "$TEST_BIN_DIR/$cmd"
  done

  # Sanity check: no go should be resolvable
  run /usr/bin/env -i PATH="$PATH" bash -c 'command -v go >/dev/null && echo found || echo notfound'
  assert_output "notfound"

  # Run the script explicitly with bash so we don't rely on /usr/bin/env
  run bash "$REPO_ROOT/cmd/goswitch" --which
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
