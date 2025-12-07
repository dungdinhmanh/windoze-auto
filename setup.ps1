$gh_raw = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/'
$notepad_catpuccin = 'https://raw.githubusercontent.com/catppuccin/notepad-plus-plus/main/themes/catppuccin-mocha.xml'
$Launchers = "${gh_raw}install_script/install-launcher.ps1"
$PwshProfile = "${gh_raw}config/Microsoft.PowerShell_profile.ps1"
$Font = "${gh_raw}install_script/install-font.ps1"
$Packages = "${gh_raw}config/packages.json"
$starship = "${gh_raw}config/starship.toml"
$terminal = "${gh_raw}config/settings.json"

Invoke-WebRequest $Packages -OutFile packages.json
winget import -i packages.json --accept-source-agreements --accept-package-agreements
Remove-Item -Path packages.json

Invoke-RestMethod $Launchers | Invoke-Expression
Invoke-RestMethod $Font | Invoke-Expression

Invoke-RestMethod $PwshProfile -OutFile "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
Invoke-RestMethod $starship -OutFile "$HOME\starship.toml"
Invoke-RestMethod $terminal -OutFile "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Invoke-RestMethod $notepad_catpuccin -OutFile "C:\Program Files\Notepad++\themes\catppuccin-mocha.xml"
