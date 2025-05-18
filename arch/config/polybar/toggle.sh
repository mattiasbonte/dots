#!/usr/bin/env bash
# FIX: DOESN'T WORK

# Terminate already running bar instances
killall -q polybar

# Launch the bar
polybar FLOATER 2>&1 | tee -a /tmp/polybar1.log & disown
polybar-msg cmd toggle
