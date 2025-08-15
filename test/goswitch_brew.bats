load 'helpers.bash'

setup() {
  setup_path_with_mocks
  source_goswitch_libs
  mock_cmd uname <<'EOF'
echo Darwin
EOF
}

@test "uses Homebrew when series is already installed" {
  mock_cmd brew <<'EOF'
case "$1" in
  list)
    if [ "$2" = "--versions" ]; then
      if [ "$3" = "go@1.23" ]; then exit 0; fi
      if [ "$3" = "go" ]; then echo "go 1.24.6"; exit 0; fi
    fi
    ;;
  --prefix)
    if [ "$2" = "go@1.23" ]; then echo "${MOCK_ROOT}/homebrew/Cellar/go@1.23/1.23.11"; exit 0; fi
    ;;
  info)
    echo "go: stable 1.24.6"
    ;;
esac
EOF

  mkdir -p "${MOCK_ROOT}/homebrew/Cellar/go@1.23/1.23.11/bin"
  cat >"${MOCK_ROOT}/homebrew/Cellar/go@1.23/1.23.11/bin/go" <<'EOF'
echo "go version go1.23.11 darwin/arm64"
EOF
  chmod +x "${MOCK_ROOT}/homebrew/Cellar/go@1.23/1.23.11/bin/go"

  run_goswitch 1.23
  assert_success
  assert_output --partial "Using Homebrew go@1.23"
  assert_output --partial "go version go1.23.11"
}

@test "prompts to install via brew when series available but not installed (auto -y)" {
  mock_cmd brew <<'EOF'
case "$1" in
  list)
    if [ "$2" = "--versions" ]; then exit 1; fi
    ;;
  info)
    if [ "$2" = "go@1.22" ]; then echo "go@1.22: stable 1.22.10"; exit 0; fi
    if [ "$2" = "go" ]; then echo "go: stable 1.24.6"; exit 0; fi
    ;;
  --prefix)
    if [ "$2" = "go@1.22" ]; then echo "${MOCK_ROOT}/homebrew/Cellar/go@1.22/1.22.10"; exit 0; fi
    ;;
  install) exit 0 ;;
esac
EOF

  mkdir -p "${MOCK_ROOT}/homebrew/Cellar/go@1.22/1.22.10/bin"
  cat >"${MOCK_ROOT}/homebrew/Cellar/go@1.22/1.22.10/bin/go" <<'EOF'
echo "go version go1.22.10 darwin/arm64"
EOF
  chmod +x "${MOCK_ROOT}/homebrew/Cellar/go@1.22/1.22.10/bin/go"

  run_goswitch -y 1.22
  assert_success
  assert_output --partial "Installing go@1.22 via Homebrew"
  assert_output --partial "Using Homebrew go@1.22"
}
