setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt NO_FLOW_CONTROL
# Dynamic repository text is embedded in PROMPT. Recursive prompt substitution
# would let a malicious Git branch name execute shell code during rendering.
unsetopt PROMPT_SUBST
