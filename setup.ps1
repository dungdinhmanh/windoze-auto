$Packages = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/packages.json'
$Launchers = 'https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/install-launcher.ps1'
Invoke-WebRequest $Packages -OutFile packages.json
winget import -i packages.json
Remove-Item -Path packages.json

Invoke-RestMethod $Launchers | Invoke-Expression