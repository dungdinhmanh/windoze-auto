# Office 365 installation script using Office Deployment Tool
$TempDir = "$env:TEMP\office-install"
$ODTExe = Join-Path $TempDir "setup.exe"
$ConfigFile = Join-Path (Split-Path $PSScriptRoot) "config\offices.xml"
$MicrosoftDownloadUrl = "https://www.microsoft.com/en-us/download/details.aspx?id=49117"

# Validate environment
if ([string]::IsNullOrWhiteSpace($env:TEMP) -or -not (Test-Path $env:TEMP)) {
    Write-Error "TEMP directory is not accessible: $env:TEMP"
    exit 1
}

if (-not (Test-Path $ConfigFile)) {
    Write-Error "Configuration file not found: $ConfigFile"
    exit 1
}

# Get latest download link from Microsoft
Write-Host "Fetching latest Office Deployment Tool link..."
try {
    $PageContent = curl.exe -s -q $MicrosoftDownloadUrl 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to fetch Microsoft download page"
    }
    
    # Extract download link using regex (looking for officedeploymenttool_*.exe)
    if ($PageContent -match 'href="([^"]*officedeploymenttool[^"]*\.exe)"') {
        $DownloadUrl = $matches[1]
        # Handle relative URLs
        if ($DownloadUrl -notmatch '^https?://') {
            $DownloadUrl = "https:" + $DownloadUrl
        }
        Write-Host "Found download link: $DownloadUrl" -ForegroundColor Green
    } else {
        throw "Could not find download link on Microsoft page"
    }
} catch {
    Write-Error "Failed to get latest download link: $_"
    Write-Host "Using fallback URL..." -ForegroundColor Yellow
    $DownloadUrl = "https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_19426-20170.exe"
}

# Create temp directory
if (!(Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir | Out-Null
}

# Download Office Deployment Tool
Write-Host "Downloading Office Deployment Tool..."
try {
    curl.exe -L -q -o $ODTExe $DownloadUrl 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to download ODT"
    }
} catch {
    Write-Error "Failed to download Office Deployment Tool: $_"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Verify ODT was downloaded
if (-not (Test-Path $ODTExe)) {
    Write-Error "ODT download failed: File not found"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Verify file size
$FileSize = (Get-Item $ODTExe).Length
if ($FileSize -lt 500KB) {
    Write-Error "ODT file appears corrupted (too small: $FileSize bytes)"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Extract ODT
Write-Host "Extracting Office Deployment Tool..."
try {
    & $ODTExe /extract:$TempDir /quiet
    if ($LASTEXITCODE -ne 0) {
        throw "ODT extraction failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Error "Failed to extract ODT: $_"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Verify setup.exe exists after extraction
$SetupExe = Join-Path $TempDir "setup.exe"
if (-not (Test-Path $SetupExe)) {
    Write-Error "setup.exe not found after extraction"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Copy config file to temp directory
try {
    Copy-Item -Path $ConfigFile -Destination (Join-Path $TempDir "offices.xml") -Force -ErrorAction Stop
} catch {
    Write-Error "Failed to copy configuration file: $_"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Run Office installation
Write-Host "Installing Microsoft Office 365..."
try {
    Push-Location $TempDir
    & $SetupExe /configure offices.xml
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

# Cleanup
try {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction Stop
    Write-Host "Cleanup completed"
} catch {
    Write-Warning "Failed to cleanup temp directory: $_"
    Write-Host "Please manually delete: $TempDir"
}

Write-Host "Office 365 installation complete!"
