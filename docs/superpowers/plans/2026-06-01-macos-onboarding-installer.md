# macOS Onboarding Installer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A single `install.sh` script that installs and updates 9 tools on a new employee's Mac via Homebrew casks, distributed from a public GitHub repo.

**Architecture:** Bash script with a reusable `install_or_upgrade` helper that checks whether each cask is already installed and calls `brew install` or `brew upgrade` accordingly. Homebrew itself is bootstrapped at the start if absent.

**Tech Stack:** Bash, Homebrew (casks)

---

### Task 1: Initialize git repo and README

**Files:**
- Create: `README.md`
- Create: `.gitignore`

- [ ] **Step 1: Initialize git repo**

```bash
cd /Users/marvinwarnke/Documents/git/HC-onboarding
git init
```

Expected: `Initialized empty Git repository in .../HC-onboarding/.git/`

- [ ] **Step 2: Create .gitignore**

```bash
cat > .gitignore << 'EOF'
.DS_Store
EOF
```

- [ ] **Step 3: Create README.md**

Create `README.md` with this exact content:

```markdown
# HC Onboarding

Installs all tools needed for a new employee's Mac in one command.

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/<ORG>/HC-onboarding/main/install.sh | bash
```

## What gets installed

| Tool | Type |
|---|---|
| Bitwarden | Password manager |
| DisplayLink | External display driver |
| Obsidian | Notes |
| Microsoft Office | Office suite |
| Discord | Communication |
| Visual Studio Code | Editor |
| Stats | System monitor |
| Raycast | Launcher |
| Google Chrome | Browser |

Re-running the script updates all tools to their latest version.
```

- [ ] **Step 4: Commit**

```bash
git add README.md .gitignore
git commit -m "chore: init repo with README"
```

---

### Task 2: Write install.sh — skeleton and Homebrew bootstrap

**Files:**
- Create: `install.sh`

- [ ] **Step 1: Verify syntax checking works**

```bash
echo '#!/bin/bash' > install.sh && bash -n install.sh && echo "syntax OK"
```

Expected: `syntax OK`

- [ ] **Step 2: Write the full skeleton with Homebrew bootstrap**

Replace `install.sh` with:

```bash
#!/bin/bash
set -euo pipefail

# ── Helpers ──────────────────────────────────────────────────────────────────

print_step() { echo ""; echo "▶ $1"; }

install_or_upgrade() {
  local cask="$1"
  if brew list --cask "$cask" &>/dev/null 2>&1; then
    echo "  ↑ Updating $cask..."
    brew upgrade --cask "$cask" || echo "  ✓ $cask is already up to date"
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

  # Add Homebrew to PATH for Apple Silicon Macs
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
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
```

- [ ] **Step 3: Verify syntax**

```bash
bash -n install.sh && echo "syntax OK"
```

Expected: `syntax OK`

- [ ] **Step 4: Make executable**

```bash
chmod +x install.sh
```

- [ ] **Step 5: Commit**

```bash
git add install.sh
git commit -m "feat: add install.sh with Homebrew bootstrap and cask installation"
```

---

### Task 3: Verify the script end-to-end

**Files:**
- Read: `install.sh`

- [ ] **Step 1: Dry-run syntax check**

```bash
bash -n install.sh && echo "syntax OK"
```

Expected: `syntax OK`

- [ ] **Step 2: Check all cask names are valid**

```bash
brew info --cask bitwarden displaylink obsidian microsoft-office discord visual-studio-code stats raycast google-chrome 2>&1 | grep -E "^(Error|==>)" | head -20
```

Expected: Lines starting with `==>` for each cask, no `Error:` lines.

- [ ] **Step 3: Verify the install_or_upgrade logic on an already-installed cask**

If any of the casks happen to be installed locally, run:

```bash
bash -c "$(grep -A8 'install_or_upgrade()' install.sh | head -10)"
brew list --cask google-chrome &>/dev/null && echo "cask check works"
```

Expected: no errors, confirms the list check works.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: verify cask names and script syntax"
```
