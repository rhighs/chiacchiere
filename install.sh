#!/bin/bash
set -e

TEAM_REPO_URL="$1"
TEAM_REPO_PATH="${2:-$HOME/.local/share/chiacchiere/team-skills}"
BIN_DIR="$HOME/.local/bin"
BASE_URL="https://raw.githubusercontent.com/rhighs/chiacchiere/main"
OPENCODE_COMMANDS="$HOME/.config/opencode/commands"
CLAUDE_SKILLS="$HOME/.claude/skills/chiacchiere"

if [ -z "$TEAM_REPO_URL" ]; then
  echo "Usage: install.sh <team-repo-url>"
  echo "Example: install.sh https://github.com/your-org/team-skills"
  exit 1
fi

echo "Setting up chiacchiere..."
echo ""

# Clone or pull team repo
if [ -d "$TEAM_REPO_PATH/.git" ]; then
  git -C "$TEAM_REPO_PATH" pull --quiet && echo "✓ team repo updated"
else
  git clone "$TEAM_REPO_URL" "$TEAM_REPO_PATH" --quiet && echo "✓ team repo cloned"
fi

# Write config
mkdir -p "$HOME/.config/chiacchiere"
cat > "$HOME/.config/chiacchiere/team.conf" << CONF
TEAM_REPO_PATH="$TEAM_REPO_PATH"
TEAM_REPO_REMOTE="$TEAM_REPO_URL"
CONF
echo "✓ config written to ~/.config/chiacchiere/team.conf"

# Download scripts
curl -fsSL "$BASE_URL/scripts/sync.sh" -o "$HOME/.config/chiacchiere/sync.sh" && chmod +x "$HOME/.config/chiacchiere/sync.sh"
curl -fsSL "$BASE_URL/scripts/pull.sh" -o "$HOME/.config/chiacchiere/pull.sh" && chmod +x "$HOME/.config/chiacchiere/pull.sh"
echo "✓ scripts installed"

# Install chiacchiere CLI binary
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/chiacchiere" << 'BIN'
#!/bin/bash
CMD="$1"; shift
case "$CMD" in
  sync)   ~/.config/chiacchiere/sync.sh "$@" ;;
  pull)   ~/.config/chiacchiere/pull.sh "$@" ;;
  status) cat ~/.config/chiacchiere/team.conf 2>/dev/null && echo "configured" || echo "not configured" ;;
  *)      echo "Usage: chiacchiere <sync|pull|status>"; exit 1 ;;
esac
BIN
chmod +x "$BIN_DIR/chiacchiere"
echo "✓ chiacchiere CLI installed to $BIN_DIR/chiacchiere"

# Install AI skill for opencode
if [ -d "$OPENCODE_COMMANDS" ] || command -v opencode &>/dev/null; then
  mkdir -p "$OPENCODE_COMMANDS"
  curl -fsSL "$BASE_URL/opencode-command/chiacchiere.md" -o "$OPENCODE_COMMANDS/chiacchiere.md"
  echo "✓ opencode skill installed"
fi

# Install AI skill for Claude Code
if [ -d "$HOME/.claude" ] || command -v claude &>/dev/null; then
  mkdir -p "$CLAUDE_SKILLS"
  curl -fsSL "$BASE_URL/claude-skill/SKILL.md" -o "$CLAUDE_SKILLS/SKILL.md"
  echo "✓ Claude Code skill installed"
fi

# Stow existing team skills
if command -v stow &>/dev/null; then
  [ -d "$TEAM_REPO_PATH/opencode" ] && stow --dir="$TEAM_REPO_PATH" opencode --target="$OPENCODE_COMMANDS" --restow 2>/dev/null && echo "✓ team opencode skills linked"
  [ -d "$TEAM_REPO_PATH/claude"   ] && stow --dir="$TEAM_REPO_PATH" claude   --target="$HOME/.claude" --restow 2>/dev/null && echo "✓ team Claude Code skills linked"
else
  echo "⚠ stow not found — install it to auto-link team skills (brew install stow)"
fi

echo ""
echo "Done. chiacchiere is ready."
echo ""
echo "  chiacchiere sync <skill>   push a skill to the team + open PR"
echo "  chiacchiere pull           pull latest team skills"
echo "  chiacchiere status         check configuration"
echo ""
echo "The AI can also use it directly — /chiacchiere is now available in opencode and Claude Code."
