<#
.SYNOPSIS
    Windoze Auto - Automated Windows Setup Script
    
.DESCRIPTION
    Clones the windoze-auto repository, runs installation scripts,
    copies configuration files, and cleans up automatically.
    
.EXAMPLE
    irm https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/setup.ps1 | iex
#>

# Configuration
$repoUrl = 'https://github.com/dungdinhmanh/windoze-auto.git'
$repoName = 'windoze-auto'
$clonePath = Join-Path $env:TEMP $repoName
$notepad_catpuccin = 'https://raw.githubusercontent.com/catppuccin/notepad-plus-plus/main/themes/catppuccin-mocha.xml'

function Invoke-Setup {
    try {
        Write-Host ""
        Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║  Windoze Auto Setup                    ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        # Step 1: Clone repository
        Write-Host "Step 1: Cloning repository..." -ForegroundColor Yellow
        if (Test-Path $clonePath) {
            Remove-Item -Path $clonePath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Check if git is available
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Host "Git not found. Installing via winget..." -ForegroundColor Yellow
            winget install Git.Git --accept-source-agreements --accept-package-agreements -q
        }
        
        git clone $repoUrl $clonePath
        if (-not (Test-Path $clonePath)) {
            throw "Failed to clone repository"
        }
        Write-Host "Repository cloned successfully" -ForegroundColor Green
        Write-Host ""
        
        # Step 2: Install packages
        Write-Host "Step 2: Installing packages via winget..." -ForegroundColor Yellow
        $packagesPath = Join-Path $clonePath "config\packages.json"
        
        if (Test-Path $packagesPath) {
            Invoke-WebRequest $packagesPath -OutFile packages.json -ErrorAction Stop
            winget import -i packages.json --accept-source-agreements --accept-package-agreements
            Remove-Item -Path packages.json -Force
            Write-Host "Packages installed successfully" -ForegroundColor Green
        } else {
            Write-Host "packages.json not found, skipping..." -ForegroundColor Yellow
        }
        Write-Host ""
        
        # Step 3: Run game launcher installer
        Write-Host "Step 3: Installing game launchers..." -ForegroundColor Yellow
        $launcherScript = Join-Path $clonePath "install_script\install-launcher.ps1"
        
        if (Test-Path $launcherScript) {
            & $launcherScript
            Write-Host "Game launchers installed successfully" -ForegroundColor Green
        } else {
            Write-Host "install-launcher.ps1 not found, skipping..." -ForegroundColor Yellow
        }
        Write-Host ""
        
        # Step 4: Run font installer
        Write-Host "Step 4: Installing fonts..." -ForegroundColor Yellow
        $fontScript = Join-Path $clonePath "install_script\install-font.ps1"
        
        if (Test-Path $fontScript) {
            & $fontScript
            Write-Host "Fonts installed successfully" -ForegroundColor Green
        } else {
            Write-Host "install-font.ps1 not found, skipping..." -ForegroundColor Yellow
        }
        Write-Host ""
        
        # Step 5: Copy configuration files
        Write-Host "Step 5: Copying configuration files..." -ForegroundColor Yellow
        
        # Create .config directory if it doesn't exist
        $configDir = "$HOME\.config"
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        # PowerShell Profile
        $pwshProfile = Join-Path $clonePath "config\Microsoft.PowerShell_profile.ps1"
        if (Test-Path $pwshProfile) {
            $pwshProfileDir = "$HOME\Documents\PowerShell"
            if (-not (Test-Path $pwshProfileDir)) {
                New-Item -ItemType Directory -Path $pwshProfileDir -Force | Out-Null
            }
            Copy-Item -Path $pwshProfile -Destination "$pwshProfileDir\Microsoft.PowerShell_profile.ps1" -Force
            Write-Host "Copied PowerShell profile" -ForegroundColor Green
        }
        
        # Starship config
        $starshipConfig = Join-Path $clonePath "config\starship.toml"
        if (Test-Path $starshipConfig) {
            Copy-Item -Path $starshipConfig -Destination "$HOME\starship.toml" -Force -ErrorAction SilentlyContinue
            Write-Host "Copied Starship config to $HOME" -ForegroundColor Green
        }
        
        # Fastfetch config
        $fastfetchConfig = Join-Path $clonePath "config\fastfetch"
        if (Test-Path $fastfetchConfig) {
            $fastfetchDir = "$configDir\fastfetch"
            if (Test-Path $fastfetchDir) {
                Remove-Item -Path $fastfetchDir -Recurse -Force
            }
            Copy-Item -Path $fastfetchConfig -Destination $fastfetchDir -Recurse -Force
            Write-Host "Copied Fastfetch config" -ForegroundColor Green
        }
        
        # YASB config
        $yasbConfig = Join-Path $clonePath "config\yasb"
        if (Test-Path $yasbConfig) {
            $yasbDir = "$configDir\yasb"
            if (Test-Path $yasbDir) {
                Remove-Item -Path $yasbDir -Recurse -Force
            }
            Copy-Item -Path $yasbConfig -Destination $yasbDir -Recurse -Force
            Write-Host "Copied YASB config" -ForegroundColor Green
        }
        
        # Windows Terminal settings
        $terminalSettings = Join-Path $clonePath "config\settings.json"
        if (Test-Path $terminalSettings) {
            $terminalDir = "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
            if (Test-Path $terminalDir) {
                Copy-Item -Path $terminalSettings -Destination "$terminalDir\settings.json" -Force
                Write-Host "Copied Windows Terminal settings" -ForegroundColor Green
            }
        }
        
        # Notepad++ Catppuccin theme
        $notepadThemesDir = "C:\Program Files\Notepad++\themes"
        if (Test-Path $notepadThemesDir) {
            try {
                Invoke-WebRequest -Uri $notepad_catpuccin -OutFile "$notepadThemesDir\catppuccin-mocha.xml" -ErrorAction Stop
                Write-Host "Copied Notepad++ theme" -ForegroundColor Green
            } catch {
                Write-Host "Failed to download Notepad++ theme" -ForegroundColor Yellow
            }
        }
        Write-Host ""
        
        # Step 6: Install PowerShell modules
        Write-Host "Step 6: Installing PowerShell modules..." -ForegroundColor Yellow
        try {
            Install-Module -Name Terminal-Icons -Repository PSGallery -Force -Confirm:$false -ErrorAction Stop
            Write-Host "Terminal-Icons installed successfully" -ForegroundColor Green
        } catch {
            Write-Host "Failed to install Terminal-Icons: $_" -ForegroundColor Yellow
        }
        Write-Host ""
        
        # Cleanup
        Write-Host "Step 7: Cleaning up..." -ForegroundColor Yellow
        if (Test-Path $clonePath) {
            Remove-Item -Path $clonePath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Repository cleaned up" -ForegroundColor Green
        }
        Write-Host ""
        
        Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║  Setup Complete!                       ║" -ForegroundColor Green
        Write-Host "║  All configurations installed          ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host ""
        
        # Cleanup on error
        if (Test-Path $clonePath) {
            Write-Host "Cleaning up after error..." -ForegroundColor Yellow
            Remove-Item -Path $clonePath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Run setup
Invoke-Setup

Write-Host "Press any key to exit..."
$null = [System.Console]::ReadKey($true)
