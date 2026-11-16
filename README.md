# Assignment 2 - Dockerized Diagnostic CLI

A Bash diagnostic tool packaged as a Docker image. One command, `diagnostic`,
reports system information, disk usage and basic network connectivity, and runs
the same way on any machine with Docker.

## Project structure

```
assignment-2/
├── README.md
├── Dockerfile
├── compose.yaml
├── .dockerignore
├── test.sh              # container test suite
├── grade.sh             # local grading script (supplied by instructor)
└── app/
    ├── diagnostic.sh    # the CLI
    └── health-check.sh  # self-test used by the Docker HEALTHCHECK
```

## Requirements

- Docker Engine
- Docker Compose v2 (`docker compose`)
- Bash, to run `test.sh` and `grade.sh`

## Build

```bash
git clone <your-repository-url>
cd assignment-2
chmod +x grade.sh test.sh app/*.sh
docker build -t diagnostic-tool .
```

## Usage

```bash
docker run --rm diagnostic-tool help
docker run --rm diagnostic-tool system
docker run --rm diagnostic-tool disk
docker run --rm diagnostic-tool network example.com
```

Running the image with no arguments prints the help text.

With Docker Compose:

```bash
docker compose run --rm diagnostic system
docker compose run --rm diagnostic network localhost
```

### Commands

| Command | Description |
|---------|-------------|
| `system` | Hostname, user, date, OS, kernel, uptime, CPU, memory, working directory |
| `network <host>` | Validates the host, resolves it and pings it |
| `disk` | Shows disk usage for the mounted filesystems |
| `help` | Shows usage |

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | success |
| 1 | operational failure (for example the host could not be resolved or pinged) |
| 2 | invalid command, missing argument or invalid input |

## Docker design

- Base image `alpine:3.20`, which keeps the image small (about 15 MB).
- Only `bash` is installed on top of the base image, because the scripts use Bash features.
- `ENTRYPOINT` is the CLI, so arguments after the image name become the command.
  `CMD ["help"]` supplies the default.
- `.dockerignore` keeps `.git`, logs and repository files out of the build context.
- `HEALTHCHECK` runs `app/health-check.sh`, which checks that the CLI is
  executable and that the tools it needs exist. It can also be run by hand:

```bash
docker run --rm --entrypoint /app/health-check.sh diagnostic-tool
```

## Testing

```bash
./test.sh
./grade.sh
```

`test.sh` builds the image and runs nine checks against it, covering help,
system, disk, the default command, invalid commands, a missing host, an invalid
host, a resolvable host and an unresolvable host. It exits 0 only if every
check passes.

## Git workflow

Work was done on `feature/diagnostic-cli` and merged into `main` with a merge
commit. The feature branch was kept for history.

## Assumptions

- Docker Engine and Docker Compose v2 are installed and the Docker daemon is running. The first build needs internet access to download the Alpine base image and install `bash`.
- The `network` command needs outbound network access and DNS from inside the container. If ICMP (ping) is blocked on the network, the ping check reports a failure and the command exits with code 1.
- The `system` command reports the container's operating system and hostname, but the kernel version, uptime, CPU and memory come from the host, because containers share the host's kernel.
- The container runs as root, because the Dockerfile has no `USER` instruction. This is acceptable because the tool only reads information, but a production image would use a non-root user.
- `test.sh` and `grade.sh` need a running Docker daemon, since they build and run the image. The network tests use `localhost` and a deliberately invalid hostname, so they do not depend on internet access once the image is built.
