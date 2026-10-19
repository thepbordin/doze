# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Doze is a set of Raycast script commands (plain bash, macOS only) that keep a Mac awake, including with the lid closed, via `pmset -a disablesleep`. There is no build, lint, or test tooling. Verify changes by running the scripts and checking `pmset -g | grep SleepDisabled` (1 = active, 0 = inactive).

## Architecture

Two layers, split by privilege:

- **Raycast entry scripts** (`doze-start.sh`, `doze-quick.sh`, `doze-toggle.sh`, `doze-stop.sh`, `doze-status.sh`) run as the user. Each begins with a `# @raycast.*` header block that Raycast parses (title, mode, icon, arguments). Keep the header format intact when editing. Start, Quick, Toggle and Stop use `silent` mode; Status uses `compact`. Toggle reads `/tmp/doze.end` to decide between calling `doze-on.sh 0` (no timer) and `doze-off.sh`.
- **Root helpers** (`helpers/doze-on.sh`, `helpers/doze-off.sh`) run via `sudo` and are the only code that calls `pmset`. The repo copies are only the source: `install.sh` copies them to `/Library/Doze/` and the entry scripts run them from there. `lib/doze-common.sh` (sourced by the entry scripts, not a Raycast command) holds the install path and `doze_require_helpers`, which fails if the helpers are missing, or with `current` if they differ from the repo copies. Stop and Toggle-off only require them to be installed so a stale helper never blocks turning sleep back on.

State lives in two files in `/tmp`, shared across the layers:

- `/tmp/doze.pid`: PID of the background timer subshell. Written by `doze-on.sh`, killed by `doze-off.sh` and by `doze-on.sh` on restart.
- `/tmp/doze.end`: epoch end time, or the literal `inf` for a Toggle doze with no timer (no `/tmp/doze.pid` exists then). Written by `doze-start.sh` / `doze-toggle.sh` after the helper returns. Read by `doze-status.sh` and `doze-stop.sh` to report remaining time. It is the only source of truth for "is doze active" in Status.

The timer is a backgrounded subshell in `doze-on.sh` that sleeps, runs `pmset -a disablesleep 0`, clears both `/tmp` files, and runs `pmset sleepnow` if the lid is closed (detected via `ioreg AppleClamshellState`).

## Security constraints

The helpers run as root through a passwordless sudoers entry (`/etc/sudoers.d/doze`, written by `install.sh`) that names their exact paths. Anything that can replace those paths can escalate to root. Therefore:

- The helpers must run from `/Library/Doze/`, where every directory in the path is root-owned. Never point sudoers at a path inside the repo: the repo directory is user-owned, so anything running as the user (or a `git pull`) can unlink a root-owned file there and substitute its own, regardless of the file's owner or mode. Making the files `root:wheel 555` inside the repo does not help.
- `install.sh` also prunes stale sudo entries (any `NOPASSWD` line for a `doze-on.sh`/`doze-off.sh` outside `/Library/Doze`) from `/etc/sudoers.d/*`, with a `.doze-bak` backup, and only warns about `/etc/sudoers`. Keep that scan matching the helper filenames in `HELPERS`.
- Editing a helper means editing `helpers/` and re-running `sudo ./install.sh`, which shows the diff and asks before installing. Keep `install.sh` and the sudoers content in sync with `DOZE_HELPERS` in `lib/doze-common.sh`.
- Keep helper logic minimal and do not have them source or execute anything user-writable. The `/tmp` state files are user-writable and the helpers read the PID from one, so treat that value as untrusted.
- Do not add new helper scripts without adding them to `HELPERS` in `install.sh` and `DOZE_HELPERS` in `lib/doze-common.sh`, and documenting them in `README.md`.
