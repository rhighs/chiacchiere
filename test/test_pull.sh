#!/bin/bash
set -euo pipefail

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_file() {
  [ -f "$1" ] || fail "Expected file: $1"
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
mkdir -p "$HOME/.config/chiacchiere" "$HOME/.config/opencode/commands" "$HOME/.claude"

REMOTE_REPO="$TMP_DIR/remote.git"
SEED_REPO="$TMP_DIR/seed"
TEAM_REPO="$TMP_DIR/team-repo"
MOCK_BIN="$TMP_DIR/mock-bin"
CALLS_LOG="$TMP_DIR/calls.log"
SKILL_FILE="$TMP_DIR/local-skill.md"

git init --bare "$REMOTE_REPO" >/dev/null

mkdir -p "$SEED_REPO"
git init "$SEED_REPO" >/dev/null
git -C "$SEED_REPO" config user.name "Test User"
git -C "$SEED_REPO" config user.email "test@example.com"
mkdir -p "$SEED_REPO/opencode" "$SEED_REPO/claude/base-skill"
cat > "$SEED_REPO/opencode/base-skill.md" <<'EOF'
---
description: |
  Base skill
namespace: general
---

Base
EOF
cat > "$SEED_REPO/claude/base-skill/SKILL.md" <<'EOF'
---
name: base-skill
description: |
  Base skill
version: 1.0.0
---

Base
EOF
git -C "$SEED_REPO" add .
git -C "$SEED_REPO" commit -m "seed" >/dev/null
git -C "$SEED_REPO" branch -M main
git -C "$SEED_REPO" remote add origin "$REMOTE_REPO"
git -C "$SEED_REPO" push -u origin main >/dev/null

git clone "$REMOTE_REPO" "$TEAM_REPO" >/dev/null
git -C "$TEAM_REPO" checkout -B main origin/main >/dev/null

cat > "$HOME/.config/chiacchiere/team.conf" <<EOF
TEAM_REPO_PATH="$TEAM_REPO"
TEAM_REPO_REMOTE="$REMOTE_REPO"
EOF

cat > "$SKILL_FILE" <<'EOF'
---
description: |
  Pull test skill
namespace: general
---

Pull body
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
chmod +x "$MOCK_BIN/gh" "$MOCK_BIN/stow"

export PATH="$MOCK_BIN:$PATH"
export CALLS_LOG

cat > "$SEED_REPO/opencode/new-skill.md" <<'EOF'
new skill content
EOF
git -C "$SEED_REPO" add opencode/new-skill.md
git -C "$SEED_REPO" commit -m "add new skill" >/dev/null
git -C "$SEED_REPO" push origin main >/dev/null

bash "$ROOT_DIR/scripts/pull.sh"

assert_file "$TEAM_REPO/opencode/new-skill.md"
assert_contains "$CALLS_LOG" "stow opencode"
assert_contains "$CALLS_LOG" "stow claude"

LOCAL_HEAD="$(git -C "$TEAM_REPO" rev-parse HEAD)"
REMOTE_HEAD="$(git -C "$TEAM_REPO" rev-parse origin/main)"
[ "$LOCAL_HEAD" = "$REMOTE_HEAD" ] || fail "Local repo did not pull latest commit"

echo "PASS: test_pull.sh"
