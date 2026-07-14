# Zsh, with the Fish workflow

An XDG-style Zsh configuration that keeps the useful parts of my Fish setup:
fast interactive editing, an Agnoster-inspired Powerline prompt, Git/tmux/editor
helpers, fuzzy completion, and an optional Programmer Dvorak Vi mode.

The default editing mode is Emacs. Vi is a feature, not a dependency.

## What is included

- Native one-line Powerline prompt with status, root/jobs, user/host, an
  explicit high-contrast working directory, Git state, project version, and OS
- Fish-like autosuggestions, syntax highlighting, completion, fuzzy tab
  selection, prefix history search, and `fzf` shortcuts
- Native directory stack with `p`/`n`, plus `zoxide` integration when installed
- `pyenv`, `rbenv`, lazy NVM, `direnv`, Rust/Cargo, Homebrew, Nix, Go, Android,
  Deno, Bun, Solana, and ATC shim paths, all guarded and portable
- Git, Emacs, Kubernetes, Ruby, tmux, notes, clipboard, JSON, process-search,
  password, and HTTP-server helpers carried over or modernized from Fish
- Three keymaps: `emacs` (default), standard `vi`, and `dvorak`

Plugins are managed by [Antidote](https://antidote.sh/) and pinned to exact
commits. Nothing downloads or auto-updates during shell startup.

## Install

Zsh 5.8 or newer and Git are required.

```sh
git clone https://github.com/Gonzih/.zsh.git ~/.config/zsh
~/.config/zsh/scripts/install.zsh
exec zsh -l
```

The installer:

1. syntax-checks the configuration;
2. installs a verified Antidote release and prewarms exact plugin pins;
3. runs isolated startup, security, plugin, and keymap tests;
4. backs up an existing `~/.zshenv` under XDG state; and
5. symlinks `~/.zshenv` to this repository.

It does not delete or replace an existing `~/.zshrc` or `~/.zprofile`.
`~/.zshenv` sets `ZDOTDIR` early, so Zsh reads the versions in this repository
instead. To validate without activating anything, run:

```sh
./scripts/install.zsh --no-activate
```

That option still installs and caches the pinned plugin code; it only skips the
backup/symlink step that changes which configuration a new Zsh process reads.

To roll back, remove the installer-created `~/.zshenv` symlink and restore the
timestamped `.zshenv` from `${XDG_STATE_HOME:-~/.local/state}/zsh/backups/`.
The former `~/.zshrc` and `~/.zprofile` were left in place and will become
active again on the next login shell.

## Optional tools

The configuration works without these binaries and enables them when present:

- `fzf` 0.48+ for `Ctrl-R`, `Ctrl-T`, `Alt-C`, and fuzzy tab selection
- `zoxide` for frecency-based `z`/`zi` directory navigation
- `direnv`, `pyenv`, `rbenv`, NVM, and `gpgconf` for their respective hooks
- a Powerline/Nerd Font for the prompt separator and branch glyph
- `eza` for richer `l` output; stock `ls` is the fallback

On macOS, a useful baseline is:

```sh
brew install fzf zoxide direnv
```

## Keymaps

Default startup uses normal Emacs-style ZLE bindings with Fish-like up/down
prefix search. Start a temporary standard Vi shell with:

```sh
ZSH_KEYMAP=vi zsh
```

For the original Programmer Dvorak remap:

```sh
ZSH_KEYMAP=dvorak zsh
```

To make either persistent, copy the local example and edit it:

```sh
cp ~/.config/zsh/.zshrc.local.example ~/.config/zsh/.zshrc.local
```

In either Vi mode, `Ctrl-C` returns from Insert or Visual mode to Normal mode
without clearing the command line. From Normal mode, `Ctrl-C` cancels the
command line.

The Dvorak map assumes the operating system is already producing Programmer
Dvorak characters. It preserves the Fish map's character bindings, which put
motions on the physical QWERTY `hjkl` positions:

| Programmer Dvorak key | Action |
|---|---|
| `d` / `n` | left / right |
| `t` / `h` | up / down with prefix history search |
| `j` chords | explicit deletes (`jj`, `jw`, `jiw`, and friends); bare `j` is non-destructive |
| `-` / `_` | end / beginning of line |
| `D` / `N` | previous / next directory-stack entry |
| `l` | clear screen |
| `k` | backward “till character” motion |

The prompt shows `I`, `N`, or `V` only in a Vi keymap. The old Fish config bound
`k` twice; this port deliberately preserves the second, effective binding.

Graphical Linux users can also opt into the old XKB setup (`us(dvp),ru`, left
Control layout toggle, Caps Lock as Control):

```zsh
ZSH_APPLY_DVORAK_LAYOUT=1
```

Put that setting in `.zshrc.local`, not in the tracked configuration.

## Local configuration

Three ignored files are available:

- `.zshenv.local` for exported variables and PATH changes needed by every Zsh
- `.zshrc.local` for feature flags needed before interactive modules load
- `.zshrc.after` for aliases/functions that should override tracked defaults

Useful flags:

```zsh
ZSH_KEYMAP=emacs          # emacs, vi, or dvorak
ZSH_USE_GPG_AGENT=0       # keep 1Password/Keychain/another SSH agent
ZSH_LAZY_NVM=0            # load NVM eagerly instead of on first use
ZSH_DISABLE_FZF=1         # retain stock Tab and skip fzf shell shortcuts
ZSH_PROMPT_SHOW_USER=0    # hide local user/host except for SSH/user changes
NOTES_DIR="$HOME/notes"
TODO_FILE="$HOME/TODO.md"
```

## Fish compatibility notes

This is a workflow port, not a line-for-line archive. A few old Fish helpers
were intentionally not published as defaults:

- `bass` is unnecessary because Zsh can source NVM directly.
- Forcing `TERM=xterm-256color` was removed; the terminal should advertise its
  own capabilities.
- `GO111MODULE=on` was removed because modern Go uses modules by default.
- AES-ECB wrappers, TrueCrypt/EncFS paths, unencrypted upload services, personal
  hostnames/account IDs, mass Docker deletion, and obsolete `youtube-dl` or
  Livestreamer wrappers were retired.
- Host-specific commands belong in `.zshrc.local`.

The portable daily helpers remain, with quoting, platform checks, and safer
modern implementations.

`start-http-server` binds to localhost by default. Pass an explicit second
argument such as `0.0.0.0` only when LAN access is intended.

## Maintenance

Run the local test suite after changes:

```sh
make check
```

After installing Antidote, verify the real pinned plugin bundle with:

```sh
make check-plugins
```

Plugin pins live in `plugins/pre.txt`, `plugins/fzf.txt`, and `plugins/post.txt`. Completion paths
load before a normal, security-checking `compinit`; `fzf-tab`, autosuggestions,
and syntax highlighting load afterward in their required order. Generated
bundles and completion dumps stay in XDG cache and are never committed.

## License

MIT
