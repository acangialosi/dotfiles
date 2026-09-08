[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

oh-my-posh font install --user CascadiaCode
if ($LASTEXITCODE -ne 0) {
    throw "Oh My Posh font installation failed (exit code $LASTEXITCODE)."
}

$profileLine = (Get-Content -Path (Join-Path $PSScriptRoot 'Microsoft.PowerShell_profile.ps1') -Raw).Trim()
$profileDirectory = Split-Path -Parent $PROFILE
New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null

if (-not (Test-Path $PROFILE) -or -not (Select-String -Path $PROFILE -SimpleMatch $profileLine -Quiet)) {
    Add-Content -Path $PROFILE -Value $profileLine
}

if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser -Force
}

Import-Module -Name Terminal-Icons
