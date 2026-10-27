# AI configuration

This folder is the source of truth for portable personal Claude and Copilot configuration.
Run the installer from the repository root:

```powershell
.\ai\install.ps1
```

The default remains Claude only. Use `-Tool Copilot` to install personal Copilot
skills, or `-Tool All` to install both tools' configuration.

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
- `copilot/skills` contains personal Copilot Agent Skills.
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
| `copilot/skills/*` (with `-Tool Copilot` or `-Tool All`) | `~/.copilot/skills/*` |

If `claude/settings.local.json` exists, the installer recursively merges it over
the committed Claude settings. Existing destination-only settings are
preserved. Keep the local file untracked for machine-specific preferences.

Claude project-local settings belong in a project's
`.claude/settings.local.json`, not in this user-level dotfiles folder.

## Human writing skill for Copilot

Install for the current user's local CLI sessions across repositories:

```powershell
.\ai\install.ps1 -Tool Copilot -WhatIf
.\ai\install.ps1 -Tool Copilot
```

In an existing Copilot session, run `/skills reload`, then `/skills info human`.
New sessions discover the installed personal skill automatically.

```text
/human --channel teams Rewrite this update: <draft>
/human --channel email Draft a reply: <context>
/human --channel document Rewrite this section: <draft>
/human learn
/human learn --source "C:\path\my-writing.docx" --channel document
/human learn --source https://example.com/my-article --channel document
/human learn --channel email --source <paste your own text>
/human typos --channel teams Rewrite: <draft>
```

Learning checks authorship, separates Teams/email/document voices, and proposes
changes for approval. Multi-author documents are excluded unless the exact
sampled contributions can be confidently attributed to you. Supplied sources
are used without expanding to mailbox searches. Microsoft 365 discovery
requires separately configured, authorized tools such as WorkIQ.

The approved profile lives at `%USERPROFILE%\.copilot\human\style.md`, outside
this public repository and outside the installed skill. The installer neither
creates nor overwrites it. Until learning is approved, the skill reports that
the profile is unlearned rather than inventing your voice. Backups and profiles
are private local files; review them before sharing. Only the reusable workflow
and an unlearned template are tracked here.

Typo mode is opt-in, takes no count argument, and distributes inconsequential
imperfections according to content length: roughly one per 200 words of eligible
prose, with fewer or none when needed for safety or naturalness. Protected content
does not increase the target. Normal writing mode does not deliberately introduce errors. These modes
are skill instructions, not a formal CLI argument parser. Generated output and
authorship judgments still require your review.

Other machines need their own installation and a securely transferred profile
if desired. This local installation does not deploy to cloud agents.

## Sensitive information

This repository is public. Do not store API keys, tokens, cookies, credentials,
private chat history, employer-confidential instructions, or private service
addresses here. An ignored file prevents accidental Git commits, but it is not
a secret store. Use 1Password, Windows Credential Manager, or environment
variables for secrets.
