#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Doze > Stop
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 😴
# @raycast.packageName Doze

# Documentation:
# @raycast.description Cancel active doze and re-enable sleep
# @raycast.author thepbordin
# @raycast.authorURL https://raycast.com/thepbordin

SLEEP_DISABLED=$(pmset -g | awk '$1 == "SleepDisabled" { print $2 }')

if [ ! -f /tmp/doze.pid ] && [ ! -f /tmp/doze.end ] && [ "$SLEEP_DISABLED" != "1" ]; then
  echo "No active doze"
  exit 0
fi

REMAINING=0
if [ -f /tmp/doze.end ]; then
  END_TIME=$(cat /tmp/doze.end)
  if [[ "$END_TIME" =~ ^[0-9]+$ ]]; then
    NOW=$(date +%s)
    REMAINING=$(( END_TIME - NOW ))
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/doze-common.sh"
doze_require_helpers

sudo "$DOZE_HELPER_DIR/doze-off.sh"

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
