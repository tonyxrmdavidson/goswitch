load 'helpers.bash'

setup() {
  setup_path_with_mocks
  source_goswitch_libs
  mock_cmd uname <<'EOF'
echo Linux
EOF
}

@test "--tar-install installs to ~/.local/goversions and activates" {
  # Mock curl (no-op) and tar (create expected tree)
  mock_cmd curl <<'EOF'
exit 0
EOF
  mock_cmd tar <<'EOF'
# emulate: tar -C <dest> -xzf ...
for i in "$@"; do
  if [ "$i" = "-C" ]; then shift; dest="$1"; fi
done
mkdir -p "${dest}/go/bin"
cat >"${dest}/go/bin/go" <<G
echo "go version go1.20.14 linux/amd64"
G
chmod +x "${dest}/go/bin/go"
EOF

  run_goswitch --tar-install 1.20.14
  assert_success
  assert_output --partial "Using tarball Go 1.20.14"
  assert_output --partial "go version go1.20.14"
}
