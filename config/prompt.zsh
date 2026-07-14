zmodload zsh/parameter

# Byte escapes remain valid even when a minimal environment starts in C locale.
typeset -g ZSH_PROMPT_SEPARATOR=${ZSH_PROMPT_SEPARATOR:-$'\xEE\x82\xB0'}
typeset -g ZSH_PROMPT_DEFAULT_USER=${ZSH_PROMPT_DEFAULT_USER:-${USER:-}}
typeset -g _ZSH_PLATFORM_CONTEXT
typeset -g _ZSH_PROMPT_BG=NONE
typeset -g _ZSH_PROMPT_ESCAPED
typeset -g _ZSH_PROMPT_BODY

case $OSTYPE in
  darwin*)
    _ZSH_PLATFORM_CONTEXT="macOS $(command sw_vers -productVersion 2>/dev/null)"
    ;;
  linux*)
    _ZSH_PLATFORM_CONTEXT="linux $(command uname -r 2>/dev/null)"
    ;;
  *)
    _ZSH_PLATFORM_CONTEXT="zsh $ZSH_VERSION"
    ;;
esac

function _zsh_prompt_escape() {
  _ZSH_PROMPT_ESCAPED=${1//\%/%%}
}

function _zsh_prompt_segment() {
  local bg=$1 fg=$2 text=$3

  if [[ $_ZSH_PROMPT_BG == NONE ]]; then
    REPLY+="%K{$bg}%F{$fg} $text "
  elif [[ $_ZSH_PROMPT_BG == $bg ]]; then
    REPLY+="%F{$fg}$text "
  else
    REPLY+="%K{$bg}%F{$_ZSH_PROMPT_BG}${ZSH_PROMPT_SEPARATOR}%F{$fg} $text "
  fi

  _ZSH_PROMPT_BG=$bg
}

function _zsh_prompt_git() {
  local branch dirty

  command git rev-parse --is-inside-work-tree &>/dev/null || return 1
  branch=$(command git symbolic-ref --quiet --short HEAD 2>/dev/null) || \
    branch=$(command git rev-parse --short HEAD 2>/dev/null) || return 1
  _zsh_prompt_escape "$branch"
  branch=$_ZSH_PROMPT_ESCAPED

  dirty=$(command git status --porcelain --ignore-submodules=dirty 2>/dev/null)
  if [[ -n $dirty ]]; then
    _zsh_prompt_segment yellow black " $branch ±"
  else
    _zsh_prompt_segment green black " $branch"
  fi
}

function _zsh_prompt_context() {
  local output version

  if [[ -f Cargo.toml ]] && (( $+commands[rustc] )); then
    output=$(command rustc --version 2>/dev/null)
    version=${${(z)output}[2]:-}
    [[ -n $version ]] && print -r -- "rust $version" && return
  elif [[ -f go.mod ]] && (( $+commands[go] )); then
    output=$(command go version 2>/dev/null)
    version=${${(z)output}[3]#go}
    [[ -n $version ]] && print -r -- "go $version" && return
  fi

  print -r -- "$_ZSH_PLATFORM_CONTEXT"
}

function _zsh_prompt_tail() {
  local bg label

  if [[ $ZSH_KEYMAP == vi || $ZSH_KEYMAP == dvorak ]]; then
    case ${_ZSH_VI_STATE:-I} in
      N) bg=red; label=N ;;
      V) bg=magenta; label=V ;;
      *) bg=green; label=I ;;
    esac
    REPLY="%K{$bg}%F{black}${ZSH_PROMPT_SEPARATOR}%F{black} $label %k%F{$bg}${ZSH_PROMPT_SEPARATOR}%f "
  else
    REPLY="%k%F{black}${ZSH_PROMPT_SEPARATOR}%f "
  fi
}

function _zsh_prompt_update_mode() {
  _zsh_prompt_tail
  PROMPT="${_ZSH_PROMPT_BODY}${REPLY}"
}

function _zsh_prompt_build() {
  local last_status=$1 context
  REPLY=''
  _ZSH_PROMPT_BG=NONE

  (( last_status != 0 )) && _zsh_prompt_segment black red '✘'
  (( EUID == 0 )) && _zsh_prompt_segment black yellow '⚡'
  (( ${#jobstates} > 0 )) && _zsh_prompt_segment black cyan '⊛'

  if [[ ${ZSH_PROMPT_SHOW_USER:-0} == 1 || ${USER:-} != $ZSH_PROMPT_DEFAULT_USER || -n ${SSH_CLIENT:-} || -n ${SSH_CONNECTION:-} ]]; then
    _zsh_prompt_escape "${USER:-unknown}"
    _zsh_prompt_segment black white "$_ZSH_PROMPT_ESCAPED"
    _zsh_prompt_segment white black 'λ'
    _zsh_prompt_escape "${HOST%%.*}"
    _zsh_prompt_segment black white "$_ZSH_PROMPT_ESCAPED"
  fi

  _zsh_prompt_segment blue black '%~'
  _zsh_prompt_git || true

  context=$(_zsh_prompt_context)
  _zsh_prompt_escape "$context"
  _zsh_prompt_segment black white "$_ZSH_PROMPT_ESCAPED"

  _ZSH_PROMPT_BODY=$REPLY
  _zsh_prompt_update_mode
  RPROMPT=''
}

function _zsh_prompt_precmd() {
  local last_status=$?
  _zsh_prompt_build "$last_status"
}

typeset -ga precmd_functions
precmd_functions=(_zsh_prompt_precmd ${precmd_functions:#_zsh_prompt_precmd})
