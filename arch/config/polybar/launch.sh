#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# is uname -a contains Linux archwise-mpb
if [[ $(uname -a) == *"archwise-mbp"* ]]; then
    polybar floater_laptop 2>&1 | tee -a /tmp/polybar1.log & disown
else
    polybar floater_desktop 2>&1 | tee -a /tmp/polybar1.log & disown
fi
