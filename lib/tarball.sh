# shellcheck shell=bash
# Requires: common.sh

# Base dir for user installs
_gs_tar_root() { echo "${HOME}/.local/goversions"; }

# OS/Arch detection helpers are in common.sh: _gs_os, _gs_arch

# Tarball URL for official Go
_gs_tar_url() {
  local ver="$1" os arch
  os="$(_gs_os)"; arch="$(_gs_arch)"
  echo "https://go.dev/dl/go${ver}.${os}-${arch}.tar.gz"
}

# Install tarball for version into ~/.local/goversions/<ver>/go
_gs_tar_install() {
  local ver="$1" url root dest tmp
  root="$(_gs_tar_root)"
  dest="${root}/${ver}"
  mkdir -p "$dest"
  url="$(_gs_tar_url "$ver")"
  tmp="$(mktemp -d)"
  _gs_info "Downloading $url"
  if ! curl -fsSL "$url" -o "${tmp}/go.tgz"; then
    _gs_err "Download failed: $url"; rm -rf "$tmp"; return 1
  fi
  rm -rf "${dest}/go"
  _gs_info "Extracting to ${dest}"
  if ! tar -C "$dest" -xzf "${tmp}/go.tgz"; then
    _gs_err "Extraction failed"; rm -rf "$tmp"; return 1
  fi
  rm -rf "$tmp"
  return 0
}

# Is tarball version installed?
_gs_tar_installed() {
  local ver="$1" root
  root="$(_gs_tar_root)"
  [ -x "${root}/${ver}/go/bin/go" ]
}

# Activate a tarball install (prepend PATH)
_gs_tar_activate() {
  local ver="$1" root bindir
  root="$(_gs_tar_root)"
  bindir="${root}/${ver}/go/bin"
  if [ ! -x "${bindir}/go" ]; then
    _gs_err "Tarball go not found at ${bindir}/go"; return 1
  fi
  export PATH="${bindir}:${PATH}"
  hash -r 2>/dev/null || true
  return 0
}

# List installed tarball versions
_gs_tar_list_installed() {
  local root; root="$(_gs_tar_root)"
  [ -d "$root" ] || return 0
  find "$root" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2>/dev/null | sort -V
}

# Pick best patch in a series (e.g., series 1.21 -> 1.21.13)
_gs_tar_best_match_in_series() {
  local mm="$1" root; root="$(_gs_tar_root)"
  [ -d "$root" ] || return 1
  find "$root" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2>/dev/null \
    | grep -E "^${mm}(\.|$)" | sort -V | tail -n1
}
