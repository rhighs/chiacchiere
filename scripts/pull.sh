#!/bin/bash
# chiacchiere pull — update team skills and restow
set -e

CONF="$HOME/.config/chiacchiere/team.conf"
[ -f "$CONF" ] && source "$CONF" || { echo "Not configured. Run install.sh first."; exit 1; }

cd "$TEAM_REPO_PATH"
git pull --quiet
echo "✓ pulled"

if command -v stow &>/dev/null; then
  [ -d opencode ] && stow opencode --target="$HOME/.config/opencode/commands" --restow && echo "✓ opencode skills linked"
  [ -d claude ]   && stow claude   --target="$HOME/.claude" --restow && echo "✓ Claude Code skills linked"
else
  # fallback: plain copy
  [ -d opencode ] && cp opencode/*.md "$HOME/.config/opencode/commands/" 2>/dev/null && echo "✓ opencode skills copied"
  [ -d claude ]   && cp -r claude/* "$HOME/.claude/skills/" 2>/dev/null && echo "✓ Claude Code skills copied"
fi
