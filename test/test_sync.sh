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
mkdir -p "$HOME/.config/chiacchiere"

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
echo "seed" > "$SEED_REPO/README.md"
git -C "$SEED_REPO" add README.md
git -C "$SEED_REPO" commit -m "seed" >/dev/null
git -C "$SEED_REPO" branch -M main
git -C "$SEED_REPO" remote add origin "$REMOTE_REPO"
git -C "$SEED_REPO" push -u origin main >/dev/null

git clone "$REMOTE_REPO" "$TEAM_REPO" >/dev/null
git -C "$TEAM_REPO" checkout -B main origin/main >/dev/null
git -C "$TEAM_REPO" config user.name "Test User"
git -C "$TEAM_REPO" config user.email "test@example.com"

cat > "$HOME/.config/chiacchiere/team.conf" <<EOF
TEAM_REPO_PATH="$TEAM_REPO"
TEAM_REPO_REMOTE="$REMOTE_REPO"
EOF

cat > "$SKILL_FILE" <<'EOF'
---
description: |
  Test sync description
namespace: general
---

# Sync Skill

This is a sync test body.
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

bash "$ROOT_DIR/scripts/sync.sh" "$SKILL_FILE"

SKILL_NAME="local-skill"
BRANCH_NAME="$(git -C "$TEAM_REPO" rev-parse --abbrev-ref HEAD)"
case "$BRANCH_NAME" in
  "chiacchiere/${SKILL_NAME}-"*) ;;
  *) fail "Unexpected branch name: $BRANCH_NAME" ;;
esac

assert_file "$TEAM_REPO/opencode/${SKILL_NAME}.md"
assert_file "$TEAM_REPO/claude/${SKILL_NAME}/SKILL.md"
assert_contains "$TEAM_REPO/claude/${SKILL_NAME}/SKILL.md" "name: ${SKILL_NAME}"
assert_contains "$TEAM_REPO/claude/${SKILL_NAME}/SKILL.md" "This is a sync test body"

LAST_COMMIT_MSG="$(git -C "$TEAM_REPO" log -1 --pretty=%s)"
[ "$LAST_COMMIT_MSG" = "skill: ${SKILL_NAME}" ] || fail "Unexpected commit message: $LAST_COMMIT_MSG"

git -C "$TEAM_REPO" ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME" || fail "Branch not pushed to origin"
assert_contains "$CALLS_LOG" "gh pr create"

echo "PASS: test_sync.sh"
