# Run from an elevated PowerShell session
# Install the Winget Cmndlet required for enabling windows features and system level installation
install-Module -Name Microsoft.WinGet.Configuration -AllowPrerelease
#winget configure '.\personal-dev-env.yaml' --accept-configuration-agreements
get-WinGetConfiguration -file .\ready-for-me.dsc.yaml | Invoke-WinGetConfiguration -AcceptConfigurationAgreements
