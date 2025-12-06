<#
.SYNOPSIS
    Game launcher installer script.

.DESCRIPTION
    Downloads and installs game launchers:
    - HoyoPlay launcher (Genshin Impact, Honkai Star Rail, etc.)
    - Wuthering Waves launcher

    This script is called by setup.ps1 after all apps are installed.
    Uses curl to download games and parses JSON/HTML responses.

    Usage: .\install-launcher.ps1
#>

param(
    [string]$HoyoPlayUrl = 'https://sg-public-api.hoyoverse.com/event/download_porter/trace/hyp_global/hyphoyoverse/default?url=https%3A%2F%2Fhoyoplay.hoyoverse.com%2F',
    [string]$WutheringWavesConfigUrl = 'https://download.kurogames.net/mc_WnGtDn85y8lJB4mTmYHYuNjIl9n6YGVm/official/global/en/pc_app.json',
    [string]$TempDir = "$env:TEMP\windoze-launchers"
)

# Create temp directory
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force -ErrorAction SilentlyContinue | Out-Null
}

function Get-RedirectUrl {
    param([string]$Url)
    
    try {
        Write-Host "Fetching download link..." -ForegroundColor Yellow
        
        # Use curl to get the HTML response (without -L flag to get the redirect page)
        $response = curl -s $Url
        
        # Parse the href from the HTML response
        # Pattern: <a href="actual_download_url">Found</a>
        if ($response -match 'href="([^"]+)"') {
            $actualUrl = $matches[1]
            Write-Host "Found actual download URL" -ForegroundColor Green
            return $actualUrl
        } else {
            throw "Could not extract download URL from response"
        }
    } catch {
        throw "Failed to get redirect URL: $_"
    }
}

function Get-JsonField {
    param(
        [string]$JsonUrl,
        [string]$FieldName
    )
    
    try {
        Write-Host "Fetching configuration..." -ForegroundColor Yellow
        
        # Use curl to get JSON response
        $jsonResponse = curl -s $JsonUrl
        
        # Parse JSON
        $json = ConvertFrom-Json -InputObject $jsonResponse -ErrorAction Stop
        
        # Get the field value (try primary first, fallback to secondary/third)
        if ($json.$FieldName) {
            Write-Host "Found $FieldName download URL" -ForegroundColor Green
            return $json.$FieldName
        } elseif ($json.primary) {
            Write-Host "Using primary mirror for $FieldName" -ForegroundColor Green
            return $json.primary
        } else {
            throw "Could not find download URL in JSON"
        }
    } catch {
        throw "Failed to get JSON field: $_"
    }
}

function Install-GameLauncher {
    param(
        [string]$Name,
        [string]$Url,
        [string]$InstallerPath,
        [string]$UrlType = 'redirect' # 'redirect' or 'json'
    )
    
    try {
        Write-Host ""
        Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║  Installing $Name" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        # Check if curl is available
        if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
            throw "curl is not installed or not in PATH"
        }
        
        # Get the actual download URL
        $downloadUrl = if ($UrlType -eq 'json') {
            Get-JsonField -JsonUrl $Url -FieldName 'primary'
        } else {
            Get-RedirectUrl -Url $Url
        }
        
        Write-Host "Download URL: $downloadUrl" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Downloading $Name installer..." -ForegroundColor Yellow
        
        # Download the installer
        curl -L -o $InstallerPath $downloadUrl
        
        if (-not (Test-Path $InstallerPath)) {
            throw "Failed to download $Name installer"
        }
        
        $fileSize = (Get-Item $InstallerPath).Length / 1MB
        Write-Host "Downloaded $Name installer ($([math]::Round($fileSize, 2)) MB)" -ForegroundColor Green
        Write-Host ""
        Write-Host "Running $Name installer..." -ForegroundColor Yellow
        
        Start-Process -FilePath $InstallerPath -Wait
        
        Write-Host "$Name installation completed" -ForegroundColor Green
        
    } catch {
        Write-Host "Error during $Name installation: $_" -ForegroundColor Red
        Write-Host ""
        if ($Name -eq "HoyoPlay") {
            Write-Host "You can manually download from:" -ForegroundColor Yellow
            Write-Host "  https://hoyoplay.hoyoverse.com/" -ForegroundColor Gray
        } elseif ($Name -eq "Wuthering Waves") {
            Write-Host "You can manually download from:" -ForegroundColor Yellow
            Write-Host "  https://wuthering.kurogames.com/" -ForegroundColor Gray
        }
        Write-Host ""
    } finally {
        # Cleanup temp file
        if (Test-Path $InstallerPath) {
            Remove-Item -Path $InstallerPath -Force -ErrorAction SilentlyContinue
        }
    }
}

# Main execution
Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Game Launcher Installation           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Install HoyoPlay
Install-GameLauncher `
    -Name "HoyoPlay" `
    -Url $HoyoPlayUrl `
    -InstallerPath "$TempDir\HoyoPlay-installer.exe" `
    -UrlType 'redirect'

# Install Wuthering Waves
Install-GameLauncher `
    -Name "Wuthering Waves" `
    -Url $WutheringWavesConfigUrl `
    -InstallerPath "$TempDir\WutheringWaves-installer.exe" `
    -UrlType 'json'

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  Game Launcher Installation Complete! ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Cleanup temp directory
if (Test-Path $TempDir) {
    Remove-Item -Path $TempDir -Force -Recurse -ErrorAction SilentlyContinue
}

Write-Host "Press any key to exit..."
$null = [System.Console]::ReadKey($true)