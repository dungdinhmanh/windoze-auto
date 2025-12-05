<#
.SYNOPSIS
    Install packages listed in packages.json using winget.

.DESCRIPTION
    Can be run via: irm https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/setup.ps1 | iex
    
    packages.json can be an array of strings or objects:
        - "7zip.7zip"
        - { "id": "Mozilla.Firefox", "version": "xx", "source": "winget" }
        - { "name": "Notepad++", "source": "winget" }

    The script will skip items already installed (when an id/name is detectable).
#>

param(
        [string]$PackagesJsonUrl = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/packages.json'
)

function ThrowIf-NoWinget {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                throw 'winget not found in PATH. Install App Installer from Microsoft Store or add winget to PATH.'
        }
}

function Read-Packages {
        param($Path)
        try {
                # Fetch from GitHub URL
                $raw = Invoke-WebRequest -Uri $Path -UseBasicParsing -ErrorAction Stop | Select-Object -ExpandProperty Content
                $json = ConvertFrom-Json -InputObject $raw -ErrorAction Stop
        } catch {
                throw "Failed to fetch and parse packages from: $Path. $_"
        }
        # Handle both array format and winget export format with Sources/Packages structure
        if ($json.Sources -is [array]) {
                # Extract packages from winget export format
                $packages = @()
                foreach ($source in $json.Sources) {
                        if ($source.Packages -is [System.Collections.IEnumerable]) {
                                $packages += $source.Packages
                        }
                }
                return $packages
        } elseif ($json -is [System.Collections.IEnumerable]) {
                # Simple array format
                return $json
        } else {
                throw "packages.json must be either a JSON array or contain Sources with Packages."
        }
}

function Build-Args {
        param($pkg)
        # Return array of arguments for winget install
        $args = @('install', '--accept-package-agreements', '--accept-source-agreements', '--exact')
        if ($pkg -is [string]) {
                $args += @('--id', $pkg)
                return $args
        }
        if ($pkg -is [PSCustomObject] -or $pkg -is [hashtable]) {
                # Support both standard format (id, name) and winget export format (PackageIdentifier, Override)
                $id = if ($pkg.id) { $pkg.id } elseif ($pkg.PackageIdentifier) { $pkg.PackageIdentifier } else { $null }
                $name = $pkg.name
                $ver = $pkg.version
                $src = $pkg.source
                $override = $pkg.Override

                if ($id) { $args += @('--id', $id) }
                elseif ($name) { $args += @('--name', $name) }
                else { throw "Package object must contain 'id'/'PackageIdentifier' or 'name': $($pkg | ConvertTo-Json -Compress)" }

                if ($ver) { $args += @('--version', $ver) }
                if ($src) { $args += @('--source', $src) }
                if ($override) { $args += @('--override', $override) }

                return $args
        }
        throw "Unsupported package entry type: $pkg"
}

function Is-Installed {
        param($pkg)
        # Determine if package is already installed using winget list by id or name
        if ($pkg -is [string]) {
                $idOrName = $pkg
                $args = @('list', '--id', $idOrName, '--exact')
        } else {
                # Support both formats: id/PackageIdentifier
                $id = if ($pkg.id) { $pkg.id } elseif ($pkg.PackageIdentifier) { $pkg.PackageIdentifier } else { $null }
                $name = $pkg.name
                if ($id) { $args = @('list', '--id', $id, '--exact') }
                elseif ($name) { $args = @('list', '--name', $name, '--exact') }
                else { return $false }
        }

        $proc = Start-Process -FilePath 'winget' -ArgumentList $args -NoNewWindow -RedirectStandardOutput -PassThru -Wait -ErrorAction SilentlyContinue
        $out = $proc.StandardOutput.ReadToEnd() 2>$null
        # winget list prints header + entries; if there are entries other than header, treat as installed
        # Simple heuristic: check if output contains a line with package id/name (excluding header)
        if ($out -match '\S') {
                # Exclude the header line "Name", "Id", etc. If more than one non-empty line, installed.
                $lines = $out -split "`r?`n" | Where-Object { $_.Trim() -ne '' }
                if ($lines.Count -gt 1) { return $true }
        }
        return $false
}

# Main
try {
        ThrowIf-NoWinget
        $packages = Read-Packages -Path $PackagesJsonUrl
} catch {
        Write-Error $_
        Write-Host "Press any key to exit..."
        $null = [System.Console]::ReadKey($true)
        exit 1
}

foreach ($pkg in $packages) {
        try {
                if (Is-Installed -pkg $pkg) {
                        if ($pkg -is [string]) { 
                                Write-Output "Skipping already installed: $pkg" 
                        } else { 
                                $pkgName = if ($pkg.id) { $pkg.id } elseif ($pkg.PackageIdentifier) { $pkg.PackageIdentifier } elseif ($pkg.name) { $pkg.name } else { "unknown" }
                                Write-Output "Skipping already installed: $pkgName" 
                        }
                        continue
                }

                $args = Build-Args -pkg $pkg
                if ($pkg -is [string]) { 
                        $displayName = $pkg 
                } else { 
                        $displayName = if ($pkg.id) { $pkg.id } elseif ($pkg.PackageIdentifier) { $pkg.PackageIdentifier } elseif ($pkg.name) { $pkg.name } else { "unknown" }
                }
                Write-Output "Installing: $displayName"
                $proc = Start-Process -FilePath 'winget' -ArgumentList $args -NoNewWindow -Wait -PassThru
                if ($proc.ExitCode -ne 0) {
                        Write-Warning "winget exited with code $($proc.ExitCode) for package: $displayName"
                } else {
                        Write-Output "Installed: $displayName"
                }
        } catch {
                Write-Warning "Failed to install package: $($_)"
        }
}

Write-Host "`nInstallation complete. Press any key to exit..."
$null = [System.Console]::ReadKey($true)