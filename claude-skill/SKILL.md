---
name: chiacchiere
description: |
  Sync locally extracted skills to the shared team repo. Use after amarcord
  extracts a skill when the user wants to share it with teammates. Triggers:
  "share this skill", "sync to team", "open a PR for this", /chiacchiere.
  Also handles: "pull team skills", "get latest from team".
version: 1.0.0
allowed-tools:
  - Bash
  - Read
---

# chiacchiere

Distributes skills extracted by amarcord to the shared team repo via PR.

## When to Use

- User runs `/amarcord` and a skill is saved — offer to sync it
- User says "share this with the team" or "open a PR for this skill"
- User says "pull latest skills" or "get team skills"

## sync

### Check config first

```bash
cat ~/.config/chiacchiere/team.conf 2>/dev/null
```

If missing:
> chiacchiere is not configured. Set it up with:
> `curl -fsSL https://raw.githubusercontent.com/rhighs/chiacchiere/main/install.sh | bash -s -- https://github.com/YOUR-ORG/team-skills`

### Find the skill

If not specified, find the most recent:
```bash
ls -t ~/.config/opencode/commands/*.md 2>/dev/null | head -1
ls -t ~/.claude/skills/*/SKILL.md 2>/dev/null | head -1
```

### Run

```bash
chiacchiere sync {skill-file-path}
```

Report the PR URL.

## pull

```bash
chiacchiere pull
```

## status

```bash
cat ~/.config/chiacchiere/team.conf 2>/dev/null && echo "configured" || echo "not configured"
ls ~/.config/opencode/commands/ 2>/dev/null | grep ":"
```
