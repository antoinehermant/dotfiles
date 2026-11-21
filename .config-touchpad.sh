#!/bin/bash
# The touchpad: tap to click and natural scrolling, with either X driver.
# Run at login by ~/.profile.
#
# libinput (the default): its own properties.  synaptics (the package
# xserver-xorg-input-synaptics, when installed, takes the touchpad): it taps
# already and scrolls on with momentum after a flick ("coasting"); natural
# scrolling is a negative scroll distance, and syndaemon stops tapping and
# scrolling while typing, as libinput does.

TOUCHPAD=$(xinput list --name-only | grep -m1 Touchpad)
[ -n "$TOUCHPAD" ] || exit 0

if xinput list-props "$TOUCHPAD" | grep -q "libinput Tapping Enabled"; then
    xinput set-prop "$TOUCHPAD" "libinput Tapping Enabled" 1
    xinput set-prop "$TOUCHPAD" "libinput Natural Scrolling Enabled" 1
elif xinput list-props "$TOUCHPAD" | grep -q "Synaptics Scrolling Distance"; then
    distance=$(xinput list-props "$TOUCHPAD" | sed -n 's/.*Synaptics Scrolling Distance ([0-9]*):[[:space:]]*-\{0,1\}\([0-9]*\),.*/\1/p')
    xinput set-prop "$TOUCHPAD" "Synaptics Scrolling Distance" -"${distance:-85}" -"${distance:-85}"
    xinput set-prop "$TOUCHPAD" "Synaptics Palm Detection" 1
    pgrep -u "$USER" -x syndaemon >/dev/null || syndaemon -i 0.5 -t -K -R -d
fi
