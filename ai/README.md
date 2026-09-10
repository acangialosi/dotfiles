# Claude configuration

This folder is the source of truth for portable personal Claude configuration.
Run the installer from the repository root:

```powershell
.\ai\install.ps1
```

The default installation mode copies files. To create symbolic links instead,
enable Windows Developer Mode or run an elevated shell, then use:

```powershell
.\ai\install.ps1 -Mode SymbolicLink
```

Existing destination files are not replaced by default. Use `-Force` to back up
conflicting destinations before replacing them. Preview either operation with
`-WhatIf`.

## Layout

- `claude/skills` contains Claude Agent Skills.
- `claude/settings.json` contains portable user settings.
- `claude/settings.local.json` contains ignored machine-specific overrides.
- `local` is ignored by Git and can hold private reference material that should
  never be published. The installer does not deploy this folder.

## Adding a skill

Create a directory beneath `claude/skills`. A valid skill directory must
contain a `SKILL.md` file:

```text
claude/skills/example/
├── SKILL.md
├── scripts/
└── references/
```

Only directories containing `SKILL.md` are installed. This allows the
documentation files that preserve the empty layout to remain in the repository
without becoming skills.

## Settings

The installer deploys:

| Source | Destination |
| --- | --- |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/skills/*` | `~/.claude/skills/*` |

If `claude/settings.local.json` exists, the installer recursively merges it over
the committed Claude settings. Existing destination-only settings are
preserved. Keep the local file untracked for machine-specific preferences.

Claude project-local settings belong in a project's
`.claude/settings.local.json`, not in this user-level dotfiles folder.

## Sensitive information

This repository is public. Do not store API keys, tokens, cookies, credentials,
private chat history, employer-confidential instructions, or private service
addresses here. An ignored file prevents accidental Git commits, but it is not
a secret store. Use 1Password, Windows Credential Manager, or environment
variables for secrets.
