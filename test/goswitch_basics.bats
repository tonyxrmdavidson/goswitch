load 'helpers.bash'

setup() {
  setup_path_with_mocks
  source_goswitch_libs
}

@test "prints help with -h" {
  run_goswitch -h
  assert_success
  assert_output --partial "goswitch - switch Go versions"
}

@test "_gs_mm parses major.minor from semver" {
  result="$(_gs_mm 1.24.6)"
  [ "$result" = "1.24" ]
}
