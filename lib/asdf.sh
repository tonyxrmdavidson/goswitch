#!/usr/bin/env bash
# lib/asdf.sh
# Requires lib/common.sh first.

# ---------- asdf CLI compatibility ----------

_gs_asdf_has_set() {
  asdf help 2>&1 | grep -qE '\basdf set\b'
}

_gs_asdf_ensure_plugin() {
  asdf plugin list 2>/dev/null | grep -qx 'golang' || asdf plugin add golang >/dev/null 2>&1 || true
}

_gs_asdf_set_home_version() {
  local ver="$1"
  _gs_asdf_ensure_plugin
  if _gs_asdf_has_set; then
    asdf set --home golang "$ver" >/dev/null 2>&1
  else
    asdf global golang "$ver" >/dev/null 2>&1
  fi
  asdf reshim golang >/dev/null 2>&1 || true
}

_gs_asdf_set_local_version() {
  local ver="$1"
  _gs_asdf_ensure_plugin
  if _gs_asdf_has_set; then
    asdf set golang "$ver" >/dev/null 2>&1
  else
    asdf local golang "$ver" >/dev/null 2>&1
  fi
  asdf reshim golang >/dev/null 2>&1 || true
}

_gs_asdf_set_system_home() {
  _gs_asdf_set_home_version "system"
}

# ---------- query utilities ----------

_gs_asdf_list_versions_clean() {
  _gs_asdf_ensure_plugin
  asdf list golang 2>/dev/null \
    | sed -e 's/^[[:space:]]*//' -e 's/*[[:space:]]*//' \
    | grep -E '^[0-9]+(\.[0-9]+){1,2}$' || true
}

_gs_asdf_latest_in_series() {
  local mm="$1"
  _gs_asdf_ensure_plugin
  asdf list all golang "$mm" 2>/dev/null \
    | grep -E "^${mm}\.[0-9]+$" \
    | sort -V | tail -n1
}

_gs_asdf_where() {
  local ver="$1"
  asdf where golang "$ver" 2>/dev/null || true
}

# ---------- activation & install ----------

# Find an executable go binary inside an asdf install dir.
# Tries both "<dir>/bin/go" and "<dir>/go/bin/go".
_gs_asdf_bin_for_dir() {
  local dir="$1"
  if [ -x "${dir}/bin/go" ]; then
    echo "${dir}/bin/go"
  elif [ -x "${dir}/go/bin/go" ]; then
    echo "${dir}/go/bin/go"
  else
    echo ""
  fi
}

_gs_activate_asdf_version() {
  local ver="$1"
  local dir bin
  dir="$(_gs_asdf_where "$ver")"
  [ -n "$dir" ] || { _gs_err "asdf golang ${ver} is not installed."; return 1; }
  bin="$(_gs_asdf_bin_for_dir "$dir")"
  [ -n "$bin" ] || { _gs_err "asdf golang ${ver} has no go binary under ${dir} (looked for bin/go and go/bin/go)."; return 1; }
  "$bin" version >/dev/null 2>&1 || { _gs_err "Installed asdf golang ${ver} failed to execute."; return 1; }
  return 0
}

goswitch_asdf_install() {
  local req="$1" exact="" mm dir bin
  _gs_asdf_ensure_plugin

  case "$req" in
    *.*.*) exact="$req" ;;
    *)     mm="$(_gs_mm "$req")"; exact="$(_gs_asdf_latest_in_series "$mm")" ;;
  esac
  [ -n "$exact" ] || { _gs_err "Could not resolve a version for ${req}."; return 1; }

  if [ -z "$(_gs_asdf_where "$exact")" ]; then
    _gs_info "Installing golang ${exact} via asdf..."
    asdf install golang "$exact" || { _gs_err "asdf install failed for ${exact}."; return 1; }
  fi

  # Persist selection (local if in a repo, else home)
  if [ -f ".tool-versions" ] || git rev-parse --show-toplevel >/dev/null 2>&1; then
    _gs_asdf_set_local_version "$exact"
  else
    _gs_asdf_set_home_version "$exact"
  fi

  dir="$(_gs_asdf_where "$exact")"
  bin="$(_gs_asdf_bin_for_dir "$dir")"
  _gs_info "Using asdf golang ${exact}: $("$bin" version 2>/dev/null)"
  return 0
}
