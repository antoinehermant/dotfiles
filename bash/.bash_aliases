#!/bin/bash

alias gossd_anthe="cd /media/anthe/ssd_anthe"
alias goanthe_ext_drive_1="cd /media/anthe/anthe_ext_drive_1"
alias gomisu="cd /home/anthe/misu"
alias da="du -sh .[^.]* * 2>/dev/null"
alias ds="du -sh"
alias e="emacsclient -n"
alias ew="emacsclient -nw"
alias v="~/software/nvim-linux-x86_64/bin/nvim"
#alias emacs="bash /home/anthe/.dotfiles/emacsclient-startup.sh"

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'


# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
