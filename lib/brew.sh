# shellcheck shell=bash
# Requires: common.sh

# Is go@<mm> available & NOT disabled?
_gs_brew_series_available() {
  local mm="$1" info
  info="$(brew info "go@${mm}" 2>&1)" || return 1
  echo "$info" | grep -qi 'disabled because' && return 1
  return 0
}

# List installed series (adds unversioned 'go' series)
_gs_brew_installed_series() {
  local out full cur_mm
  out="$(brew list --versions 2>/dev/null | awk '/^go@[0-9]+\.[0-9]+/ {sub(/^go@/,"",$1); print $1}' | sort -V)"
  [ -n "$out" ] && echo "$out"
  if brew list --versions go >/dev/null 2>&1; then
    full="$(brew list --versions go 2>/dev/null | awk '{print $2}' | tail -n1)"
    cur_mm="$(echo "$full" | awk -F. '{print $1"."$2}')"
    if ! echo "$out" | grep -qx "$cur_mm"; then echo "$cur_mm"; fi
  fi
}

# All available series (strict) + current unversioned 'go' series
_gs_brew_all_series() {
  local series cur_mm
  series="$(brew search go@ 2>/dev/null | grep -E '^go@[0-9]+\.[0-9]+$' | sed -E 's/^go@//' | sort -V)"
  [ -n "$series" ] && echo "$series"
  cur_mm="$(_gs_brew_current_series 2>/dev/null)"
  if [ -n "$cur_mm" ] && ! echo "$series" | grep -qx "$cur_mm"; then echo "$cur_mm"; fi
}

# Not installed series
_gs_brew_not_installed_series() {
  local all installed s mm
  all="$(_gs_brew_all_series)"
  installed="$(_gs_brew_installed_series)"
  s="|$(echo "$installed" | tr ' \n' '||')"
  echo "$all" | while IFS= read -r mm; do
    [ -n "$mm" ] || continue
    case "$s" in *"|$mm|"*) ;; *) echo "$mm" ;; esac
  done
}

# Activate series (supports go@<mm> and unversioned 'go' when it matches)
_gs_activate_brew_series() {
  local mm="$1" prefix bin cur_mm
  if brew --prefix "go@${mm}" >/dev/null 2>&1; then
    prefix="$(brew --prefix "go@${mm}")" || return 1
  else
    cur_mm="$(_gs_brew_current_series 2>/dev/null)" || return 1
    if [ "$cur_mm" = "$mm" ] && brew --prefix go >/dev/null 2>&1; then
      prefix="$(brew --prefix go)" || return 1
    else
      return 1
    fi
  fi
  bin="${prefix}/bin"
  [ -x "${bin}/go" ] || return 1
  export PATH="${bin}:${PATH}"
  hash -r 2>/dev/null || true
  return 0
}

# Interactive installer
goswitch_brew_install() {
  if ! _gs_has brew; then _gs_err "Homebrew not found."; return 1; fi
  local not_installed_list line
  not_installed_list="$(_gs_brew_not_installed_series)"
  if [ -z "$not_installed_list" ]; then _gs_info "All discovered Homebrew go@ series are already installed."; return 0; fi

  local -a arr; arr=()
  while IFS= read -r line; do [ -n "$line" ] && arr=("${arr[@]}" "$line"); done <<EOF
$not_installed_list
EOF

  _gs_info "Homebrew Go series NOT installed:"
  local i
  for i in "${!arr[@]}"; do printf "  [%d] go@%s\n" "$((i+1))" "${arr[$i]}"; done

  local choice
  while :; do
    read -r -p "Select a number to install (or 'q' to cancel): " choice
    case "$choice" in
      [Qq]) _gs_info "Cancelled."; return 1 ;;
      ''|*[!0-9]*) _gs_err "Invalid selection."; continue ;;
      *) [ "$choice" -ge 1 ] && [ "$choice" -le "${#arr[@]}" ] && break || _gs_err "Invalid selection." ;;
    esac
  done

  local mm="${arr[$((choice-1))]}"
  read -r -p "Install Homebrew go@${mm}? [Y/n] " ans; ans="${ans:-Y}"
  case "$ans" in
    [Yy]*)
      if _gs_brew_series_available "$mm"; then
        _gs_info "Installing go@${mm} via Homebrew..."; brew install "go@${mm}" || { _gs_err "Homebrew install failed."; return 1; }
      else
        local cur_mm="$(_gs_brew_current_series 2>/dev/null)"
        if [ "$cur_mm" = "$mm" ]; then _gs_info "Installing current 'go' ($cur_mm) via Homebrew..."; brew install go || { _gs_err "Homebrew install failed."; return 1; }
        else _gs_err "Homebrew go@${mm} unavailable/disabled, and 'go' is $cur_mm."; return 1; fi
      fi
      _gs_activate_brew_series "$mm" || { _gs_err "Installed but could not activate go@${mm}."; return 1; }
      _gs_info "Activated Homebrew go@${mm}: $(go version)"
      ;;
    *) _gs_info "Cancelled."; return 1 ;;
  esac
}
