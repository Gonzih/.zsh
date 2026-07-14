zmodload zsh/complist
fpath=("$ZDOTDIR/completions" $fpath)

zstyle ':completion:*' use-cache true
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/completion"
zstyle ':completion:*' completer _complete _match _approximate
if [[ -n ${LS_COLORS:-} ]]; then
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
fi
zstyle ':completion:*' menu no
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:corrections' format '%F{yellow}-- %d (%e errors) --%f'
zstyle ':completion:*:messages' format '%F{magenta}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'
zstyle ':fzf-tab:*' fzf-flags --height=60% --layout=reverse --border
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -la --color=always $realpath 2>/dev/null || ls -la $realpath'
zstyle ':fzf-tab:complete:kill:*' fzf-preview 'ps -p $word -o command 2>/dev/null'

# Refuse insecure completion paths without disabling compinit's audit. This is
# Untrusted entries are removed rather than accepted through compinit's bypass
# flag, then the remaining path is audited normally.
autoload -Uz compaudit compinit
typeset -a _zsh_insecure_completion_paths _zsh_insecure_completion_dirs
_zsh_insecure_completion_paths=(${(f)"$(compaudit 2>/dev/null)"})
if (( ${#_zsh_insecure_completion_paths} )); then
  typeset _zsh_insecure_path
  for _zsh_insecure_path in "${_zsh_insecure_completion_paths[@]}"; do
    if [[ -d $_zsh_insecure_path ]]; then
      _zsh_insecure_completion_dirs+=("$_zsh_insecure_path")
    else
      _zsh_insecure_completion_dirs+=("${_zsh_insecure_path:h}")
    fi
  done
  typeset -aU _zsh_insecure_completion_dirs
  typeset -a _zsh_safe_fpath
  typeset _zsh_fpath_entry _zsh_insecure_dir _zsh_fpath_entry_abs _zsh_insecure_dir_abs
  for _zsh_fpath_entry in "${fpath[@]}"; do
    _zsh_fpath_entry_abs=${_zsh_fpath_entry:A}
    typeset _zsh_fpath_is_safe=1
    for _zsh_insecure_dir in "${_zsh_insecure_completion_dirs[@]}"; do
      _zsh_insecure_dir_abs=${_zsh_insecure_dir:A}
      if [[ $_zsh_fpath_entry_abs == "$_zsh_insecure_dir_abs" || $_zsh_fpath_entry_abs == "$_zsh_insecure_dir_abs"/* ]]; then
        _zsh_fpath_is_safe=0
        break
      fi
    done
    (( _zsh_fpath_is_safe )) && _zsh_safe_fpath+=("$_zsh_fpath_entry")
  done
  fpath=("${_zsh_safe_fpath[@]}")

  if [[ -t 2 && ${ZSH_SILENCE_COMPAUDIT_WARNING:-0} != 1 ]]; then
    print -u2 -- "zsh: ignored insecure completion paths: ${(j:, :)_zsh_insecure_completion_dirs}"
  fi
fi

compinit -d "$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION"

unset _zsh_insecure_completion_paths _zsh_insecure_completion_dirs _zsh_insecure_path
unset _zsh_safe_fpath _zsh_fpath_entry _zsh_insecure_dir _zsh_fpath_entry_abs _zsh_insecure_dir_abs _zsh_fpath_is_safe
