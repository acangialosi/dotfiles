[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Copy', 'SymbolicLink')]
    [string]$Mode = 'Copy',

    [string]$HomePath = $HOME,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$aiRoot = $PSScriptRoot

function Test-ItemsEquivalent {
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    $sourceItem = Get-Item -LiteralPath $Source
    $destinationItem = Get-Item -LiteralPath $Destination
    $sourceIsDirectory = $sourceItem -is [System.IO.DirectoryInfo]
    $destinationIsDirectory = $destinationItem -is [System.IO.DirectoryInfo]

    if ($sourceIsDirectory -ne $destinationIsDirectory) {
        return $false
    }

    if (-not $sourceIsDirectory) {
        return (Get-FileHash -LiteralPath $Source).Hash -eq
            (Get-FileHash -LiteralPath $Destination).Hash
    }

    $sourceFiles = @{}
    foreach ($file in Get-ChildItem -LiteralPath $Source -File -Recurse) {
        $relativePath = [System.IO.Path]::GetRelativePath($Source, $file.FullName)
        $sourceFiles[$relativePath] = (Get-FileHash -LiteralPath $file.FullName).Hash
    }

    $destinationFiles = @{}
    foreach ($file in Get-ChildItem -LiteralPath $Destination -File -Recurse) {
        $relativePath = [System.IO.Path]::GetRelativePath($Destination, $file.FullName)
        $destinationFiles[$relativePath] = (Get-FileHash -LiteralPath $file.FullName).Hash
    }

    if ($sourceFiles.Count -ne $destinationFiles.Count) {
        return $false
    }

    foreach ($relativePath in $sourceFiles.Keys) {
        if (-not $destinationFiles.ContainsKey($relativePath) -or
            $sourceFiles[$relativePath] -ne $destinationFiles[$relativePath]) {
            return $false
        }
    }

    return $true
}

function Move-ExistingItemToBackup {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupPath = "$Path.backup-$timestamp"
    $suffix = 1

    while (Test-Path -LiteralPath $backupPath) {
        $backupPath = "$Path.backup-$timestamp-$suffix"
        $suffix++
    }

    Move-Item -LiteralPath $Path -Destination $backupPath
    Write-Host "Backed up '$Path' to '$backupPath'."
}

function Install-Item {
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        return
    }

    if (Test-Path -LiteralPath $Destination) {
        if (Test-ItemsEquivalent -Source $Source -Destination $Destination) {
            Write-Host "'$Destination' is already up to date."
            return
        }

        if (-not $Force) {
            throw "Destination '$Destination' already exists. Re-run with -Force to back it up and replace it."
        }

        if ($PSCmdlet.ShouldProcess($Destination, 'Back up existing item')) {
            Move-ExistingItemToBackup -Path $Destination
        }
        else {
            return
        }
    }

    $parent = Split-Path -Parent $Destination
    if ($PSCmdlet.ShouldProcess($parent, 'Create destination directory')) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (-not $PSCmdlet.ShouldProcess($Destination, "Install from '$Source' using $Mode")) {
        return
    }

    if ($Mode -eq 'SymbolicLink') {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $Source | Out-Null
    }
    elseif ((Get-Item -LiteralPath $Source) -is [System.IO.DirectoryInfo]) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Recurse
    }
    else {
        Copy-Item -LiteralPath $Source -Destination $Destination
    }

    Write-Host "Installed '$Source' to '$Destination'."
}

function Get-SkillSources {
    $skills = @{}
    $sourceRoot = Join-Path $aiRoot 'claude\skills'

    foreach ($directory in Get-ChildItem -LiteralPath $sourceRoot -Directory) {
        if (Test-Path -LiteralPath (Join-Path $directory.FullName 'SKILL.md')) {
            $skills[$directory.Name] = $directory.FullName
        }
    }

    return $skills
}

function Install-Skills {
    param(
        [Parameter(Mandatory)]
        [string]$DestinationRoot
    )

    $skills = Get-SkillSources
    foreach ($name in ($skills.Keys | Sort-Object)) {
        Install-Item -Source $skills[$name] -Destination (Join-Path $DestinationRoot $name)
    }
}

function Merge-Hashtable {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Base,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Overlay
    )

    foreach ($key in $Overlay.Keys) {
        if ($Base[$key] -is [System.Collections.IDictionary] -and
            $Overlay[$key] -is [System.Collections.IDictionary]) {
            $Base[$key] = Merge-Hashtable -Base $Base[$key] -Overlay $Overlay[$key]
        }
        else {
            $Base[$key] = $Overlay[$key]
        }
    }

    return $Base
}

function Read-JsonHashtable {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $value = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable
    if ($value -isnot [System.Collections.IDictionary]) {
        throw "Settings file '$Path' must contain a JSON object at its root."
    }

    return $value
}

function Install-ClaudeSettings {
    $settingsSource = Join-Path $aiRoot 'claude\settings.json'
    $localSettingsSource = Join-Path $aiRoot 'claude\settings.local.json'
    if (-not (Test-Path -LiteralPath $settingsSource) -and
        -not (Test-Path -LiteralPath $localSettingsSource)) {
        return
    }

    $destination = Join-Path $HomePath '.claude\settings.json'
    $settings = @{}
    $currentSettingsJson = $null

    if (Test-Path -LiteralPath $destination) {
        $settings = Read-JsonHashtable -Path $destination
        $currentSettingsJson = $settings | ConvertTo-Json -Depth 100 -Compress
    }
    if (Test-Path -LiteralPath $settingsSource) {
        $settings = Merge-Hashtable -Base $settings -Overlay (Read-JsonHashtable -Path $settingsSource)
    }
    if (Test-Path -LiteralPath $localSettingsSource) {
        $settings = Merge-Hashtable -Base $settings -Overlay (Read-JsonHashtable -Path $localSettingsSource)
    }

    $mergedSettingsJson = $settings | ConvertTo-Json -Depth 100 -Compress
    if ($null -ne $currentSettingsJson -and $currentSettingsJson -eq $mergedSettingsJson) {
        Write-Host "'$destination' is already up to date."
        return
    }

    if (-not $PSCmdlet.ShouldProcess($destination, 'Merge Claude settings')) {
        return
    }

    $parent = Split-Path -Parent $destination
    New-Item -ItemType Directory -Path $parent -Force | Out-Null

    if (Test-Path -LiteralPath $destination) {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        Copy-Item -LiteralPath $destination -Destination "$destination.backup-$timestamp"
    }

    $temporaryPath = Join-Path $parent "settings.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        $settings | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $temporaryPath -Encoding utf8
        Move-Item -LiteralPath $temporaryPath -Destination $destination -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath
        }
    }

    Write-Host "Merged Claude settings into '$destination'."
}

$claudeRoot = Join-Path $HomePath '.claude'

Install-Skills -DestinationRoot (Join-Path $claudeRoot 'skills')

Install-Item `
    -Source (Join-Path $aiRoot 'claude\CLAUDE.md') `
    -Destination (Join-Path $claudeRoot 'CLAUDE.md')

Install-ClaudeSettings
