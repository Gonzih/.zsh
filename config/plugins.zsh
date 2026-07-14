typeset -g ANTIDOTE_INSTALL="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/antidote"
typeset -gx ANTIDOTE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}/antidote"

if [[ ${ZSH_SKIP_PLUGINS:-0} == 1 || ! -r "$ANTIDOTE_INSTALL/functions/antidote" ]]; then
  function zsh_plugins_load_pre() { return 0 }
  function zsh_plugins_load_fzf_tab() { return 0 }
  function zsh_plugins_load_post() { return 0 }

  if [[ ${ZSH_SKIP_PLUGINS:-0} != 1 ]]; then
    print -u2 -- "zsh: plugins are not installed; run $ZDOTDIR/scripts/install.zsh"
  fi
else
  fpath=("$ANTIDOTE_INSTALL/functions" $fpath)
  autoload -Uz antidote

  function zsh_plugins_load_pre() {
    antidote load \
      "$ZDOTDIR/plugins/pre.txt" \
      "$ZSH_CACHE_DIR/plugins-pre.zsh"
  }

  function zsh_plugins_load_fzf_tab() {
    [[ ${ZSH_DISABLE_FZF:-0} == 1 ]] && return 0
    (( $+commands[fzf] )) || return 0
    antidote load \
      "$ZDOTDIR/plugins/fzf.txt" \
      "$ZSH_CACHE_DIR/plugins-fzf.zsh"
  }

  function zsh_plugins_load_post() {
    antidote load \
      "$ZDOTDIR/plugins/post.txt" \
      "$ZSH_CACHE_DIR/plugins-post.zsh"
  }
fi
