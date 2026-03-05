#!/bin/bash
set -euo pipefail

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_file() {
  [ -f "$1" ] || fail "Expected file: $1"
}

assert_exec() {
  [ -x "$1" ] || fail "Expected executable: $1"
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  grep -q "$pattern" "$file" || fail "Expected '$pattern' in $file"
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

export HOME="$TMP_DIR/home"
mkdir -p "$HOME/.config/opencode/commands" "$HOME/.claude"

SOURCE_REPO="$TMP_DIR/source-team-repo"
INSTALL_TARGET="$TMP_DIR/team-repo"
MOCK_BIN="$TMP_DIR/mock-bin"
CALLS_LOG="$TMP_DIR/calls.log"
SKILL_FILE="$TMP_DIR/local-skill.md"

mkdir -p "$SOURCE_REPO"
git init "$SOURCE_REPO" >/dev/null
git -C "$SOURCE_REPO" config user.name "Test User"
git -C "$SOURCE_REPO" config user.email "test@example.com"
mkdir -p "$SOURCE_REPO/opencode" "$SOURCE_REPO/claude/demo-skill"
cat > "$SOURCE_REPO/opencode/demo-skill.md" <<'EOF'
Demo skill
EOF
cat > "$SOURCE_REPO/claude/demo-skill/SKILL.md" <<'EOF'
---
name: demo-skill
description: |
  Demo skill
version: 1.0.0
---

Demo skill
EOF
git -C "$SOURCE_REPO" add .
git -C "$SOURCE_REPO" commit -m "seed" >/dev/null

cat > "$SKILL_FILE" <<'EOF'
---
description: |
  Install test skill
namespace: general
---

Install body
EOF

mkdir -p "$MOCK_BIN"
cat > "$MOCK_BIN/gh" <<'EOF'
#!/bin/bash
echo "gh $*" >> "$CALLS_LOG"
exit 0
EOF
cat > "$MOCK_BIN/stow" <<'EOF'
#!/bin/bash
echo "stow $*" >> "$CALLS_LOG"
exit 0
EOF
cat > "$MOCK_BIN/curl" <<'EOF'
#!/bin/bash
set -e
url=""
out=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o)
      out="$2"
      shift 2
      ;;
    -fsSL)
      shift
      ;;
    *)
      if [ -z "$url" ]; then
        url="$1"
      fi
      shift
      ;;
  esac
done

echo "curl $url -> $out" >> "$CALLS_LOG"

case "$url" in
  */scripts/sync.sh)
    cp "$ROOT_DIR/scripts/sync.sh" "$out"
    ;;
  */scripts/pull.sh)
    cp "$ROOT_DIR/scripts/pull.sh" "$out"
    ;;
  */opencode-command/chiacchiere.md)
    cp "$ROOT_DIR/opencode-command/chiacchiere.md" "$out"
    ;;
  */claude-skill/SKILL.md)
    cp "$ROOT_DIR/claude-skill/SKILL.md" "$out"
    ;;
  *)
    echo "unsupported url: $url" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gh" "$MOCK_BIN/stow" "$MOCK_BIN/curl"

export PATH="$MOCK_BIN:$PATH"
export CALLS_LOG
export ROOT_DIR

bash "$ROOT_DIR/install.sh" "$SOURCE_REPO" "$INSTALL_TARGET"

assert_file "$HOME/.config/chiacchiere/team.conf"
assert_contains "$HOME/.config/chiacchiere/team.conf" "TEAM_REPO_PATH=\"$INSTALL_TARGET\""
assert_contains "$HOME/.config/chiacchiere/team.conf" "TEAM_REPO_REMOTE=\"$SOURCE_REPO\""

assert_exec "$HOME/.config/chiacchiere/sync.sh"
assert_exec "$HOME/.config/chiacchiere/pull.sh"
assert_exec "$HOME/.local/bin/chiacchiere"

assert_file "$INSTALL_TARGET/opencode/demo-skill.md"
assert_file "$INSTALL_TARGET/claude/demo-skill/SKILL.md"
assert_contains "$CALLS_LOG" "stow --dir=$INSTALL_TARGET opencode"
assert_contains "$CALLS_LOG" "stow --dir=$INSTALL_TARGET claude"

STATUS_OUTPUT="$($HOME/.local/bin/chiacchiere status)"
echo "$STATUS_OUTPUT" | grep -q "configured" || fail "chiacchiere status did not report configured"

echo "PASS: test_install.sh"
