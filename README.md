# windoze-auto

Automated Windows installation and configuration script that installs apps via winget and game launchers (HoyoPlay, Wuthering Waves).

## Features

✅ **Automated Package Installation** - Install all Windows apps in one command using winget  
✅ **Game Launcher Setup** - Automatically download and install game launchers:
   - HoyoPlay (Genshin Impact, Honkai Star Rail, Zenless Zone Zero, etc.)
   - Wuthering Waves
✅ **Smart Downloading** - Uses curl to fetch installers with intelligent URL parsing
✅ **Trace Key Support** - Extracts trace_key from HoyoPlay API for tracking
✅ **Configuration Management** - All packages defined in `packages.json`
✅ **Terminal Configs** - Includes PowerShell profile and Alacritty terminal settings

## Installation

### Method 1: Direct PowerShell (Recommended)

Run setup.ps1 directly from GitHub:

```powershell
irm https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/setup.ps1 | iex
```

### Method 2: Using curl

```powershell
curl https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/setup.ps1 -o $env:TEMP\setup.ps1; & $env:TEMP\setup.ps1
```

## What Gets Installed

### Apps (via winget)
All packages defined in `packages.json` including:
- 7-Zip, Notepad++, WinRAR (Compression)
- Alacritty, Starship, PowerShell Preview (Terminal)
- Visual Studio Code, Neovim (Editors)
- Chrome, Firefox (Browsers)
- Git, Node.js, Python (Development)
- VLC, OBS Studio (Media)
- Discord, Bitwarden (Communication/Security)
- And more...

### Game Launchers
- **HoyoPlay** - Launcher for Hoyoverse games
- **Wuthering Waves** - Game launcher for Wuthering Waves

## Files

| File | Purpose |
|------|---------|
| `setup.ps1` | Main installation script - runs all installation steps |
| `install-launcher.ps1` | Game launcher installer (HoyoPlay & Wuthering Waves) |
| `packages.json` | List of apps to install via winget |
| `Microsoft.PowerShell_profile.ps1` | PowerShell profile customization |
| `alacritty.toml` | Alacritty terminal configuration |
| `settings.json` | Additional settings |

## How It Works

### Setup Process

1. **Phase 1: Package Installation**
   - Downloads `packages.json` from GitHub
   - Imports all packages using `winget import`
   - Cleans up temporary files

2. **Phase 2: Game Launcher Installation**
   - Fetches HoyoPlay installer using redirect parsing
   - Extracts trace_key for tracking
   - Fetches Wuthering Waves installer from JSON config
   - Downloads and installs both launchers

### HoyoPlay Download Flow

```
API Request
    ↓
HTML Response with Download Link
    ↓
Extract trace_key
    ↓
Download File with trace_key.exe
    ↓
Execute Installer
    ↓
Cleanup
```

## Requirements

- Windows 10 or later
- PowerShell 5.1+ (or PowerShell 7+)
- curl (built-in on Windows 10+)
- winget (App Installer from Microsoft Store)
- Internet connection for online installation

## Configuration

### Customize Packages

Edit `packages.json` to add/remove apps. Format:

```json
[
  {
    "PackageIdentifier": "7zip.7zip",
    "Override": "--locale=vi-VN"
  },
  {
    "PackageIdentifier": "Microsoft.VisualStudioCode"
  }
]
```

### Custom Game Launchers

Edit `install-launcher.ps1` to add more game launchers:

```powershell
Install-GameLauncher `
    -Name "Your Game" `
    -Url $YourGameUrl `
    -InstallerPath "$TempDir\YourGame-installer.exe" `
    -UrlType 'json' # or 'redirect'
```

## Terminal Configuration

### PowerShell Profile

Copy `Microsoft.PowerShell_profile.ps1` to:
```
$PROFILE
```

## Troubleshooting

### "curl is not installed"
- curl comes pre-installed when install via setup.ps1
- For older Windows, install via winget: `winget install cURL.cURL`

### "winget not found"
- Install "App Installer" from Microsoft Store
- Or download from: https://aka.ms/wingetcli

### "Failed to download installer"
- Check internet connection
- Verify firewall isn't blocking curl/downloads
- Try running PowerShell as Administrator

### "Cannot find path" errors
- Ensure temp directory exists: `$env:TEMP\windoze-launchers`
- Script creates it automatically, but check permissions

## Support

For issues or feature requests, please create an issue on GitHub.

## License

MIT License - feel free to use and modify

## Author

dungdinhmanh

---

**Note**: This script is designed for personal use on Windows machines. Always review scripts before running, especially those downloaded from the internet.
