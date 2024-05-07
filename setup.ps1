# Run from an elevated PowerShell session
# Install Powershell
winget install Microsoft.PowerShell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
# Install the Winget Cmndlet required for enabling windows features and system level installation
install-Module -Name Microsoft.WinGet.Configuration -AllowPrerelease
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
# Run the dsc configuration using winget cmdlet. Winget.exe cannot run as system or install Windows Optional Features
get-WinGetConfiguration -file $PSScriptRoot\ready-for-me.dsc.yaml | Invoke-WinGetConfiguration -AcceptConfigurationAgreements
