# Office 365 installation script using Office Tool Plus Console + Ohook Activation
$TempDir = "$env:TEMP\office-install"
$OhookActivationUrl = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/refs/heads/master/MAS/Separate-Files-Version/Activators/Ohook_Activation_AIO.cmd"

# Enable TLSv1.2 for compatibility
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# Do not display progress for WebRequest
$ProgressPreference = 'SilentlyContinue'

# Validate environment
if ([string]::IsNullOrWhiteSpace($env:TEMP) -or -not (Test-Path $env:TEMP)) {
    Write-Error "TEMP directory is not accessible: $env:TEMP"
    exit 1
}

# Create temp directory
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

# Always download Office Tool Plus with runtime version
$OfficeToolPlusDownloadUrl = "https://www.officetool.plus/redirect/download.php?type=runtime&arch=x64"

# Download Office Tool Plus
Write-Host "Downloading Office Tool Plus (with runtime)..."
$OfficeToolPlusZip = Join-Path $TempDir "OfficeToolPlus.zip"
$DownloadSuccess = $false

do {
    try {
        Invoke-WebRequest -Uri $OfficeToolPlusDownloadUrl -UseBasicParsing -OutFile $OfficeToolPlusZip -ErrorAction Stop
        $DownloadSuccess = $true
    } catch {
        Write-Warning "An error occurred while downloading Office Tool Plus: $_"
        $UserChoice = Read-Host "Do you want to retry? (Y/N)"
        if ($UserChoice -ne "Y" -and $UserChoice -ne "y") {
            Write-Host "Please download Office Tool Plus from https://www.officetool.plus/ or try again."
            Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
            exit 1
        }
    }
} while (-not $DownloadSuccess)

# Verify Office Tool Plus was downloaded
if (-not (Test-Path $OfficeToolPlusZip)) {
    Write-Error "Office Tool Plus download failed: File not found"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Verify file size
$FileSize = (Get-Item $OfficeToolPlusZip).Length
if ($FileSize -lt 5MB) {
    Write-Error "Office Tool Plus file appears corrupted (too small: $FileSize bytes)"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Extract Office Tool Plus
Write-Host "Extracting Office Tool Plus..."
try {
    Expand-Archive -LiteralPath $OfficeToolPlusZip -DestinationPath $TempDir -Force -ErrorAction Stop
} catch {
    Write-Error "Failed to extract Office Tool Plus: $_"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Find the extracted Office Tool Plus Console executable
$OfficeToolPlusConsole = Join-Path $TempDir "Office Tool\Office Tool Plus.Console.exe"
if (-not (Test-Path $OfficeToolPlusConsole)) {
    Write-Error "Office Tool Plus Console not found after extraction"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Run Office installation using direct command line
Write-Host "Installing Microsoft Office 365 using Office Tool Plus Console..."
try {
    Push-Location $TempDir
    # Use the exact command line format as provided
    & $OfficeToolPlusConsole deploy /O365ProPlusRetail.exclapps Access,Groove,Lync,M365Companion,OneDrive,OneNote,Outlook,OutlookForWindows,Publisher,Teams /add O365ProPlusRetail_vi-vn /channel BetaChannel /edition 64 /shortcuts /acpteula True /setprops "DeviceBasedLicensing:1"
    if ($LASTEXITCODE -ne 0) {
        throw "Office installation failed with exit code $LASTEXITCODE"
    }
    Pop-Location
    Write-Host "Office installation completed successfully"
} catch {
    Write-Error "Failed to install Office: $_"
    Pop-Location -ErrorAction SilentlyContinue
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Download and run Ohook activation
Write-Host "Downloading Ohook activation..."
$OhookScriptPath = Join-Path $env:TEMP "Ohook_Activation_AIO.cmd"
try {
    Invoke-WebRequest -Uri $OhookActivationUrl -UseBasicParsing -OutFile $OhookScriptPath -ErrorAction Stop
    Write-Host "Ohook activation downloaded successfully"
} catch {
    Write-Warning "Failed to download Ohook activation: $_"
    Write-Host "Office installed but activation skipped"
}

# Run Ohook activation if download successful
if (Test-Path $OhookScriptPath) {
    Write-Host "Running Ohook activation..."
    try {
        & cmd.exe /c $OhookScriptPath
        Write-Host "Ohook activation completed"
    } catch {
        Write-Warning "Failed to run Ohook activation: $_"
    }
}

# Cleanup
try {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction Stop
    Write-Host "Cleanup completed"
} catch {
    Write-Warning "Failed to cleanup temp directory: $_"
    Write-Host "Please manually delete: $TempDir"
}

Write-Host "Office 365 installation and activation complete!"
