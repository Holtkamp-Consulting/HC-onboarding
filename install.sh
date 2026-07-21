#!/bin/bash
set -euo pipefail

# ── Helpers ──────────────────────────────────────────────────────────────────

print_step() { echo ""; echo "▶ $1"; }

require_command_line_tools() {
  if xcode-select -p &>/dev/null; then
    return
  fi

  print_step "Apple Command Line Tools"
  echo "  Apple's Command Line Tools are required before Homebrew can be installed."
  echo "  Opening Apple's installer now. Complete it, then run this onboarding command again."
  echo ""
  echo "  If macOS says the software is not available from the Software Update server:"
  echo "    1. Install pending updates in System Settings > General > Software Update"
  echo "    2. Run this onboarding command again after macOS is up to date"
  echo "    3. If it still fails, download Command Line Tools for Xcode manually:"
  echo "       https://developer.apple.com/download/all/"
  echo ""

  xcode-select --install || true
  exit 1
}

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

require_command_line_tools

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
  citrix-workspace
  chatgpt
  dbeaver-community
)

for cask in "${CASKS[@]}"; do
  install_or_upgrade "$cask"
done

# ── Auto-update service ─────────────────────────────────────────────────────────

print_step "Auto-update service"

AUTO_UPDATE_LABEL="com.holtkamp-consulting.hc-onboarding.autoupdate"
AUTO_UPDATE_DIR="$HOME/Library/Application Support/HC-onboarding"
AUTO_UPDATE_SCRIPT="$AUTO_UPDATE_DIR/auto-update.sh"
AUTO_UPDATE_PLIST="$HOME/Library/LaunchAgents/$AUTO_UPDATE_LABEL.plist"
AUTO_UPDATE_LOG="$HOME/Library/Logs/$AUTO_UPDATE_LABEL.log"
BREW_BIN="$(command -v brew)"

mkdir -p "$AUTO_UPDATE_DIR"
mkdir -p "$(dirname "$AUTO_UPDATE_PLIST")"
mkdir -p "$(dirname "$AUTO_UPDATE_LOG")"

# Generate the standalone unattended update script. Static parts use a quoted
# heredoc (no expansion); the CASKS array is injected from the live array above
# so the scheduled job can never drift out of sync with the interactive run.
cat > "$AUTO_UPDATE_SCRIPT" <<'EOF'
#!/bin/bash
set -uo pipefail

BREW_BIN="__BREW_BIN__"
if [[ -x "$BREW_BIN" ]]; then
  eval "$("$BREW_BIN" shellenv)"
fi

if ! command -v brew &>/dev/null; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') brew not found, skipping auto-update"
  exit 0
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') Starting auto-update"
brew update || true

EOF

{
  echo "CASKS=("
  printf '  %s\n' "${CASKS[@]}"
  echo ")"
  echo ""
} >> "$AUTO_UPDATE_SCRIPT"

cat >> "$AUTO_UPDATE_SCRIPT" <<'EOF'
for cask in "${CASKS[@]}"; do
  if brew list --cask "$cask" &>/dev/null; then
    if [[ -n "$(brew outdated --cask "$cask" 2>/dev/null)" ]]; then
      echo "  Upgrading $cask..."
      brew upgrade --cask "$cask" || true
    fi
  fi
done

echo "$(date '+%Y-%m-%d %H:%M:%S') Auto-update finished"
EOF

sed -i '' "s#__BREW_BIN__#$BREW_BIN#" "$AUTO_UPDATE_SCRIPT"
chmod +x "$AUTO_UPDATE_SCRIPT"

# Generate the per-user LaunchAgent plist (unquoted heredoc — variable
# expansion is wanted; none of the interpolated values contain '$').
cat > "$AUTO_UPDATE_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$AUTO_UPDATE_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$AUTO_UPDATE_SCRIPT</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>9</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
  <key>RunAtLoad</key>
  <false/>
  <key>StandardOutPath</key>
  <string>$AUTO_UPDATE_LOG</string>
  <key>StandardErrorPath</key>
  <string>$AUTO_UPDATE_LOG</string>
</dict>
</plist>
PLIST

# Register idempotently: bootout (ignoring failure when nothing is loaded yet)
# then bootstrap, so re-running this script always ends with exactly one
# registered service and never a "service already loaded" error.
UID_NUM="$(id -u)"
launchctl bootout "gui/$UID_NUM/$AUTO_UPDATE_LABEL" &>/dev/null || true
if launchctl bootstrap "gui/$UID_NUM" "$AUTO_UPDATE_PLIST"; then
  launchctl enable "gui/$UID_NUM/$AUTO_UPDATE_LABEL"
  echo "  ✓ Auto-update service installed — runs daily at 09:00"
  echo "  Logs: $AUTO_UPDATE_LOG"
else
  echo "  ! Failed to register auto-update service, skipping." >&2
fi

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "✓ All done! Open your Applications folder to find the installed apps."
echo ""
