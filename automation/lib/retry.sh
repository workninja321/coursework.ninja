#!/usr/bin/env bash
# retry.sh - Retry logic with exponential backoff and jitter
# Requires: logging.sh and compat.sh to be sourced first

[[ -n "${_RETRY_SH_LOADED:-}" ]] && return 0
_RETRY_SH_LOADED=1

RETRY_MAX_ATTEMPTS="${RETRY_MAX_ATTEMPTS:-3}"
RETRY_INITIAL_WAIT="${RETRY_INITIAL_WAIT:-30}"
RETRY_MAX_WAIT="${RETRY_MAX_WAIT:-300}"
RETRY_BACKOFF_FACTOR="${RETRY_BACKOFF_FACTOR:-2}"
RETRY_JITTER_MAX="${RETRY_JITTER_MAX:-10}"

OPENCODE_TIMEOUT="${OPENCODE_TIMEOUT:-600}"
FALLBACK_MODEL="${FALLBACK_MODEL:-claude-sonnet-4}"

PATTERN_RATE_LIMIT="rate.?limit|429|too many requests|quota|throttl"
PATTERN_CONTEXT_LENGTH="context.?length|token.?limit|maximum.?context|too.?long"
PATTERN_TRANSIENT="timeout|connection|temporary|unavailable|503|502|ECONNRESET"

calculate_backoff_with_jitter() {
    local current_wait="$1"
    local next_wait=$((current_wait * RETRY_BACKOFF_FACTOR))
    
    [[ $next_wait -gt $RETRY_MAX_WAIT ]] && next_wait=$RETRY_MAX_WAIT
    
    local jitter=$((RANDOM % RETRY_JITTER_MAX))
    echo $((next_wait + jitter))
}

sleep_with_backoff() {
    local wait_time="$1"
    local jitter=$((RANDOM % RETRY_JITTER_MAX))
    local total=$((wait_time + jitter))
    log_info "Waiting ${total}s before retry (${wait_time}s + ${jitter}s jitter)"
    sleep "$total"
}

detect_error_type() {
    local log_file="$1"
    
    [[ ! -f "$log_file" ]] && echo "unknown" && return
    
    if grep -qiE "$PATTERN_RATE_LIMIT" "$log_file" 2>/dev/null; then
        echo "rate_limit"
    elif grep -qiE "$PATTERN_CONTEXT_LENGTH" "$log_file" 2>/dev/null; then
        echo "context_length"
    elif grep -qiE "$PATTERN_TRANSIENT" "$log_file" 2>/dev/null; then
        echo "transient"
    else
        echo "unknown"
    fi
}

run_with_retry() {
    local model="$1"
    local prompt="$2"
    local output_file="$3"
    local step_name="${4:-opencode}"
    local log_file="${5:-${LOG_DIR:-./logs}/opencode-${LOG_RUN_ID:-unknown}-${step_name}.log}"
    
    local attempt=1
    local wait_time=$RETRY_INITIAL_WAIT
    local current_model="$model"
    local exit_code=0
    
    log_info "Starting ${step_name} with model ${current_model}" \
        "{\"model\": \"${current_model}\", \"output_file\": \"${output_file}\"}"
    
    while [[ $attempt -le $RETRY_MAX_ATTEMPTS ]]; do
        log_info "Attempt ${attempt}/${RETRY_MAX_ATTEMPTS}" \
            "{\"attempt\": ${attempt}, \"model\": \"${current_model}\"}"
        
        : > "$log_file"
        
        set +e
        timeout_cmd "$OPENCODE_TIMEOUT" opencode run --model "$current_model" "$prompt" \
            2>&1 | tee -a "${LOG_TEXT_FILE:-/dev/null}" | tee "$log_file"
        exit_code=${PIPESTATUS[0]}
        set -e
        
        if [[ $exit_code -eq 124 || $exit_code -eq 137 ]]; then
            log_warning "Timeout after ${OPENCODE_TIMEOUT}s" \
                "{\"error_type\": \"timeout\", \"timeout_seconds\": ${OPENCODE_TIMEOUT}}"
            ((attempt++))
            [[ $attempt -le $RETRY_MAX_ATTEMPTS ]] && sleep_with_backoff "$wait_time"
            wait_time=$(calculate_backoff_with_jitter "$wait_time")
            continue
        fi
        
        local error_type
        error_type=$(detect_error_type "$log_file")
        
        case "$error_type" in
            rate_limit)
                log_warning "Rate limited, backing off ${wait_time}s" \
                    "{\"error_type\": \"rate_limit\", \"wait_seconds\": ${wait_time}}"
                sleep_with_backoff "$wait_time"
                wait_time=$(calculate_backoff_with_jitter "$wait_time")
                ((attempt++))
                continue
                ;;
            context_length)
                if [[ "$current_model" != "$FALLBACK_MODEL" && -n "$FALLBACK_MODEL" ]]; then
                    log_warning "Context length exceeded, switching to ${FALLBACK_MODEL}" \
                        "{\"error_type\": \"context_length\", \"fallback_model\": \"${FALLBACK_MODEL}\"}"
                    current_model="$FALLBACK_MODEL"
                    ((attempt++))
                    continue
                fi
                ;;
            transient)
                log_warning "Transient error, retrying in ${wait_time}s" \
                    "{\"error_type\": \"transient\", \"wait_seconds\": ${wait_time}}"
                sleep_with_backoff "$wait_time"
                wait_time=$(calculate_backoff_with_jitter "$wait_time")
                ((attempt++))
                continue
                ;;
        esac
        
        if [[ $exit_code -eq 0 && -s "$output_file" ]]; then
            log_info "Completed successfully after ${attempt} attempt(s)" \
                "{\"attempts\": ${attempt}, \"model\": \"${current_model}\", \"success\": true}"
            return 0
        fi
        
        log_warning "Failed (exit=${exit_code}, output_exists=$([[ -s "$output_file" ]] && echo true || echo false))" \
            "{\"exit_code\": ${exit_code}, \"attempt\": ${attempt}}"
        
        ((attempt++))
        if [[ $attempt -le $RETRY_MAX_ATTEMPTS ]]; then
            sleep_with_backoff "$wait_time"
            wait_time=$(calculate_backoff_with_jitter "$wait_time")
        fi
    done
    
    log_error "Failed after ${RETRY_MAX_ATTEMPTS} attempts" \
        "{\"attempts\": ${RETRY_MAX_ATTEMPTS}, \"model\": \"${current_model}\", \"success\": false}"
    return 1
}

retry_command() {
    local max_attempts="${1:-3}"
    local wait_time="${2:-5}"
    shift 2
    local cmd=("$@")
    
    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        if "${cmd[@]}"; then
            return 0
        fi
        
        log_warning "Command failed (attempt ${attempt}/${max_attempts}): ${cmd[*]}"
        ((attempt++))
        
        if [[ $attempt -le $max_attempts ]]; then
            sleep "$wait_time"
            wait_time=$((wait_time * 2))
        fi
    done
    
    log_error "Command failed after ${max_attempts} attempts: ${cmd[*]}"
    return 1
}

run_image_generation() {
    local slug="$1"
    local short_title="$2"
    local scene="$3"
    local output_file="$4"
    
    local attempt=1
    local wait_time=10
    local max_attempts=3
    
    [[ -z "${OPENROUTER_API_KEY:-}" ]] && {
        log_warning "OPENROUTER_API_KEY not set, skipping image generation"
        return 1
    }
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Image generation attempt ${attempt}/${max_attempts}" \
            "{\"slug\": \"${slug}\", \"attempt\": ${attempt}}"
        
        local tmp_png
        tmp_png=$(mktemp "/tmp/${slug}.XXXXXX.png")
        
        local response http_code body
        response=$(curl -sS -w "\n%{http_code}" "https://openrouter.ai/api/v1/chat/completions" \
            -H "Authorization: Bearer ${OPENROUTER_API_KEY}" \
            -H "Content-Type: application/json" \
            --max-time 120 \
            -d "{\"model\":\"google/gemini-3-pro-image-preview\",\"messages\":[{\"role\":\"user\",\"content\":\"Generate a 16:9 banner image for a blog post. Background: photorealistic ${scene}. Apply a duotone overlay transitioning from navy blue (#0B1630) on the left to gold (#F4A826) on the right. Add white bold text \\\"${short_title}\\\" prominently centered. Professional corporate style, clean and modern. No additional text or elements.\"}],\"modalities\":[\"image\",\"text\"],\"image_config\":{\"aspect_ratio\":\"16:9\"}}" 2>/dev/null) || {
            log_warning "Curl failed for image generation"
            rm -f "$tmp_png"
            ((attempt++))
            sleep_with_backoff "$wait_time"
            wait_time=$((wait_time * 2))
            continue
        }
        
        http_code="${response##*$'\n'}"
        body="${response%$'\n'*}"
        
        if [[ "$http_code" != "200" ]]; then
            log_warning "Image API returned HTTP ${http_code}" \
                "{\"http_code\": \"${http_code}\", \"attempt\": ${attempt}}"
            rm -f "$tmp_png"
            ((attempt++))
            sleep_with_backoff "$wait_time"
            wait_time=$((wait_time * 2))
            continue
        fi
        
        local image_url
        image_url=$(printf '%s' "$body" | jq -r '.choices[0].message.images[0].image_url.url // empty' 2>/dev/null)
        
        if [[ -z "$image_url" ]]; then
            log_warning "No image URL in response" "{\"attempt\": ${attempt}}"
            rm -f "$tmp_png"
            ((attempt++))
            sleep_with_backoff "$wait_time"
            wait_time=$((wait_time * 2))
            continue
        fi
        
        if [[ "$image_url" == data:image* ]]; then
            printf '%s' "$image_url" | sed 's/^data:image\/[a-zA-Z0-9+.-]*;base64,//' | base64 -d > "$tmp_png" 2>/dev/null || true
        else
            curl -sS -f --max-time 60 "$image_url" -o "$tmp_png" 2>/dev/null || true
        fi
        
        if [[ ! -s "$tmp_png" ]]; then
            log_warning "Image decode/download failed" "{\"attempt\": ${attempt}}"
            rm -f "$tmp_png"
            ((attempt++))
            sleep_with_backoff "$wait_time"
            wait_time=$((wait_time * 2))
            continue
        fi
        
        if cwebp -q 85 "$tmp_png" -o "$output_file" >/dev/null 2>&1 && [[ -s "$output_file" ]]; then
            rm -f "$tmp_png"
            log_info "Image generated successfully" \
                "{\"slug\": \"${slug}\", \"attempts\": ${attempt}, \"output\": \"${output_file}\"}"
            return 0
        fi
        
        log_warning "WebP conversion failed" "{\"attempt\": ${attempt}}"
        rm -f "$tmp_png"
        ((attempt++))
        sleep_with_backoff "$wait_time"
        wait_time=$((wait_time * 2))
    done
    
    log_error "Image generation failed after ${max_attempts} attempts" \
        "{\"slug\": \"${slug}\", \"attempts\": ${max_attempts}}"
    return 1
}
