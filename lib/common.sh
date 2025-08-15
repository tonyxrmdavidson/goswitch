# lib/common.sh
# shellcheck shell=bash

_gs_has() { command -v "$1" >/dev/null 2>&1; }
_gs_err() { printf '%s\n' "$*" >&2; }
_gs_info() { printf '%s\n' "$*"; }
_gs_mm() { echo "$1" | awk -F. '{print $1"."$2}'; }  # e.g., 1.24.6 -> 1.24

# OS/Arch detection
_gs_uname_s() { uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]'; }
_gs_uname_m() { uname -m 2>/dev/null; }

# Returns "darwin" or "linux" (pass-through otherwise)
_gs_os() {
  local s; s="$(_gs_uname_s)"
  case "$s" in
    darwin) echo darwin ;;
    linux)  echo linux  ;;
    *)      echo "$s"   ;;
  esac
}

# Returns "amd64" or "arm64" for Go tarball naming
_gs_arch() {
  local m; m="$(_gs_uname_m)"
  case "$m" in
    x86_64|amd64) echo amd64 ;;
    aarch64|arm64) echo arm64 ;;
    *)             echo "$m"  ;;
  esac
}
