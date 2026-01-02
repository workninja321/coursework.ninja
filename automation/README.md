# SEO Machine - Automated Page Generation

This automation system generates blog posts and landing pages from a Google Sheet queue, using Claude Code to create the content.

## Architecture

```
Google Sheet (Queue) → seo-machine.mjs → Claude Code → Git commit/push → GitHub Pages
```

## Setup Steps

### 1. Google Cloud Setup (one-time)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or use existing)
3. Enable **Google Sheets API**
4. Go to **IAM & Admin > Service Accounts**
5. Create a service account
6. Create a JSON key and download it
7. Save as `automation/secrets/service-account.json`

### 2. Google Sheet Setup

1. Create a new Google Sheet
2. Share it with your service account email (as Editor)
3. Create a tab named `Queue` with these columns:

| Column | Required | Description |
|--------|----------|-------------|
| id | Yes | Unique identifier (e.g., `2024-01-15-post-001`) |
| type | Yes | `blog` or `landing` |
| slug | Yes | URL slug (kebab-case, e.g., `wgu-mba-guide`) |
| title | Yes | Page title |
| primary_keyword | Yes | Main SEO keyword |
| secondary_keywords | Yes | Comma-separated keywords |
| publish_date | Yes | Date to publish (YYYY-MM-DD) |
| status | Yes | `READY`, `PUBLISHED`, `SKIP`, or `ERROR` |
| tags | No | Comma-separated tags |
| category | No | Category name |
| internal_links | No | Comma-separated slugs to link to |
| notes | No | Extra instructions for Claude |

### 3. Environment Setup

```bash
# Copy example env file
cp .env.example .env

# Edit with your values
nano .env
```

### 4. Install Dependencies

```bash
npm install
```

### 5. Test Run

```bash
npm run seo:run
```

## Daily Automation

### macOS/Linux (cron)

```bash
# Edit crontab
crontab -e

# Add this line (runs at 3:15 AM daily)
15 3 * * * cd /path/to/coursework-ninja && source .env && npm run seo:run >> automation/logs/seo.log 2>&1
```

### Windows (Task Scheduler)

1. Open Task Scheduler
2. Create Basic Task
3. Set trigger: Daily at your preferred time
4. Action: Start a program
   - Program: `node`
   - Arguments: `scripts/seo-machine.mjs`
   - Start in: `C:\path\to\coursework-ninja`

## How It Works

1. **Reads Sheet**: Fetches all rows where `status = READY` and `publish_date <= today`
2. **Creates Tasks**: Writes task data to `automation/tasks.json`
3. **Runs Claude**: Executes Claude Code in headless mode to generate pages
4. **Validates**: Checks if expected files were created
5. **Commits**: Stages, commits, and pushes to GitHub
6. **Updates Sheet**: Marks rows as `PUBLISHED` or `ERROR`

## Safety Features

- **No API Key Required**: Uses your Claude Max plan authentication
- **No Bash Execution**: Claude is restricted from running shell commands
- **Clean Git Required**: Won't run if there are uncommitted changes
- **Deterministic Paths**: Files always go to `blog/<slug>/` or `landing/<slug>/`

## Troubleshooting

### "ANTHROPIC_API_KEY is set" error
Unset the API key to use Max plan auth:
```bash
unset ANTHROPIC_API_KEY
```

### "Working tree is not clean" error
Commit or stash your changes first:
```bash
git add -A && git commit -m "WIP"
# or
git stash
```

### "Missing service account key" error
Make sure `automation/secrets/service-account.json` exists and contains your Google service account key.

### Pages not appearing on GitHub Pages
- Check that GitHub Pages is enabled (Settings > Pages)
- Ensure you're deploying from the correct branch
- Wait 2-3 minutes for GitHub to rebuild

## Files

```
automation/
├── README.md                          # This file
├── secrets/                           # (gitignored) Service account keys
│   └── service-account.json
├── logs/                              # (gitignored) Execution logs
├── tasks.json                         # Current task queue (generated)
├── content-plan.json                  # Master content plan with all topics
├── blog-template-reference.md         # HTML template for blog posts
├── image-gen-reference.md             # OpenRouter image generation guide
├── daily-blog-autopilot.md            # OpenCode autopilot instructions
├── run-daily-blog.sh                  # Launcher script for autopilot
├── setup-autopilot.sh                 # Install/manage autopilot scheduler
└── com.courseworkninja.dailyblog.plist # macOS LaunchAgent config

scripts/
└── seo-machine.mjs                    # Main automation script
└── sync-site.mjs                      # Blog index sync script
```

---

## OpenCode Autopilot Mode

Fully automated blog generation using OpenCode running on autopilot.

### How It Works

```
LaunchAgent (daily 9 AM) OR manual trigger
    → run-daily-blog.sh [max_posts]
        → Loop until max reached or no pending posts:
            → opencode run [autopilot instructions]
                → Select ONE highest-priority pending blog
                → Research topic via web search
                → Generate blog HTML with researched content
                → Create cover image via OpenRouter API
                → Update blog index
                → Git commit & push
                → Update content-plan.json
                → Signal success
            → Fresh OpenCode session for next post
```

**Key features:**
- ONE post per OpenCode session (fresh context each time)
- Research phase before writing (web search for current info)
- Automatic restart for next post after success
- Stops on error or when no pending posts remain

### Quick Start

```bash
cd automation

# Publish ONE post (test)
./setup-autopilot.sh one

# Publish up to 3 posts
./setup-autopilot.sh run 3

# Publish up to 10 posts
./setup-autopilot.sh run 10

# Install daily scheduler (9 AM, up to 10 posts)
./setup-autopilot.sh install

# Check status
./setup-autopilot.sh status

# View logs
./setup-autopilot.sh logs

# Clear error markers
./setup-autopilot.sh clear

# Uninstall scheduler
./setup-autopilot.sh uninstall
```

### Status Markers

The autopilot creates marker files to track state:

| File | Meaning |
|------|---------|
| `logs/LAST_SUCCESS` | Last successfully published slug + timestamp |
| `logs/NO_PENDING_POSTS` | No more pending blogs in content-plan.json |
| `logs/GIT_PUSH_FAILED` | Git push failed, needs manual intervention |

### Configuration

Edit `daily-blog-autopilot.md` to change:
- Research queries and depth
- Quality checklist
- Content requirements

Edit `com.courseworkninja.dailyblog.plist` to change:
- Run time (default: 9:00 AM)
- Working directory

Edit `run-daily-blog.sh` to change:
- Default max posts per session
- Sleep time between posts

### Requirements

- OpenCode CLI installed (`/opt/homebrew/bin/opencode`)
- `.env` file with `OPENROUTER_API_KEY`
- `cwebp` installed (`brew install webp`)
- `jq` installed (`brew install jq`)
- Git configured with push access

### Logs

Logs are written to:
- `automation/logs/autopilot-YYYY-MM-DD.log` - Full session output
- `automation/logs/launchd-stdout.log` - LaunchAgent stdout
- `automation/logs/launchd-stderr.log` - LaunchAgent stderr
- `automation/logs/telegram-stdout.log` - Telegram listener log

---

## Telegram Integration

Remote monitoring and control via Telegram bot.

### Setup

1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot` and follow prompts
3. Copy the bot token
4. Add to `.env`:
   ```
   TELEGRAM_BOT_TOKEN=your-bot-token
   TELEGRAM_CHAT_ID=your-chat-id
   ```
5. To get your chat ID:
   - Message your bot
   - Visit: `https://api.telegram.org/bot<TOKEN>/getUpdates`
   - Find `chat.id` in the response

### Start Telegram Listener

```bash
./setup-autopilot.sh telegram-install
```

### Bot Commands

| Command | Action |
|---------|--------|
| `/status` | Show autopilot status |
| `/run N` | Start autopilot for N posts |
| `/one` | Publish one post |
| `/stop` | Stop after current post |
| `/logs` | Get recent log file |
| `/pending` | List next pending posts |
| `/skip` | Skip current post |
| `/approve` | Approve pending action |

### Notifications You'll Receive

| Event | Message |
|-------|---------|
| Session start | Posts count, timestamp |
| Post selected | Slug, title, priority |
| Research started | Topic being researched |
| Writing started | Slug |
| Image generation | Slug |
| Push to GitHub | - |
| Success | URL, timestamp |
| Session complete | Total count, duration |
| Error | Stage, details |
| Git failure | Slug, troubleshooting tips |

### Manage Telegram Listener

```bash
./setup-autopilot.sh telegram-install    # Start
./setup-autopilot.sh telegram-uninstall  # Stop
./setup-autopilot.sh telegram-restart    # Restart
./setup-autopilot.sh telegram-test       # Test message
```
