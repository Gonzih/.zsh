#!/usr/bin/env zsh

emulate -LR zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

typeset -r root=${0:A:h:h}
typeset -r temporary_base=${TMPDIR:-/tmp}
typeset -r temporary_home=$(command mktemp -d "${temporary_base%/}/zsh-config.XXXXXX")
trap 'command rm -rf -- "$temporary_home"' EXIT INT TERM

function fail() {
  print -u2 -- "check failed: $*"
  return 1
}

print -- 'syntax: zsh -n'
typeset file
for file in \
  "$root/.zshenv" \
  "$root/.zprofile" \
  "$root/.zshrc" \
  "$root"/completions/* \
  "$root"/config/*.zsh \
  "$root"/functions/* \
  "$root"/scripts/*.zsh \
  "$root"/tests/*.zsh; do
  [[ -f $file ]] && zsh -n "$file"
done

function check_mode() {
  local mode=$1
  HOME="$temporary_home" \
  XDG_CACHE_HOME="$temporary_home/cache" \
  XDG_STATE_HOME="$temporary_home/state" \
  XDG_DATA_HOME="$temporary_home/data" \
  LC_ALL=C \
  ZDOTDIR="$root" \
  ZSH_KEYMAP="$mode" \
  ZSH_SKIP_PLUGINS=1 \
  ZSH_SKIP_INTEGRATIONS=1 \
  ZSH_USE_GPG_AGENT=0 \
    zsh -dfi -c '
      source "$ZDOTDIR/.zshenv"
      source "$ZDOTDIR/.zshrc"
      _zsh_prompt_build 7
      [[ $PROMPT == *✘* ]] || exit 21
      [[ -n $HISTFILE && $HISTFILE == $XDG_STATE_HOME/* ]] || exit 22
      [[ ${_comps[tm]:-} == _tm && ${_comps[note]:-} == _note ]] || exit 48

      case $ZSH_KEYMAP in
        emacs)
          [[ $(bindkey -M emacs "^P") == *up-line-or-beginning-search* ]] || exit 23
          ;;
        vi)
          [[ $(bindkey -M vicmd h) == *vi-backward-char* ]] || exit 24
          ;;
        dvorak)
          [[ $(bindkey -M vicmd d) == *vi-backward-char* ]] || exit 25
          [[ $(bindkey -M vicmd t) == *up-line-or-beginning-search* ]] || exit 26
          [[ $(bindkey -M vicmd h) == *down-line-or-beginning-search* ]] || exit 27
          [[ $(bindkey -M vicmd n) == *vi-forward-char* ]] || exit 28
          [[ $(bindkey -M vicmd jj) == *kill-whole-line* ]] || exit 29
          [[ $(bindkey -M viins "^C") == *vi-cmd-mode* ]] || exit 34
          [[ $(bindkey -M vicmd "^D") == *_zsh_exit_shell* ]] || exit 35
          [[ $(bindkey -M vicmd J) == *_zsh_dvorak_delete_at_eol* ]] || exit 36
          [[ $(bindkey -M vicmd j) != *vi-delete* ]] || exit 37
          [[ $(bindkey -M visual l) == *_zsh_dvorak_visual_clear* ]] || exit 38
          [[ $(bindkey -M visual h) == *down-line* ]] || exit 39
          [[ $(bindkey -M visual t) == *up-line* ]] || exit 40
          _ZSH_VI_STATE=N
          _zsh_prompt_update_mode
          [[ $PROMPT == *" N "* ]] || exit 33
          ;;
      esac
    ' || fail "startup in $mode mode"
}

print -- 'startup: emacs, vi, and Programmer Dvorak modes'
check_mode emacs
check_mode vi
check_mode dvorak

print -- 'security: hostile Git branch names cannot execute through PROMPT'
typeset -r prompt_probe_repo=$temporary_home/prompt-probe
typeset -r prompt_probe_marker=$temporary_home/prompt-injection-ran
command mkdir -p -- "$prompt_probe_repo"
command git -C "$prompt_probe_repo" init --quiet
command git -C "$prompt_probe_repo" checkout --quiet -b '$(_zsh_prompt_injection_probe)'
HOME="$temporary_home" \
XDG_CACHE_HOME="$temporary_home/cache" \
XDG_STATE_HOME="$temporary_home/state" \
XDG_DATA_HOME="$temporary_home/data" \
ZDOTDIR="$root" \
ZSH_SKIP_PLUGINS=1 \
ZSH_SKIP_INTEGRATIONS=1 \
PROMPT_PROBE="$prompt_probe_marker" \
  zsh -dfi -c '
    source "$ZDOTDIR/.zshenv"
    source "$ZDOTDIR/.zshrc"
    function _zsh_prompt_injection_probe() { : >| "$PROMPT_PROBE" }
    cd "$1"
    _zsh_prompt_build 0
    print -P -- "$PROMPT" >/dev/null
    [[ ! -e $PROMPT_PROBE ]] || exit 30
  ' _ "$prompt_probe_repo" || fail 'Git branch prompt-injection regression'

print -- 'security: insecure completion directories are ignored'
typeset -r insecure_completion_dir=$temporary_home/insecure-completions
command mkdir -p -- "$insecure_completion_dir"
command chmod 0777 "$insecure_completion_dir"
command touch "$insecure_completion_dir/_unsafe"
HOME="$temporary_home" \
XDG_CACHE_HOME="$temporary_home/insecure-cache" \
XDG_STATE_HOME="$temporary_home/state" \
XDG_DATA_HOME="$temporary_home/data" \
ZDOTDIR="$root" \
ZSH_SKIP_PLUGINS=1 \
ZSH_SKIP_INTEGRATIONS=1 \
  zsh -dfi -c '
    source "$ZDOTDIR/.zshenv"
    fpath=("$1" $fpath)
    source "$ZDOTDIR/.zshrc"
    [[ ${_comps[unsafe]:-} != _unsafe ]] || exit 50
  ' _ "$insecure_completion_dir" || fail 'insecure completion-path regression'

print -- 'navigation: p/n rotate backward and forward'
command mkdir -p -- "$temporary_home/dirs/a" "$temporary_home/dirs/b" "$temporary_home/dirs/c"
HOME="$temporary_home" \
XDG_CACHE_HOME="$temporary_home/cache" \
XDG_STATE_HOME="$temporary_home/state" \
XDG_DATA_HOME="$temporary_home/data" \
ZDOTDIR="$root" \
ZSH_SKIP_PLUGINS=1 \
ZSH_SKIP_INTEGRATIONS=1 \
  zsh -dfi -c '
    source "$ZDOTDIR/.zshenv"
    source "$ZDOTDIR/.zshrc"
    cd "$1/a"
    cd "$1/b"
    cd "$1/c"
    p
    [[ $PWD == "$1/b" ]] || exit 31
    n
    [[ $PWD == "$1/c" ]] || exit 32
  ' _ "$temporary_home/dirs" || fail 'directory stack navigation'

print -- 'startup: non-interactive shell stays silent'
typeset noninteractive_output
noninteractive_output=$(
  HOME="$temporary_home" \
  XDG_CACHE_HOME="$temporary_home/cache" \
  XDG_STATE_HOME="$temporary_home/state" \
  XDG_DATA_HOME="$temporary_home/data" \
  ZDOTDIR="$root" \
  ZSH_SKIP_PLUGINS=1 \
  ZSH_SKIP_INTEGRATIONS=1 \
    zsh -dfc 'source "$ZDOTDIR/.zshenv"; source "$ZDOTDIR/.zshrc"'
)
[[ -z $noninteractive_output ]] || fail 'non-interactive startup emitted output'

print -- 'security: completion audits remain enabled'
if command grep -Eq 'compinit[[:space:]]+(-u|-C)' "$root/config/completion.zsh"; then
  fail 'completion config bypasses compaudit'
fi

command grep -Eq 'pin:[0-9a-f]{40}' "$root/plugins/pre.txt" || fail 'pre plugin is not pinned'
command grep -Eq 'pin:[0-9a-f]{40}' "$root/plugins/fzf.txt" || fail 'fzf plugin is not pinned'
[[ $(command grep -Ec 'pin:[0-9a-f]{40}' "$root/plugins/post.txt") == 2 ]] || fail 'post plugins are not pinned'

print -- 'all checks passed'
