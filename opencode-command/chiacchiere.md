---
description: Sync a locally extracted skill to the shared team repo and open a PR. Run after /amarcord extracts a skill, when you want to share it with the team. Also use /chiacchiere pull to get the latest skills from teammates.
---

# /chiacchiere

Distributes skills extracted by amarcord to the shared team repo.
One person learns, everyone benefits.

## Usage

```
/chiacchiere sync    # sync the skill just extracted to the team repo
/chiacchiere pull    # pull latest skills from the team
/chiacchiere status  # check if team sync is configured
```

---

## sync

Run this after `/amarcord` extracts a skill and you want to share it.

### Step 1 — Check configuration

```bash
cat ~/.config/chiacchiere/team.conf 2>/dev/null
```

If missing → tell the user to run setup first:
```
chiacchiere is not configured. Set it up with:
curl -fsSL https://raw.githubusercontent.com/rhighs/chiacchiere/main/install.sh | bash -s -- https://github.com/YOUR-ORG/team-skills
```

### Step 2 — Find the skill to sync

If the user specified a file, use it.
If not, find the most recently modified skill:

```bash
ls -t ~/.config/opencode/commands/*.md 2>/dev/null | head -1
```

Confirm with the user: "Sync `{filename}`?"

### Step 3 — Run sync

```bash
chiacchiere sync {skill-file-path}
```

Report the PR URL when done.

---

## pull

Pull latest skills from the team repo.

```bash
chiacchiere pull
```

Reports how many skills were updated.

---

## status

```bash
cat ~/.config/chiacchiere/team.conf 2>/dev/null && echo "configured" || echo "not configured"
ls ~/.config/opencode/commands/ | grep ":" | wc -l
```

Report: configured yes/no, how many team skills are installed.
