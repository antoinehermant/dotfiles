#!/bin/sh

# Start the D-Bus session
exec dbus-launch --exit-with-session /usr/local/emacs29.3-x11/bin/emacs -mm --debug-init
