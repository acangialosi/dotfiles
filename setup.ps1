[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$isAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdministrator) {
    throw 'Administrator privileges are required. From this terminal, run: sudo pwsh -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1'
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'WinGet is unavailable. Install Microsoft App Installer from https://aka.ms/getwinget, then run setup.ps1 again.'
}

function Install-WinGetPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    if (Test-WinGetPackageInstalled -Id $Id) {
        Write-Host "WinGet package '$Id' is already installed."
        return
    }

    winget install --id $Id --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install WinGet package '$Id' (exit code $LASTEXITCODE)."
    }
}

function Test-WinGetPackageInstalled {
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    winget list --id $Id --exact --accept-source-agreements --disable-interactivity | Out-Null
    $listExitCode = $LASTEXITCODE

    if ($listExitCode -eq 0) {
        return $true
    }

    $packageNotInstalledExitCode = -1978335212 # 0x8A150014
    if ($listExitCode -eq $packageNotInstalledExitCode) {
        return $false
    }

    throw "Failed to query WinGet package '$Id' (exit code $listExitCode)."
}

function Invoke-DscConfiguration {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    dsc config set --file $Path
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to apply DSC configuration '$Path' (exit code $LASTEXITCODE)."
    }
}

Install-WinGetPackage -Id Microsoft.AppInstaller
Install-WinGetPackage -Id Microsoft.PowerShell
Install-WinGetPackage -Id Microsoft.DSC

if ((Test-WinGetPackageInstalled -Id Microsoft.Git) -and
    -not (Test-WinGetPackageInstalled -Id Git.Git)) {
    throw "Microsoft.Git is installed and blocks the official Git.Git installer. Run 'winget uninstall --id Microsoft.Git --exact', then run setup.ps1 again."
}

$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
    [System.Environment]::GetEnvironmentVariable('Path', 'User')

if (-not (Get-Command dsc -ErrorAction SilentlyContinue)) {
    throw 'The DSC executable was installed but is not available on PATH. Open a new terminal and run setup.ps1 again.'
}

Invoke-DscConfiguration -Path (Join-Path $PSScriptRoot '.configurations\default.dsc.yaml')