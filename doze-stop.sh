#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Stop
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 😴
# @raycast.packageName Doze

# Documentation:
# @raycast.description Cancel active doze and re-enable sleep
# @raycast.author thepbordin
# @raycast.authorURL https://raycast.com/thepbordin

if [ ! -f /tmp/doze.pid ] && [ ! -f /tmp/doze.end ]; then
  echo "No active doze"
  exit 0
fi

REMAINING=0
if [ -f /tmp/doze.end ]; then
  END_TIME=$(cat /tmp/doze.end)
  NOW=$(date +%s)
  REMAINING=$(( END_TIME - NOW ))
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

sudo "$SCRIPT_DIR/helpers/doze-off.sh"

if [ $? -ne 0 ]; then
  echo "Failed to stop doze"
  exit 1
fi

rm -f /tmp/doze.end

if [ "$REMAINING" -gt 60 ]; then
  MINS=$(( REMAINING / 60 ))
  echo "Sleep re-enabled (cancelled ${MINS}m remaining)"
else
  echo "Sleep re-enabled"
fi
