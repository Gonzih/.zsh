# Tests and constrained environments can explicitly request a hook-free shell.
[[ ${ZSH_SKIP_INTEGRATIONS:-0} == 1 ]] && return 0

# Python and Ruby version managers.
if (( $+commands[pyenv] )); then
  eval "$(pyenv init - zsh)"
fi

if (( $+commands[rbenv] )); then
  eval "$(rbenv init - zsh)"
fi

# NVM is expensive to source. By default, load it on the first NVM-managed
# command; ZSH_LAZY_NVM=0 selects a conventional eager load.
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  if [[ ${ZSH_LAZY_NVM:-1} == 1 ]]; then
    function _zsh_load_nvm() {
      unfunction nvm node npm npx corepack _zsh_load_nvm 2>/dev/null || true
      source "$NVM_DIR/nvm.sh"
    }

    function nvm() { _zsh_load_nvm; nvm "$@" }
    function node() { _zsh_load_nvm; command node "$@" }
    function npm() { _zsh_load_nvm; command npm "$@" }
    function npx() { _zsh_load_nvm; command npx "$@" }
    function corepack() { _zsh_load_nvm; command corepack "$@" }
  else
    source "$NVM_DIR/nvm.sh"
  fi
fi

# Fish's bass plugin is unnecessary in Zsh; native scripts can be sourced.
if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi

if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

# fzf 0.48+ ships its completion and key-binding integration in one command.
if [[ ${ZSH_DISABLE_FZF:-0} != 1 ]] && (( $+commands[fzf] )) && [[ -t 0 && -t 1 ]]; then
  typeset _zsh_fzf_init
  if _zsh_fzf_init=$(fzf --zsh 2>/dev/null); then
    [[ -n $_zsh_fzf_init ]] && eval "$_zsh_fzf_init"
  fi
  unset _zsh_fzf_init
fi

# Preserve the Fish behavior of using gpg-agent for SSH, but allow an easy
# opt-out for macOS Keychain, 1Password, or another agent.
if [[ ${ZSH_USE_GPG_AGENT:-1} == 1 ]] && (( $+commands[gpgconf] )); then
  typeset _zsh_gpg_socket
  command gpgconf --launch gpg-agent 2>/dev/null || true
  _zsh_gpg_socket=$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null)
  [[ -n $_zsh_gpg_socket ]] && export SSH_AUTH_SOCK="$_zsh_gpg_socket"
  [[ -n ${TTY:-} ]] && export GPG_TTY=$TTY
  unset _zsh_gpg_socket
fi

if [[ ${ZSH_APPLY_DVORAK_LAYOUT:-0} == 1 ]]; then
  myxkbmap
fi
