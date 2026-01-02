#!/bin/bash
PROJECT_DIR="/Users/mx/Documents/WGU/Claude/coursework-ninja"

if [ -f "${PROJECT_DIR}/.env" ]; then
    export $(grep -v '^#' "${PROJECT_DIR}/.env" | xargs)
fi

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    echo "Telegram not configured (missing TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID)"
    exit 0
fi

send_message() {
    local message="$1"
    local parse_mode="${2:-HTML}"
    
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${message}" \
        -d "parse_mode=${parse_mode}" \
        > /dev/null 2>&1
}

send_document() {
    local file="$1"
    local caption="$2"
    
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument" \
        -F "chat_id=${TELEGRAM_CHAT_ID}" \
        -F "document=@${file}" \
        -F "caption=${caption}" \
        > /dev/null 2>&1
}

case "$1" in
    start)
        send_message "🚀 <b>Autopilot Started</b>

📅 $(date '+%Y-%m-%d %H:%M')
📊 Max posts: ${2:-10}"
        ;;
    
    selecting)
        send_message "🔍 <b>Selecting next post...</b>

Reading content-plan.json"
        ;;
    
    selected)
        send_message "📝 <b>Post Selected</b>

<b>Slug:</b> <code>$2</code>
<b>Title:</b> $3
<b>Priority:</b> $4"
        ;;
    
    researching)
        send_message "🔬 <b>Researching...</b>

Topic: <code>$2</code>
Searching web for current info..."
        ;;
    
    writing)
        send_message "✍️ <b>Writing blog post...</b>

<code>$2</code>"
        ;;
    
    image)
        send_message "🎨 <b>Generating cover image...</b>

<code>$2</code>"
        ;;
    
    image_done)
        send_message "✅ <b>Cover image created</b>

<code>images/blog/$2-cover.webp</code>"
        ;;
    
    pushing)
        send_message "📤 <b>Pushing to GitHub...</b>"
        ;;
    
    success)
        send_message "✅ <b>Successfully Published!</b>

<b>Slug:</b> <code>$2</code>
<b>URL:</b> https://coursework.ninja/blog/$2/
<b>Time:</b> $(date '+%H:%M:%S')

🔄 Starting next post in 10s..."
        ;;
    
    complete)
        send_message "🎉 <b>Autopilot Session Complete</b>

📊 Posts published: <b>$2</b>
⏱️ Duration: $3
📅 $(date '+%Y-%m-%d %H:%M')"
        ;;
    
    no_posts)
        send_message "📭 <b>No Pending Posts</b>

All blog posts have been published!
Add more topics to content-plan.json to continue."
        ;;
    
    error)
        send_message "❌ <b>Error Occurred</b>

<b>Stage:</b> $2
<b>Details:</b> $3

Manual intervention may be required."
        ;;
    
    git_failed)
        send_message "🚨 <b>Git Push Failed!</b>

<b>Slug:</b> <code>$2</code>

⚠️ Autopilot stopped. Please check:
• Git credentials
• Remote repository access
• Merge conflicts"
        ;;
    
    intervention)
        send_message "🛑 <b>Human Intervention Required</b>

<b>Reason:</b> $2
<b>Details:</b> $3

Reply with:
/approve - Continue
/skip - Skip this post
/stop - Stop autopilot"
        ;;
    
    log)
        LOG_FILE="${PROJECT_DIR}/automation/logs/autopilot-$(date +%Y-%m-%d).log"
        if [ -f "$LOG_FILE" ]; then
            tail -50 "$LOG_FILE" > /tmp/recent_log.txt
            send_document "/tmp/recent_log.txt" "Recent autopilot log"
            rm /tmp/recent_log.txt
        else
            send_message "📄 No log file for today"
        fi
        ;;
    
    status)
        PENDING=$(grep -c '"status": "pending"' "${PROJECT_DIR}/automation/content-plan.json" 2>/dev/null || echo "?")
        PUBLISHED=$(grep -c '"status": "published"' "${PROJECT_DIR}/automation/content-plan.json" 2>/dev/null || echo "?")
        
        send_message "📊 <b>Autopilot Status</b>

<b>Pending blogs:</b> ${PENDING}
<b>Published:</b> ${PUBLISHED}
<b>Last update:</b> $(date '+%Y-%m-%d %H:%M')"
        ;;
    
    test)
        send_message "🧪 <b>Test Message</b>

Telegram integration is working!
$(date '+%Y-%m-%d %H:%M:%S')"
        ;;
    
    *)
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  start [max]      - Session started"
        echo "  selecting        - Selecting next post"
        echo "  selected <slug> <title> <priority>"
        echo "  researching <slug>"
        echo "  writing <slug>"
        echo "  image <slug>"
        echo "  image_done <slug>"
        echo "  pushing"
        echo "  success <slug>"
        echo "  complete <count> <duration>"
        echo "  no_posts         - No pending posts"
        echo "  error <stage> <details>"
        echo "  git_failed <slug>"
        echo "  intervention <reason> <details>"
        echo "  log              - Send recent log file"
        echo "  status           - Send current stats"
        echo "  test             - Test message"
        ;;
esac
