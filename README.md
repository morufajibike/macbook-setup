# macbook-setup

An idempotent macOS bootstrap and dotfiles repository. **This machine is the
source of truth:** the live configuration is captured here, committed, and then
applied to a fresh or target Mac to mirror the setup.

Deployment is by **symlink, not copy**. After install, the files under
`dotfiles/` *are* your live config — editing `~/.zshrc` edits the repo, and a
re-run never silently overwrites: anything in the way is moved to a timestamped
backup first.

Everything is **idempotent and re-runnable**. Run `./install.sh` as many times
as you like; already-correct symlinks, already-installed packages, and
already-cloned plugins are left untouched.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| macOS | The entrypoint only checks for Darwin (`uname -s`) and exits on any other OS. Developed against recent macOS; older releases are untested. |
| Xcode Command Line Tools | `xcode-select --install` if missing. Provides `git` and a compiler toolchain (pyenv builds CPython from source). |
| git | Bundled with the Command Line Tools. |
| Internet access | Required for Homebrew, oh-my-zsh, plugin/theme/font clones, and casks. |

Homebrew does **not** need to be installed beforehand — `scripts/00-brew.sh`
installs it automatically on the first run (Apple Silicon → `/opt/homebrew`,
Intel → `/usr/local`).

---

## Quick start

```sh
git clone https://github.com/morufajibike/macbook-setup.git
cd macbook-setup
./install.sh
```

`install.sh` invokes each step via `bash`, so the executable bit is not
required. If you downloaded the repo as a zip rather than cloning it (which can
strip the executable bit), make the scripts runnable first:

```sh
chmod +x install.sh scripts/*.sh
./install.sh
```

The run prints a coloured `[INFO] / [WARN] / [ERROR]` log to stderr and a
summary with next steps when it completes.

### Installing the GUI apps

The `apps` group (GUI casks) is **opt-in** and skipped by default in every
mode. Pass `--with-apps` (or set `INSTALL_APPS=1`) to include it:

```sh
# Flag form
./install.sh --with-apps

# Environment form
INSTALL_APPS=1 ./install.sh
```

You can also name `apps` explicitly in `BREW_GROUPS` (see below).

### Previewing changes (dry run)

Run with `--dry-run` (or `-n`, or set `DRY_RUN=1` in the environment) to
preview every action without making any change to the system:

```sh
# Flag form
./install.sh --dry-run

# Environment form (composes with BREW_GROUPS)
DRY_RUN=1 BREW_GROUPS=core ./install.sh
```

In dry-run mode the bootstrap prints `[dry-run] would ...` lines for every
mutating operation — symlinks, backups, Homebrew install, brew bundle (with
the assembled Brewfile printed in full), git clones, git identity write, SSH
keygen, and `defaults write` calls — but touches nothing on disk. A banner
at the start and end confirms no changes were made.

---

## How it works (architecture)

`install.sh` is a thin orchestrator:

1. Sets strict mode (`set -euo pipefail`) so any failed step aborts the run.
2. Sources `lib/common.sh` for shared helpers (logging, `command_exists`,
   `repo_root`, `ensure_dir`, `backup_then_symlink`).
3. Verifies the OS is Darwin.
4. Discovers `scripts/[0-9]*.sh`, sorts them numerically, and runs each in turn
   via `bash`. A step is never skipped silently — a missing or failed step
   fails the whole run.

### Symlink-with-backup deployment

Dotfiles are deployed by `backup_then_symlink` (`lib/common.sh`). For each file:

1. Ensure the target's parent directory exists.
2. If the target is already the correct symlink to the repo source → no-op.
3. If anything else occupies the target (regular file, directory, or a wrong
   symlink) → move it to `~/dotfiles-backup/<name>.<timestamp>` before
   replacing it.
4. Create the symlink (`ln -sfn <repo-source> <home-target>`).

Backups are **collision-safe**: the timestamp has only second resolution, so
the path is suffixed with the PID and a random number and re-rolled if it still
exists. Nothing is ever clobbered.

The result: the repo is the durable source of truth. Edits made directly to
`~/.zshrc`, `~/.vimrc`, etc. are edits to the repo files (they are the same
inode). To change config, edit the files under `dotfiles/` and commit.

---

## Homebrew package groups

The `Brewfile` is a single valid Brewfile organised into groups by `# group:`
marker comments. `brew bundle` ignores the comments, so the file installs
cleanly as-is; the grouping is interpreted by `scripts/00-brew.sh`, which
assembles a temporary Brewfile from only the selected groups before calling
`brew bundle`.

| Group | Default | Roughly contains |
|---|---|---|
| `core` | **yes** | Shell and git essentials, plus the prompt font: `zsh`, `bash-completion`, `git-lfs`, `glow`, `gh`, `tmux`, `bat`, `coreutils`, `gawk`, `jq`, `tree`, `wget`, `pre-commit`, and the `font-meslo-lg-nerd-font` cask. |
| `cloud-devops` | no | Cloud and container tooling: `awscli`, `azure-cli`, `ansible`, `docker`/`docker-compose`, `colima`, `helm`, `minikube`, `k9s`, `stern`, `argocd`, and Terraform tooling (`tfenv`, `terragrunt`, `tfsort`, `terraform-docs`, `checkov`, `infracost`, `trivy`, `actionlint`). |
| `languages` | no | Runtimes and toolchains: `node`, `python@3.10`, `pyenv`, `pipenv`, `uv`, `ipython`. |
| `databases` | no | `mysql`, `postgresql@17`. |
| `apps` | no — opt-in via `--with-apps` | GUI casks: `ghostty`, `visual-studio-code`, `google-chrome`, `firefox`, `docker`, `flux`, `adobe-acrobat-reader`. |

### Choosing groups

**Interactive (a terminal on stdin):** you are prompted per group. `core`
defaults to yes (`[Y/n]`); every other group defaults to no (`[y/N]`), so a
fresh machine installs only what you pick.

The `apps` group is excluded from the defaults in **all** modes (interactive
prompts, the non-interactive fallback, and dry-run) and is never prompted for.
It is installed only via `--with-apps`, `INSTALL_APPS=1`, or by naming `apps`
explicitly in `BREW_GROUPS`.

**`BREW_GROUPS` override** (space- or comma-separated) pre-selects groups and
skips the prompts on both interactive and non-interactive runs:

```sh
# Install only core and languages
BREW_GROUPS="core languages" ./install.sh

# Comma form is equivalent
BREW_GROUPS="core,languages" ./install.sh
```

Behaviour summary:

| Situation | Result |
|---|---|
| `BREW_GROUPS` set | Installs exactly those groups (prompts skipped); may include `apps`. |
| Interactive, `BREW_GROUPS` unset | Prompts per default group (`core` defaults yes, rest no); `apps` is not prompted. |
| Non-interactive, `BREW_GROUPS` unset (CI, piped input) | Installs the default groups (everything except `apps`), with a warning, so unattended provisioning still works. |
| `--with-apps` / `INSTALL_APPS=1` | Adds `apps` to the selection on any path above. |
| Unknown group name | Rejected with an error listing the valid groups. |

`brew bundle` is idempotent: re-running only installs whatever is missing.
Already-installed packages are skipped (`--no-upgrade`), and apps already
present on disk are adopted rather than reinstalled (`cask_args adopt: true`).

> **Caveat on refreshing the Brewfile.** `brew bundle dump` does **not**
> preserve the `# group:` markers. After a dump you must re-add the markers and
> re-sort entries into the right groups by hand before committing, or the
> per-group selection in `00-brew.sh` is lost.

---

## Per-script reference

Scripts run in numeric order. Each sources `lib/common.sh` and is individually
idempotent.

| Script | What it does |
|---|---|
| `00-brew.sh` | Installs Homebrew if absent, ensures `brew` is on PATH for the session, then prompts per Brewfile group (or honours `BREW_GROUPS`) and bundles only the selected groups. |
| `10-shell.sh` | Installs oh-my-zsh unattended (`RUNZSH=no CHSH=no`), then clones the powerlevel10k theme, `zsh-syntax-highlighting`, and `zsh-autosuggestions` — each only if absent. |
| `20-dotfiles.sh` | Symlinks every file under `dotfiles/` into `$HOME` at the matching relative path, backing up anything in the way. Also symlinks the whole `git-hooks/` directory to `~/.git-hooks`. |
| `25-git-identity.sh` | Sets the per-machine git identity. Prompts for name/email (or reads `GIT_USER_NAME`/`GIT_USER_EMAIL`, or skips on a non-TTY) and writes them to the untracked `~/.gitconfig.local`. |
| `30-vim.sh` | Clones Vundle if absent, then runs `vim -u ~/.vimrc +PluginInstall +qall` to install the plugins declared in `.vimrc`, then builds the `markdown-preview.nvim` preview server. |
| `40-tmux.sh` | Clones TPM if absent, then runs `tpm/bin/install_plugins` to install the plugins declared in `.tmux.conf`. |
| `50-python.sh` | Installs the pinned Python version (`3.13.11`) via pyenv and sets it as the global default, then installs `flake8`, `ipython`, and `pytest` into that version's pip. |
| `60-fonts.sh` | Installs fonts not available as Homebrew casks: FiraCode and Powerline fonts into `~/Library/Fonts`. Clones the Operator Mono ligature builder and builds it only if you supply the original OTF files in `.fonts-work/operator-mono-lig/original/`. |
| `70-ssh.sh` | Generates an Ed25519 GitHub SSH key at `~/.ssh/id_ed25519_github`, adds it to the agent/keychain, appends a `github.com` host block to `~/.ssh/config`, and prints the public key. Skipped entirely if the key already exists. |
| `80-macos.sh` | Applies a curated set of reversible `defaults write` system settings, then restarts Finder/Dock/SystemUIServer. |

`80-macos.sh` sets: show all file extensions and hidden files; Finder path and
status bars; fast key repeat and short initial delay; press-and-hold off;
expanded Save/Print panels; no `.DS_Store` on network/USB volumes; and an
immediate password lock after the screen saver/display sleep.

---

## What gets configured (dotfiles)

Every file below is symlinked from `dotfiles/` into `$HOME`.

| Dotfile | Manages |
|---|---|
| `.zshrc` | oh-my-zsh with the powerlevel10k theme and plugins (`git`, `autopep8`, `pep8`, `aws`, `tmux`, `zsh-syntax-highlighting`, `zsh-autosuggestions`); pyenv init; NVM; arch-aware MySQL client and system Java PATH entries; the `k=kubectl` alias; sources `~/.bash_additions`; the powerlevel10k instant-prompt block; and the `claude` tmux wrapper (see below). |
| `.vimrc` | Vundle-managed plugins — NERDTree, `vim-flake8`, `vim-airline`, SimpylFold, `copilot.vim`, `vim-markdown`, and `markdown-preview.nvim` — plus indent/fold settings, `Ctrl-t` to toggle NERDTree, flake8 on save for `*.py`, Markdown conceal on Markdown buffers, and a buffer-local `:Glow` command that renders the current file in the terminal via `glow`. |
| `.tmux.conf` | TPM plugins (`tpm`, `tmux-sensible`, `nord-tmux`, `tmux-resurrect`, `tmux-colors-solarized`, `tmux-sessionx`); top status bar; vi-style keys; pane navigation/splitting; large scrollback; status-line styling. |
| `.bashrc` | Interactive bash setup: sources `~/.bash_additions`, pyenv init, Homebrew and kubectl completion, Rust/cargo env. |
| `.bash_additions` | Shared aliases/functions sourced by both `.zshrc` and `.bashrc`: git shortcuts (`ga`, `gs`, `gsw`, `gsh`, `gl`, `gcom`, `gca`, `gcb`) and project helpers. |
| `.gitconfig` | Global git config (see [Git identity](#git-identity)): `excludesfile`, `core.hooksPath = ~/.git-hooks`, `gh` credential helper, Git LFS filters, push/pull defaults, and an `[include]` of `~/.gitconfig.local`. |
| `.gitignore_global` | Global ignore patterns (`.DS_Store`, `*.swp`, Terraform caches, `.pre-commit-config.yaml`, local tooling config, etc.). |
| `.config/ghostty/config` | Ghostty terminal config: `niji` theme, `MesloLGS NF` font at 16pt, window geometry, split keybindings, shell integration. |

### The `claude` tmux wrapper

`.zshrc` defines a `claude` shell function. Outside tmux it creates/attaches to
a session named `claude` and runs Claude Code inside it; inside tmux it runs
normally. This ensures agent teams render in split panes.

### Git hooks

`20-dotfiles.sh` symlinks `git-hooks/` → `~/.git-hooks`, which `.gitconfig`
references via `core.hooksPath`, so the hooks apply to every repository on the
machine:

- `pre-commit` — runs the global `pre-commit` config (gitleaks secret scan and
  the standard hook set) and any per-repo `.pre-commit-config.yaml`. **No-op if
  `~/.pre-commit-config.yaml` does not exist** (see [Security notes](#security--trust-notes)).
- `pre-push`, `post-checkout`, `post-commit`, `post-merge` — Git LFS
  passthrough hooks; each warns and exits if `git-lfs` is not on PATH.

---

## Rendering Markdown

The Vim setup ships three ways to read a Markdown file, from a quick in-editor
view to a fully-rendered browser preview. All are provided by the `tabular`,
`vim-markdown`, and `markdown-preview.nvim` plugins (installed by `30-vim.sh`)
plus the `glow` formula (`core` Brewfile group). (`tabular` is a `vim-markdown`
dependency that enables table alignment.)

| Method | How | Notes |
|---|---|---|
| In the Vim buffer | Open the `.md` file | Syntax highlighting, section folding (`space` toggles `za`), and conceal of markup — `**bold**` shows as `bold` and link URLs are hidden (`conceallevel=2`). Plain highlighting/conceal only; it does not draw tables or large headings. |
| In the terminal | `:Glow` in a Markdown buffer, or `glow <file>.md` from the shell | Renders the current file via the `glow` pager; press `q` to return to Vim. Requires the `glow` formula. |
| In the browser | `:MarkdownPreview` in a Markdown buffer | Fully-rendered, live-updating HTML preview that refreshes on save; `:MarkdownPreviewStop` closes it. Server built by `30-vim.sh` (downloads a prebuilt binary via `curl`; no `node` required), pinned to loopback (`g:mkdp_open_to_the_world = 0`). |

---

## Git identity

Personal identity never lives in the repo. The tracked `dotfiles/.gitconfig`
ships placeholders (`Your Name` / `you@example.com`) and includes
`~/.gitconfig.local` **last**, so the local file's `[user]` block wins.

`25-git-identity.sh` writes that untracked local file:

- **Interactive:** prompts for name and email (defaults shown from any existing
  `~/.gitconfig.local`). Email must contain `@`.
- **Non-interactive:** uses `GIT_USER_NAME` and `GIT_USER_EMAIL` if both are
  set; otherwise warns and skips, leaving any existing local file untouched.

```sh
# Non-interactive identity
GIT_USER_NAME="Ada Lovelace" GIT_USER_EMAIL="ada@example.com" ./install.sh
```

Values are written via `git config -f` (so they are correctly escaped), and
newlines/carriage returns are rejected to prevent config injection.

---

## First-run / post-install steps

A few things complete on first use rather than during the bootstrap:

- **powerlevel10k prompt.** On the first interactive shell, if `~/.p10k.zsh` is
  absent, powerlevel10k runs its `p10k configure` wizard automatically. The
  required `MesloLGS NF` font is installed by the `core` Brewfile group.
  Re-run the interactive wizard at any time to change the prompt style:
  ```sh
  p10k configure
  ```
  It is non-destructive — it rewrites `~/.p10k.zsh` with your choices and
  reloads the prompt. The wizard's first questions detect your terminal font,
  so the terminal must already be using the `MesloLGS NF` Nerd Font (Ghostty's
  bundled config sets this; other terminals must set it manually) or the
  preview glyphs render as missing-glyph boxes. The wizard asks a series of
  questions; the key answers that produce the one-line **Rainbow** prompt
  (filled coloured powerline segments) are:

  | Question | Answer |
  |---|---|
  | Prompt Style | Rainbow |
  | Show current time | 24-hour |
  | Prompt Separators | Angled |
  | Prompt Heads | Sharp |
  | Prompt Tails | Flat |
  | Prompt Height | One line |
  | Prompt Spacing | Compact |
  | Icons | Many |
  | Prompt Flow | Concise |

  then apply/save when prompted. `p10k configure` only affects the machine it
  is run on; a fresh install elsewhere falls back to the wizard unless
  `~/.p10k.zsh` is committed into `dotfiles/`.
- **Vim plugins.** Installed by `30-vim.sh`. To install plugins added to
  `.vimrc` later, or to re-run by hand:
  ```sh
  vim +PluginInstall +qall   # install
  vim +PluginUpdate  +qall   # update
  ```
- **Tmux plugins.** Installed by `40-tmux.sh` via TPM. Inside a running tmux
  session, press `prefix + I` (capital i) to install newly added plugins, or
  `prefix + U` to update.
- **GitHub SSH key.** `70-ssh.sh` generates `~/.ssh/id_ed25519_github` and adds
  it to the agent/keychain. **Add the public key to GitHub** at
  <https://github.com/settings/keys>:
  ```sh
  cat ~/.ssh/id_ed25519_github.pub
  ```

---

## Customising

**Add/remove a Homebrew package.** Edit `Brewfile` under the correct `# group:`
marker. Keep entries grouped — if you run `brew bundle dump`, re-add the markers
afterwards (see the caveat above).

**Add a new dotfile.** Drop it into `dotfiles/` at the path it should occupy
under `$HOME` (e.g. `dotfiles/.config/foo/bar`). `20-dotfiles.sh` walks
`dotfiles/` with `find -type f` and symlinks every leaf file, so nested paths
are picked up automatically with no script change.

**Tune macOS defaults.** Edit `scripts/80-macos.sh`; each `defaults write` is
commented. Revert any setting with `defaults delete <domain> <key>` or via
System Settings. The pinned Python version lives in `PYTHON_VERSION` at the top
of `scripts/50-python.sh`.

---

## Re-running & updating

`./install.sh` is safe to re-run at any time:

- Homebrew install is skipped (already present); `brew bundle` installs only
  what is missing — already-installed packages are skipped and apps already
  present on disk are adopted rather than reinstalled.
- oh-my-zsh, theme, plugin, Vundle, TPM, and font clones are skipped if their
  directories already exist.
- Symlinks that already point to the right source are left alone.
- Python is skipped if the pinned version is already installed via pyenv.
- The SSH key is skipped if `~/.ssh/id_ed25519_github` already exists.

Backups accumulate in `~/dotfiles-backup/` (one timestamped entry per replaced
file). That directory is safe to prune once you are confident the deployment is
correct.

---

## Security / trust notes

This bootstrap makes deliberate trust and convenience trade-offs worth
understanding before you run it:

- **Upstream installers run at install time.** Homebrew and oh-my-zsh are
  installed via the conventional `curl … | bash` pattern, executing code
  fetched from those projects' servers. This is each project's documented
  install method, but you are trusting those upstreams (and your network path)
  at run time.
- **Plugin, theme, and font clones are unpinned.** The zsh plugins,
  powerlevel10k, Vundle, TPM, and the font repositories are cloned from their
  default branch with no commit pin, so you receive whatever is current
  upstream when you run the bootstrap.
- **The generated SSH key has no passphrase.** `70-ssh.sh` creates the key with
  `-N ""` so the unattended run does not block on a prompt. For a
  passphrase-protected key, remove `-N ""` (ssh-keygen will then prompt) or
  supply one in that script before running.
- **The global pre-commit hook is opt-in.** The `pre-commit` hook (via
  `core.hooksPath`) runs a gitleaks secret scan only if `~/.pre-commit-config.yaml`
  exists. Without that file the hook is a no-op, so no secret scanning happens
  until you add the config.

---

## Linting / CI

`.github/workflows/lint.yml` runs on every push and pull request:

- **shellcheck** (`severity: warning`, warnings treated as errors) across all
  `.sh` files, excluding `.fonts-work`.
- **shfmt** formatting check (`-i 2 -ln bash`) across all `.sh` files,
  excluding `.git` and `.fonts-work`.

Run both locally before committing:

```sh
# Format check (matches CI)
find . -name '*.sh' -not -path './.git/*' -not -path './.fonts-work/*' \
  -print0 | xargs -0 shfmt -d -i 2 -ln bash

# Lint
shellcheck scripts/*.sh install.sh lib/*.sh
```

Install the tools with `brew install shellcheck shfmt` if they are not already
present.
