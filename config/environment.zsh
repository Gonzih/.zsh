# Keep this module fast and silent: .zshenv loads it for every Zsh process.
typeset -gU path PATH
typeset -a _zsh_preferred_paths

export GOPATH="${GOPATH:-$HOME/go}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export NPM_PACKAGES="${NPM_PACKAGES:-$HOME/.npm-packages}"
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"

export EDITOR="${EDITOR:-emacsclient -t}"
export VISUAL="${VISUAL:-$EDITOR}"
export ALTERNATE_EDITOR="${ALTERNATE_EDITOR:-emacs}"
export CLICOLOR="${CLICOLOR:-1}"

_zsh_preferred_paths=(
  "$HOME/.cargo/bin"
  "$HOME/.local/share/atc/shims/bin"
  "$HOME/.foundry/bin"
  "$HOME/bin"
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /opt/homebrew/opt/openjdk@17/bin
  "$HOME/Library/Application Support/Coursier/bin"
  /run/wrappers/bin
  "$HOME/.nix-profile/bin"
  /nix/var/nix/profiles/default/bin
  /run/current-system/sw/bin
  "/etc/profiles/per-user/${USER:-user}/bin"
  /usr/local/bin
  "$GOPATH/bin"
  "$HOME/.linkerd2/bin"
  "$NPM_PACKAGES/bin"
  "$HOME/.pub-cache/bin"
  "$HOME/.local/bin"
  "$HOME/.local/share/solana/install/active_release/bin"
  "$HOME/.deno/bin"
  "$BUN_INSTALL/bin"
  "$PYENV_ROOT/bin"
)

typeset -a _zsh_existing_paths
typeset _zsh_path
for _zsh_path in "${_zsh_preferred_paths[@]}"; do
  [[ -d $_zsh_path ]] && _zsh_existing_paths+=("$_zsh_path")
done
path=("${_zsh_existing_paths[@]}" "${path[@]}")

unset _zsh_preferred_paths _zsh_existing_paths _zsh_path
