# Claude Agent Skills

Each child directory containing a `SKILL.md` file is a real, installable
Claude Agent Skill. The installer copies those directories to
`~/.claude/skills`.

## Available skills

- `italian-doc-scan` converts photographed or scanned Italian citizenship case
  documents into organized transcriptions, English translations, and a case
  summary index.

To add another skill, create a child directory with a `SKILL.md` file. Optional
supporting files can be placed in `scripts/` and `references/` within that
directory.
