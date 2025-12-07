# Font installation script for Maple Mono NF CN
$FontName = "MapleMono-NF-CN-unhinted"
$TempDir = "$env:TEMP\maple-font-install"
$FontDir = "$env:WINDIR\Fonts"

# Create temp directory
if (!(Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir | Out-Null
}

# Get latest release info
$ApiUrl = "https://api.github.com/repos/subframe7536/maple-font/releases/latest"
$Release = Invoke-RestMethod -Uri $ApiUrl

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
Invoke-WebRequest -Uri $ZipAsset.browser_download_url -OutFile $ZipPath
Invoke-WebRequest -Uri $Sha256Asset.browser_download_url -OutFile $Sha256Path

# Verify hash
$ExpectedHash = (Get-Content $Sha256Path).Split()[0]
$ActualHash = (Get-FileHash -Path $ZipPath -Algorithm SHA256).Hash.ToLower()

if ($ActualHash -ne $ExpectedHash.ToLower()) {
    Write-Error "Hash verification failed!"
    exit 1
}

Write-Host "Hash verified successfully"

# Extract and install fonts
Write-Host "Installing fonts..."
Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force
$FontFiles = Get-ChildItem -Path $TempDir -Filter "*.ttf" -Recurse

foreach ($Font in $FontFiles) {
    Copy-Item -Path $Font.FullName -Destination $FontDir -Force
    Write-Host "Installed: $($Font.Name)"
}

# Cleanup
Remove-Item -Path $TempDir -Recurse -Force

Write-Host "Installation complete!"