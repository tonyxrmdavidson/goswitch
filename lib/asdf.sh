# shellcheck shell=bash
# Requires: common.sh

# Ensure asdf + golang plugin exist (add plugin if missing)
_gs_asdf_ensure() {
  if ! _gs_has asdf; then
    _gs_err "asdf is not installed (https://asdf-vm.com)."
    return 1
  fi
  if ! asdf plugin list 2>/dev/null | grep -qx "golang"; then
    _gs_info "Adding asdf golang plugin..."
    # Prefer community plugin
    asdf plugin add golang https://github.com/asdf-community/asdf-golang.git || return 1
  fi
  return 0
}

# Clean asdf 'golang' list output (remove leading '*' and spaces)
_gs_asdf_list_versions_clean() {
  asdf list golang 2>/dev/null | sed 's/^[[:space:]]*\*//; s/^[[:space:]]*//'
}

# List all available remote golang versions (from plugin)
_gs_asdf_list_all_remote() {
  asdf list all golang 2>/dev/null
}

# Find latest patch in a series (e.g., "1.21" -> "1.21.13") from remote index
_gs_asdf_latest_patch_for_series() {
  local mm="$1"
  _gs_asdf_list_all_remote | grep -E "^${mm}(\.|$)" | sort -V | tail -n1
}

# Install a specific version via asdf (assumes plugin exists)
_gs_asdf_install_version() {
  local ver="$1"
  _gs_info "Installing golang ${ver} via asdf..."
  asdf install golang "${ver}" || return 1
  # refresh shims; harmless even if not using shims
  asdf reshim golang || true
  return 0
}

# Activate an asdf golang version (handles both bin layouts)
_gs_activate_asdf_version() {
  local ver="$1" dir bin1 bin2 usebin
  dir="$(asdf where golang "$ver")" || return 1
  bin1="${dir}/bin/go"    # some setups
  bin2="${dir}/go/bin/go" # common layout for asdf-golang
  if [ -x "$bin1" ]; then
    usebin="$(dirname "$bin1")"
  elif [ -x "$bin2" ]; then
    usebin="$(dirname "$bin2")"
  elif [ -x "$HOME/.asdf/shims/go" ]; then
    usebin="$HOME/.asdf/shims"
  else
    _gs_err "Could not find go binary under ${dir}/bin or ${dir}/go/bin."
    return 1
  fi
  export PATH="${usebin}:${PATH}"
  hash -r 2>/dev/null || true
  return 0
}

# Public: interactive/non-interactive asdf installer
# Usage:
#   goswitch --asdf-install 1.21.13
#   goswitch --asdf-install 1.21     # installs latest patch
goswitch_asdf_install() {
  local req="$1" ver=""
  _gs_asdf_ensure || return 1

  # If 'req' is a series (x.y), find latest patch; else use as-is
  if echo "$req" | grep -Eq '^[0-9]+\.[0-9]+$'; then
    ver="$(_gs_asdf_latest_patch_for_series "$req")"
    if [ -z "$ver" ]; then
      _gs_err "Could not find a remote version for series ${req} via asdf."
      return 1
    fi
  else
    ver="$req"
  fi

  # Skip install if already present
  if _gs_asdf_list_versions_clean | grep -qx "$ver"; then
    _gs_info "asdf golang $ver is already installed."
  else
    _gs_asdf_install_version "$ver" || {
      _gs_err "asdf install failed for ${ver}."
      return 1
    }
  fi

  # Activate immediately
  if _gs_activate_asdf_version "$ver"; then
    _gs_info "Using asdf golang ${ver}: $(go version)"
    return 0
  fi
  _gs_err "Installed but could not activate asdf golang ${ver}."
  return 1
}
