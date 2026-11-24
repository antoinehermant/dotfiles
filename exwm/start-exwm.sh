#!/bin/bash

# The login goes straight to the loading screen (bin/anthe-splash), until
# Emacs is ready: no blank screen nor blinks meanwhile
xsetroot -solid '#011627'
export ANTHE_SPLASH="${XDG_RUNTIME_DIR:-/tmp}/anthe-splash"
rm -f "$ANTHE_SPLASH"
~/.dotfiles/bin/anthe-splash &

compton &
# Start the D-Bus session
#exec dbus-launch --exit-with-session /usr/local/emacs29.3-x11/bin/emacs -mm
# xss-lock -- slock &
emacs -mm -l ~/.config/exwm/desktop.el
#
# exec dbus-launch --exit-with-session emacs -mm -l ~/.config/exwm/desktop.el --debug-init
