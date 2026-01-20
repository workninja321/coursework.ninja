#!/usr/bin/env bash
# lock.sh - File locking with heartbeat and stale detection
# Uses flock when available, falls back to mkdir-based locking on macOS
# Requires: logging.sh

[[ -n "${_LOCK_SH_LOADED:-}" ]] && return 0
_LOCK_SH_LOADED=1

LOCK_DIR="${LOCK_DIR:-./locks}"
LOCK_FILE=""
LOCK_FD=""
LOCK_HEARTBEAT_PID=""
LOCK_STALE_THRESHOLD="${LOCK_STALE_THRESHOLD:-300}"
LOCK_HEARTBEAT_INTERVAL="${LOCK_HEARTBEAT_INTERVAL:-60}"
LOCK_USE_FLOCK=""  # Set dynamically based on availability

init_lock() {
    local lock_dir="${1:-$LOCK_DIR}"
    LOCK_DIR="$lock_dir"
    
    mkdir -p "$LOCK_DIR" || {
        log_error "Cannot create lock directory: ${LOCK_DIR}"
        return 1
    }
    
    if command -v flock >/dev/null 2>&1; then
        LOCK_USE_FLOCK=1
        log_debug "Using flock for locking"
    else
        LOCK_USE_FLOCK=""
        log_debug "Using mkdir fallback for locking (flock not available)"
    fi
    
    return 0
}

_is_process_alive() {
    local pid="$1"
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

_get_lock_info() {
    local lock_file="$1"
    local info_file="${lock_file}.info"
    
    [[ ! -f "$info_file" ]] && return 1
    
    cat "$info_file"
}

_write_lock_info() {
    local lock_file="$1"
    local info_file="${lock_file}.info"
    
    local timestamp
    timestamp="$(date +%s)"
    
    printf '%s\n%s\n%s\n' "$$" "$timestamp" "$(hostname)" > "$info_file"
}

_update_heartbeat() {
    local lock_file="$1"
    local info_file="${lock_file}.info"
    
    [[ ! -f "$info_file" ]] && return 1
    
    local pid hostname
    { read -r pid; read -r _; read -r hostname; } < "$info_file"
    
    local timestamp
    timestamp="$(date +%s)"
    
    printf '%s\n%s\n%s\n' "$pid" "$timestamp" "$hostname" > "$info_file"
}

_is_lock_stale() {
    local lock_file="$1"
    local info_file="${lock_file}.info"
    
    [[ ! -f "$info_file" ]] && return 0
    
    local pid timestamp hostname
    { read -r pid; read -r timestamp; read -r hostname; } < "$info_file"
    
    if _is_process_alive "$pid"; then
        return 1
    fi
    
    local now
    now="$(date +%s)"
    local age=$((now - timestamp))
    
    if [[ $age -gt $LOCK_STALE_THRESHOLD ]]; then
        log_warning "Stale lock detected (age: ${age}s, pid: ${pid})"
        return 0
    fi
    
    return 1
}

_start_heartbeat() {
    local lock_file="$1"
    
    (
        while true; do
            sleep "$LOCK_HEARTBEAT_INTERVAL"
            _update_heartbeat "$lock_file" || break
        done
    ) &
    
    LOCK_HEARTBEAT_PID=$!
    log_debug "Heartbeat started (pid: ${LOCK_HEARTBEAT_PID})"
}

_stop_heartbeat() {
    if [[ -n "$LOCK_HEARTBEAT_PID" ]]; then
        kill "$LOCK_HEARTBEAT_PID" 2>/dev/null || true
        wait "$LOCK_HEARTBEAT_PID" 2>/dev/null || true
        LOCK_HEARTBEAT_PID=""
        log_debug "Heartbeat stopped"
    fi
}

acquire_lock() {
    local lock_name="${1:-autopilot}"
    local wait_timeout="${2:-0}"
    
    LOCK_FILE="${LOCK_DIR}/${lock_name}.lock"
    
    if [[ -f "$LOCK_FILE" ]] && _is_lock_stale "$LOCK_FILE"; then
        log_warning "Removing stale lock: ${LOCK_FILE}"
        rm -f "$LOCK_FILE" "${LOCK_FILE}.info"
        rm -rf "${LOCK_FILE}.d" 2>/dev/null || true
    fi
    
    if [[ -n "$LOCK_USE_FLOCK" ]]; then
        _acquire_lock_flock "$wait_timeout"
    else
        _acquire_lock_mkdir "$wait_timeout"
    fi
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        _write_lock_info "$LOCK_FILE"
        _start_heartbeat "$LOCK_FILE"
        log_info "Lock acquired: ${lock_name}"
    fi
    
    return $result
}

_acquire_lock_flock() {
    local wait_timeout="${1:-0}"
    
    exec 200>"$LOCK_FILE"
    LOCK_FD=200
    
    local flock_args=(-n)
    if [[ $wait_timeout -gt 0 ]]; then
        flock_args=(-w "$wait_timeout")
    fi
    
    if ! flock "${flock_args[@]}" 200; then
        _report_lock_holder
        return 1
    fi
    
    return 0
}

_acquire_lock_mkdir() {
    local wait_timeout="${1:-0}"
    local lock_dir_path="${LOCK_FILE}.d"
    local elapsed=0
    
    while true; do
        if mkdir "$lock_dir_path" 2>/dev/null; then
            printf '%s\n' "$$" > "${lock_dir_path}/pid"
            printf '%s\n' "$(hostname)" > "${lock_dir_path}/host"
            return 0
        fi
        
        if [[ -f "${lock_dir_path}/pid" ]]; then
            local holder_pid
            holder_pid=$(cat "${lock_dir_path}/pid" 2>/dev/null || echo "")
            if [[ -n "$holder_pid" ]] && ! kill -0 "$holder_pid" 2>/dev/null; then
                log_warning "Cleaning up dead lock holder (pid: ${holder_pid})"
                rm -rf "$lock_dir_path" 2>/dev/null || true
                continue
            fi
        fi
        
        if [[ $wait_timeout -le 0 ]]; then
            _report_lock_holder
            return 1
        fi
        
        if [[ $elapsed -ge $wait_timeout ]]; then
            _report_lock_holder
            return 1
        fi
        
        sleep 1
        ((elapsed++))
    done
}

_report_lock_holder() {
    local info
    info=$(_get_lock_info "$LOCK_FILE")
    if [[ -n "$info" ]]; then
        local pid timestamp
        { read -r pid; read -r timestamp; } <<< "$info"
        log_error "Lock held by pid ${pid} since $(date -r "$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$timestamp")"
    else
        log_error "Lock is held by another process"
    fi
}

release_lock() {
    _stop_heartbeat
    
    if [[ -n "$LOCK_USE_FLOCK" && -n "$LOCK_FD" ]]; then
        flock -u "$LOCK_FD" 2>/dev/null || true
        eval "exec ${LOCK_FD}>&-" 2>/dev/null || true
        LOCK_FD=""
    fi
    
    if [[ -n "$LOCK_FILE" ]]; then
        rm -f "$LOCK_FILE" "${LOCK_FILE}.info"
        rm -rf "${LOCK_FILE}.d" 2>/dev/null || true
        log_info "Lock released"
        LOCK_FILE=""
    fi
}

is_locked() {
    local lock_name="${1:-autopilot}"
    local lock_file="${LOCK_DIR}/${lock_name}.lock"
    
    if _is_lock_stale "$lock_file"; then
        return 1
    fi
    
    if [[ -n "$LOCK_USE_FLOCK" ]]; then
        [[ ! -f "$lock_file" ]] && return 1
        exec 201>"$lock_file"
        if flock -n 201 2>/dev/null; then
            flock -u 201
            exec 201>&-
            return 1
        fi
        exec 201>&-
        return 0
    else
        [[ -d "${lock_file}.d" ]] && return 0
        return 1
    fi
}

get_lock_holder() {
    local lock_name="${1:-autopilot}"
    local lock_file="${LOCK_DIR}/${lock_name}.lock"
    local info_file="${lock_file}.info"
    
    [[ ! -f "$info_file" ]] && return 1
    
    local pid timestamp hostname
    { read -r pid; read -r timestamp; read -r hostname; } < "$info_file"
    
    echo "${pid}:${hostname}:${timestamp}"
}

with_lock() {
    local lock_name="$1"
    shift
    local cmd=("$@")
    
    acquire_lock "$lock_name" || return 1
    
    local exit_code=0
    "${cmd[@]}" || exit_code=$?
    
    release_lock
    
    return $exit_code
}

setup_lock_cleanup_trap() {
    trap 'release_lock; exit' EXIT
    trap 'release_lock; exit 1' INT TERM
}

force_release_lock() {
    local lock_name="${1:-autopilot}"
    local lock_file="${LOCK_DIR}/${lock_name}.lock"
    
    local info pid
    info=$(_get_lock_info "$lock_file")
    if [[ -n "$info" ]]; then
        read -r pid <<< "$info"
        if _is_process_alive "$pid"; then
            log_warning "Force killing process ${pid}"
            kill -9 "$pid" 2>/dev/null || true
            sleep 1
        fi
    fi
    
    rm -f "$lock_file" "${lock_file}.info"
    rm -rf "${lock_file}.d" 2>/dev/null || true
    log_warning "Force released lock: ${lock_name}"
}
