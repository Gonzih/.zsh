alias g='git'
alias gadd='git add --patch'
alias gci='git commit --verbose'
alias h='hg'

alias e='emacsclient -t'
alias et='emacsclient -t'
alias emacs-daemon='emacs --daemon'
alias emacs-stop-daemon="emacsclient -e '(kill-emacs)'"

alias tailf='tail -f'
alias k='kubectl'
alias kx='kubectx'
alias kns='kubens'

alias be='bundle exec'
alias bi='bundle install --binstubs=.bin --path vendor/bundle'
alias bu='bundle update'

alias nix-install='nix-env --install'
alias nix-list="nix-env -q '*'"

if (( $+functions[compdef] )); then
  if [[ -n ${_comps[git]:-} ]]; then
    compdef g=git
    compdef gadd=git
    compdef gci=git
  fi
  [[ -n ${_comps[hg]:-} ]] && compdef h=hg
  [[ -n ${_comps[kubectl]:-} ]] && compdef k=kubectl
fi
