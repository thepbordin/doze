#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Doze > Toggle
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🌙
# @raycast.packageName Doze

# Documentation:
# @raycast.description Toggle doze: start (no time limit) if inactive, stop if active
# @raycast.author thepbordin
# @raycast.authorURL https://raycast.com/thepbordin

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/doze-common.sh"

ACTIVE=0
if [ -f /tmp/doze.end ]; then
  END_TIME=$(cat /tmp/doze.end)
  if [ "$END_TIME" = "inf" ]; then
    ACTIVE=1
  elif [[ "$END_TIME" =~ ^[0-9]+$ ]] && [ "$END_TIME" -gt "$(date +%s)" ]; then
    ACTIVE=1
  fi
fi

if [ "$ACTIVE" -eq 1 ]; then
  doze_require_helpers
  sudo "$DOZE_HELPER_DIR/doze-off.sh"

  if [ $? -ne 0 ]; then
    echo "Failed to stop doze"
    exit 1
  fi

  rm -f /tmp/doze.end
  echo "Sleep re-enabled"
else
  # 0 = no timer; stays on until toggled off or stopped
  doze_require_helpers current
  sudo "$DOZE_HELPER_DIR/doze-on.sh" 0

  if [ $? -ne 0 ]; then
    echo "Failed to start doze"
    exit 1
  fi

  echo "inf" > /tmp/doze.end
  echo "Sleep disabled until toggled off"
fi
