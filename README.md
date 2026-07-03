# HC Onboarding

Installs all tools needed for a new employee's Mac in one command.

The installer runs on macOS, asks for administrator access once, installs
Homebrew if needed, updates Homebrew, and then installs or upgrades all listed
apps via Homebrew Cask. If Apple's Command Line Tools are missing, they may be
installed as part of the Homebrew setup.

## Usage

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Holtkamp-Consulting/HC-onboarding/main/install.sh)"
```

## Requirements

- macOS
- Internet connection
- Administrator password for `sudo`

## What gets installed

| Tool | Type |
|---|---|
| Apple Command Line Tools | Developer tools required by Homebrew |
| Homebrew | Package manager |
| Bitwarden | Password manager |
| DisplayLink | External display driver |
| Obsidian | Notes |
| Microsoft Office | Office suite |
| Discord | Communication |
| Visual Studio Code | Editor |
| Stats | System monitor |
| Raycast | Launcher |
| Google Chrome | Browser |
| Citrix Receiver / Citrix Workspace | Remote desktop client |
| ChatGPT | AI assistant |
| DBeaver Community | Database client |

Re-running the script updates Homebrew and upgrades installed apps when newer
versions are available.
