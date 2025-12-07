$Packages = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/packages.json'
$Launchers = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/install-launcher.ps1'
$PwshProfile = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/Microsoft.PowerShell_profile.ps1'
$starship = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/starship.toml'
$terminal = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/settings.json'
$notepad_catpuccin = 'https://github.com/catppuccin/notepad-plus-plus/blob/main/themes/catppuccin-mocha.xml'
$font = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/install-font.ps1'
Invoke-WebRequest $Packages -OutFile packages.json
winget import -i packages.json
Remove-Item -Path packages.json

Invoke-RestMethod $Launchers | Invoke-Expression

Invoke-RestMethod $font | Invoke-Expression

Invoke-RestMethod $PwshProfile -OutFile "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
Invoke-RestMethod $starship -OutFile "$HOME\starship.toml"
Invoke-RestMethod $terminal -OutFile "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Invoke-RestMethod $notepad_catpuccin -OutFile "C:\Program Files\Notepad++\themes\catppuccin-mocha.xml"
