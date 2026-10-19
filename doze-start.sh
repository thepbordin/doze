#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Doze > Start
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ⚡
# @raycast.packageName Doze
# @raycast.argument1 { "type": "text", "placeholder": "Hours (0)", "optional": true }
# @raycast.argument2 { "type": "text", "placeholder": "Minutes (0)", "optional": true }

# Documentation:
# @raycast.description Prevent sleep (incl. lid close) for a set duration (5 minutes if left blank)
# @raycast.author thepbordin
# @raycast.authorURL https://raycast.com/thepbordin

if [ -z "$1" ] && [ -z "$2" ]; then
  HOURS=0
  MINUTES=5
else
  HOURS="${1:-0}"
  MINUTES="${2:-0}"
fi

if ! [[ "$HOURS" =~ ^[0-9]+$ ]] || ! [[ "$MINUTES" =~ ^[0-9]+$ ]]; then
  echo "Enter valid numbers"
  exit 1
fi

TOTAL_SECONDS=$(( (HOURS * 3600) + (MINUTES * 60) ))

if [ "$TOTAL_SECONDS" -le 0 ]; then
  echo "Set at least 1 minute"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/doze-common.sh"
doze_require_helpers current

sudo "$DOZE_HELPER_DIR/doze-on.sh" "$TOTAL_SECONDS"

if [ $? -ne 0 ]; then
  echo "Failed to start doze"
  exit 1
fi

END_TIME=$(( $(date +%s) + TOTAL_SECONDS ))
echo "$END_TIME" > /tmp/doze.end

if [ "$HOURS" -gt 0 ] && [ "$MINUTES" -gt 0 ]; then
  echo "Sleep disabled for ${HOURS}h ${MINUTES}m"
elif [ "$HOURS" -gt 0 ]; then
  echo "Sleep disabled for ${HOURS}h"
else
  echo "Sleep disabled for ${MINUTES}m"
fi
