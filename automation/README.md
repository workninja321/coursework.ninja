# Blog Automation System

Automated blog generation for Coursework Ninja using OpenCode with enterprise-grade reliability.

## Features

- **Batch processing**: Up to 20 posts per session (configurable)
- **Failure budgets**: Stops after 3 consecutive or 5 total failures
- **Retry with backoff**: Exponential backoff with jitter for rate limits
- **Atomic state management**: Crash recovery and resume support
- **Telegram notifications**: Real-time progress updates
- **Structured logging**: JSON + human-readable logs

## Quick Start

```bash
cd automation

# Run default batch (20 posts)
./setup-autopilot.sh run

# Run specific number of posts
./setup-autopilot.sh run 5

# Run single post (testing)
./setup-autopilot.sh one

# Check status
./setup-autopilot.sh status

# View logs
./setup-autopilot.sh logs
```

## How It Works

```
Session Start
    |
    v
[Lock acquired] --> [Git pull/rebase] --> [Session state created]
    |
    v
For each post (up to MAX_POSTS):
    |
    +-- Check failure budget
    +-- Select pending post from content-plan.json
    +-- Create work directory
    |
    +-- Phases:
    |   1. preflight  - Check disk space, reference files
    |   2. compose    - OpenCode generates content (with retry)
    |   3. validate   - 12-point validation check
    |   4. image      - Generate cover image (fallback on fail)
    |   5. promote    - Copy to blog/<slug>/
    |   6. sync       - Run sync-site.mjs
    |   7. push       - Git commit and push
    |
    +-- Notify result
    +-- Continue to next post
    |
    v
Session End --> [Notify summary] --> [Release lock]
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_POSTS` | `20` | Posts per session (first argument) |
| `MAX_CONSECUTIVE_FAILURES` | `3` | Stop after N consecutive failures |
| `MAX_TOTAL_FAILURES` | `5` | Stop after N total failures |
| `MAX_COMPOSE_RETRIES` | `2` | Retry compose step on failure |
| `SESSION_TIMEOUT_HOURS` | `4` | Maximum session runtime |
| `OPENCODE_MODEL` | `openai/gpt-4.1` | Primary model for content |
| `FALLBACK_MODEL` | `anthropic/claude-sonnet-4` | Fallback on context errors |
| `OPENCODE_TIMEOUT` | `600` | Timeout per OpenCode call (seconds) |

## Requirements

- `opencode` CLI installed
- `jq` for JSON processing
- `cwebp` for image conversion
- `curl` for API calls
- `git` configured with push access
- `.env` file with `OPENROUTER_API_KEY`

Optional:
- `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` for notifications

## File Structure

```
automation/
├── run-blog.sh              # Main automation script
├── setup-autopilot.sh       # Manager script
├── validate-post.sh         # 12-point validation
├── telegram-notify.sh       # Notification handler
├── content-plan.json        # Content queue
├── prompts/
│   └── compose.md           # OpenCode prompt template
├── lib/
│   ├── logging.sh           # JSON + text logging
│   ├── retry.sh             # Exponential backoff
│   ├── notify.sh            # Telegram wrapper
│   ├── state.sh             # Atomic state management
│   └── lock.sh              # flock-based locking
├── logs/
│   ├── autopilot-YYYY-MM-DD.log   # Human-readable
│   └── autopilot-YYYY-MM-DD.jsonl # JSON structured
├── state/
│   └── session.json         # Current session state
├── locks/
│   └── autopilot.lock       # Prevents concurrent runs
└── work/
    └── <run-id>/            # Staged content per post
```

## Logs

### Human-readable
```bash
tail -f automation/logs/autopilot-$(date +%Y-%m-%d).log
```

### JSON structured (for parsing)
```bash
cat automation/logs/autopilot-$(date +%Y-%m-%d).jsonl | jq .
```

### Search logs
```bash
grep "error" automation/logs/autopilot-*.log
jq 'select(.level == "error")' automation/logs/autopilot-*.jsonl
```

## Daily Scheduler (macOS)

```bash
# Install LaunchAgent (runs at 9 AM daily)
./setup-autopilot.sh install

# Check status
./setup-autopilot.sh status

# Uninstall
./setup-autopilot.sh uninstall
```

## Telegram Integration

1. Create bot via [@BotFather](https://t.me/BotFather)
2. Add to `.env`:
   ```
   TELEGRAM_BOT_TOKEN=your-token
   TELEGRAM_CHAT_ID=your-chat-id
   ```
3. Test: `./setup-autopilot.sh telegram-test`

### Notifications You'll Receive

| Event | Message |
|-------|---------|
| Session start | Max posts, timestamp |
| Post selected | Slug, title, priority |
| Phase updates | Compose, image, push |
| Post success | URL, time |
| Post failure | Stage, reason |
| Session end | Total completed, failed, duration |
| Failure budget warning | When approaching limits |

## Troubleshooting

### "Lock is held by another process"
Another autopilot instance is running. Wait for it to finish or:
```bash
# Force release (use carefully)
rm -f automation/locks/autopilot.lock*
```

### "Rebase conflict"
Manual intervention required:
```bash
cd /path/to/project
git status
git rebase --abort  # or resolve conflicts
```

### "Failure budget exceeded"
Too many posts failed. Check:
- Content plan for invalid entries
- OpenCode model availability
- API rate limits

### View detailed errors
```bash
# Check specific run
cat automation/work/<run-id>/state.json | jq .

# Check validation output
cat automation/logs/opencode-<run-id>-compose.log
```

## Adding Content

Edit `content-plan.json` to add new posts:

```json
{
  "type": "blog",
  "slug": "your-new-post-slug",
  "title": "Your Post Title",
  "primaryKeyword": "main keyword",
  "secondaryKeywords": ["kw1", "kw2"],
  "category": "degree-guides",
  "tags": ["tag1", "tag2"],
  "priority": 1,
  "status": "pending",
  "internalLinks": ["existing-slug-1", "existing-slug-2"],
  "estimatedReadTime": 10
}
```
