# Run from an elevated PowerShell session
# Install Powershell
winget install Microsoft.PowerShell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
pwsh.exe -file "$PSScriptRoot\setup.ps7.ps1"