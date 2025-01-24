#!/bin/bash

alias gossd_anthe="cd /media/anthe/ssd_anthe"
alias goanthe_ext_drive_1="cd /media/anthe/anthe_ext_drive_1"
alias gomisu="cd /home/anthe/misu"
alias da="du -sm .[^.]* * 2>/dev/null"
alias ds="du -sh"
alias e="emacsclient -n"
alias ew="emacsclient -nw"
#alias emacs="bash /home/anthe/.dotfiles/emacsclient-startup.sh"
if [ -n "$INSIDE_EMACS" ]; then
    export EDITOR="emacsclient -n"
    export VISUAL="emacsclient -n"
else
    export EDITOR="emacs -nw"
    export VISUAL="emacs -nw"
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

PS1="[\u | \W] 🐧 "

function ubelix() {
    MOUNT_POINT="$HOME/ubelix"  
    REMOTE="ubelix3:/"

    if ! mountpoint -q "$MOUNT_POINT"; then
        echo "Mounting $REMOTE to $MOUNT_POINT..."
        sshfs "$REMOTE" "$MOUNT_POINT"

        if mountpoint -q "$MOUNT_POINT"; then
            echo "Successfully mounted. Navigating to $MOUNT_POINT..."
        else
            echo "Failed to mount $REMOTE."
            return 1
        fi
    fi

    cd "$MOUNT_POINT" || return 1
}

function hermant() {
    ubelix
    LOCATION="$MOUNT_POINT/storage/workspaces/climate_charibdis/climate_ism/hermant/"
    cd "$LOCATION" || return 1
}

function charibdis() {
    ubelix
    LOCATION="$MOUNT_POINT/storage/workspaces/climate_charibdis/climate_ism/"
    cd "$LOCATION" || return 1
}

function filepath() {
    function="find $(pwd) -maxdepth 1 -name $1 -type f"
    $function | clip
}

function clip() {
    tr -d '\n' | xsel --clipboard --input
}

kuproxy() {
	socks_host="localhost"
	socks_port="1080"
	gsettings set org.gnome.system.proxy mode 'manual'
	gsettings set org.gnome.system.proxy.socks host "$socks_host"
	gsettings set org.gnome.system.proxy.socks port "$socks_port"
	trap "disable_proxy" EXIT
	ssh -D "$socks_port" kupflores
}

disable_proxy() {
    # Disable system proxy settings
    gsettings set org.gnome.system.proxy mode 'none'
    echo "System proxy disabled."
}

rsynckup() {

    rsync -auv $(cat /home/anthe/kup/.rsync.conf) /home/anthe/kup/ kupflores:/home/hermant/kup/
    rsync -auv $(cat /home/anthe/kup/.rsync.conf) kupflores:/home/hermant/kup/ /home/anthe/kup/

    rsync -auv $(cat /home/anthe/kup/.rsync.conf) /home/anthe/kup/ ubelix2:/storage/homefs/ah23k256/kup/
    rsync -auv $(cat /home/anthe/kup/.rsync.conf) ubelix2:/storage/homefs/ah23k256/kup/ /home/anthe/kup/

    rclone sync --delete-during /home/anthe/kup/notes gdrive:/kup/notes
}
