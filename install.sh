#!/bin/bash
set -e

TEAM_REPO_URL="$1"
TEAM_REPO_PATH="${2:-$HOME/.local/share/chiacchiere/team-skills}"
BIN_DIR="$HOME/.local/bin"
BASE_URL="https://raw.githubusercontent.com/rhighs/chiacchere/main"

if [ -z "$TEAM_REPO_URL" ]; then
  echo "Usage: install.sh <team-repo-url>"; exit 1
fi

echo "Setting up chiacchiere..."

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

# Install scripts
mkdir -p "$HOME/.config/chiacchiere"
curl -fsSL "$BASE_URL/scripts/sync.sh" -o "$HOME/.config/chiacchiere/sync.sh" && chmod +x "$HOME/.config/chiacchiere/sync.sh"
curl -fsSL "$BASE_URL/scripts/pull.sh" -o "$HOME/.config/chiacchiere/pull.sh" && chmod +x "$HOME/.config/chiacchiere/pull.sh"

# Install chiacchiere binary
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/chiacchiere" << 'BIN'
#!/bin/bash
CMD="$1"; shift
case "$CMD" in
  sync) ~/.config/chiacchiere/sync.sh "$@" ;;
  pull) ~/.config/chiacchiere/pull.sh "$@" ;;
  *) echo "Usage: chiacchiere <sync|pull>"; exit 1 ;;
esac
BIN
chmod +x "$BIN_DIR/chiacchiere"

# Stow existing team skills
if command -v stow &>/dev/null; then
  [ -d "$TEAM_REPO_PATH/opencode" ] && stow --dir="$TEAM_REPO_PATH" opencode --target="$HOME/.config/opencode/commands" --restow && echo "✓ opencode skills linked"
  [ -d "$TEAM_REPO_PATH/claude"   ] && stow --dir="$TEAM_REPO_PATH" claude   --target="$HOME/.claude" --restow && echo "✓ Claude Code skills linked"
else
  echo "⚠ stow not found (brew install stow / apt install stow) — skills not yet linked"
fi

echo ""
echo "Done."
echo "  chiacchiere sync <skill-file>   push a skill + open PR"
echo "  chiacchiere pull                pull latest team skills"
