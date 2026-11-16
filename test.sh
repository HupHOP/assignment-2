#!/usr/bin/env bash
set -u

IMAGE="diagnostic-tool"
PASS=0
FAIL=0

# run_test NAME EXPECTED_EXIT_CODE EXPECTED_TEXT ARGS...
run_test() {
    local name="$1" want_rc="$2" want_text="$3"
    shift 3
    local output rc
    output="$(docker run --rm "$IMAGE" "$@" 2>&1)"
    rc=$?
    if [[ $rc -eq $want_rc ]] && grep -q -- "$want_text" <<< "$output"; then
        echo "PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $name (exit $rc, expected $want_rc; looking for '$want_text')"
        sed 's/^/    /' <<< "$output"
        FAIL=$((FAIL + 1))
    fi
}

echo "Building image..."
if ! docker build -q -t "$IMAGE" . > /dev/null; then
    echo "FAIL: docker build failed" >&2
    exit 1
fi

run_test "help exits 0 and shows usage" 0 "Usage: diagnostic" help
run_test "system exits 0 and shows hostname" 0 "Hostname" system
run_test "disk shows filesystems" 0 "Filesystem" disk
run_test "invalid command is rejected" 2 "unknown command" nonsense
run_test "no arguments falls back to help" 0 "Usage: diagnostic"
run_test "network without a host is" 2 "requires a host" network
run_test "network rejects a bad hostname" 2 "invalid hostname" network 'a;b'
run_test "network resolves localhost" 0 "Resolved address" network localhost
run_test "network reports an unresolvable host" 1 "FAILED" network no-such-host.invalid



echo
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]]
