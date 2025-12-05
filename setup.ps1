Invoke-WebRequest "https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/main/packages.json" -OutFile packages.json
winget import -i packages.json --accept-source-agreements --accept-package-agreements
Remove-Item -Path packages.json