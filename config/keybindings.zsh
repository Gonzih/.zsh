autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

zmodload zsh/terminfo

typeset -g ZSH_KEYMAP=${ZSH_KEYMAP:-emacs}
ZSH_KEYMAP=${ZSH_KEYMAP:l}

case $ZSH_KEYMAP in
  emacs)
    bindkey -e
    ;;
  vi|dvorak)
    bindkey -v
    KEYTIMEOUT=${ZSH_KEYTIMEOUT:-20}
    ;;
  *)
    print -u2 -- "zsh: unknown ZSH_KEYMAP=$ZSH_KEYMAP; using emacs"
    ZSH_KEYMAP=emacs
    bindkey -e
    ;;
esac

function _zsh_bind_navigation_keys() {
  local map=$1

  bindkey -M "$map" '^P' up-line-or-beginning-search
  bindkey -M "$map" '^N' down-line-or-beginning-search
  bindkey -M "$map" '^C' send-break
  bindkey -M "$map" '^L' clear-screen

  [[ -n ${terminfo[kcuu1]:-} ]] && bindkey -M "$map" "$terminfo[kcuu1]" up-line-or-beginning-search
  [[ -n ${terminfo[kcud1]:-} ]] && bindkey -M "$map" "$terminfo[kcud1]" down-line-or-beginning-search
  [[ -n ${terminfo[kcub1]:-} ]] && bindkey -M "$map" "$terminfo[kcub1]" backward-char
  [[ -n ${terminfo[kcuf1]:-} ]] && bindkey -M "$map" "$terminfo[kcuf1]" forward-char
  [[ -n ${terminfo[khome]:-} ]] && bindkey -M "$map" "$terminfo[khome]" beginning-of-line
  [[ -n ${terminfo[kend]:-} ]] && bindkey -M "$map" "$terminfo[kend]" end-of-line
  [[ -n ${terminfo[kdch1]:-} ]] && bindkey -M "$map" "$terminfo[kdch1]" delete-char

  # Terminals do not always advertise application-mode sequences correctly.
  bindkey -M "$map" '^[[A' up-line-or-beginning-search
  bindkey -M "$map" '^[[B' down-line-or-beginning-search
  bindkey -M "$map" '^[[H' beginning-of-line
  bindkey -M "$map" '^[[F' end-of-line
  bindkey -M "$map" '^[[3~' delete-char
}

_zsh_bind_navigation_keys emacs
_zsh_bind_navigation_keys viins
_zsh_bind_navigation_keys vicmd
unfunction _zsh_bind_navigation_keys

if [[ $ZSH_KEYMAP == vi || $ZSH_KEYMAP == dvorak ]]; then
  # Fish's first Ctrl-C leaves insert/visual mode without discarding the
  # buffer; Ctrl-C in command mode cancels it.
  bindkey -M viins '^C' vi-cmd-mode
  bindkey -M visual '^C' vi-cmd-mode

  typeset -g _ZSH_VI_STATE=I

  function _zsh_ctrl_c_editing() {
    # Disable the terminal interrupt character while ZLE owns the terminal so
    # its active keymap receives Ctrl-C as an ordinary key.
    command stty intr undef 2>/dev/null < /dev/tty || true
  }

  function _zsh_ctrl_c_restore() {
    # Commands must inherit ordinary SIGINT behavior.
    command stty intr '^C' 2>/dev/null < /dev/tty || true
  }

  function _zsh_keymap_select() {
    case $KEYMAP in
      vicmd) _ZSH_VI_STATE=N ;;
      visual) _ZSH_VI_STATE=V ;;
      *) _ZSH_VI_STATE=I ;;
    esac
    (( $+functions[_zsh_prompt_update_mode] )) && _zsh_prompt_update_mode
    zle reset-prompt
  }

  function _zsh_line_init() {
    local previous_state=$_ZSH_VI_STATE
    _ZSH_VI_STATE=I
    if [[ $previous_state != I ]]; then
      (( $+functions[_zsh_prompt_update_mode] )) && _zsh_prompt_update_mode
      zle reset-prompt
    fi
  }

  autoload -Uz add-zle-hook-widget
  autoload -Uz add-zsh-hook
  add-zle-hook-widget keymap-select _zsh_keymap_select
  add-zle-hook-widget line-init _zsh_line_init
  add-zsh-hook precmd _zsh_ctrl_c_editing
  add-zsh-hook preexec _zsh_ctrl_c_restore
  add-zsh-hook zshexit _zsh_ctrl_c_restore
fi

if [[ $ZSH_KEYMAP == dvorak ]]; then
  # Physical hjkl positions on Programmer Dvorak emit dhtn.
  bindkey -M vicmd d vi-backward-char
  bindkey -M vicmd h down-line-or-beginning-search
  bindkey -M vicmd t up-line-or-beginning-search
  bindkey -M vicmd n vi-forward-char
  bindkey -M visual d vi-backward-char
  bindkey -M visual h down-line
  bindkey -M visual t up-line
  bindkey -M visual n vi-forward-char

  # Port Fish's explicit j-prefixed deletes without making a bare j
  # destructive.
  bindkey -M vicmd jj kill-whole-line
  bindkey -M vicmd jw kill-word
  bindkey -M vicmd jW kill-word
  bindkey -M vicmd je kill-word
  bindkey -M vicmd jE kill-word
  bindkey -M vicmd jb backward-kill-word
  bindkey -M vicmd jB backward-kill-word
  bindkey -M vicmd jgE backward-kill-word

  function _zsh_dvorak_kill_word_object() {
    zle vi-forward-char
    zle vi-forward-char
    zle vi-backward-word
    zle kill-word
  }
  zle -N _zsh_dvorak_kill_word_object
  bindkey -M vicmd jiw _zsh_dvorak_kill_word_object
  bindkey -M vicmd jiW _zsh_dvorak_kill_word_object
  bindkey -M vicmd jaw _zsh_dvorak_kill_word_object
  bindkey -M vicmd jaW _zsh_dvorak_kill_word_object

  function _zsh_dvorak_delete_at_eol() {
    zle vi-end-of-line
    zle vi-delete-char
  }
  zle -N _zsh_dvorak_delete_at_eol
  bindkey -M vicmd J _zsh_dvorak_delete_at_eol

  bindkey -M vicmd -- - vi-end-of-line
  bindkey -M vicmd _ vi-beginning-of-line
  bindkey -M vicmd j- kill-line
  bindkey -M vicmd j_ backward-kill-line
  bindkey -M vicmd c- vi-change-eol

  function _zsh_dvorak_change_bol() {
    zle backward-kill-line
    zle -K viins
  }
  zle -N _zsh_dvorak_change_bol
  bindkey -M vicmd c_ _zsh_dvorak_change_bol

  function _zsh_dvorak_copy_eol() {
    zle kill-line
    zle yank
  }
  function _zsh_dvorak_copy_bol() {
    zle backward-kill-line
    zle yank
  }
  zle -N _zsh_dvorak_copy_eol
  zle -N _zsh_dvorak_copy_bol
  bindkey -M vicmd y- _zsh_dvorak_copy_eol
  bindkey -M vicmd y_ _zsh_dvorak_copy_bol

  function _zsh_dirstack_previous() {
    if p; then
      (( $+functions[_zsh_prompt_build] )) && _zsh_prompt_build 0
    else
      zle beep
    fi
    zle reset-prompt
  }
  function _zsh_dirstack_next() {
    if n; then
      (( $+functions[_zsh_prompt_build] )) && _zsh_prompt_build 0
    else
      zle beep
    fi
    zle reset-prompt
  }
  zle -N _zsh_dirstack_previous
  zle -N _zsh_dirstack_next
  bindkey -M vicmd D _zsh_dirstack_previous
  bindkey -M vicmd N _zsh_dirstack_next

  function _zsh_exit_shell() {
    zle -I
    _zsh_ctrl_c_restore
    builtin exit
  }
  zle -N _zsh_exit_shell
  bindkey -M vicmd ZZ _zsh_exit_shell
  bindkey -M vicmd ZQ _zsh_exit_shell
  bindkey -M vicmd ';q' _zsh_exit_shell
  bindkey -M vicmd '^D' _zsh_exit_shell

  bindkey -M vicmd l clear-screen
  function _zsh_dvorak_visual_clear() {
    zle visual-mode
    zle clear-screen
  }
  zle -N _zsh_dvorak_visual_clear
  bindkey -M visual l _zsh_dvorak_visual_clear
  bindkey -M visual c vi-change

  # The Fish file bound k twice; its second (effective) definition was a
  # backwards "till" motion.
  bindkey -M vicmd k vi-find-prev-char-skip
fi
