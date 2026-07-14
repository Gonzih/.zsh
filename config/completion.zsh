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

# Keep compinit's ownership/permission audit and silently ignore anything it
# finds insecure. `-i` is the secure non-interactive answer to its audit prompt.
autoload -Uz compinit
compinit -i -d "$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION"
