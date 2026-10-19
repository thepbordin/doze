# Doze

Raycast script commands to prevent your Mac from sleeping — including lid close — for a set duration using `pmset disablesleep`.

## Commands

| Command | Description |
|---------|-------------|
| **Doze > Start** | Set hours and minutes to prevent sleep. Defaults to 5 minutes if both are left blank. Automatically re-enables when time is up. |
| **Doze > Quick Start** | One-click 5 minute doze, no input needed. Change `MINUTES` in `doze-quick.sh` to adjust. |
| **Doze > Toggle** | One command to flip doze on or off. Starts a doze with no time limit if inactive, stops it if active. |
| **Doze > Stop** | Cancel active doze early and re-enable sleep. Also works when the state files are gone but sleep is still disabled. |
| **Doze > Status** | Check remaining doze time. |

## Setup

### 1. Clone and add to Raycast

```bash
git clone https://github.com/thepbordin/doze.git && cd doze
chmod +x doze-start.sh doze-quick.sh doze-toggle.sh doze-stop.sh doze-status.sh
```

In Raycast: **Settings > Extensions > Script Commands > Add Directory** > select the `doze/` folder.

### 2. Install the root helpers (one-time, needs your password)

`pmset` needs root, so doze uses two small helper scripts run through passwordless `sudo`. They are installed to `/Library/Doze/`, where every directory in the path is root-owned, so nothing running as your user can replace them. The copy in this repo is only the source.

```bash
sudo ./install.sh
```

The installer shows you a diff of what will run as root and asks before installing. It then:

- copies `helpers/doze-on.sh` and `helpers/doze-off.sh` to `/Library/Doze/` (`root:wheel`, mode `555`)
- writes `/etc/sudoers.d/doze` (validated with `visudo`) allowing only those two paths, for your user. This **replaces** any older doze entries in that file.

Use `sudo ./install.sh --yes` to skip the prompt, and `sudo ./install.sh --uninstall` to remove everything.

## Updating

```bash
git pull
sudo ./install.sh   # only needed when helpers/ changed; safe to re-run anytime
```

You don't have to remember: if the installed helpers differ from the repo's, Start, Quick Start and Toggle refuse to run and tell you to re-run `sudo ./install.sh`. Stop never waits on this, so you can always turn sleep back on.

### Upgrading from the old setup

Older versions ran the helpers straight from the repo and needed `chown`/`chmod` after cloning. That did not actually protect against privilege escalation, because the repo directory is user-owned and so any file in it can be swapped out. Run `sudo ./install.sh` once. It moves the helpers to `/Library/Doze/` and **prunes the old sudo entries**, so the repo copies stop being trusted.

Old entries are dangerous even when the file they point to is gone (for example a deleted `~/.myscripts/...` copy): the path is user-writable, so anything running as you could recreate it and get root. The installer scans `/etc/sudoers.d/*` (and warns about `/etc/sudoers`) for any passwordless entry on a `doze-on.sh` / `doze-off.sh` outside `/Library/Doze/`, lists each one, and removes it after you confirm. Other lines in those files are kept, and the original is saved next to it as `<name>.doze-bak` (sudo ignores files with a dot in the name, so the backup is inert). Anything else that pointed at the old paths, such as another checkout of this repo, stops working until you run its installer.

Raycast may still list the old script directory (Raycast keeps these in its encrypted database, under Script Commands). Remove stale ones in **Settings > Extensions > Script Commands**; it only affects the Raycast list and carries no privilege.

## How it works

```
doze/
├── doze-start.sh       # Raycast entry: validates input, calls installed helper via sudo
├── doze-quick.sh       # Raycast entry: fixed 5 minute doze
├── doze-toggle.sh      # Raycast entry: starts (no timer) or stops depending on /tmp/doze.end
├── doze-stop.sh        # Raycast entry: cancels timer and re-enables sleep
├── doze-status.sh      # Raycast entry: reads /tmp/doze.end for remaining time
├── install.sh          # (sudo) installs helpers to /Library/Doze + writes the sudoers entry
├── lib/
│   └── doze-common.sh  # sourced by entry scripts: checks installed helpers are present/current
└── helpers/            # source of the root helpers; not executed from here
    ├── doze-on.sh      # pmset disablesleep 1 + background auto-reenable timer (0 = no timer)
    └── doze-off.sh     # kills timer + pmset disablesleep 0
```

- **Start** runs `pmset -a disablesleep 1` and spawns a background process that waits the duration then re-enables sleep automatically.
- PID tracked in `/tmp/doze.pid`, end timestamp in `/tmp/doze.end` (`inf` for a Toggle doze with no timer).
- **Stop** kills the background timer and runs `pmset -a disablesleep 0`.
- Only `/Library/Doze/doze-on.sh` and `/Library/Doze/doze-off.sh` can be run as root without a password.

## Verify

```bash
pmset -g | grep SleepDisabled
# SleepDisabled 1 = active, SleepDisabled 0 = inactive
ls -l /Library/Doze/
# Expected: -r-xr-xr-x  root  wheel  for both files
```

## Requirements

- macOS
- [Raycast](https://raycast.com)

## License

MIT
