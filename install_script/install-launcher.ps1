
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
        $response = curl -s $Url 2>&1
        
        if ($null -eq $response -or [string]::IsNullOrWhiteSpace($response)) {
            throw "Empty response from URL. Check your internet connection."
        }
        
        # Convert response to string if needed
        $responseString = $response -join " "
        
        Write-Host "Response received, parsing..." -ForegroundColor Yellow
        
        # Parse the href from the HTML response
        # Pattern: <a href="actual_download_url?trace_key=xyz">Found</a>
        if ($responseString -match 'href="([^"]+)"') {
            $actualUrl = $matches[1]
            return $actualUrl
        } else {
            Write-Host "Response content: $responseString" -ForegroundColor Gray
            throw "Could not extract download URL from response. Response may be invalid."
        }
    } catch {
        throw "Failed to get redirect URL: $_"
    }
}

function Get-TraceKeyFromUrl {
    param([string]$Url)
    
    try {
        # Extract trace_key from URL
        # Pattern: trace_key=xyz
        if ($Url -match 'trace_key=([a-zA-Z0-9_]+)') {
            $traceKey = $matches[1]
            return $traceKey
        } else {
            throw "Could not extract trace_key from URL"
        }
    } catch {
        throw "Failed to extract trace_key: $_"
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
        $jsonResponse = curl -s $JsonUrl 2>&1
        
        if ($null -eq $jsonResponse -or [string]::IsNullOrWhiteSpace($jsonResponse)) {
            throw "Empty response from URL. Check your internet connection."
        }
        
        # Convert response to string if needed
        $jsonString = $jsonResponse -join ""
        
        Write-Host "Response received, parsing JSON..." -ForegroundColor Yellow
        
        # Parse JSON
        $json = ConvertFrom-Json -InputObject $jsonString -ErrorAction Stop
        
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
        Write-Host "║ Installing $Name                    ║" -ForegroundColor Cyan
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
        
        # For HoyoPlay, extract trace_key to use as filename
        $finalInstallerPath = $InstallerPath
        $traceKey = $null
        
        if ($Name -eq "HoyoPlay") {
            if ($downloadUrl -match 'trace_key=([a-zA-Z0-9_\.]+)') {
                $traceKey = $matches[1]
                $finalInstallerPath = Join-Path (Split-Path $InstallerPath) "$traceKey.exe"
            }
        }
        
        Write-Host ""
        Write-Host "Downloading $Name installer..." -ForegroundColor Yellow
        
        # For HoyoPlay, use curl -L with the original API URL
        if ($Name -eq "HoyoPlay" -and $traceKey) {
            # Curl -L to follow redirects and save with trace_key as filename
            curl -L -o $finalInstallerPath $Url
        } else {
            # For other games, use the extracted download URL
            curl -L -o $finalInstallerPath $downloadUrl
        }
        
        if (-not (Test-Path $finalInstallerPath)) {
            throw "Failed to download $Name installer"
        }
        
        Write-Host "Downloaded $Name installer successfully" -ForegroundColor Green
        Write-Host ""
        Write-Host "Running $Name installer..." -ForegroundColor Yellow
        
        Start-Process -FilePath $finalInstallerPath -Wait
        
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
        # Cleanup temp files
        if (Test-Path $InstallerPath) {
            Remove-Item -Path $InstallerPath -Force -ErrorAction SilentlyContinue
        }
        # Also cleanup trace_key named file if it exists
        $tempDirPath = Split-Path $InstallerPath
        Get-Item "$tempDirPath\*_*.exe" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

# Main execution
Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Game Launcher Installation            ║" -ForegroundColor Cyan
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
Write-Host "║  Game Launcher Installation Complete!  ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Cleanup temp directory
if (Test-Path $TempDir) {
    Remove-Item -Path $TempDir -Force -Recurse -ErrorAction SilentlyContinue
}

Write-Host "Press any key to exit..."
$null = [System.Console]::ReadKey($true)