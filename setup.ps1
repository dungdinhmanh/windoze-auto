# Download and parse packages.json
$packagesUrl = "https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/refs/heads/main/packages.json"
$packages = Invoke-RestMethod -Uri $packagesUrl

# Install each package via winget
foreach ($package in $packages.packages) {
        Write-Host "Installing $($package.id)..."
        winget install --id $package.id --silent --accept-package-agreements --accept-source-agreements
}

Write-Host "Installation complete!"