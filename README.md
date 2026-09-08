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
  automatic time and time-zone detection.
- `tools.core.dsc.yaml` installs Microsoft App Installer, Windows Terminal,
  PowerShell, DSC, 1Password, the official Git for Windows distribution,
  GitHub Copilot, and VS Code Insiders.
- `tools.extended.dsc.yaml` installs GitHub CLI, Claude Code, Claude Desktop,
  and Azure CLI.
- `runtimes.core.dsc.yaml` installs Node.js and Python.
- `default.dsc.yaml` includes the core tools, extended tools, core runtimes, and
  core settings.
- `runtimes.dsc.yaml` can be applied separately to install the optional .NET SDK
  and Azure Developer CLI.

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

Review configuration changes before applying them. Machine setup must not
format disks, force a reboot, or select a GitHub account automatically.
