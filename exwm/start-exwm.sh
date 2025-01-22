#!/bin/sh

# Ensure the script is executable
chmod +x /home/anthe/.dotfiles/exwm/start-exwm.sh

# Start the D-Bus session
exec dbus-launch --exit-with-session emacs -mm --debug-init
