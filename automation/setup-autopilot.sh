#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="/Users/mx/Documents/WGU/Claude/coursework-ninja"
LOG_DIR="${SCRIPT_DIR}/logs"
NOTIFY="${SCRIPT_DIR}/telegram-notify.sh"

BLOG_PLIST="com.courseworkninja.dailyblog.plist"
TELEGRAM_PLIST="com.courseworkninja.telegram.plist"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"

case "$1" in
    install)
        echo "Installing autopilot scheduler..."
        mkdir -p "$LAUNCH_AGENTS"
        cp "${SCRIPT_DIR}/${BLOG_PLIST}" "${LAUNCH_AGENTS}/"
        launchctl load "${LAUNCH_AGENTS}/${BLOG_PLIST}"
        echo "Autopilot installed. Runs daily at 9:00 AM."
        ;;
    
    uninstall)
        echo "Uninstalling autopilot scheduler..."
        launchctl unload "${LAUNCH_AGENTS}/${BLOG_PLIST}" 2>/dev/null || true
        rm -f "${LAUNCH_AGENTS}/${BLOG_PLIST}"
        echo "Autopilot uninstalled."
        ;;
    
    telegram-install)
        echo "Installing Telegram listener..."
        mkdir -p "$LAUNCH_AGENTS" "$LOG_DIR"
        cp "${SCRIPT_DIR}/${TELEGRAM_PLIST}" "${LAUNCH_AGENTS}/"
        launchctl load "${LAUNCH_AGENTS}/${TELEGRAM_PLIST}"
        echo "Telegram listener installed and running."
        $NOTIFY test
        ;;
    
    telegram-uninstall)
        echo "Uninstalling Telegram listener..."
        launchctl unload "${LAUNCH_AGENTS}/${TELEGRAM_PLIST}" 2>/dev/null || true
        rm -f "${LAUNCH_AGENTS}/${TELEGRAM_PLIST}"
        echo "Telegram listener uninstalled."
        ;;
    
    telegram-restart)
        echo "Restarting Telegram listener..."
        launchctl unload "${LAUNCH_AGENTS}/${TELEGRAM_PLIST}" 2>/dev/null || true
        sleep 1
        launchctl load "${LAUNCH_AGENTS}/${TELEGRAM_PLIST}"
        echo "Restarted."
        ;;
    
    telegram-test)
        echo "Sending test message..."
        $NOTIFY test
        ;;
    
    start)
        echo "Running autopilot via scheduler..."
        launchctl start com.courseworkninja.dailyblog
        ;;
    
    run)
        MAX=${2:-3}
        echo "Running autopilot directly (max ${MAX} posts)..."
        "${SCRIPT_DIR}/run-daily-blog.sh" "$MAX"
        ;;
    
    one)
        echo "Running autopilot for ONE post..."
        "${SCRIPT_DIR}/run-daily-blog.sh" 1
        ;;
    
    stop)
        echo "Sending stop signal..."
        touch "$LOG_DIR/STOP_AUTOPILOT"
        echo "Autopilot will stop after current post."
        ;;
    
    status)
        echo "=== Scheduler Status ==="
        echo -n "Autopilot: "
        launchctl list 2>/dev/null | grep -q "dailyblog" && echo "installed" || echo "not installed"
        echo -n "Telegram:  "
        launchctl list 2>/dev/null | grep -q "telegram" && echo "running" || echo "not running"
        echo ""
        echo "=== Markers ==="
        [ -f "$LOG_DIR/LAST_SUCCESS" ] && echo "Last success: $(cat $LOG_DIR/LAST_SUCCESS)"
        [ -f "$LOG_DIR/NO_PENDING_POSTS" ] && echo "Status: No pending posts"
        [ -f "$LOG_DIR/GIT_PUSH_FAILED" ] && echo "Status: Git push failed!"
        [ -f "$LOG_DIR/STOP_AUTOPILOT" ] && echo "Status: Stop requested"
        echo ""
        echo "=== Content Plan ==="
        PENDING=$(grep -c '"status": "pending"' "${PROJECT_DIR}/automation/content-plan.json" 2>/dev/null || echo "?")
        PUBLISHED=$(grep -c '"status": "published"' "${PROJECT_DIR}/automation/content-plan.json" 2>/dev/null || echo "?")
        echo "Pending blogs: $PENDING"
        echo "Published: $PUBLISHED"
        ;;
    
    logs)
        LOG_FILE="${LOG_DIR}/autopilot-$(date +%Y-%m-%d).log"
        if [ -f "$LOG_FILE" ]; then
            tail -100 "$LOG_FILE"
        else
            echo "No logs for today."
            echo "Available logs:"
            ls -la "$LOG_DIR"/*.log 2>/dev/null | tail -5
        fi
        ;;
    
    clear)
        echo "Clearing status markers..."
        rm -f "$LOG_DIR/LAST_SUCCESS" "$LOG_DIR/NO_PENDING_POSTS" 
        rm -f "$LOG_DIR/GIT_PUSH_FAILED" "$LOG_DIR/STOP_AUTOPILOT"
        rm -f "$LOG_DIR/SKIP_CURRENT" "$LOG_DIR/APPROVED"
        echo "Cleared."
        ;;
    
    *)
        echo "Blog Autopilot Manager"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Autopilot Commands:"
        echo "  install          Install daily scheduler (9 AM)"
        echo "  uninstall        Remove scheduler"
        echo "  start            Trigger scheduled run now"
        echo "  run [N]          Run directly, up to N posts (default: 3)"
        echo "  one              Run directly, publish 1 post"
        echo "  stop             Stop after current post"
        echo "  status           Show status"
        echo "  logs             View today's logs"
        echo "  clear            Clear status markers"
        echo ""
        echo "Telegram Commands:"
        echo "  telegram-install    Start Telegram bot listener"
        echo "  telegram-uninstall  Stop Telegram bot listener"
        echo "  telegram-restart    Restart Telegram listener"
        echo "  telegram-test       Send test message"
        echo ""
        echo "Bot Commands (send via Telegram):"
        echo "  /status  - Show status"
        echo "  /run N   - Start autopilot for N posts"
        echo "  /one     - Publish one post"
        echo "  /stop    - Stop autopilot"
        echo "  /logs    - Get recent logs"
        echo "  /pending - List pending posts"
        exit 1
        ;;
esac
