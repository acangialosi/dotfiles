# Run from an elevated PowerShell session
# Install Powershell
winget install Microsoft.PowerShell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
# Install the Winget Cmndlet required for enabling windows features and system level installation
install-Module -Name Microsoft.WinGet.Configuration -AllowPrerelease
#winget configure '.\personal-dev-env.yaml' --accept-configuration-agreements
get-WinGetConfiguration -file .\ready-for-me.dsc.yaml | Invoke-WinGetConfiguration -AcceptConfigurationAgreements
