#!/bin/bash
# Enables lid-close sleep prevention and starts a background timer to re-enable.
# Called via sudo from the Raycast "Doze > Start" script.
# Usage: doze-on.sh <seconds>

SECONDS_TO_SLEEP="$1"

if [ -z "$SECONDS_TO_SLEEP" ] || [ "$SECONDS_TO_SLEEP" -le 0 ] 2>/dev/null; then
  exit 1
fi

if [ -f /tmp/doze.pid ]; then
  OLD_PID=$(cat /tmp/doze.pid)
  kill "$OLD_PID" 2>/dev/null
fi

pmset -a disablesleep 1

(
  sleep "$SECONDS_TO_SLEEP"
  pmset -a disablesleep 0
  rm -f /tmp/doze.pid /tmp/doze.end
) &

echo $! > /tmp/doze.pid
chmod 666 /tmp/doze.pid
