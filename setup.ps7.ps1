# Run from an elevated PowerShell session
# Install the Winget Cmndlet required for enabling windows features and system level installation
set-psrepository -name PSGallery -InstallationPolicy Trusted
install-Module -Name Microsoft.WinGet.Configuration -AllowPrerelease -AcceptLicense
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
# Run the dsc configuration using winget cmdlet. Winget.exe cannot run as system or install Windows Optional Features
get-WinGetConfiguration -file $PSScriptRoot\.configurations\ready-for-me.dsc.yaml | Invoke-WinGetConfiguration -AcceptConfigurationAgreements
