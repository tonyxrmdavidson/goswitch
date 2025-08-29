#!/usr/bin/env bash
# lib/brew.sh
# Requires lib/common.sh first.

_gs_os() { uname -s | tr '[:upper:]' '[:lower:]'; }

_gs_brew_series_available() {
  local mm="$1"
  brew info --json=v2 "go@${mm}" >/dev/null 2>&1
}

_gs_brew_installed_series() {
  brew list --versions go go@1.20 go@1.21 go@1.22 go@1.23 go@1.24 2>/dev/null \
    | awk '{print $1,$2}' \
    | awk '
        $1 ~ /^go@/ { sub(/^go@/, "", $1); print $1; next }
        $1 == "go" { split($2,a,"."); print a[1]"."a[2] }
      ' | sort -Vu
}

# IMPORTANT: verify using explicit path, not `command -v go` (which may be an asdf shim).
_gs_activate_brew_series() {
  local mm="$1"
  local brew_prefix="/opt/homebrew"  # Apple Silicon default; Linuxbrew will differ

  # Allow brew to tell us its prefix (portable)
  if command -v brew >/dev/null 2>&1; then
    brew_prefix="$(brew --prefix)"
  fi

  # Ensure requested series is installed (or the generic go)
  if ! brew list --versions "go@${mm}" >/dev/null 2>&1 && ! brew list --versions go >/dev/null 2>&1; then
    _gs_err "Homebrew go@${mm} is not installed."
    return 1
  fi

  # Unlink all known kegs quietly
  brew unlink go go@1.20 go@1.21 go@1.22 go@1.23 go@1.24 >/dev/null 2>&1 || true

  # Link requested series
  if ! brew link --overwrite --force "go@${mm}" >/dev/null 2>&1; then
    # Try generic go as fallback (e.g., when mm corresponds to the unversioned formula)
    brew link --overwrite --force go >/dev/null 2>&1 || true
  fi

  # Clear shell cache (for *this* process)
  hash -r

  # Verify by inspecting the fixed symlink path, not PATH
  local link_path="${brew_prefix}/bin/go"
  local target
  target="$(readlink "$link_path" 2>/dev/null || true)"

  # Preferred success: the symlink points at Cellar/go@<mm>/.../bin/go
  if echo "$target" | grep -q "Cellar/go@${mm}/"; then
    return 0
  fi

  # Fallback: even if the symlink is generic, confirm the version matches mm
  if "$link_path" version 2>/dev/null | grep -q "go${mm}\."; then
    return 0
  fi

  _gs_err "Homebrew activation didn’t result in go@${mm} at ${link_path}."
  return 1
}

goswitch_brew_switch() {
  local req="$1" mm
  mm="$(_gs_mm "$req")"
  if brew list --versions "go@${mm}" >/dev/null 2>&1 || brew list --versions go >/dev/null 2>&1; then
    _gs_activate_brew_series "$mm"
  else
    return 1
  fi
}

goswitch_brew_install() {
  local req="${1:-}"
  local mm
  if [ -n "$req" ]; then
    mm="$(_gs_mm "$req")"
    if ! _gs_brew_series_available "$mm"; then
      _gs_err "Homebrew has no formula for go@${mm} on this system."
      return 1
    fi
    brew install "go@${mm}" || return 1
    _gs_activate_brew_series "$mm"
    return $?
  fi
  local installed
  installed="$(_gs_brew_installed_series | tr '\n' ' ')"
  echo "Homebrew installed series:"
  if [ -n "$installed" ]; then
    echo "$installed" | tr ' ' '\n'
  else
    echo "(none)"
  fi
  echo
  echo "Tip: run 'goswitch 1.xx' to switch directly once installed."
}
