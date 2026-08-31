#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Status
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🔍
# @raycast.packageName Doze

# Documentation:
# @raycast.description Check remaining doze time
# @raycast.author thepbordin
# @raycast.authorURL https://raycast.com/thepbordin

if [ ! -f /tmp/doze.end ]; then
  echo "No active doze"
  exit 0
fi

END_TIME=$(cat /tmp/doze.end)
NOW=$(date +%s)
REMAINING=$(( END_TIME - NOW ))

if [ "$REMAINING" -le 0 ]; then
  rm -f /tmp/doze.end
  echo "Doze expired"
  exit 0
fi

HOURS=$(( REMAINING / 3600 ))
MINS=$(( (REMAINING % 3600) / 60 ))

if [ "$HOURS" -gt 0 ]; then
  echo "Dozing — ${HOURS}h ${MINS}m remaining"
else
  echo "Dozing — ${MINS}m remaining"
fi
