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
├── README.md           # This file
├── secrets/            # (gitignored) Service account keys
│   └── service-account.json
├── logs/               # (gitignored) Execution logs
└── tasks.json          # Current task queue (generated)

scripts/
└── seo-machine.mjs     # Main automation script
```
