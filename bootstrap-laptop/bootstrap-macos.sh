#!/bin/bash

set -euo pipefail

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ME=$(basename "$0")

log() {
  >&2 echo "${ME}: $*"
}

die() {
  log "$@"
  exit 1
}

usage() {
  log "Usage: ./bootstrap_macos.sh"
  # defaults to install everything
  # if needed, add commands to install: cli tools only, GUI applications only, and fonts only
  exit "$1"
}

OS="$(uname)"
[[ "$OS" != "Darwin" ]] && die  "Unsupported operating system ${OS}"

OPTION="${1:-}"
[[ "$OPTION" == "-h" || "$OPTION" == "--help" ]] && usage 0

log "xcode-select: verifying installation status"
if ! xcode-select -p &> /dev/null; then
  log "xcode-select: installing..."
  xcode-select --install
  log "xcode-select: check 'Install Command Line Developer Tools' prompt"
  until xcode-select -p &>/dev/null; do
    echo "xcode-select: waiting to finish installing..."
    sleep 30
  done
  log "xcode-select: installed successfully"
fi
log "brew: verifying installation status"
if ! which brew &> /dev/null; then
  log "brew: installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  log "brew: adding Homebrew to PATH"
  case "$SHELL" in
    /bin/bash)
      # shellcheck disable=SC2016
      (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> "${HOME}/.bash_profile"
      ;;
    /bin/zsh)
      # shellcheck disable=SC2016
      (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> "${HOME}/.zprofile"
      ;;
    *) die "${SHELL}: unsupported shell environment"
  esac
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  log "brew: upgrading to latest packages"
  brew upgrade
fi

log "installing command-line tools..."
cli_tools=("coreutils" "node" "jq" "yq" "1password-cli" "python3" "terraform" "gh")
for tool in "${cli_tools[@]}"; do
  log "${tool}: verifying installation status"
  if ! brew list "$tool" &> /dev/null; then
    brew install "$tool"
  else
    log "${tool}: already installed"
  fi
done

log "installing GUI applications..."
gui_apps=("google-chrome" "visual-studio-code" "docker" "postman" "microsoft-outlook" "slack" "spotify" "notion" "vlc" "linearmouse" "1password" "github")
for app in "${gui_apps[@]}"; do
  log "${app}: verifying installation status"
  if ! brew list --cask "$app" &>/dev/null; then
    brew install --cask "$app"
  else
    log "${app}: already installed"
  fi
done

log "installing fonts..."
log "font-jetbrains-mono: verifying installation status"
if ! brew list --cask font-jetbrains-mono &>/dev/null; then
  brew tap homebrew/cask-fonts
  brew install --cask font-jetbrains-mono
else
  log "font-jetbrains-mono: already installed."
fi

log "removing auto-hide animation from Dock"
autohide_setting=$(defaults read com.apple.dock autohide-time-modifier)
if [[ "$autohide_setting" != "0" ]]; then
  defaults write com.apple.dock autohide-time-modifier -int 0
  killall Dock
else
  log "dock auto-hide delay time is already set to 0"
fi

# Creates a directory to store github repositories
[ -d "${HOME}/src/github" ] || mkdir -p "${HOME}/src/github"
