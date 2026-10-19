# Doze

Raycast commands that keep your Mac awake, even with the lid closed.

| Command | What it does |
|---------|--------------|
| **Doze > Toggle** | Flip doze on (no time limit) or off |
| **Doze > Start** | Doze for a set time (hours, minutes). Blank = 5 min |
| **Doze > Quick Start** | One-click 5 min doze |
| **Doze > Stop** | Stop now and re-enable sleep |
| **Doze > Status** | Show time remaining |

## Setup

```bash
git clone https://github.com/thepbordin/doze.git && cd doze
sudo ./install.sh
```

Then in Raycast: **Settings > Extensions > Script Commands > Add Directory** and pick the `doze/` folder.

`install.sh` shows you what will run as root, asks, then installs two helper scripts to `/Library/Doze/` and a matching passwordless-`sudo` entry. It also removes any older doze sudo entries.

## Updating

```bash
git pull && sudo ./install.sh
```

If you forget, Start, Quick Start and Toggle tell you to re-run it. Stop always works.

Upgrading from an older version? Same command; it migrates you. Remove stale script directories in Raycast's settings if it still lists old ones.

## Uninstall

```bash
sudo ./install.sh --uninstall
```

## Check it

```bash
pmset -g | grep SleepDisabled   # 1 = awake, 0 = normal sleep
```

## Why a separate install step?

`pmset` needs root. The helpers run as root through `sudo`, so they live in a root-owned folder rather than in this repo, where any process running as you could swap them out. Details are in [CLAUDE.md](CLAUDE.md).

Requires macOS and [Raycast](https://raycast.com). MIT license.
