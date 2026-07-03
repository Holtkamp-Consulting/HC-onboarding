# HC Onboarding

Installs all tools needed for a new employee's Mac in one command.

The installer runs on macOS, asks for administrator access once, installs
Homebrew if needed, updates Homebrew, and then installs or upgrades all listed
apps via Homebrew Cask. If Apple's Command Line Tools are missing, the script
starts Apple's installer automatically.

## Usage

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Holtkamp-Consulting/HC-onboarding/main/install.sh)"
```

## Requirements

- macOS
- Internet connection
- Administrator password for `sudo`
- Current macOS software updates installed

An Apple ID is not required for the normal installation flow. If Apple's
Command Line Tools cannot be installed through Software Update, manually
downloading them from Apple Developer Downloads may require signing in with an
Apple ID.

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

## Troubleshooting

### Command Line Tools cannot be installed

Homebrew requires Apple's Command Line Tools. On a fresh Mac, the onboarding
script opens the Command Line Tools installer automatically. If macOS shows:

```text
The software cannot be installed because it is currently not available from the Software Update server.
```

or, in German:

```text
Die Software kann nicht installiert werden, da sie derzeit auf dem Softwareupdateserver nicht verfügbar ist.
```

this usually means the Mac is missing current macOS software updates. Install
all pending updates in **System Settings → General → Software Update** first.

After the Mac is up to date, run the onboarding command again. The script will
start the Command Line Tools installer again if they are still missing.

You can also trigger the installer manually with:

```bash
xcode-select --install
```

If the same error still appears after all macOS updates are installed, download
the matching "Command Line Tools for Xcode" package manually from:

https://developer.apple.com/download/all/

After the Command Line Tools are installed, run the onboarding command again.
