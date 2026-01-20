#!/usr/bin/env bash
# state.sh - Atomic state management with recovery support
# Requires: logging.sh, jq

[[ -n "${_STATE_SH_LOADED:-}" ]] && return 0
_STATE_SH_LOADED=1

STATE_DIR="${STATE_DIR:-./state}"
STATE_FILE=""
SESSION_STATE_FILE=""

PHASE_PREFLIGHT="preflight"
PHASE_COMPOSE="compose"
PHASE_VALIDATE="validate"
PHASE_IMAGE="image"
PHASE_PROMOTE="promote"
PHASE_SYNC="sync"
PHASE_PUSH="push"
PHASE_DONE="done"
PHASE_FAILED="failed"

init_state() {
    local state_dir="${1:-$STATE_DIR}"
    STATE_DIR="$state_dir"
    SESSION_STATE_FILE="${STATE_DIR}/session.json"
    
    mkdir -p "$STATE_DIR"
    
    if [[ ! -d "$STATE_DIR" ]]; then
        log_error "Cannot create state directory: ${STATE_DIR}"
        return 1
    fi
    
    return 0
}

_atomic_write() {
    local file="$1"
    local content="$2"
    local tmp_file="${file}.tmp.$$"
    
    printf '%s\n' "$content" > "$tmp_file" || {
        rm -f "$tmp_file"
        return 1
    }
    
    mv "$tmp_file" "$file" || {
        rm -f "$tmp_file"
        return 1
    }
    
    return 0
}

create_session_state() {
    local session_id="$1"
    local max_posts="$2"
    local timestamp
    timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    
    local state
    state=$(jq -n \
        --arg id "$session_id" \
        --arg ts "$timestamp" \
        --argjson max "$max_posts" \
        '{
            session_id: $id,
            started_at: $ts,
            updated_at: $ts,
            max_posts: $max,
            completed_count: 0,
            failed_count: 0,
            consecutive_failures: 0,
            current_post: null,
            status: "running",
            posts: []
        }')
    
    _atomic_write "$SESSION_STATE_FILE" "$state" || {
        log_error "Failed to create session state"
        return 1
    }
    
    log_info "Session state created: ${session_id}"
    return 0
}

get_session_state() {
    [[ -f "$SESSION_STATE_FILE" ]] || return 1
    cat "$SESSION_STATE_FILE"
}

update_session_state() {
    local updates="$1"
    
    [[ ! -f "$SESSION_STATE_FILE" ]] && {
        log_error "No session state file to update"
        return 1
    }
    
    local current
    current=$(cat "$SESSION_STATE_FILE")
    
    local timestamp
    timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    
    local updated
    updated=$(printf '%s' "$current" | jq --arg ts "$timestamp" ". + {updated_at: \$ts} + ${updates}")
    
    _atomic_write "$SESSION_STATE_FILE" "$updated" || {
        log_error "Failed to update session state"
        return 1
    }
    
    return 0
}

create_post_state() {
    local run_id="$1"
    local slug="$2"
    local title="$3"
    
    STATE_FILE="${STATE_DIR}/${run_id}.json"
    
    local timestamp
    timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    
    local state
    state=$(jq -n \
        --arg run_id "$run_id" \
        --arg slug "$slug" \
        --arg title "$title" \
        --arg ts "$timestamp" \
        '{
            run_id: $run_id,
            slug: $slug,
            title: $title,
            started_at: $ts,
            updated_at: $ts,
            current_phase: "preflight",
            phase_attempts: {},
            completed_phases: [],
            status: "running",
            error: null,
            outputs: {}
        }')
    
    _atomic_write "$STATE_FILE" "$state" || {
        log_error "Failed to create post state for ${slug}"
        return 1
    }
    
    update_session_state "{\"current_post\": \"${slug}\"}" || true
    
    log_info "Post state created: ${run_id} (${slug})"
    return 0
}

get_post_state() {
    local run_id="${1:-}"
    local file="${STATE_DIR}/${run_id}.json"
    
    [[ -z "$run_id" ]] && file="$STATE_FILE"
    [[ -f "$file" ]] || return 1
    
    cat "$file"
}

update_post_phase() {
    local phase="$1"
    local status="$2"
    local error="${3:-}"
    
    [[ ! -f "$STATE_FILE" ]] && {
        log_error "No post state file to update"
        return 1
    }
    
    local timestamp
    timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    
    local current
    current=$(cat "$STATE_FILE")
    
    local current_attempts
    current_attempts=$(printf '%s' "$current" | jq -r ".phase_attempts.\"${phase}\" // 0")
    local new_attempts=$((current_attempts + 1))
    
    local updated
    if [[ "$status" == "completed" ]]; then
        updated=$(printf '%s' "$current" | jq \
            --arg phase "$phase" \
            --arg ts "$timestamp" \
            --argjson attempts "$new_attempts" \
            '.updated_at = $ts |
             .current_phase = $phase |
             .phase_attempts[$phase] = $attempts |
             .completed_phases += [$phase] |
             .completed_phases |= unique')
    elif [[ "$status" == "failed" ]]; then
        updated=$(printf '%s' "$current" | jq \
            --arg phase "$phase" \
            --arg ts "$timestamp" \
            --arg err "$error" \
            --argjson attempts "$new_attempts" \
            '.updated_at = $ts |
             .current_phase = $phase |
             .phase_attempts[$phase] = $attempts |
             .status = "failed" |
             .error = $err')
    else
        updated=$(printf '%s' "$current" | jq \
            --arg phase "$phase" \
            --arg ts "$timestamp" \
            --argjson attempts "$new_attempts" \
            '.updated_at = $ts |
             .current_phase = $phase |
             .phase_attempts[$phase] = $attempts')
    fi
    
    _atomic_write "$STATE_FILE" "$updated" || {
        log_error "Failed to update post phase"
        return 1
    }
    
    return 0
}

set_post_output() {
    local key="$1"
    local value="$2"
    
    [[ ! -f "$STATE_FILE" ]] && return 1
    
    local current
    current=$(cat "$STATE_FILE")
    
    local updated
    updated=$(printf '%s' "$current" | jq \
        --arg key "$key" \
        --arg val "$value" \
        '.outputs[$key] = $val')
    
    _atomic_write "$STATE_FILE" "$updated"
}

mark_post_done() {
    local status="${1:-success}"
    
    [[ ! -f "$STATE_FILE" ]] && return 1
    
    local timestamp
    timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    
    local current
    current=$(cat "$STATE_FILE")
    
    local updated
    updated=$(printf '%s' "$current" | jq \
        --arg ts "$timestamp" \
        --arg status "$status" \
        '.updated_at = $ts |
         .ended_at = $ts |
         .current_phase = "done" |
         .status = $status')
    
    _atomic_write "$STATE_FILE" "$updated" || return 1
    
    local slug
    slug=$(printf '%s' "$current" | jq -r '.slug')
    
    if [[ "$status" == "success" ]]; then
        update_session_state "{
            \"completed_count\": (.completed_count + 1),
            \"consecutive_failures\": 0,
            \"current_post\": null,
            \"posts\": (.posts + [{\"slug\": \"${slug}\", \"status\": \"success\"}])
        }" || true
    else
        update_session_state "{
            \"failed_count\": (.failed_count + 1),
            \"consecutive_failures\": (.consecutive_failures + 1),
            \"current_post\": null,
            \"posts\": (.posts + [{\"slug\": \"${slug}\", \"status\": \"failed\"}])
        }" || true
    fi
    
    return 0
}

is_phase_completed() {
    local phase="$1"
    
    [[ ! -f "$STATE_FILE" ]] && return 1
    
    local completed
    completed=$(jq -r ".completed_phases | index(\"${phase}\") != null" "$STATE_FILE")
    
    [[ "$completed" == "true" ]]
}

get_resumable_phase() {
    [[ ! -f "$STATE_FILE" ]] && {
        echo "$PHASE_PREFLIGHT"
        return 0
    }
    
    local current_phase
    current_phase=$(jq -r '.current_phase // "preflight"' "$STATE_FILE")
    
    local status
    status=$(jq -r '.status' "$STATE_FILE")
    
    [[ "$status" == "success" || "$status" == "failed" ]] && {
        echo "none"
        return 0
    }
    
    echo "$current_phase"
}

find_incomplete_runs() {
    local -a incomplete=()
    
    for state_file in "${STATE_DIR}"/*.json; do
        [[ ! -f "$state_file" ]] && continue
        [[ "$(basename "$state_file")" == "session.json" ]] && continue
        
        local status
        status=$(jq -r '.status // "unknown"' "$state_file" 2>/dev/null)
        
        if [[ "$status" == "running" ]]; then
            local run_id
            run_id=$(jq -r '.run_id' "$state_file")
            incomplete+=("$run_id")
        fi
    done
    
    printf '%s\n' "${incomplete[@]}"
}

get_failure_counts() {
    [[ ! -f "$SESSION_STATE_FILE" ]] && {
        echo "0 0"
        return
    }
    
    local consecutive total
    consecutive=$(jq -r '.consecutive_failures // 0' "$SESSION_STATE_FILE")
    total=$(jq -r '.failed_count // 0' "$SESSION_STATE_FILE")
    
    echo "$consecutive $total"
}

check_failure_budget() {
    local max_consecutive="${1:-3}"
    local max_total="${2:-5}"
    
    local counts
    counts=$(get_failure_counts)
    local consecutive="${counts%% *}"
    local total="${counts##* }"
    
    if [[ $consecutive -ge $max_consecutive ]]; then
        log_error "Failure budget exceeded: ${consecutive} consecutive failures (max: ${max_consecutive})"
        return 1
    fi
    
    if [[ $total -ge $max_total ]]; then
        log_error "Failure budget exceeded: ${total} total failures (max: ${max_total})"
        return 1
    fi
    
    return 0
}

end_session() {
    local status="${1:-completed}"
    
    [[ ! -f "$SESSION_STATE_FILE" ]] && return 0
    
    local timestamp
    timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    
    update_session_state "{
        \"status\": \"${status}\",
        \"ended_at\": \"${timestamp}\",
        \"current_post\": null
    }"
    
    log_info "Session ended with status: ${status}"
}

cleanup_old_states() {
    local days_old="${1:-7}"
    
    find "$STATE_DIR" -name "*.json" -type f -mtime +"$days_old" -delete 2>/dev/null || true
    log_info "Cleaned up state files older than ${days_old} days"
}
