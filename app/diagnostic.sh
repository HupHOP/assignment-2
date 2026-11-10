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

cmd_system() {
    echo "system: not implemented yet"
}

cmd_network() {
    echo "network: not implemented yet (host: $1)"
}

cmd_disk() {
    echo "disk: not implemented yet"
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
