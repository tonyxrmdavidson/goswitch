load 'helpers.bash'

setup() {
  setup_path_with_mocks
  source_goswitch_libs
  # Pretend Linux so asdf is preferred (works cross-OS)
  mock_cmd uname <<'EOF'
echo Linux
EOF
}

@test "activates asdf exact version if installed" {
  # asdf list shows installed 1.19.13; where points to our fake dir
  mock_cmd asdf <<'EOF'
case "$1" in
  list) echo "  *1.19.13";;
  where) echo "${MOCK_ROOT}/asdf/installs/golang/1.19.13";;
  reshim) ;;
  plugin) echo "golang";;
esac
EOF

  mkdir -p "${MOCK_ROOT}/asdf/installs/golang/1.19.13/go/bin"
  cat >"${MOCK_ROOT}/asdf/installs/golang/1.19.13/go/bin/go" <<'EOF'
echo "go version go1.19.13 linux/amd64"
EOF
  chmod +x "${MOCK_ROOT}/asdf/installs/golang/1.19.13/go/bin/go"

  run_goswitch 1.19.13
  assert_success
  assert_output --partial "Using asdf golang 1.19.13"
  assert_output --partial "go version go1.19.13"
}

@test "offers asdf install when not installed and installs latest patch for series" {
  # plugin missing → add, list all gives 1.21.13 latest in series, install creates tree
  mock_cmd asdf <<'EOF'
case "$1" in
  plugin)
    if [ "$2" = "list" ]; then exit 1; fi
    if [ "$2" = "add" ]; then exit 0; fi
    ;;
  list)
    if [ "$2" = "all" ]; then printf "%s\n" 1.21.0 1.21.13 1.22.0; exit 0; fi
    ;;
  install)
    ver="$3"
    mkdir -p "${MOCK_ROOT}/asdf/installs/golang/${ver}/go/bin"
    cat >"${MOCK_ROOT}/asdf/installs/golang/${ver}/go/bin/go" <<EOS
echo "go version go${ver} linux/amd64"
EOS
    chmod +x "${MOCK_ROOT}/asdf/installs/golang/${ver}/go/bin/go"
    ;;
  where)
    echo "${MOCK_ROOT}/asdf/installs/golang/$3"
    ;;
  reshim) ;;
esac
EOF

  run_goswitch --asdf-install 1.21
  assert_success
  assert_output --partial "Installing golang 1.21.13 via asdf"
  assert_output --partial "Using asdf golang 1.21.13"
}
