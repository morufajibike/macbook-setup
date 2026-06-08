# Brewfile — curated, grouped package list for this machine.
#
# Entries are organised into groups, each introduced by a marker line:
#   # group: <name>
# Every line that follows a marker belongs to that group until the next marker.
#
# This file is STILL a valid Brewfile: `brew bundle --file=Brewfile` ignores
# the comment markers and installs everything. The per-group selection is done
# by scripts/00-brew.sh, which prompts you per group and assembles only the
# selected groups into a temporary Brewfile before calling brew bundle.
#
# Groups (and their default prompt): core is recommended (default yes); all
# other groups default to no, so a fresh machine installs only what you pick.
#
# To refresh from this machine:
#   brew bundle dump --file=Brewfile --force
# NOTE: `brew bundle dump` does NOT preserve the `# group:` markers — after a
# dump you must re-add them (and re-sort entries into the right groups) by hand
# before committing, or scripts/00-brew.sh's grouping will be lost.
#
# Taps note: homebrew/cask-versions is deliberately excluded — it was
# deprecated in 2024 and its versioned casks were migrated into homebrew/cask.
#
# Casks deliberately excluded:
#   fig              — discontinued
#   docker-desktop   — replaced by colima + docker formula
#   iterm2           — replaced by ghostty
#   wezterm@nightly  — not in regular use

# group: core
# Always recommended: shell, git essentials, and the prompt font. The font is
# kept here because the Ghostty/powerlevel10k prompt glyphs need it regardless
# of which terminal or apps are chosen.
tap "homebrew/services"
brew "bash-completion"
brew "bat"
brew "coreutils"
brew "gawk"
brew "gh"
brew "git-lfs"
brew "jq"
brew "pre-commit"
brew "tmux"
brew "tree"
brew "wget"
brew "zsh"
cask "font-meslo-lg-nerd-font"

# group: cloud-devops
tap "derailed/k9s"
brew "actionlint"
brew "ansible"
brew "argocd"
brew "awscli"
brew "azure-cli"
brew "checkov"
brew "colima"
brew "docker"
brew "docker-compose"
brew "helm"
brew "infracost"
brew "derailed/k9s/k9s"
brew "minikube"
brew "stern"
brew "terraform-docs"
brew "terragrunt"
brew "tfenv"
brew "tflint"
brew "tfsort"
brew "trivy"

# group: languages
brew "ipython"
brew "node"
brew "openjdk@11"
brew "openssl@1.1"
brew "pipenv"
brew "pyenv"
brew "python@3.10"
brew "uv"

# group: databases
brew "mysql"
brew "postgresql@17"

# group: apps
cask "adobe-acrobat-reader"
cask "docker"
cask "dropbox"
cask "firefox"
cask "flux"
cask "ghostty"
cask "google-chrome"
cask "visual-studio-code"
