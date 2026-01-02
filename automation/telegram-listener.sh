#!/bin/bash
PROJECT_DIR="/Users/mx/Documents/WGU/Claude/coursework-ninja"
LOG_DIR="${PROJECT_DIR}/automation/logs"
OFFSET_FILE="${LOG_DIR}/.telegram_offset"
NOTIFY="${PROJECT_DIR}/automation/telegram-notify.sh"

if [ -f "${PROJECT_DIR}/.env" ]; then
    export $(grep -v '^#' "${PROJECT_DIR}/.env" | xargs)
fi

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    echo "Telegram not configured"
    exit 1
fi

mkdir -p "$LOG_DIR"

get_offset() {
    if [ -f "$OFFSET_FILE" ]; then
        cat "$OFFSET_FILE"
    else
        echo "0"
    fi
}

set_offset() {
    echo "$1" > "$OFFSET_FILE"
}

send_reply() {
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=$1" \
        -d "parse_mode=HTML" \
        > /dev/null 2>&1
}

process_command() {
    local cmd="$1"
    
    case "$cmd" in
        /start|/help)
            send_reply "🤖 <b>Coursework Ninja Bot</b>

<b>Commands:</b>
/status - Show autopilot status
/run [N] - Start autopilot (N posts, default 3)
/one - Publish one post
/stop - Stop autopilot
/logs - Get recent logs
/pending - List pending posts
/skip - Skip current post
/approve - Approve pending action
/test - Test notification"
            ;;
        
        /status)
            $NOTIFY status
            ;;
        
        /run*)
            N=$(echo "$cmd" | awk '{print $2}')
            N=${N:-3}
            send_reply "🚀 Starting autopilot for ${N} posts..."
            nohup "${PROJECT_DIR}/automation/run-daily-blog.sh" "$N" > /dev/null 2>&1 &
            ;;
        
        /one)
            send_reply "🚀 Starting autopilot for 1 post..."
            nohup "${PROJECT_DIR}/automation/run-daily-blog.sh" 1 > /dev/null 2>&1 &
            ;;
        
        /stop)
            touch "$LOG_DIR/STOP_AUTOPILOT"
            send_reply "🛑 Stop signal sent. Autopilot will stop after current post."
            ;;
        
        /logs)
            $NOTIFY log
            ;;
        
        /pending)
            PENDING=$(grep -B5 '"status": "pending"' "${PROJECT_DIR}/automation/content-plan.json" | grep '"slug"' | head -5 | sed 's/.*: "//;s/".*//' | tr '\n' ', ')
            send_reply "📋 <b>Next pending posts:</b>

${PENDING:-None}"
            ;;
        
        /skip)
            touch "$LOG_DIR/SKIP_CURRENT"
            send_reply "⏭️ Skip signal sent."
            ;;
        
        /approve)
            touch "$LOG_DIR/APPROVED"
            send_reply "✅ Approved."
            ;;
        
        /test)
            $NOTIFY test
            ;;
        
        *)
            if [[ "$cmd" == /* ]]; then
                send_reply "❓ Unknown command: $cmd

Send /help for available commands."
            fi
            ;;
    esac
}

echo "Telegram listener started. Polling for commands..."

while true; do
    OFFSET=$(get_offset)
    
    RESPONSE=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=${OFFSET}&timeout=30")
    
    UPDATES=$(echo "$RESPONSE" | jq -r '.result | length')
    
    if [ "$UPDATES" -gt 0 ]; then
        for i in $(seq 0 $((UPDATES - 1))); do
            UPDATE_ID=$(echo "$RESPONSE" | jq -r ".result[$i].update_id")
            CHAT_ID=$(echo "$RESPONSE" | jq -r ".result[$i].message.chat.id")
            TEXT=$(echo "$RESPONSE" | jq -r ".result[$i].message.text // empty")
            
            if [ "$CHAT_ID" = "$TELEGRAM_CHAT_ID" ] && [ -n "$TEXT" ]; then
                echo "[$(date)] Received: $TEXT"
                process_command "$TEXT"
            fi
            
            set_offset $((UPDATE_ID + 1))
        done
    fi
    
    sleep 1
done
