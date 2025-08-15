load 'helpers.bash'

setup() {
  setup_path_with_mocks
  source_goswitch_libs
  mock_cmd uname <<'EOF'
echo Darwin
EOF
}

@test "--from-mod switches to version from go.mod" {
  cat > go.mod <<'EOF'
module example.com/mymodule

go 1.23
EOF

  mock_cmd brew <<'EOF'
case "$1" in
  list)
    if [ "$2" = "--versions" ]; then
      if [ "$3" = "go@1.23" ]; then exit 0; fi
      exit 1
    fi
    ;;
  --prefix)
    if [ "$2" = "go@1.23" ]; then echo "${MOCK_ROOT}/homebrew/Cellar/go@1.23/1.23.11"; fi
    ;;
  info) echo "go: stable 1.24.6" ;;
esac
EOF

  mkdir -p "${MOCK_ROOT}/homebrew/Cellar/go@1.23/1.23.11/bin"
  cat >"${MOCK_ROOT}/homebrew/Cellar/go@1.23/1.23.11/bin/go" <<'EOF'
echo "go version go1.23.11 darwin/arm64"
EOF
  chmod +x "${MOCK_ROOT}/homebrew/Cellar/go@1.23/1.23.11/bin/go"

  run_goswitch --from-mod
  assert_success
  assert_output --partial "Using Homebrew go@1.23"
  assert_output --partial "go version go1.23.11"
}
