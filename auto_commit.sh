#!/bin/bash
# Auto-committing script with quote support
# Runs once daily via launchd daemon (backup to GitHub Actions)

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export HOME="/Users/user"
export GIT_TERMINAL_PROMPT=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/auto_commit.log"
LOCK_FILE="$SCRIPT_DIR/.auto_commit.lock"

cd "$SCRIPT_DIR"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_message "===== Starting auto-commit ====="

# ── Lock: prevent overlapping runs ──────────────────────────────────────────
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE")
    if kill -0 "$LOCK_PID" 2>/dev/null; then
        log_message "SKIP: Another instance already running (PID $LOCK_PID)"
        exit 0
    else
        log_message "Stale lock file found, removing."
        rm -f "$LOCK_FILE"
    fi
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# ── Git repo check ───────────────────────────────────────────────────────────
if [ ! -d ".git" ]; then
    log_message "ERROR: Not in a git repository"
    exit 1
fi

# ── Date guard: only one commit per calendar day from Mac ────────────────────
TODAY_DATE=$(date '+%Y-%m-%d')
if grep -q "$TODAY_DATE" commit_log.txt 2>/dev/null; then
    log_message "SKIP: Already committed today ($TODAY_DATE)"
    exit 0
fi

# ── Your real GitHub identity ─────────────────────────────────────────────────
git config user.name "asbinthapa99"
git config user.email "asbinthapa27@gmail.com"

# ── Fetch a random quote ─────────────────────────────────────────────────────
RESPONSE=$(curl -sf https://zenquotes.io/api/random || echo "")
if [ -n "$RESPONSE" ]; then
    QUOTE=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin)[0]; print(d['q'])" 2>/dev/null)
    AUTHOR=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin)[0]; print(d['a'])" 2>/dev/null)
fi
if [ -z "$QUOTE" ]; then
    QUOTE="Keep pushing forward, one commit at a time."
    AUTHOR="Unknown"
fi
log_message "Quote: $QUOTE — $AUTHOR"

# ── Increment day counter ────────────────────────────────────────────────────
if [ -f "day_count.txt" ]; then
    DAY=$(cat day_count.txt)
    DAY=$((DAY + 1))
else
    DAY=1
fi
echo $DAY > day_count.txt
log_message "Day: $DAY"

# ── Determine session ────────────────────────────────────────────────────────
HOUR=$(date '+%H')
if [ "$HOUR" -lt 15 ]; then
    LABEL="🌅 Morning"
else
    LABEL="🌙 Evening"
fi

NOW=$(date '+%Y-%m-%d %H:%M:%S')

# ── Update commit log ────────────────────────────────────────────────────────
echo "| Day $DAY | $NOW | $LABEL | $QUOTE — $AUTHOR |" >> commit_log.txt

# ── Write clean README ───────────────────────────────────────────────────────
TOTAL=$(git rev-list --count HEAD 2>/dev/null || echo "—")

cat > README.md << EOF
# 🔥 Streak Tracker

> Automatically updated twice daily. Every commit counts.

---

## 📊 Stats

| | |
|---|---|
| **Current Day** | Day $DAY |
| **Last Updated** | $NOW UTC |
| **Total Commits** | $TOTAL |
| **Started** | 2026-02-17 |

---

## 💬 Quote of the Commit

> "$QUOTE"
>
> — *$AUTHOR*

---

## 📅 Recent Commit Log

| Day | Timestamp | Session | Quote |
|-----|-----------|---------|-------|
EOF

tail -10 commit_log.txt >> README.md

cat >> README.md << EOF

---

*This repository is part of a daily consistency challenge. Powered by GitHub Actions.*
EOF

log_message "README updated"

# ── Stage and commit ─────────────────────────────────────────────────────────
git add day_count.txt README.md commit_log.txt 2>> "$LOG_FILE"
GIT_OUTPUT=$(git commit -m "Day $DAY | $LABEL | \"$QUOTE\" — $AUTHOR" 2>&1)
if [ $? -ne 0 ]; then
    log_message "ERROR: commit failed: $GIT_OUTPUT"
    exit 1
fi
log_message "Commit OK"

# ── Push ─────────────────────────────────────────────────────────────────────
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
PUSH_OUTPUT=$(git push origin "$BRANCH" 2>&1)
if [ $? -ne 0 ]; then
    log_message "ERROR: push failed: $PUSH_OUTPUT"
    exit 1
fi

log_message "✓ COMPLETE: Day $DAY pushed at $NOW"
log_message "===== End ====="
