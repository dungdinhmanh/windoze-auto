$gh_raw = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/'
$Packages = "${gh_raw}packages.json"
$Launchers = "${gh_raw}install-launcher.ps1"
$PwshProfile = "${gh_raw}Microsoft.PowerShell_profile.ps1"
$starship = "${gh_raw}starship.toml"
$terminal = "${gh_raw}settings.json"
$notepad_catpuccin = 'https://github.com/catppuccin/notepad-plus-plus/blob/main/themes/catppuccin-mocha.xml'
$font = "${gh_raw}install-font.ps1"

Invoke-WebRequest $Packages -OutFile packages.json
winget import -i packages.json
Remove-Item -Path packages.json

Invoke-RestMethod $Launchers | Invoke-Expression

Invoke-RestMethod $font | Invoke-Expression

Invoke-RestMethod $PwshProfile -OutFile "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
Invoke-RestMethod $starship -OutFile "$HOME\starship.toml"
Invoke-RestMethod $terminal -OutFile "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Invoke-RestMethod $notepad_catpuccin -OutFile "C:\Program Files\Notepad++\themes\catppuccin-mocha.xml"
