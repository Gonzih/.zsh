[[ -o interactive ]] || return 0

typeset -g ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
typeset -g ZSH_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
command mkdir -p -- "$ZSH_CACHE_DIR" "$ZSH_STATE_DIR"

# Machine-specific settings belong here. This is intentionally loaded before
# the modules so values such as ZSH_KEYMAP can configure startup behavior.
[[ -r "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"

source "$ZDOTDIR/config/options.zsh"
source "$ZDOTDIR/config/history.zsh"
source "$ZDOTDIR/config/plugins.zsh"

zsh_plugins_load_pre
source "$ZDOTDIR/config/completion.zsh"
source "$ZDOTDIR/config/aliases.zsh"
source "$ZDOTDIR/config/functions.zsh"
source "$ZDOTDIR/config/integrations.zsh"
source "$ZDOTDIR/config/keybindings.zsh"
source "$ZDOTDIR/config/prompt.zsh"

# Late machine-specific aliases/functions can override tracked defaults while
# still loading before plugins wrap the final ZLE widgets.
[[ -r "$ZDOTDIR/.zshrc.after" ]] && source "$ZDOTDIR/.zshrc.after"

# fzf-tab must follow compinit; autosuggestions must follow custom widgets;
# syntax highlighting must be the final widget-wrapping plugin.
zsh_plugins_load_fzf_tab
zsh_plugins_load_post

unfunction zsh_plugins_load_pre zsh_plugins_load_fzf_tab zsh_plugins_load_post 2>/dev/null || true
