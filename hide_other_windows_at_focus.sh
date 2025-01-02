#!/bin/bash

# Delay for 0.5 seconds to ensure the Alt-Tab action is processed
#sleep 0.5

# Get the ID of the currently focused window
current_window_id=$(xdotool getactivewindow)

# Get the list of all visible windows
for win in $(xdotool search --onlyvisible --name .); do
    if [ "$win" != "$current_window_id" ]; then
        xdotool windowminimize $win  # Minimize all other windows
    fi
done
