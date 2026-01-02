#!/bin/bash
set -e

PROJECT_DIR="/Users/mx/Documents/WGU/Claude/coursework-ninja"
AUTOPILOT_FILE="${PROJECT_DIR}/automation/daily-blog-autopilot.md"
LOG_DIR="${PROJECT_DIR}/automation/logs"
NOTIFY="${PROJECT_DIR}/automation/telegram-notify.sh"
DATE=$(date +%Y-%m-%d)
START_TIME=$(date +%s)

mkdir -p "$LOG_DIR"

rm -f "$LOG_DIR/LAST_SUCCESS" "$LOG_DIR/NO_PENDING_POSTS" "$LOG_DIR/GIT_PUSH_FAILED"

if [ -f "${PROJECT_DIR}/.env" ]; then
    export $(grep -v '^#' "${PROJECT_DIR}/.env" | xargs)
else
    echo "[$(date)] ERROR: .env file not found" >> "$LOG_DIR/autopilot-${DATE}.log"
    exit 1
fi

if [ ! -f "$AUTOPILOT_FILE" ]; then
    echo "[$(date)] ERROR: Autopilot file not found" >> "$LOG_DIR/autopilot-${DATE}.log"
    exit 1
fi

PROMPT=$(cat "$AUTOPILOT_FILE")
POST_COUNT=0
MAX_POSTS=${1:-15}

echo "[$(date)] === Autopilot Session Started (max: ${MAX_POSTS} posts) ===" >> "$LOG_DIR/autopilot-${DATE}.log"

$NOTIFY start "$MAX_POSTS"

while [ $POST_COUNT -lt $MAX_POSTS ]; do
    
    if [ -f "$LOG_DIR/NO_PENDING_POSTS" ]; then
        echo "[$(date)] No more pending posts. Stopping." >> "$LOG_DIR/autopilot-${DATE}.log"
        $NOTIFY no_posts
        rm -f "$LOG_DIR/NO_PENDING_POSTS"
        break
    fi
    
    if [ -f "$LOG_DIR/GIT_PUSH_FAILED" ]; then
        echo "[$(date)] Git push failed. Manual intervention required. Stopping." >> "$LOG_DIR/autopilot-${DATE}.log"
        FAILED_SLUG=$(cat "$LOG_DIR/GIT_PUSH_FAILED" 2>/dev/null || echo "unknown")
        $NOTIFY git_failed "$FAILED_SLUG"
        break
    fi
    
    if [ -f "$LOG_DIR/STOP_AUTOPILOT" ]; then
        echo "[$(date)] Stop requested. Stopping." >> "$LOG_DIR/autopilot-${DATE}.log"
        rm -f "$LOG_DIR/STOP_AUTOPILOT"
        break
    fi
    
    rm -f "$LOG_DIR/LAST_SUCCESS"
    
    echo "[$(date)] Starting post #$((POST_COUNT + 1))..." >> "$LOG_DIR/autopilot-${DATE}.log"
    $NOTIFY selecting
    
    cd "$PROJECT_DIR"
    opencode run "$PROMPT" 2>&1 | tee -a "$LOG_DIR/autopilot-${DATE}.log"
    
    if [ -f "$LOG_DIR/LAST_SUCCESS" ]; then
        SLUG=$(head -1 "$LOG_DIR/LAST_SUCCESS")
        echo "[$(date)] Successfully published: ${SLUG}" >> "$LOG_DIR/autopilot-${DATE}.log"
        $NOTIFY success "$SLUG"
        POST_COUNT=$((POST_COUNT + 1))
        
        echo "[$(date)] Waiting 10s before next post..." >> "$LOG_DIR/autopilot-${DATE}.log"
        sleep 10
    else
        if [ -f "$LOG_DIR/NO_PENDING_POSTS" ]; then
            continue
        fi
        echo "[$(date)] No success marker found. Session may have failed." >> "$LOG_DIR/autopilot-${DATE}.log"
        $NOTIFY error "session" "No success marker found after OpenCode run"
        break
    fi
done

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DURATION_MIN=$((DURATION / 60))

echo "" >> "$LOG_DIR/autopilot-${DATE}.log"
echo "[$(date)] === Autopilot Session Complete ===" >> "$LOG_DIR/autopilot-${DATE}.log"
echo "[$(date)] Total posts published: ${POST_COUNT}" >> "$LOG_DIR/autopilot-${DATE}.log"
echo "[$(date)] Duration: ${DURATION_MIN} minutes" >> "$LOG_DIR/autopilot-${DATE}.log"
echo "" >> "$LOG_DIR/autopilot-${DATE}.log"

$NOTIFY complete "$POST_COUNT" "${DURATION_MIN}m"

exit 0
