# Font installation script for Maple Mono NF CN
# Improved with better curl handling and error checking based on install-launcher.ps1
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
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

# Check if curl.exe is available
if (-not (Test-Path "C:\Windows\System32\curl.exe")) {
    Write-Error "curl.exe is not installed or not found at C:\Windows\System32\curl.exe"
    exit 1
}

# Get latest release info
$ApiUrl = "https://api.github.com/repos/subframe7536/maple-font/releases/latest"

function Get-GitHubRelease {
    param([string]$ApiUrl)
    
    try {
        Write-Host "Fetching latest release info from GitHub..." -ForegroundColor Yellow
        
        # Use curl to fetch JSON from GitHub API
        $JsonResponse = curl.exe -s $ApiUrl 2>&1
        
        if ($null -eq $JsonResponse -or [string]::IsNullOrWhiteSpace($JsonResponse)) {
            throw "Empty response from GitHub API. Check your internet connection."
        }
        
        # Convert response to string safely
        $jsonString = if ($JsonResponse -is [array]) {
            $JsonResponse -join ""
        } else {
            [string]$JsonResponse
        }
        
        if ([string]::IsNullOrWhiteSpace($jsonString)) {
            throw "Empty or invalid response from GitHub API"
        }
        
        Write-Host "Response received, parsing JSON..." -ForegroundColor Yellow
        
        # Parse JSON
        $Release = $jsonString | ConvertFrom-Json -ErrorAction Stop
        
        if (-not $Release -or -not $Release.assets) {
            throw "Invalid release data structure from GitHub API"
        }
        
        return $Release
    } catch {
        throw "Failed to fetch release info from GitHub: $_"
    }
}

try {
    $Release = Get-GitHubRelease -ApiUrl $ApiUrl
    Write-Host "Latest release info fetched successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to fetch release info: $_"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Find the font zip and sha256 files
$ZipAsset = $Release.assets | Where-Object { $_.name -eq "$FontName.zip" }
$Sha256Asset = $Release.assets | Where-Object { $_.name -eq "$FontName.sha256" }

if (-not $ZipAsset -or -not $Sha256Asset) {
    Write-Error "Could not find font files in latest release"
    Write-Host "Available files:" -ForegroundColor Yellow
    $Release.assets | ForEach-Object { Write-Host "  - $($_.name)" }
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Download files
$ZipPath = Join-Path $TempDir "$FontName.zip"
$Sha256Path = Join-Path $TempDir "$FontName.sha256"

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Installing Maple Mono NF CN Font" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Downloading $FontName.zip..." -ForegroundColor Yellow
try {
    # Download zip file (without -s flag to show progress)
    curl.exe -L -o $ZipPath $ZipAsset.browser_download_url 
    if ($LASTEXITCODE -ne 0) {
        throw "curl.exe failed with exit code $LASTEXITCODE. Failed to download zip file"
    }
    
    # Download sha256 file (without -s flag to show progress)
    Write-Host "Downloading $FontName.sha256..." -ForegroundColor Yellow
    curl.exe -L -o $Sha256Path $Sha256Asset.browser_download_url
    if ($LASTEXITCODE -ne 0) {
        throw "curl.exe failed with exit code $LASTEXITCODE. Failed to download sha256 file"
    }
    
    Write-Host "Files downloaded successfully" -ForegroundColor Green
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

# Verify file sizes (should be reasonable)
$ZipSize = (Get-Item $ZipPath).Length
$Sha256Size = (Get-Item $Sha256Path).Length

if ($ZipSize -lt 1MB) {
    Write-Warning "Zip file appears too small ($([math]::Round($ZipSize/1MB, 2))MB). File may be corrupt."
}

if ($Sha256Size -lt 64) {
    Write-Warning "SHA256 file appears too small ($Sha256Size bytes). File may be corrupt."
}

# Verify hash
Write-Host "Verifying file integrity..." -ForegroundColor Yellow
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
    Write-Host "Hash verified successfully" -ForegroundColor Green
} catch {
    Write-Error "Hash verification error: $_"
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Extract and install fonts
Write-Host "Installing fonts..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force -ErrorAction Stop
    Write-Host "Fonts extracted successfully" -ForegroundColor Green
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

$InstalledCount = 0
foreach ($Font in $FontFiles) {
    try {
        Copy-Item -Path $Font.FullName -Destination $FontDir -Force -ErrorAction Stop
        Write-Host "Installed: $($Font.Name)" -ForegroundColor Green
        $InstalledCount++
    } catch {
        Write-Error "Failed to copy font $($Font.Name): $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Font Installation Complete!" -ForegroundColor Cyan
Write-Host "Installed $InstalledCount font files" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Cleanup
try {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction Stop
    Write-Host "Cleanup completed" -ForegroundColor Green
} catch {
    Write-Warning "Failed to cleanup temp directory: $_"
    Write-Host "Installation complete! (Please manually delete: $TempDir)"
}