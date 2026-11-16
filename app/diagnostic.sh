#!/usr/bin/env bash
set -u

usage() {
    cat << 'EOF'
Usage: diagnostic <command> [arguments]

Commands:
  system           Show system information
  network <host>   Check connectivity to a host
  disk             Show disk usage
  help             Show this help message

Exit codes: 0 success, 1 runtime failure, 2 invalid command or input
EOF
}
row() {
    printf '%-18s: %s\n' "$1" "$2"
}

get_uptime() {
    awk '{
        s = int($1)
        printf "%d days, %d hours, %d minutes", int(s / 86400), int((s % 86400) / 3600), int((s % 3600) / 60)
    }' /proc/uptime
}

get_memory() {
    awk '
        /^MemTotal:/     {t = $2}
        /^MemAvailable:/ {a = $2}
        END {printf "Total: %d MiB | Available: %d MiB", t / 1024, a / 1024}
    ' /proc/meminfo
}

get_cpu_model() {
    local model
    model="$(awk -F': *' '/^model name/ {print $2; exit}' /proc/cpuinfo)"
    echo "${model:-$(uname -m)}"
}

cmd_system() {
    row "Hostname" "$(hostname)"
    row "Current User" "$(id -un)"
    row "Date/Time" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    row "Operating System" "$(grep '^PRETTY_NAME' /etc/os-release | cut -d= -f2 | tr -d '"')"
    row "Kernel Version" "$(uname -r)"
    row "Uptime" "$(get_uptime)"
    row "CPU Model" "$(get_cpu_model)"
    row "CPU Cores" "$(nproc)"
    row "Memory" "$(get_memory)"
    row "Working Directory" "$(pwd)"
}

is_valid_host() {
    local h="$1"
    [[ -n "$h" && ${#h} -le 253 ]] || return 1
    [[ "$h" != *..* ]] || return 1
    [[ "$h" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]]
}

cmd_network() {
    local host="$1"

    if ! is_valid_host "$host"; then
        echo "Error: invalid hostname or IP address: $host" >&2
        exit 2
    fi

    echo "Network check for: $host"

    local resolved=""
    if command -v getent >/dev/null 2>&1; then
        resolved="$(getent ahosts "$host" | awk 'NR==1 {print $1}')"
    fi
    if [[ -z "$resolved" ]]; then
        echo "Resolution: FAILED - could not resolve $host" >&2
        exit 1
    fi
    echo "Resolved address: $resolved"

    if ! command -v ping >/dev/null 2>&1; then
        echo "Ping: skipped (ping is not installed)"
    elif ping -c 2 -W 2 -- "$host" >/dev/null 2>&1; then
        echo "Ping: host is reachable"
    else
        echo "Ping: no reply from $host" >&2
        exit 1
    fi

    echo "Result: all checks passed"
}

cmd_disk() {
    echo "Disk usage:"
    if ! df -hP; then
        echo "Error: could not read disk information" >&2
        exit 1
    fi
}



main() {
    if [[ $# -lt 1 ]]; then
        echo "Error: no command given" >&2
        usage >&2
        exit 2
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        system)
            cmd_system
            ;;
        network)
            if [[ $# -lt 1 ]]; then
                echo "Error: 'network' requires a host" >&2
                usage >&2
                exit 2
            fi
            cmd_network "$1"
            ;;
        disk)
            cmd_disk
            ;;
        help|-h|--help)
            usage
            ;;
        *)
            echo "Error: unknown command '$cmd'" >&2
            usage >&2
            exit 2
            ;;
    esac
}

main "$@"
