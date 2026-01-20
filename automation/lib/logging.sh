#!/usr/bin/env bash
# =============================================================================
# logging.sh - Unified logging library for blog automation
# =============================================================================
# Provides both human-readable (.log) and JSON structured (.jsonl) logging.
# JSON logs enable machine parsing for monitoring and debugging.
#
# Usage:
#   source lib/logging.sh
#   init_logging "/path/to/logs"
#   log_info "Starting process"
#   log_error "Something failed" '{"code": 500}'
#
# Dependencies: jq
# =============================================================================

# Prevent multiple sourcing
[[ -n "${_LOGGING_SH_LOADED:-}" ]] && return 0
_LOGGING_SH_LOADED=1

# -----------------------------------------------------------------------------
# Configuration (can be overridden before sourcing)
# -----------------------------------------------------------------------------
LOG_DIR="${LOG_DIR:-./logs}"
LOG_DATE="${LOG_DATE:-$(date +%Y-%m-%d)}"
LOG_TEXT_FILE=""
LOG_JSON_FILE=""

# Global context (set by main script)
LOG_RUN_ID="${LOG_RUN_ID:-}"
LOG_SLUG="${LOG_SLUG:-}"
LOG_PHASE="${LOG_PHASE:-}"

# -----------------------------------------------------------------------------
# Initialize logging
# -----------------------------------------------------------------------------
init_logging() {
    local log_dir="${1:-$LOG_DIR}"
    LOG_DIR="$log_dir"
    LOG_DATE="$(date +%Y-%m-%d)"
    LOG_TEXT_FILE="${LOG_DIR}/autopilot-${LOG_DATE}.log"
    LOG_JSON_FILE="${LOG_DIR}/autopilot-${LOG_DATE}.jsonl"
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    # Test write access
    if ! touch "$LOG_TEXT_FILE" 2>/dev/null; then
        echo "ERROR: Cannot write to log file: $LOG_TEXT_FILE" >&2
        return 1
    fi
    
    return 0
}

# -----------------------------------------------------------------------------
# Set logging context
# -----------------------------------------------------------------------------
set_log_context() {
    LOG_RUN_ID="${1:-$LOG_RUN_ID}"
    LOG_SLUG="${2:-$LOG_SLUG}"
    LOG_PHASE="${3:-$LOG_PHASE}"
}

set_log_phase() {
    LOG_PHASE="$1"
}

set_log_slug() {
    LOG_SLUG="$1"
}

set_log_run_id() {
    LOG_RUN_ID="$1"
}

# -----------------------------------------------------------------------------
# Core logging function
# -----------------------------------------------------------------------------
_log() {
    local level="$1"
    local message="$2"
    local extra="${3:-}"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local timestamp_iso
    timestamp_iso="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    
    local level_upper
    level_upper="$(printf '%s' "$level" | tr '[:lower:]' '[:upper:]')"
    
    local log_line="[${timestamp}] [${level_upper}]"
    [[ -n "$LOG_PHASE" ]] && log_line+=" [${LOG_PHASE}]"
    [[ -n "$LOG_SLUG" ]] && log_line+=" [${LOG_SLUG}]"
    log_line+=" ${message}"
    
    # Write to text log file
    if [[ -n "$LOG_TEXT_FILE" ]]; then
        echo "$log_line" >> "$LOG_TEXT_FILE"
    fi
    
    # Also write to stdout/stderr based on level
    case "$level" in
        error|fatal)
            echo "$log_line" >&2
            ;;
        warning)
            echo "$log_line" >&2
            ;;
        info|debug)
            echo "$log_line"
            ;;
    esac
    
    # JSON structured log
    if [[ -n "$LOG_JSON_FILE" ]]; then
        _log_json "$level" "$message" "$timestamp_iso" "$extra"
    fi
}

_log_json() {
    local level="$1"
    local message="$2"
    local timestamp="$3"
    local extra="${4:-}"
    
    # Validate extra is valid JSON, default to empty object
    if [[ -n "$extra" ]]; then
        if ! echo "$extra" | jq empty 2>/dev/null; then
            extra="{}"
        fi
    else
        extra="{}"
    fi
    
    # Build JSON entry (compact, one line)
    jq -n -c \
        --arg ts "$timestamp" \
        --arg level "$level" \
        --arg msg "$message" \
        --arg run_id "${LOG_RUN_ID:-}" \
        --arg slug "${LOG_SLUG:-}" \
        --arg phase "${LOG_PHASE:-}" \
        --argjson extra "$extra" \
        '{
            timestamp: $ts,
            level: $level,
            message: $msg,
            run_id: (if $run_id == "" then null else $run_id end),
            slug: (if $slug == "" then null else $slug end),
            phase: (if $phase == "" then null else $phase end)
        } + $extra' \
        >> "$LOG_JSON_FILE" 2>/dev/null || true
}

# -----------------------------------------------------------------------------
# Public logging functions
# -----------------------------------------------------------------------------
log_debug() {
    _log "debug" "$1" "${2:-}"
}

log_info() {
    _log "info" "$1" "${2:-}"
}

log_warning() {
    _log "warning" "$1" "${2:-}"
}

log_error() {
    _log "error" "$1" "${2:-}"
}

log_fatal() {
    _log "fatal" "$1" "${2:-}"
}

# Convenience alias
log() {
    log_info "$@"
}

# -----------------------------------------------------------------------------
# Phase logging (logs + updates context)
# -----------------------------------------------------------------------------
log_phase_start() {
    local phase="$1"
    local message="${2:-Starting ${phase}}"
    LOG_PHASE="$phase"
    log_info "$message" "{\"event\": \"phase_start\", \"phase\": \"${phase}\"}"
}

log_phase_end() {
    local phase="${1:-$LOG_PHASE}"
    local status="$2"
    local message="${3:-Phase ${phase} ${status}}"
    log_info "$message" "{\"event\": \"phase_end\", \"phase\": \"${phase}\", \"status\": \"${status}\"}"
}

# -----------------------------------------------------------------------------
# Structured event logging
# -----------------------------------------------------------------------------
log_event() {
    local event="$1"
    local message="$2"
    shift 2
    local extra="{\"event\": \"${event}\""
    
    # Add any additional key=value pairs
    while [[ $# -gt 0 ]]; do
        local key="${1%%=*}"
        local value="${1#*=}"
        extra+=", \"${key}\": \"${value}\""
        shift
    done
    extra+="}"
    
    log_info "$message" "$extra"
}

# -----------------------------------------------------------------------------
# Metrics logging
# -----------------------------------------------------------------------------
log_metric() {
    local metric="$1"
    local value="$2"
    local unit="${3:-}"
    
    local extra="{\"event\": \"metric\", \"metric\": \"${metric}\", \"value\": ${value}"
    [[ -n "$unit" ]] && extra+=", \"unit\": \"${unit}\""
    extra+="}"
    
    log_debug "Metric: ${metric}=${value}${unit:+ ${unit}}" "$extra"
}

# -----------------------------------------------------------------------------
# Session summary logging
# -----------------------------------------------------------------------------
log_session_start() {
    local max_posts="$1"
    log_info "=== Blog Automation Session Started ===" \
        "{\"event\": \"session_start\", \"max_posts\": ${max_posts}, \"pid\": $$}"
}

log_session_end() {
    local posts_completed="$1"
    local posts_failed="$2"
    local duration_seconds="$3"
    
    local duration_min=$((duration_seconds / 60))
    log_info "=== Session Complete: ${posts_completed} published, ${posts_failed} failed, ${duration_min}m ===" \
        "{\"event\": \"session_end\", \"posts_completed\": ${posts_completed}, \"posts_failed\": ${posts_failed}, \"duration_seconds\": ${duration_seconds}}"
}

log_post_start() {
    local slug="$1"
    local title="$2"
    local priority="${3:-}"
    
    LOG_SLUG="$slug"
    log_info "Starting post: ${slug} - ${title}" \
        "{\"event\": \"post_start\", \"title\": \"${title}\", \"priority\": \"${priority}\"}"
}

log_post_end() {
    local slug="$1"
    local status="$2"
    local reason="${3:-}"
    
    local extra="{\"event\": \"post_end\", \"status\": \"${status}\""
    [[ -n "$reason" ]] && extra+=", \"reason\": \"${reason}\""
    extra+="}"
    
    log_info "Post ${slug}: ${status}${reason:+ - ${reason}}" "$extra"
    LOG_SLUG=""
}

# -----------------------------------------------------------------------------
# Error context logging
# -----------------------------------------------------------------------------
log_error_context() {
    local message="$1"
    local error_code="${2:-}"
    local error_type="${3:-}"
    local recoverable="${4:-true}"
    
    local extra="{\"event\": \"error\""
    [[ -n "$error_code" ]] && extra+=", \"error_code\": \"${error_code}\""
    [[ -n "$error_type" ]] && extra+=", \"error_type\": \"${error_type}\""
    extra+=", \"recoverable\": ${recoverable}}"
    
    log_error "$message" "$extra"
}

# -----------------------------------------------------------------------------
# Log file management
# -----------------------------------------------------------------------------
get_log_file() {
    echo "$LOG_TEXT_FILE"
}

get_json_log_file() {
    echo "$LOG_JSON_FILE"
}

# Get last N lines from today's log
get_recent_logs() {
    local lines="${1:-50}"
    if [[ -f "$LOG_TEXT_FILE" ]]; then
        tail -n "$lines" "$LOG_TEXT_FILE"
    fi
}

# Search JSON logs
search_logs() {
    local query="$1"
    if [[ -f "$LOG_JSON_FILE" ]]; then
        grep -i "$query" "$LOG_JSON_FILE" | jq -s '.' 2>/dev/null || true
    fi
}
