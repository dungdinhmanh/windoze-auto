$Packages = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/packages.json'
$Launchers = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/install-launcher.ps1'
$PwshProfile = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/Microsoft.PowerShell_profile.ps1'
$starship = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/starship.toml'
Invoke-WebRequest $Packages -OutFile packages.json
winget import -i packages.json
Remove-Item -Path packages.json

Invoke-RestMethod $Launchers | Invoke-Expression

Invoke-RestMethod $PwshProfile -OutFile "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
Invoke-RestMethod $starship -OutFile "$HOME\starship.toml"
