# Auto-Commit System

A self-modifying script that automatically commits and pushes every 11 hours 24/7 **even when laptop is closed/off**.

## How It Works

### GitHub Actions (Recommended — Cloud-based, always reliable)

- `.github/workflows/auto_commit.yml` — Scheduled workflow that runs every 11 hours on GitHub's servers
  - No local daemon or credentials needed
  - Works even when your laptop is off
  - Uses the built-in `GITHUB_TOKEN` for authentication

### macOS LaunchDaemon (Local — Requires laptop to be on and credentials configured)

- `auto_commit.sh` - Main script that self-modifies, tracks days, and commits
- `com.user.autocommit.daemon.plist` - macOS LaunchDaemon (runs every 11 hours automatically, 24/7)
- `day_count.txt` - Tracks which day you're on
- `auto_commit.sh.log` - Detailed log with timestamps

## Current Setup

✅ **GitHub Actions workflow active** — Runs on GitHub's cloud every 11 hours  
✅ **24/7 operation** — Works even with laptop closed/off  
✅ **Every 11 hours** — Automatic commits (cron: `0 */11 * * *`)  
✅ **No credentials required** — Uses built-in `GITHUB_TOKEN`  
✅ **Already running** — Latest commit: Day 9

## What Happens Automatically

Every 11 hours (day or night, on or off):
1. LaunchDaemon wakes the script
2. Increments day counter
3. Creates entry like "Day 9 - 2026-02-20 21:44:14"
4. Commits to git: "auto-commit: Day 9 at 2026-02-20 21:44:14"
5. Pushes to GitHub (main branch)
6. Logs everything with timestamps

**Example log:**
```
[2026-02-20 21:44:14] ===== Starting auto-commit =====
[2026-02-20 21:44:14] Incremented day to: 9
[2026-02-20 21:44:14] Git commit successful
[2026-02-20 21:44:14] Git push successful
[2026-02-20 21:44:14] ✓ COMPLETE: Day 9 committed and pushed
```

## Commands

### Check if daemon is running
```bash
sudo launchctl list | grep autocommit
```

Should show:
```
-       0       com.user.autocommit.daemon
```

### View detailed logs
```bash
tail -f /Users/user/shell/auto_commit.sh.log
```

### View GitHub commits
```bash
cd /Users/user/shell
git log --oneline | head -10
```

## Customization

### Change the Interval

Edit the plist file:

```bash
sudo nano /Library/LaunchDaemons/com.user.autocommit.daemon.plist
```

Find this section:
```xml
<key>StartInterval</key>
<integer>39600</integer>
```

Change the number (in seconds):
- 39600 = 11 hours
- 3600 = 1 hour
- 7200 = 2 hours
- 86400 = 24 hours

Then reload:
```bash
sudo launchctl unload /Library/LaunchDaemons/com.user.autocommit.daemon.plist
sudo launchctl load /Library/LaunchDaemons/com.user.autocommit.daemon.plist
```

## Cleanup

To remove the automatic scheduling:

```bash
sudo launchctl unload /Library/LaunchDaemons/com.user.autocommit.daemon.plist
sudo rm /Library/LaunchDaemons/com.user.autocommit.daemon.plist
```

## Requirements

- Git repository initialized
- Remote repository set up (origin)
- Credentials configured (uses HTTPS with git credential helper)
- macOS (uses LaunchDaemon)

## Troubleshooting

### Check daemon status
```bash
sudo launchctl list | grep autocommit
```

Exit code explanations:
- `0` = Normal exit (successful)
- `1` = Error occurred (check logs)
- `-1` = Currently running

### View error details
```bash
tail -50 /Users/user/shell/auto_commit.sh.log
```

### Manual test
```bash
cd /Users/user/shell
sudo ./auto_commit.sh
```

### Git credentials fail
Make sure high-level operations work:
```bash
git push origin main
```

If using SSH, ensure key is loaded. If using HTTPS, ensure credential helper is configured.

