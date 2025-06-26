#!/bin/bash


TOUCHPAD_ID=$(xinput | rg Touchpad | awk -F'id=' '{print $2}' | awk '{print $1}')

xinput set-prop $TOUCHPAD_ID "libinput Tapping Enabled" 1
xinput set-prop $TOUCHPAD_ID "libinput Natural Scrolling Enabled" 1
