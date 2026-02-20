#!/bin/bash

# Auto-committing self-modifying script
# Runs every 11 hours via launchd daemon
# Tracks commits and pushes to GitHub automatically

# Setup environment for cron/launchd execution
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export HOME="/Users/user"
# Prevent git from hanging waiting for credentials in non-interactive daemon mode
export GIT_TERMINAL_PROMPT=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/auto_commit.sh.log"
cd "$SCRIPT_DIR"

# Function to log with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_message "===== Starting auto-commit ====="

# Verify we're in a git repo
if [ ! -d ".git" ]; then
    log_message "ERROR: Not in a git repository"
    exit 1
fi

# Configure git user for this session (needed when running as root/daemon)
git config user.name "AutoCommit Bot" 2>> "$LOG_FILE"
git config user.email "autocommit@bot.local" 2>> "$LOG_FILE"

# Get the day count
if [ -f "day_count.txt" ]; then
    DAY=$(cat day_count.txt)
    DAY=$((DAY + 1))
else
    DAY=1
fi

# Update day count
echo $DAY > day_count.txt
log_message "Incremented day to: $DAY"

# Get current date
TODAY=$(date +"%Y-%m-%d %H:%M:%S")

# Append to README.md
echo "Day $DAY - $TODAY" >> README.md
log_message "Updated README.md: Day $DAY - $TODAY"

# Stage and commit
git add day_count.txt README.md 2>> "$LOG_FILE"
GIT_OUTPUT=$(git commit -m "auto-commit: Day $DAY at $TODAY" 2>&1)
if [ $? -eq 0 ]; then
    log_message "Git commit successful"
    log_message "  $GIT_OUTPUT"
else
    log_message "ERROR on git commit: $GIT_OUTPUT"
    exit 1
fi

# Push to repository
PUSH_OUTPUT=$(git push origin main 2>&1)
PUSH_CODE=$?
if [ $PUSH_CODE -eq 0 ]; then
    log_message "Git push successful"
    log_message "  $PUSH_OUTPUT"
else
    PUSH_OUTPUT2=$(git push origin master 2>&1)
    PUSH_CODE2=$?
    if [ $PUSH_CODE2 -eq 0 ]; then
        log_message "Git push to master successful"
        log_message "  $PUSH_OUTPUT2"
    else
        log_message "ERROR: Push failed to both main and master"
        log_message "  main: $PUSH_OUTPUT"
        log_message "  master: $PUSH_OUTPUT2"
        exit 1
    fi
fi

log_message "✓ COMPLETE: Day $DAY committed and pushed at $TODAY"
log_message "===== End auto-commit ====="
echo ""
