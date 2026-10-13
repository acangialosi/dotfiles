# Windows development environment

This repository configures a Windows development machine with WinGet and DSC.
Machine configurations live exclusively in `.configurations`; the other folders
contain settings and scripts consumed after the base machine is configured.

## Quick start

From an unelevated PowerShell session, including the VS Code integrated
terminal, run:

```powershell
sudo pwsh -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
```

The bootstrap verifies Microsoft App Installer, installs PowerShell and DSC, and applies
`.configurations\default.dsc.yaml`. Optional runtimes are not installed by the
bootstrap. The elevated child process is required for machine-wide package
installers; VS Code itself remains unelevated.

## Configurations

- `settings.core.dsc.yaml` configures safe Windows Explorer preferences and
  automatic time and time-zone detection, and sets Google as Edge's default
  search engine.
- `tools.core.dsc.yaml` installs Microsoft App Installer, Windows Terminal,
  PowerShell, DSC, 1Password, the official Git for Windows distribution,
  GitHub CLI, GitHub Copilot, and VS Code Insiders.
- `tools.extended.dsc.yaml` installs Claude Code, Claude Desktop, and Azure CLI.
- `runtimes.core.dsc.yaml` installs Node.js and Python.
- `default.dsc.yaml` includes the core tools, extended tools, core runtimes, and
  core settings.
- `runtimes.dsc.extended.yaml` can be applied separately to install the optional
  .NET SDK and Azure Developer CLI.

## Default setup inventory

Running `setup.ps1` makes exactly these changes to the machine.

### Tools installed (WinGet)

| Name | WinGet ID | Configuration |
|------|-----------|---------------|
| Microsoft App Installer | `Microsoft.AppInstaller` | `tools.core` |
| Windows Terminal | `Microsoft.WindowsTerminal` | `tools.core` |
| PowerShell | `Microsoft.PowerShell` | `tools.core` |
| DSC | `Microsoft.DSC` | `tools.core` |
| 1Password | `AgileBits.1Password` | `tools.core` |
| Git for Windows | `Git.Git` | `tools.core` |
| GitHub CLI | `GitHub.cli` | `tools.core` |
| GitHub Copilot | `GitHub.Copilot` | `tools.core` |
| VS Code Insiders | `Microsoft.VisualStudioCode.Insiders` | `tools.core` |
| Claude Code | `Anthropic.ClaudeCode` | `tools.extended` |
| Claude Desktop | `Anthropic.Claude` | `tools.extended` |
| Azure CLI | `Microsoft.AzureCLI` | `tools.extended` |

### Runtimes installed (WinGet, latest version)

| Name | WinGet ID | Configuration |
|------|-----------|---------------|
| Node.js | `OpenJS.NodeJS` | `runtimes.core` |
| Python 3.14 | `Python.Python.3.14` | `runtimes.core` |

### Settings changed (`settings.core.dsc.yaml`, Windows registry)

| Setting | Registry key | Value | Data |
|---------|--------------|-------|------|
| Show file extensions | `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `HideFileExt` | `0` (DWord) |
| Show hidden files | `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `Hidden` | `1` (DWord) |
| Automatic time | `HKLM\SYSTEM\CurrentControlSet\Services\W32Time` | `Start` | `3` (DWord) |
| Automatic time zone | `HKLM\SYSTEM\CurrentControlSet\Services\tzautoupdate` | `Start` | `3` (DWord) |
| Allow location for time zone | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location` | `Value` | `Allow` (String) |
| Edge: enable default search policy | `HKLM\SOFTWARE\Policies\Microsoft\Edge` | `DefaultSearchProviderEnabled` | `1` (DWord) |
| Edge: default search name | `HKLM\SOFTWARE\Policies\Microsoft\Edge` | `DefaultSearchProviderName` | `Google` (String) |
| Edge: default search URL | `HKLM\SOFTWARE\Policies\Microsoft\Edge` | `DefaultSearchProviderSearchURL` | `https://www.google.com/search?q={searchTerms}` (String) |

The Edge values are machine policy, so Edge shows its search engine setting as
managed by your organization.

### Optional (not applied by default)

| Name | WinGet ID | Configuration |
|------|-----------|---------------|
| .NET SDK 10 | `Microsoft.DotNet.SDK.10` | `runtimes.dsc.extended.yaml` |
| Azure Developer CLI | `Microsoft.Azd` | `runtimes.dsc.extended.yaml` |

If the Microsoft VFS/Scalar Git distribution is already installed, remove it
before setup so the official Git for Windows installer can proceed:

```powershell
winget uninstall --id Microsoft.Git --exact
```

Apply or verify an individual configuration with DSC:

```powershell
dsc config test --file .\.configurations\default.dsc.yaml
dsc config set --file .\.configurations\default.dsc.yaml
```

## Git identity and authentication

The setup intentionally does not configure a global Git name, email, credential
helper, or GitHub account. Configure identity per repository or with Git
`includeIf` rules so personal and work accounts remain separate.

## Optional settings

- Run `.\terminal\configure-omp.ps1` to configure Oh My Posh without replacing
  an existing PowerShell profile.
- `terminal\terminal.fragment.json` contains Windows Terminal settings that can
  be imported or merged manually.
- `visualstudio\extensions\extensions.vsconfig` contains the Visual Studio
  extension selection.
- `visualstudio\settings\devbox` contains Visual Studio unified settings.
- `ai` contains portable personal instructions, settings, and Agent Skills for
  Claude. Run `.\ai\install.ps1 -WhatIf` to preview installation, then
  `.\ai\install.ps1` to copy configured files into the current user's Claude
  directory. See `ai\README.md` for the layout and local override conventions.

Review configuration changes before applying them. Machine setup must not
format disks, force a reboot, or select a GitHub account automatically.
