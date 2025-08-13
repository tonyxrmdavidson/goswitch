# Bash completion for goswitch
_goswitch_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local versions=""

  if command -v goswitch >/dev/null 2>&1; then
    # Use internal helpers via a subshell to avoid polluting current env
    local root
    root="$(dirname "$(dirname "$(command -v goswitch)")")"
    . "$root/lib/common.sh"
    . "$root/lib/brew.sh"

    if _gs_has brew; then versions="$versions $(_gs_brew_all_series)"; fi
    if _gs_has asdf; then versions="$versions $(_gs_asdf_list_versions_clean)"; fi
  fi
  COMPREPLY=( $(compgen -W "$versions" -- "$cur") )
  return 0
}
complete -F _goswitch_completions goswitch
