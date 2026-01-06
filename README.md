# windoze-auto

Automated Windows installation and configuration script that installs apps via winget, game launchers (HoyoPlay, Wuthering Waves), Office 365 with Ohook activation, and fonts.

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
- **HoyoPlay** - Launcher for Hoyoverse games with automatic trace key handling
- **Wuthering Waves** - Game launcher with automatic configuration download

### Office 365
- **Microsoft Office 365 ProPlus** - Full Office suite with exclusions (Access, Teams, etc.)
- **Ohook Activation** - Automatic activation using Microsoft Activation Scripts
- **Office Tool Plus** - Enterprise deployment via API-generated configuration

### Fonts
- **Maple Mono NF CN** - Programming font with complete character set
- **Auto-hash verification** - SHA256 integrity checking
- **Silent installation** - Background font registration

## Files

| File | Purpose |
|------|---------|
| `setup.ps1` | Main installation script - runs all installation steps with auto NuGet provider |
| `install-launcher.ps1` | Game launcher installer with enhanced curl handling and error checking |
| `install-office.ps1` | Office 365 installer with Office Tool Plus API and Ohook activation |
| `install-font.ps1` | Font installer with progress display and hash verification |
| `packages.json` | List of apps to install via winget |
| `config/offices.xml` | Office configuration template (legacy, now uses API) |
| `Microsoft.PowerShell_profile.ps1` | PowerShell profile customization |
| `config/starship.toml` | Starship shell configuration |
| `config/fastfetch/config.jsonc` | Fastfetch system info display configuration |
| `config/yasb/` | Yet Another Status Bar configuration |
| `config/settings.json` | Additional settings |

## Requirements

- Windows 10 or later
- PowerShell 5.1+ (or PowerShell 7+)
- curl (install from packages.json)
- winget (Built-in package manager)
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

## Configuration

### Office Installation
The Office installer uses Office Tool Plus API for automatic configuration generation:
- **API Endpoint**: `https://server-win.ccin.top/office-tool-plus/api/xml_generator/`
- **Products**: `O365ProPlusRetail_MatchOS` with exclusions for Access, Teams, etc.
- **Channel**: `Current` (BetaChannel)
- **Activation**: Automatic Ohook activation after installation

### Font Installation
Maple Mono NF CN font installation includes:
- **Progress display**: Shows download progress with visual indicators
- **Hash verification**: SHA256 integrity checking for downloaded files
- **Auto-retry**: Handles network issues gracefully
- **Batch installation**: Installs all font variants at once

### Game Launcher Configuration
Enhanced launcher installation with:
- **URL handling**: Supports both redirect and JSON-based URL types
- **Trace key extraction**: Automatic handling for HoyoPlay trace keys
- **Error handling**: Comprehensive error checking and user feedback
- **Cleanup**: Automatic cleanup of temporary files

### PowerShell Profile
Enhanced with auto NuGet provider installation:
- **Auto-accept**: `-AcceptLicense` parameter for non-interactive installation
- **Force installation**: `-Force` parameter to skip confirmation prompts
- **Module management**: Automatic Terminal-Icons module installation

Copy `Microsoft.PowerShell_profile.ps1` to:
```
$PROFILE
```

## Troubleshooting

### "curl is not installed"
- curl comes pre-installed when install via setup.ps1
- For older Windows, install via winget: `winget install cURL.cURL`
- Verify curl path: `Test-Path "C:\Windows\System32\curl.exe"`

### "winget not found"
- Install "App Installer" from Microsoft Store
- Or download from: https://aka.ms/wingetcli
- Check Windows version: winget requires Windows 10 1809+ or Windows 11

### "Failed to download installer"
- Check internet connection and proxy settings
- Verify firewall isn't blocking curl/downloads
- Try running PowerShell as Administrator
- Check disk space (minimum 5GB free space recommended)

### Office Installation Issues
- **Office Tool Plus download fails**: Check internet connection and retry
- **Activation fails**: Ensure Office installation completed successfully
- **XML generation error**: Verify API endpoint accessibility

### Font Installation Issues
- **Hash verification fails**: File may be corrupted, retry download
- **Font files not found**: Check archive integrity, ensure TTF files exist
- **Permission errors**: Run PowerShell as Administrator for system font installation

### Game Launcher Issues
- **HoyoPlay trace key**: Script automatically extracts, check download URL
- **JSON parsing error**: Verify API response structure
- **Installer validation**: File size check ensures valid downloads

### "Cannot find path" errors
- Ensure temp directories exist: `$env:TEMP\windoze-auto`
- Script creates directories automatically, but check permissions
- Verify user has write access to temp and system directories

### PowerShell Module Issues
- **NuGet provider**: Script auto-installs with `-AcceptLicense`
- **Module installation**: Check execution policy: `Get-ExecutionPolicy`
- **Network issues**: Verify PSGallery access: `Install-Module -Name PowerShellGet -Force`

## Support

For issues or feature requests, please create an issue on GitHub.

## License

MIT License - feel free to use and modify

## Author

dungdinhmanh

---

**Note**: This script is designed for personal use on Windows machines. Always review scripts before running, especially those downloaded from the internet.
