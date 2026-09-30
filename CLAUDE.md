# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Doze is a set of Raycast script commands (plain bash, macOS only) that keep a Mac awake, including with the lid closed, via `pmset -a disablesleep`. There is no build, lint, or test tooling. Verify changes by running the scripts and checking `pmset -g | grep disablesleep` (1 = active, 0 = inactive).

## Architecture

Two layers, split by privilege:

- **Raycast entry scripts** (`doze-start.sh`, `doze-quick.sh`, `doze-stop.sh`, `doze-status.sh`) run as the user. Each begins with a `# @raycast.*` header block that Raycast parses (title, mode, icon, arguments). Keep the header format intact when editing. Start and Stop use `silent` mode; Status uses `compact`.
- **Root helpers** (`helpers/doze-on.sh`, `helpers/doze-off.sh`) run via `sudo` and are the only code that calls `pmset`. The entry scripts locate them with `$(dirname "$0")/helpers/...`.

State lives in two files in `/tmp`, shared across the layers:

- `/tmp/doze.pid`: PID of the background timer subshell. Written by `doze-on.sh`, killed by `doze-off.sh` and by `doze-on.sh` on restart.
- `/tmp/doze.end`: epoch end time. Written by `doze-start.sh` after the helper returns. Read by `doze-status.sh` and `doze-stop.sh` to report remaining time. It is the only source of truth for "is doze active" in Status.

The timer is a backgrounded subshell in `doze-on.sh` that sleeps, runs `pmset -a disablesleep 0`, clears both `/tmp` files, and runs `pmset sleepnow` if the lid is closed (detected via `ioreg AppleClamshellState`).

## Security constraints

The helpers run as root through a passwordless sudoers entry that names their exact paths (`/etc/sudoers.d/doze`). Anything that can write to them can escalate to root. Therefore:

- The helpers must stay `root:wheel` with mode `555`. Git does not preserve ownership, so this is a manual post-clone step documented in `README.md`. Editing a helper requires `sudo` and must be followed by re-applying the `chown` and `chmod`.
- Keep helper logic minimal and do not have them source or execute anything user-writable. The `/tmp` state files are user-writable and the helpers read the PID from one, so treat that value as untrusted.
- Do not add new helper scripts without also documenting the matching sudoers line and lock-down step in `README.md`.
