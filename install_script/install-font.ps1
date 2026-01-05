# Font installation script for Maple Mono NF CN
$FontName = "MapleMono-NF-CN-unhinted"
$TempDir = "$env:TEMP\maple-font-install"
$FontDir = "$env:WINDIR\Fonts"

# Validate environment variables
if ([string]::IsNullOrWhiteSpace($env:TEMP) -or -not (Test-Path $env:TEMP)) {
    Write-Error "TEMP directory is not accessible: $env:TEMP"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($env:WINDIR) -or -not (Test-Path $FontDir)) {
    Write-Error "Fonts directory is not accessible: $FontDir"
    exit 1
}

# Create temp directory
if (!(Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir | Out-Null
}

# Get latest release info
$ApiUrl = "https://api.github.com/repos/subframe7536/maple-font/releases/latest"

try {
    # Use curl to fetch JSON from GitHub API
    $JsonResponse = curl.exe -s $ApiUrl 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "curl.exe failed with exit code $LASTEXITCODE"
    }
    $Release = $JsonResponse | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Error "Failed to fetch release info from GitHub: $_"
    exit 1
}

if (-not $Release) {
    Write-Error "No release data received from GitHub API"
    exit 1
}

# Find the font zip and sha256 files
$ZipAsset = $Release.assets | Where-Object { $_.name -eq "$FontName.zip" }
$Sha256Asset = $Release.assets | Where-Object { $_.name -eq "$FontName.sha256" }

if (!$ZipAsset -or !$Sha256Asset) {
    Write-Error "Could not find font files in latest release"
    exit 1
}

# Download files
$ZipPath = Join-Path $TempDir "$FontName.zip"
$Sha256Path = Join-Path $TempDir "$FontName.sha256"

Write-Host "Downloading $FontName.zip..."
try {
    # Download zip file
    curl.exe -L -o $ZipPath $ZipAsset.browser_download_url 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to download zip file"
    }
    
    # Download sha256 file
    curl.exe -L -o $Sha256Path $Sha256Asset.browser_download_url 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to download sha256 file"
    }
} catch {
    Write-Error "Failed to download font files: $_"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Verify files were downloaded
if (-not (Test-Path $ZipPath) -or -not (Test-Path $Sha256Path)) {
    Write-Error "Download failed: Files not found"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Verify hash
try {
    $Sha256Content = Get-Content $Sha256Path -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($Sha256Content)) {
        throw "SHA256 file is empty"
    }
    $ExpectedHash = $Sha256Content.Split()[0].ToLower()
    
    $ActualHash = (Get-FileHash -Path $ZipPath -Algorithm SHA256 -ErrorAction Stop).Hash.ToLower()
    
    if ($ActualHash -ne $ExpectedHash) {
        Write-Error "Hash verification failed! Expected: $ExpectedHash, Got: $ActualHash"
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }
    Write-Host "Hash verified successfully"
} catch {
    Write-Error "Hash verification error: $_"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Extract and install fonts
Write-Host "Installing fonts..."
try {
    Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force -ErrorAction Stop
} catch {
    Write-Error "Failed to extract font archive: $_"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Find extracted font files
$FontFiles = Get-ChildItem -Path $TempDir -Filter "*.ttf" -Recurse -ErrorAction SilentlyContinue
if (-not $FontFiles -or $FontFiles.Count -eq 0) {
    Write-Error "No TTF files found in archive"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

foreach ($Font in $FontFiles) {
    try {
        Copy-Item -Path $Font.FullName -Destination $FontDir -Force -ErrorAction Stop
        Write-Host "Installed: $($Font.Name)"
    } catch {
        Write-Error "Failed to copy font $($Font.Name): $_"
    }
}

# Cleanup
try {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction Stop
    Write-Host "Installation complete!"
} catch {
    Write-Warning "Failed to cleanup temp directory: $_"
    Write-Host "Installation complete! (Please manually delete: $TempDir)"
}