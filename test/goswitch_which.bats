load 'helpers.bash'

setup() {
  setup_path_with_mocks
  source_goswitch_libs
}

@test "--which fails with clear error when no 'go' on PATH" {
  # Resolve absolute paths to tools BEFORE constraining PATH (Bash 3.x friendly)
  LN_BIN="$(command -v ln)"
  needed_tools=( bash dirname uname tr grep sed head sort tail awk cut cat env printf )

  # Collect "cmd|/abs/path" pairs in an indexed array (no associative arrays)
  SRC_CMDS=()
  for cmd in "${needed_tools[@]}"; do
    if src_path="$(command -v "$cmd" 2>/dev/null)"; then
      SRC_CMDS+=("${cmd}|${src_path}")
    fi
  done

  # Now constrain PATH to ONLY TEST_BIN_DIR so any system 'go' is hidden
  export PATH="$TEST_BIN_DIR"
  unset BASH_ENV
  unset ENV

  # Symlink required tools into TEST_BIN_DIR using absolute ln path
  for pair in "${SRC_CMDS[@]}"; do
    cmd="${pair%%|*}"
    path="${pair#*|}"
    "$LN_BIN" -sf "$path" "$TEST_BIN_DIR/$cmd"
  done

  # Run the CLI with our symlinked bash so PATH stays constrained
  run "$TEST_BIN_DIR/bash" "$REPO_ROOT/cmd/goswitch" --which
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
