# chiacchiere

> *"chiacchiere"* — Italian for gossip, chatter. Also: the thing that spreads what your AI learned around the team.

---

Your agent figures something out. Normally that knowledge dies when the session ends.
**chiacchiere** syncs it to a shared team repo so everyone's agent benefits.

Works alongside [amarcord](https://github.com/rhighs/amarcord). amarcord extracts —
chiacchiere distributes.

```
amarcord extracts skill → chiacchiere opens PR → team reviews → everyone pulls
```

---

## How It Works

1. **amarcord** saves a skill locally (opencode or Claude Code)
2. **chiacchiere** copies it to the shared team repo, opens a PR
3. Team reviews and merges
4. Everyone pulls — both opencode and Claude Code versions are ready

Skills are namespaced by project (`my-project:some-fix.md`, `general:some-pattern.md`),
auto-detected from the current git remote.

Before creating a new skill, chiacchiere checks for duplicates — updates existing
skills instead of creating noise.

---

## Setup

### 1. Create a shared team repo

Use the template in `team-repo-template/` or create a fresh repo:

```bash
gh repo create your-org/team-skills --private
```

### 2. Install on each machine

```bash
curl -fsSL https://raw.githubusercontent.com/rhighs/chiacchiere/main/install.sh | bash -s -- https://github.com/YOUR-ORG/team-skills
```

This:
- Clones the team repo
- Symlinks all skills into place via `stow` (opencode + Claude Code)
- Writes config to `~/.config/chiacchiere/team.conf`

### 3. Use it

After running `/amarcord` and a skill is saved locally:

```bash
chiacchiere sync ~/.config/opencode/commands/my-project:some-fix.md
```

Or let amarcord call it automatically — if `~/.config/chiacchiere/team.conf` exists,
amarcord calls chiacchiere after every extraction.

---

## Pull latest from the team

```bash
chiacchiere pull
```

---

## Namespace convention

`{project}:{description}.md` — auto-detected from `git remote get-url origin`.

```
my-project:mcp-proxy-namespaced-params.md
general:git-rebase-conflict-resolution.md
pleasetriage:vercel-dns-config.md
```

---

## Team repo structure

```
team-skills/
  opencode/              → stowed to ~/.config/opencode/commands/
    my-project:fix.md
  claude/                → stowed to ~/.claude/skills/
    my-project:fix/
      SKILL.md
  README.md
```

---

## Requirements

- `git`, `gh` (GitHub CLI)
- `stow` (`brew install stow` / `apt install stow`)
- [amarcord](https://github.com/rhighs/amarcord) (for extraction)

## Tests

```bash
bash test/run_tests.sh
```

---

## Credit

Built on top of [amarcord](https://github.com/rhighs/amarcord).
