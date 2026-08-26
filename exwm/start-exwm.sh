#!/bin/bash

compton &
# Start the D-Bus session
#exec dbus-launch --exit-with-session /usr/local/emacs29.3-x11/bin/emacs -mm
# xss-lock -- slock &
emacs -mm -l ~/.config/exwm/desktop.el
#
# exec dbus-launch --exit-with-session emacs -mm -l ~/.config/exwm/desktop.el --debug-init
