#!/usr/bin/env bash
# notify.sh - Telegram notification wrapper with enhanced reliability
# Requires: logging.sh sourced first, telegram-notify.sh available

[[ -n "${_NOTIFY_SH_LOADED:-}" ]] && return 0
_NOTIFY_SH_LOADED=1

NOTIFY_SCRIPT="${NOTIFY_SCRIPT:-}"
NOTIFY_ENABLED="${NOTIFY_ENABLED:-1}"
NOTIFY_TIMEOUT="${NOTIFY_TIMEOUT:-30}"

init_notify() {
    local script_dir="${1:-$(dirname "${BASH_SOURCE[0]}")/..}"
    NOTIFY_SCRIPT="${script_dir}/telegram-notify.sh"
    
    if [[ ! -x "$NOTIFY_SCRIPT" ]]; then
        log_warning "Telegram notify script not found or not executable: ${NOTIFY_SCRIPT}"
        NOTIFY_ENABLED=0
        return 1
    fi
    
    return 0
}

_safe_notify() {
    [[ "$NOTIFY_ENABLED" != "1" ]] && return 0
    [[ -z "$NOTIFY_SCRIPT" ]] && return 0
    
    timeout "$NOTIFY_TIMEOUT" "$NOTIFY_SCRIPT" "$@" 2>/dev/null || {
        log_warning "Notification failed (non-fatal): $1"
        return 0
    }
}

notify_session_start() {
    local max_posts="$1"
    local failure_budget="${2:-5}"
    
    _safe_notify start "$max_posts"
    log_info "Telegram: session_start (max=${max_posts})"
}

notify_session_end() {
    local completed="$1"
    local failed="$2"
    local duration="$3"
    
    _safe_notify complete "$completed" "$duration"
    log_info "Telegram: session_end (completed=${completed}, failed=${failed})"
}

notify_post_selected() {
    local slug="$1"
    local title="$2"
    local priority="${3:-}"
    local position="${4:-}"
    local total="${5:-}"
    
    _safe_notify selected "$slug" "$title" "$priority"
    log_info "Telegram: post_selected (${slug})"
}

notify_phase() {
    local phase="$1"
    local slug="$2"
    
    case "$phase" in
        research)
            _safe_notify researching "$slug"
            ;;
        compose|write)
            _safe_notify writing "$slug"
            ;;
        image)
            _safe_notify image "$slug"
            ;;
        image_done)
            _safe_notify image_done "$slug"
            ;;
        push)
            _safe_notify pushing
            ;;
    esac
    
    log_info "Telegram: phase_${phase} (${slug})"
}

notify_post_success() {
    local slug="$1"
    local url="${2:-https://coursework.ninja/blog/${slug}/}"
    
    _safe_notify success "$slug"
    log_info "Telegram: post_success (${slug})"
}

notify_post_failed() {
    local slug="$1"
    local stage="$2"
    local reason="$3"
    
    _safe_notify error "$stage" "$reason"
    log_info "Telegram: post_failed (${slug}, stage=${stage})"
}

notify_no_posts() {
    _safe_notify no_posts
    log_info "Telegram: no_pending_posts"
}

notify_git_failed() {
    local slug="$1"
    
    _safe_notify git_failed "$slug"
    log_info "Telegram: git_failed (${slug})"
}

notify_failure_budget_warning() {
    local consecutive="$1"
    local total="$2"
    local max_consecutive="$3"
    local max_total="$4"
    
    local message="⚠️ <b>Failure Budget Warning</b>

<b>Consecutive failures:</b> ${consecutive}/${max_consecutive}
<b>Total failures:</b> ${total}/${max_total}

Autopilot will stop if limits are reached."
    
    _safe_notify_raw "$message"
    log_warning "Failure budget warning: consecutive=${consecutive}/${max_consecutive}, total=${total}/${max_total}"
}

notify_fatal_stop() {
    local reason="$1"
    local details="${2:-}"
    
    _safe_notify intervention "Fatal Error - Autopilot Stopped" "$reason: $details"
    log_error "Telegram: fatal_stop (${reason})"
}

notify_recovery_attempt() {
    local run_id="$1"
    local phase="$2"
    local slug="$3"
    
    local message="🔄 <b>Recovering Previous Run</b>

<b>Run ID:</b> <code>${run_id}</code>
<b>Phase:</b> ${phase}
<b>Slug:</b> <code>${slug}</code>

Attempting to resume from last checkpoint..."
    
    _safe_notify_raw "$message"
    log_info "Telegram: recovery_attempt (${run_id}, phase=${phase})"
}

notify_progress() {
    local completed="$1"
    local total="$2"
    local current_slug="$3"
    
    local percent=0
    [[ $total -gt 0 ]] && percent=$((completed * 100 / total))
    
    local bar=""
    local filled=$((percent / 10))
    local empty=$((10 - filled))
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    
    local message="📊 <b>Progress Update</b>

${bar} ${percent}%
<b>Completed:</b> ${completed}/${total}
<b>Current:</b> <code>${current_slug}</code>"
    
    _safe_notify_raw "$message"
}

_safe_notify_raw() {
    local message="$1"
    
    [[ "$NOTIFY_ENABLED" != "1" ]] && return 0
    [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]] && return 0
    [[ -z "${TELEGRAM_CHAT_ID:-}" ]] && return 0
    
    timeout "$NOTIFY_TIMEOUT" curl -sS --connect-timeout 10 --max-time 30 \
        -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        --data-urlencode "text=${message}" \
        -d "parse_mode=HTML" \
        >/dev/null 2>&1 || {
        log_warning "Raw notification failed (non-fatal)"
        return 0
    }
}

notify_custom() {
    local title="$1"
    local body="$2"
    local emoji="${3:-📢}"
    
    local message="${emoji} <b>${title}</b>

${body}"
    
    _safe_notify_raw "$message"
    log_info "Telegram: custom (${title})"
}

notify_test() {
    _safe_notify test
    log_info "Telegram: test message sent"
}

send_log_file() {
    local log_file="${1:-${LOG_TEXT_FILE:-}}"
    
    [[ -f "$log_file" ]] || {
        log_warning "Log file not found for sending: ${log_file}"
        return 1
    }
    
    _safe_notify log
}
