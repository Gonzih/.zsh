# This file is symlinked from ~/.zshenv by scripts/install.zsh.
# :A resolves that symlink, so the repository can live outside ~/.config/zsh.
if [[ -z ${ZDOTDIR:-} || ! -r ${ZDOTDIR}/.zshrc ]]; then
  export ZDOTDIR="${${(%):-%N}:A:h}"
fi

source "$ZDOTDIR/config/environment.zsh"

[[ -r "$ZDOTDIR/.zshenv.local" ]] && source "$ZDOTDIR/.zshenv.local"
