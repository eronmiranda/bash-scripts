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

# TODO: if needed, add command(s) to do minimal or full installation
usage() {
  cat <<EOF
Usage: $ME [OPTION]

Setups personal dev environment on a MacOS laptop.
Installs CLI tools, GUI applications, and fonts.

Available options:
  -h, --help
      Print this help message

  -x, --debug
      Enable debugging

EOF

  exit "$1"
}

OS="$(uname)"
[[ "$OS" != "Darwin" ]] && die "Unsupported operating system ${OS}"

OPTION="${1:-}"

case "$OPTION" in
  -h|--help) usage 0;;
  -x|--debug) set -x;;
  -*) 
    log "${OPTION}: no such option"
    usage 1
    ;;
esac

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
CLI_TOOLS=("coreutils" "node" "jq" "yq" "1password-cli" "python3" "terraform" "gh")
for tool in "${CLI_TOOLS[@]}"; do
  log "${tool}: verifying installation status"
  if ! brew list "$tool" &> /dev/null; then
    log "${tool}: installing..."
    brew install "$tool"
  fi
done

log "installing GUI applications..."
GUI_APPS=("google-chrome" "visual-studio-code" "docker" "postman" "microsoft-outlook" "slack" "spotify" "notion" "vlc" "linearmouse" "1password" "github")
for app in "${GUI_APPS[@]}"; do
  log "${app}: verifying installation status"
  if ! brew list --cask "$app" &>/dev/null; then
    log "${app}: installing..."
    brew install --cask "$app"
  fi
done

log "installing fonts..."
log "font-jetbrains-mono: verifying installation status"
if ! brew list --cask font-jetbrains-mono &>/dev/null; then
  log "font-jetbrains-mono: installing..."
  brew tap homebrew/cask-fonts
  brew install --cask font-jetbrains-mono
fi

if [ ! -d "${HOME}/src/github" ]; then
  log "${HOME}/src/github: creating directory for your github repos..."
  mkdir -p "${HOME}/src/github"
fi
# add additional directories here if needed

# Below commands will change default settings on apps

automatic_spelling_correction=$(defaults read NSGlobalDomain NSAutomaticSpellingCorrectionEnabled)
if [[ "$automatic_spelling_correction" != "0" ]]; then
  log "global preference: disabling automatic spelling correction"
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
fi

PLISTBUDDY="/usr/libexec/PlistBuddy"

DOCK_PLIST="${HOME}/Library/Preferences/com.apple.dock.plist"
log "dock: changing default settings..." 
log "dock: creating a copy of original ${DOCK_PLIST}"
cp "$DOCK_PLIST" "${DOCK_PLIST}.backup"

dock_autohide=$("$PLISTBUDDY" -c "Print :autohide-time-modifier" "$DOCK_PLIST")
if [[ "$dock_autohide" != "0" ]]; then
  log "dock: removing auto-hide animation"
  "$PLISTBUDDY" -c "Set :autohide-time-modifier 0" "$DOCK_PLIST"
  killall Dock
fi

TERMINAL_PLIST="${HOME}/Library/Preferences/com.apple.Terminal.plist"
TERMINAL_PROFILE="Homebrew"
log "terminal: changing default settings..."
log "terminal: creating a copy of original ${TERMINAL_PLIST}"
cp "$TERMINAL_PLIST" "${TERMINAL_PLIST}.backup"

terminal_default_theme=$("$PLISTBUDDY" -c "Print:'Default Window Settings'" "$TERMINAL_PLIST")
if [[ "$terminal_default_theme" != "$TERMINAL_PROFILE" ]]; then
  log "terminal: setting the default theme to ${TERMINAL_PROFILE}"
  "$PLISTBUDDY" -c "Set :'Default Window Settings' '${TERMINAL_PROFILE}'" "$TERMINAL_PLIST"
fi

terminal_startup_theme=$("$PLISTBUDDY" -c "Print:'Startup Window Settings'" "$TERMINAL_PLIST")
if [[ "$terminal_startup_theme" != "$TERMINAL_PROFILE" ]]; then
  log "terminal: setting the startup theme to ${TERMINAL_PROFILE}"
  "$PLISTBUDDY" -c "Set :'Startup Window Settings' '${TERMINAL_PROFILE}'" "$TERMINAL_PLIST"
fi

set +e
terminal_option_metakey=$("$PLISTBUDDY" -c "Print :'Window Settings':'${TERMINAL_PROFILE}':'useOptionAsMetaKey'" "$TERMINAL_PLIST" 2>/dev/null)
set -e
if [[ "$terminal_option_metakey" != "true" ]]; then
  log "terminal: enabling useOptionAsMetaKey"
  "$PLISTBUDDY" -c "Set :'Window Settings':'${TERMINAL_PROFILE}':'useOptionAsMetaKey' true" "$TERMINAL_PLIST" 2>/dev/null || \
  "$PLISTBUDDY" -c "Add :'Window Settings':'${TERMINAL_PROFILE}':'useOptionAsMetaKey' bool true" "$TERMINAL_PLIST"
fi

set +e
terminal_audible_bell=$("$PLISTBUDDY" -c "Print :'Window Settings':'${TERMINAL_PROFILE}':Bell" "$TERMINAL_PLIST" 2>/dev/null)
set -e
if [[ "$terminal_audible_bell" != "false" ]]; then
  log "terminal: disabling audible bell"
  "$PLISTBUDDY" -c "Set :'Window Settings':'${TERMINAL_PROFILE}':Bell false" "$TERMINAL_PLIST" 2>/dev/null || \
  "$PLISTBUDDY" -c "Add :'Window Settings':'${TERMINAL_PROFILE}':Bell bool false" "$TERMINAL_PLIST"
fi

terminal_secure_keyboard=$("$PLISTBUDDY" -c "Print:SecureKeyboardEntry" "$TERMINAL_PLIST")
if [[ "$terminal_secure_keyboard" != "true" ]]; then
  log "terminal: enabling secure keyboard entry"
  "$PLISTBUDDY" -c "Set :SecureKeyboardEntry true" "$TERMINAL_PLIST"
fi

log "terminal: restart to see changes"
