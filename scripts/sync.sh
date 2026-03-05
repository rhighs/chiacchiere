#!/bin/bash
# chiacchiere sync — copy a skill to the team repo and open a PR
set -e

SKILL_FILE="$1"
CONF="$HOME/.config/chiacchiere/team.conf"

if [ ! -f "$CONF" ]; then
  echo "No team config. Run: curl -fsSL https://raw.githubusercontent.com/rhighs/chiacchiere/main/install.sh | bash -s -- <repo-url>" >&2
  exit 1
fi
source "$CONF"

if [ ! -f "$SKILL_FILE" ]; then
  echo "Skill file not found: $SKILL_FILE" >&2; exit 1
fi

SKILL_NAME=$(basename "$SKILL_FILE" .md)
BRANCH="chiacchiere/${SKILL_NAME}-$(date +%Y%m%d-%H%M%S)"

cd "$TEAM_REPO_PATH"
git fetch origin --quiet
git checkout -b "$BRANCH" origin/main --quiet

mkdir -p "opencode" "claude/${SKILL_NAME}"

# opencode version (plain markdown)
cp "$SKILL_FILE" "opencode/${SKILL_NAME}.md"

# Claude Code version (add required SKILL.md frontmatter)
BODY=$(grep -v '^---' "$SKILL_FILE" | grep -v '^description:' | grep -v '^namespace:' | sed '/^$/N;/^\n$/d')
DESC=$(sed -n '/^description:/,/^[a-z]/{ /^description:/d; /^[a-z]/d; p }' "$SKILL_FILE" | sed 's/^  //')

cat > "claude/${SKILL_NAME}/SKILL.md" << SKILLEOF
---
name: ${SKILL_NAME}
description: |
  ${DESC:-See ${SKILL_NAME}}
version: 1.0.0
---

${BODY}
SKILLEOF

git add "opencode/${SKILL_NAME}.md" "claude/${SKILL_NAME}/SKILL.md"
git commit -m "skill: ${SKILL_NAME}"
git push origin "$BRANCH" --quiet

gh pr create \
  --title "skill: ${SKILL_NAME}" \
  --body "Extracted by [amarcord](https://github.com/rhighs/amarcord) + synced by chiacchiere.

**Install after merge:**
\`\`\`bash
chiacchiere pull
\`\`\`" \
  --head "$BRANCH" \
  --base main

echo "PR opened: ${SKILL_NAME}"
