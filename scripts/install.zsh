#!/usr/bin/env zsh

emulate -LR zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

typeset -r repo_dir=${0:A:h:h}
typeset -r antidote_ref=v2.1.0
typeset -r antidote_commit=4913257e0ae3fee2a77e7189e526fe55b6ff9536
typeset -r data_home=${XDG_DATA_HOME:-$HOME/.local/share}
typeset -r state_home=${XDG_STATE_HOME:-$HOME/.local/state}
typeset -r cache_home=${XDG_CACHE_HOME:-$HOME/.cache}
typeset -r antidote_dir=$data_home/zsh/antidote
typeset activate=1

function usage() {
  print -- 'usage: scripts/install.zsh [--no-activate]'
  print -- '  --no-activate  install plugins and validate without changing ~/.zshenv'
}

while (( $# > 0 )); do
  case $1 in
    --no-activate) activate=0 ;;
    -h|--help) usage; exit 0 ;;
    *) print -u2 -- "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

print -- 'Checking Zsh sources...'
typeset file
for file in \
  "$repo_dir/.zshenv" \
  "$repo_dir/.zprofile" \
  "$repo_dir/.zshrc" \
  "$repo_dir"/completions/* \
  "$repo_dir"/config/*.zsh \
  "$repo_dir"/functions/* \
  "$repo_dir"/scripts/*.zsh \
  "$repo_dir"/tests/*.zsh; do
  [[ -f $file ]] && zsh -n "$file"
done

if [[ -d $antidote_dir/.git ]]; then
  typeset installed_commit
  installed_commit=$(command git -C "$antidote_dir" rev-parse HEAD)
  if [[ $installed_commit != $antidote_commit ]]; then
    print -u2 -- "Antidote at $antidote_dir is not the pinned build."
    print -u2 -- "Expected $antidote_commit, found $installed_commit."
    print -u2 -- 'Move that directory aside and run the installer again.'
    exit 1
  fi
  if [[ -n $(command git -C "$antidote_dir" status --porcelain) ]]; then
    print -u2 -- "Antidote at $antidote_dir has local modifications."
    print -u2 -- 'Move that directory aside and run the installer again.'
    exit 1
  fi
elif [[ -e $antidote_dir || -L $antidote_dir ]]; then
  print -u2 -- "$antidote_dir exists but is not the pinned Antidote checkout."
  print -u2 -- 'Move that path aside and run the installer again.'
  exit 1
else
  print -- "Installing Antidote $antidote_ref..."
  command mkdir -p -- "${antidote_dir:h}"
  typeset -r temporary_dir="$antidote_dir.tmp.$$"
  command git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$antidote_ref" \
    https://github.com/mattmc3/antidote.git "$temporary_dir"

  typeset cloned_commit
  cloned_commit=$(command git -C "$temporary_dir" rev-parse HEAD)
  if [[ $cloned_commit != $antidote_commit ]]; then
    command rm -rf -- "$temporary_dir"
    print -u2 -- "Antidote verification failed: expected $antidote_commit, found $cloned_commit"
    exit 1
  fi
  command mv -- "$temporary_dir" "$antidote_dir"
fi

command mkdir -p -- "$cache_home/zsh" "$state_home/zsh"

print -- 'Running isolated startup checks...'
"$repo_dir/tests/check.zsh"
"$repo_dir/tests/plugins.zsh"

if (( activate )); then
  typeset -r bootstrap=$HOME/.zshenv
  typeset -r target=$repo_dir/.zshenv

  if [[ -L $bootstrap && ${bootstrap:A} == ${target:A} ]]; then
    print -- "Already active: $bootstrap -> $target"
  else
    if [[ -e $bootstrap || -L $bootstrap ]]; then
      typeset -r timestamp=$(command date +%Y%m%d-%H%M%S)
      typeset -r backup_dir=$state_home/zsh/backups/$timestamp
      command mkdir -p -- "$backup_dir"
      command mv -- "$bootstrap" "$backup_dir/.zshenv"
      print -- "Backed up the previous .zshenv to $backup_dir/.zshenv"
    fi
    command ln -s -- "$target" "$bootstrap"
    print -- "Activated $target through $bootstrap"
  fi
fi

if (( activate )); then
  print -- 'Ready. Start a fresh login shell with: exec zsh -l'
else
  print -- 'Validated without activation.'
fi
