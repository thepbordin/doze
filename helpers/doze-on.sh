#!/bin/bash
# Enables lid-close sleep prevention and starts a background timer to re-enable.
# Called via sudo from the Raycast "Doze > Start" script.
# Usage: doze-on.sh <seconds>   (0 = no timer, stays on until doze-off.sh)

SECONDS_TO_SLEEP="$1"

if ! [[ "$SECONDS_TO_SLEEP" =~ ^[0-9]+$ ]]; then
  exit 1
fi

if [ -f /tmp/doze.pid ]; then
  OLD_PID=$(cat /tmp/doze.pid)
  kill "$OLD_PID" 2>/dev/null
  rm -f /tmp/doze.pid
fi

pmset -a disablesleep 1

if [ "$SECONDS_TO_SLEEP" -eq 0 ]; then
  exit 0
fi

(
  sleep "$SECONDS_TO_SLEEP"
  pmset -a disablesleep 0
  rm -f /tmp/doze.pid /tmp/doze.end
  LID_CLOSED=$(ioreg -r -k AppleClamshellState -d 4 | grep AppleClamshellState | head -1)
  if echo "$LID_CLOSED" | grep -q "Yes"; then
    pmset sleepnow
  fi
) &

echo $! > /tmp/doze.pid
chmod 644 /tmp/doze.pid
