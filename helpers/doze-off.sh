#!/bin/bash
# Cancels sleep prevention and kills background timer.
# Called via sudo from the Raycast "Doze > Stop" script.

if [ -f /tmp/doze.pid ]; then
  PID=$(cat /tmp/doze.pid)
  kill "$PID" 2>/dev/null
fi

pmset -a disablesleep 0
rm -f /tmp/doze.pid /tmp/doze.end
