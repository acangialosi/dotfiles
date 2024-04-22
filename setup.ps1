# Install the Winget Cmndlet required for enabling windows features and system level installation
install-Module -Name Microsoft.WinGet.Configuration -AllowPrerelease
#winget configure '.\personal-dev-env.yaml' --accept-configuration-agreements
get-WinGetConfiguration -file .\windows\windowsfeatures.yaml | Invoke-WinGetConfiguration -AcceptConfigurationAgreements
