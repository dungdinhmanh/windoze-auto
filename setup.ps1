<#
.SYNOPSIS
    Install packages listed in packages.json using winget.

.DESCRIPTION
    Default looks for "packages.json" in the same folder as this script.
    packages.json can be an array of strings or objects:
        - "7zip.7zip"
        - { "id": "Mozilla.Firefox", "version": "xx", "source": "winget" }
        - { "name": "Notepad++", "source": "winget" }

    The script will skip items already installed (when an id/name is detectable).
#>

param(
        [string]$PackagesJsonPath = (Join-Path -Path $PSScriptRoot -ChildPath 'packages.json')
)

function ThrowIf-NoWinget {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                throw 'winget not found in PATH. Install App Installer from Microsoft Store or add winget to PATH.'
        }
}

function Read-Packages {
        param($Path)
        if (-not (Test-Path $Path)) {
                throw "Packages file not found: $Path"
        }
        try {
                $raw = Get-Content -Raw -Path $Path
                $json = ConvertFrom-Json -InputObject $raw -ErrorAction Stop
        } catch {
                throw "Failed to parse JSON file: $Path. $_"
        }
        if (-not ($json -is [System.Collections.IEnumerable])) {
                throw "packages.json must be a JSON array."
        }
        return $json
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
                $id = $pkg.id
                $name = $pkg.name
                $ver = $pkg.version
                $src = $pkg.source

                if ($id) { $args += @('--id', $id) }
                elseif ($name) { $args += @('--name', $name) }
                else { throw "Package object must contain 'id' or 'name': $($pkg | ConvertTo-Json -Compress)" }

                if ($ver) { $args += @('--version', $ver) }
                if ($src) { $args += @('--source', $src) }

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
                $id = $pkg.id
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
        $packages = Read-Packages -Path $PackagesJsonPath
} catch {
        Write-Error $_
        exit 1
}

foreach ($pkg in $packages) {
        try {
                if (Is-Installed -pkg $pkg) {
                        if ($pkg -is [string]) { Write-Output "Skipping already installed: $pkg" }
                        else { Write-Output "Skipping already installed: $($pkg.id ?? $pkg.name)" }
                        continue
                }

                $args = Build-Args -pkg $pkg
                Write-Output ("Installing: " + ($pkg -is [string] ? $pkg : ($pkg.id ?? $pkg.name)))
                $proc = Start-Process -FilePath 'winget' -ArgumentList $args -NoNewWindow -Wait -PassThru
                if ($proc.ExitCode -ne 0) {
                        Write-Warning "winget exited with code $($proc.ExitCode) for package: $($pkg -is [string] ? $pkg : ($pkg.id ?? $pkg.name))"
                } else {
                        Write-Output "Installed: $($pkg -is [string] ? $pkg : ($pkg.id ?? $pkg.name))"
                }
        } catch {
                Write-Warning "Failed to install package: $($_)"
        }
}