#!/bin/bash
set -euo pipefail

# ── Helpers ──────────────────────────────────────────────────────────────────

print_step() { echo ""; echo "▶ $1"; }

install_or_upgrade() {
  local cask="$1"
  if brew list --cask "$cask" &>/dev/null; then
    echo "  ↑ Updating $cask..."
    brew upgrade --cask "$cask"
  else
    echo "  + Installing $cask..."
    brew install --cask "$cask"
  fi
}

# ── Preflight ─────────────────────────────────────────────────────────────────

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This script only runs on macOS." >&2
  exit 1
fi

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
