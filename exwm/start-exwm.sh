#!/bin/bash

picom &
# Start the D-Bus session
#exec dbus-launch --exit-with-session /usr/local/emacs29.3-x11/bin/emacs -mm
xss-lock -- slock &
/usr/local/emacs29.3-x11/bin/emacs -mm -l ~/.config/exwm/desktop.el
