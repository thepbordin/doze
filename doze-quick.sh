#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Doze > Quick Doze
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🚀
# @raycast.packageName Doze

# Documentation:
# @raycast.description Prevent sleep (incl. lid close) for 5 minutes
# @raycast.author thepbordin
# @raycast.authorURL https://raycast.com/thepbordin

MINUTES=5
TOTAL_SECONDS=$(( MINUTES * 60 ))

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

sudo "$SCRIPT_DIR/helpers/doze-on.sh" "$TOTAL_SECONDS"

if [ $? -ne 0 ]; then
  echo "Failed to start doze"
  exit 1
fi

echo $(( $(date +%s) + TOTAL_SECONDS )) > /tmp/doze.end

echo "Sleep disabled for ${MINUTES}m"
