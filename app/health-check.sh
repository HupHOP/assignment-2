#!/usr/bin/env bash
set -u

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
status=0

# check NAME COMMAND... -> runs the command quietly and records a failure
check() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "OK:   $name"
    else
        echo "FAIL: $name" >&2
        status=1
    fi
}

check "diagnostic.sh is executable" test -x "$APP_DIR/diagnostic.sh"
check "diagnostic.sh help runs" "$APP_DIR/diagnostic.sh" help

for tool in awk df getent hostname; do
    check "tool available: $tool" command -v "$tool"
done

if (( status == 0 )); then
    echo "healthy"
else
    echo "unhealthy" >&2
fi
exit "$status"
