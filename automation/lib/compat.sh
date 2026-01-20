#!/usr/bin/env bash
# compat.sh - macOS/Linux compatibility layer for timeout and flock
# Provides portable fallbacks when GNU coreutils are not available

[[ -n "${_COMPAT_SH_LOADED:-}" ]] && return 0
_COMPAT_SH_LOADED=1

# Kill timeout in seconds for timeout_cmd (after TERM, wait this long then KILL)
KILL_AFTER="${KILL_AFTER:-30}"

# Parse duration strings like "4h", "30m", "300" into seconds
parse_duration() {
    local input="$1"
    case "$input" in
        *s) echo "${input%s}" ;;
        *m) echo "$(( ${input%m} * 60 ))" ;;
        *h) echo "$(( ${input%h} * 3600 ))" ;;
        *d) echo "$(( ${input%d} * 86400 ))" ;;
        *)  echo "$input" ;;
    esac
}

# Portable timeout command with fallback to Perl
# Usage: timeout_cmd DURATION COMMAND [ARGS...]
# Returns: exit code of command, or 124 on timeout
timeout_cmd() {
    local duration="$1"
    shift

    # Try GNU timeout first (Linux default)
    if command -v timeout >/dev/null 2>&1; then
        if timeout --help 2>&1 | grep -q -- '--kill-after'; then
            timeout --kill-after="${KILL_AFTER}" "$duration" "$@"
        else
            timeout "$duration" "$@"
        fi
        return $?
    fi

    # Try gtimeout (Homebrew coreutils on macOS)
    if command -v gtimeout >/dev/null 2>&1; then
        if gtimeout --help 2>&1 | grep -q -- '--kill-after'; then
            gtimeout --kill-after="${KILL_AFTER}" "$duration" "$@"
        else
            gtimeout "$duration" "$@"
        fi
        return $?
    fi

    # Fallback: Perl-based timeout (ships with macOS)
    local seconds
    seconds="$(parse_duration "$duration")"
    
    KILL_AFTER="${KILL_AFTER}" /usr/bin/perl -e '
        use strict;
        use warnings;
        use POSIX qw(setsid);
        
        my $timeout = shift @ARGV;
        my $kill_after = $ENV{KILL_AFTER} || 30;
        my @cmd = @ARGV;
        
        die "No command specified" unless @cmd;
        
        my $timed_out = 0;
        my $pid = fork();
        die "fork failed: $!" unless defined $pid;
        
        if ($pid == 0) {
            # Child: create new process group and exec
            setsid();
            exec @cmd;
            exit 127;
        }
        
        # Parent: set up alarm
        $SIG{ALRM} = sub {
            $timed_out = 1;
            kill "TERM", -$pid;  # Kill process group
            alarm $kill_after;
            $SIG{ALRM} = sub {
                kill "KILL", -$pid;
            };
        };
        
        alarm $timeout;
        waitpid($pid, 0);
        alarm 0;
        
        my $status = $?;
        
        if ($timed_out) {
            exit 124;  # Standard timeout exit code
        }
        
        if ($status & 127) {
            # Killed by signal
            exit 128 + ($status & 127);
        }
        
        exit $status >> 8;
    ' "$seconds" "$@"
}

# Check if native timeout is available (for informational purposes)
has_native_timeout() {
    command -v timeout >/dev/null 2>&1 || command -v gtimeout >/dev/null 2>&1
}

# Check if native flock is available
has_native_flock() {
    command -v flock >/dev/null 2>&1
}

# Print compatibility status (for debugging)
print_compat_status() {
    echo "=== Compatibility Status ==="
    if has_native_timeout; then
        if command -v timeout >/dev/null 2>&1; then
            echo "timeout: native ($(which timeout))"
        else
            echo "timeout: gtimeout ($(which gtimeout))"
        fi
    else
        echo "timeout: Perl fallback"
    fi
    
    if has_native_flock; then
        echo "flock: native ($(which flock))"
    else
        echo "flock: mkdir fallback"
    fi
    echo "============================"
}
