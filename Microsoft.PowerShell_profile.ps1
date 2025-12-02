Import-Module -Name Terminal-Icons
$ENV:STARSHIP_CONFIG = "$HOME\starship.toml"
Invoke-Expression (&starship init powershell)
