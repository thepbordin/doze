# Doze

Raycast script commands to prevent your Mac from sleeping — including lid close — for a set duration using `pmset disablesleep`.

## Commands

| Command | Description |
|---------|-------------|
| **Doze > Start** | Set hours and minutes to prevent sleep. Automatically re-enables when time is up. |
| **Doze > Stop** | Cancel active doze early and re-enable sleep. |
| **Doze > Status** | Check remaining doze time. |

## Setup

### 1. Clone and add to Raycast

```bash
git clone <repo-url> && cd doze
chmod +x doze-start.sh doze-stop.sh doze-status.sh
chmod 555 helpers/doze-on.sh helpers/doze-off.sh
```

In Raycast: **Settings > Extensions > Script Commands > Add Directory** > select the `doze/` folder.

### 2. Configure passwordless sudo (one-time)

The helper scripts require root to run `pmset`. Grant passwordless sudo to avoid prompts:

```bash
sudo visudo -f /etc/sudoers.d/doze
```

Add these lines, replacing `<YOUR_USERNAME>` with your macOS username (`whoami`) and `<PATH_TO_DOZE>` with the absolute path to this folder:

```
<YOUR_USERNAME> ALL=(ALL) NOPASSWD: <PATH_TO_DOZE>/helpers/doze-on.sh
<YOUR_USERNAME> ALL=(ALL) NOPASSWD: <PATH_TO_DOZE>/helpers/doze-off.sh
```

Save and exit (`:wq` in vi, or `ctrl+X` in nano via `sudo EDITOR=nano visudo -f /etc/sudoers.d/doze`).

## How it works

```
doze/
├── doze-start.sh       # Raycast entry: validates input, calls helper via sudo
├── doze-stop.sh        # Raycast entry: cancels timer, calls helper via sudo
├── doze-status.sh      # Raycast entry: reads /tmp/doze.end for remaining time
└── helpers/
    ├── doze-on.sh      # (root) pmset disablesleep 1 + background auto-reenable timer
    └── doze-off.sh     # (root) kills timer + pmset disablesleep 0
```

- **Start** runs `pmset -a disablesleep 1` and spawns a background process that waits the duration then re-enables sleep automatically.
- PID tracked in `/tmp/doze.pid`, end timestamp in `/tmp/doze.end`.
- **Stop** kills the background timer and runs `pmset -a disablesleep 0`.
- Helper scripts should be locked read-only (`chmod 555`) since they run as root via sudoers.

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
