#!/bin/bash
set -euo pipefail

# ── Helpers ──────────────────────────────────────────────────────────────────

print_step() { echo ""; echo "▶ $1"; }

install_or_upgrade() {
  local cask="$1"
  if brew list --cask "$cask" &>/dev/null; then
    if [[ -n "$(brew outdated --cask "$cask" 2>/dev/null)" ]]; then
      echo "  ↑ Updating $cask..."
      brew upgrade --cask "$cask" || true
    else
      echo "  ✓ $cask already up to date"
    fi
  else
    echo "  + Installing $cask..."
    local output
    if ! output=$(brew install --cask "$cask" 2>&1); then
      local app_path
      app_path=$(echo "$output" | grep -o "'/Applications/[^']*'" | tr -d "'")
      if [[ -n "$app_path" ]]; then
        echo "  ✗ Removing existing $(basename "$app_path")..."
        sudo rm -rf "$app_path" || true
        brew install --cask "$cask" || echo "  ! Failed to install $cask, skipping." >&2
      else
        echo "  ! Failed to install $cask, skipping." >&2
      fi
    fi
  fi
}

# ── Preflight ─────────────────────────────────────────────────────────────────

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This script only runs on macOS." >&2
  exit 1
fi

# Authenticate once and keep sudo session alive for the duration of the script
sudo -v
while true; do sudo -n true; sleep 50; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

echo ""
echo "╔══════════════════════════════════╗"
echo "║   HC Onboarding — Mac Setup      ║"
echo "╚══════════════════════════════════╝"

# ── Homebrew ─────────────────────────────────────────────────────────────────

print_step "Homebrew"

if ! command -v brew &>/dev/null; then
  echo "  Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon Macs and persist to shell profile
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  fi

  brew update
else
  echo "  Updating Homebrew..."
  brew update
fi

# ── Tools ─────────────────────────────────────────────────────────────────────

print_step "Installing tools"

CASKS=(
  bitwarden
  displaylink
  obsidian
  microsoft-office
  discord
  visual-studio-code
  stats
  raycast
  google-chrome
)

for cask in "${CASKS[@]}"; do
  install_or_upgrade "$cask"
done

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "✓ All done! Open your Applications folder to find the installed apps."
echo ""
