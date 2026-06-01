# macOS Onboarding Installer — Design Spec

**Date:** 2026-06-01
**Status:** Approved

## Overview

A single Bash script (`install.sh`) that installs all required and optional tools for new employees on a fresh macOS machine. Distributed as a public GitHub repository — no token or authentication required.

## Goals

- One command gets a new employee's Mac fully set up
- Works on both fresh installs and existing machines (updates installed apps)
- No manual steps beyond pasting a single `curl | bash` command

## Distribution

The script is hosted in a public GitHub repo and run via:

```bash
curl -fsSL https://raw.githubusercontent.com/<org>/HC-onboarding/main/install.sh | bash
```

This One-Liner is provided in the onboarding documentation.

## Repository Structure

```
HC-onboarding/
├── install.sh       # Installer script
└── README.md        # One-Liner + short description
```

## Script Flow

1. **Preflight** — Verify running on macOS; print welcome message
2. **Homebrew** — Install Homebrew if not present (`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`), otherwise run `brew update`
3. **Cask installation** — For each cask: run `brew install --cask <name>` to install if missing, then `brew upgrade --cask <name>` to update if already installed (Homebrew does not auto-upgrade on `install`)
4. **Summary** — Print completion message

## Tools

| Tool | Homebrew Cask | Category |
|---|---|---|
| Bitwarden | `bitwarden` | Required |
| DisplayLink | `displaylink` | Required |
| Obsidian | `obsidian` | Required |
| Microsoft Office | `microsoft-office` | Required |
| Discord | `discord` | Required |
| Visual Studio Code | `visual-studio-code` | Optional |
| Stats | `stats` | Optional |
| Raycast | `raycast` | Optional |
| Google Chrome | `google-chrome` | Optional |

## Decisions

- **Homebrew-based**: All 9 tools have official casks; update logic is built-in
- **No interactive prompts**: Install everything — no opt-in/opt-out
- **Public repo**: No authentication required, One-Liner works out of the box
- **Update on re-run**: Script calls both `brew install --cask` and `brew upgrade --cask` per tool, so re-running always upgrades
