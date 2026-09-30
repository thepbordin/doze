# Doze

Raycast script commands to prevent your Mac from sleeping — including lid close — for a set duration using `pmset disablesleep`.

## Commands

| Command | Description |
|---------|-------------|
| **Doze > Start** | Set hours and minutes to prevent sleep. Automatically re-enables when time is up. |
| **Doze > Quick Start** | One-click 5 minute doze, no input needed. Change `MINUTES` in `doze-quick.sh` to adjust. |
| **Doze > Stop** | Cancel active doze early and re-enable sleep. |
| **Doze > Status** | Check remaining doze time. |

## Setup

### 1. Clone and add to Raycast

```bash
git clone https://github.com/thepbordin/doze.git && cd doze
chmod +x doze-start.sh doze-quick.sh doze-stop.sh doze-status.sh
```

In Raycast: **Settings > Extensions > Script Commands > Add Directory** > select the `doze/` folder.

### 2. Lock helper scripts (MANDATORY)

> **This step is required.** The helper scripts run as root via sudo. Without this, any user-level process could modify them and escalate to root. Git does not preserve ownership or permissions on clone.

```bash
sudo chown root:wheel helpers/doze-on.sh helpers/doze-off.sh
sudo chmod 555 helpers/doze-on.sh helpers/doze-off.sh
```

Verify:

```bash
ls -l helpers/
# Expected: -r-xr-xr-x  root  wheel  for both files
```

### 3. Configure passwordless sudo (one-time)

The helper scripts require root to run `pmset`. Grant passwordless sudo to avoid prompts:
Add these lines (copy-paste friendly — `$USER` and `$(pwd)` resolve automatically):

```bash
echo "$USER ALL=(ALL) NOPASSWD: $(pwd)/helpers/doze-on.sh" | sudo tee -a /etc/sudoers.d/doze
echo "$USER ALL=(ALL) NOPASSWD: $(pwd)/helpers/doze-off.sh" | sudo tee -a /etc/sudoers.d/doze
```

Or manually via `sudo visudo -f /etc/sudoers.d/doze` (`:wq` to save in vi, `ctrl+X` in nano via `sudo EDITOR=nano visudo -f /etc/sudoers.d/doze`).

## How it works

```
doze/
├── doze-start.sh       # Raycast entry: validates input, calls helper via sudo
├── doze-quick.sh       # Raycast entry: fixed 5 minute doze, calls helper via sudo
├── doze-stop.sh        # Raycast entry: cancels timer, calls helper via sudo
├── doze-status.sh      # Raycast entry: reads /tmp/doze.end for remaining time
└── helpers/
    ├── doze-on.sh      # (root) pmset disablesleep 1 + background auto-reenable timer
    └── doze-off.sh     # (root) kills timer + pmset disablesleep 0
```

- **Start** runs `pmset -a disablesleep 1` and spawns a background process that waits the duration then re-enables sleep automatically.
- PID tracked in `/tmp/doze.pid`, end timestamp in `/tmp/doze.end`.
- **Stop** kills the background timer and runs `pmset -a disablesleep 0`.
- Helper scripts must be owned by `root:wheel` and locked read-only (`chmod 555`) to prevent privilege escalation.

## Verify

```bash
pmset -g | grep disablesleep
# disablesleep 1 = active, disablesleep 0 = inactive
```

## Requirements

- macOS
- [Raycast](https://raycast.com)

## License

MIT
