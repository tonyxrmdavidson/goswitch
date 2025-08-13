# shellcheck shell=bash
_gs_has() { command -v "$1" >/dev/null 2>&1; }
_gs_err() { printf '%s\n' "$*" >&2; }
_gs_info() { printf '%s\n' "$*"; }
_gs_mm() { echo "$1" | awk -F. '{print $1"."$2}'; }  # e.g., 1.24.6 -> 1.24

# asdf: clean leading "*" and spaces
_gs_asdf_list_versions_clean() {
  asdf list golang 2>/dev/null | sed 's/^[[:space:]]*\*//; s/^[[:space:]]*//'
}

# brew: current unversioned "go" series (e.g., 1.24)
_gs_brew_current_series() {
  local cur_full
  cur_full="$(brew info go 2>/dev/null | awk '/^go: stable /{print $3; exit}')" || return 1
  [ -z "$cur_full" ] && return 1
  echo "$cur_full" | awk -F. '{print $1"."$2}'
}
