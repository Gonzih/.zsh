#!/usr/bin/env zsh

emulate -LR zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

typeset -r root=${0:A:h:h}
typeset -r antidote_dir=${XDG_DATA_HOME:-$HOME/.local/share}/zsh/antidote
typeset -r temporary_base=${TMPDIR:-/tmp}
typeset -r temporary_bin=$(command mktemp -d "${temporary_base%/}/zsh-fzf.XXXXXX")
trap 'command rm -rf -- "$temporary_bin"' EXIT INT TERM

[[ -r "$antidote_dir/functions/antidote" ]] || {
  print -u2 -- "plugin check failed: Antidote is missing at $antidote_dir"
  exit 1
}

print -- 'plugins: pinned bundles and widget order'
command ln -s -- "${commands[true]}" "$temporary_bin/fzf"
PATH="$temporary_bin:$PATH" \
ZDOTDIR="$root" \
ZSH_KEYMAP=emacs \
ZSH_SKIP_INTEGRATIONS=1 \
ZSH_USE_GPG_AGENT=0 \
  zsh -dfi -c '
    source "$ZDOTDIR/.zshenv"
    source "$ZDOTDIR/.zshrc"

    [[ $(bindkey "^I") == *fzf-tab-complete* ]] || exit 41
    (( ${+functions[_zsh_autosuggest_start]} )) || exit 42
    (( ${+functions[_zsh_highlight]} )) || exit 43
    [[ ! -o promptsubst ]] || exit 44
  '

print -- 'plugins: stock Tab fallback without fzf'
ZDOTDIR="$root" \
ZSH_KEYMAP=emacs \
ZSH_DISABLE_FZF=1 \
ZSH_SKIP_INTEGRATIONS=1 \
ZSH_USE_GPG_AGENT=0 \
  zsh -dfi -c '
    source "$ZDOTDIR/.zshenv"
    source "$ZDOTDIR/.zshrc"

    [[ $(bindkey "^I") != *fzf-tab-complete* ]] || exit 45
    (( ${+functions[_zsh_autosuggest_start]} )) || exit 46
    (( ${+functions[_zsh_highlight]} )) || exit 47
  '

print -- 'plugin checks passed'
