#!/bin/bash

ln -sf ~/.dotfiles/bash/.bash_aliases ~/.bash_aliases
ln -sf ~/.dotfiles/bash/.bash_functions ~/.bash_functions
ln -sf ~/.dotfiles/bash/.bash_exports ~/.bash_exports
ln -sf ~/.dotfiles/bash/.bash_tweaks ~/.bash_tweaks

# mbsync config
ln -sf ~/.dotfiles/rcfiles/.mbsyncrc ~/.mbsyncrc

# gpg-agent config (passphrase window and cache)
mkdir -p ~/.gnupg && chmod 700 ~/.gnupg
ln -sf ~/.dotfiles/rcfiles/gpg-agent.conf ~/.gnupg/gpg-agent.conf

# OAuth2 tokens for the UniBe mail (mbsync, Emacs)
mkdir -p ~/.local/bin
ln -sf ~/.dotfiles/bin/ms365-token ~/.local/bin/ms365-token

# Sync the inboxes as soon as mail arrives (started by Emacs with mu4e)
ln -sf ~/.dotfiles/bin/mail-idle ~/.local/bin/mail-idle
# and sync saved drafts and sent messages at once (run by Emacs)
ln -sf ~/.dotfiles/bin/mail-sync-folder ~/.local/bin/mail-sync-folder

# Contacts and calendars: vdirsyncer syncs them with the Pi (Radicale) and
# Infomaniak, khard reads the contacts (passwords in ~/.secrets/dav-*.gpg)
mkdir -p ~/.config/vdirsyncer ~/.config/khard
ln -sf ~/.dotfiles/rcfiles/vdirsyncer/config ~/.config/vdirsyncer/config
ln -sf ~/.dotfiles/rcfiles/khard/khard.conf ~/.config/khard/khard.conf
ln -sf ~/.dotfiles/bin/radicale-set-password ~/.local/bin/radicale-set-password

# Notifications (dunst, started by EXWM)
mkdir -p ~/.config/dunst
ln -sf ~/.dotfiles/rcfiles/dunstrc ~/.config/dunst/dunstrc
ln -sf ~/.dotfiles/bin/notify-bell ~/.local/bin/notify-bell

# The lock screen (SPC k z, SPC k Z away; xss-lock, started by EXWM):
# i3lock-color with the Jarvis ring, built by hand in ~/.local/bin/i3lock-color
# (rcfiles/i3lock/jarvis-ring.patch says how)
ln -sf ~/.dotfiles/bin/anthe-lock ~/.local/bin/anthe-lock

# Zathura, as an Emacs buffer in EXWM (its colours are written by Emacs)
mkdir -p ~/.config/zathura
ln -sf ~/.dotfiles/rcfiles/zathura/zathurarc ~/.config/zathura/zathurarc
mkdir -p ~/.config/nsxiv/exec
ln -sf ~/.dotfiles/rcfiles/nsxiv/exec/win-title ~/.config/nsxiv/exec/win-title

# ncview config
ln -sf ~/.dotfiles/rcfiles/.ncviewrc ~/.ncviewrc

# matoplotlib config
ln -sf ~/.dotfiles/rcfiles/matplotlibrc ~/.config/matplotlib/matplotlibrc

#RM -f ~/.config/doom/*
ln -sf ~/.dotfiles/emacs/config-local.el ~/.config/doom/config.el
ln -sf ~/.dotfiles/emacs/init.el ~/.config/doom/
ln -sf ~/.dotfiles/emacs/packages.el ~/.config/doom/
ln -sf ~/.dotfiles/exwm/* ~/.config/exwm/

# I did not manage to make it a hardlink, and soft link does not work (exwm not in WM list)
sudo cp ~/.config/exwm/exwm.desktop /usr/share/xsessions/exwm.desktop

# neovim + lazyvim
ln -sf ~/.dotfiles/nvim/lua/config/* ~/.config/nvim/lua/config/
ln -sf ~/.dotfiles/nvim/lua/plugins/* ~/.config/nvim/lua/plugins/

# qutebrowser config
ln -sf ~/.dotfiles/qutebrowser/config.py ~/.config/qutebrowser/config.py
mkdir -p ~/.config/qutebrowser/greasemonkey
ln -sf ~/.dotfiles/qutebrowser/greasemonkey/notifications.js ~/.config/qutebrowser/greasemonkey/
ln -sf ~/.dotfiles/qutebrowser/themes/* ~/.config/qutebrowser/qutebrowser-themes/themes/
mkdir -p ~/.config/qutebrowser/userscripts
ln -sf ~/.dotfiles/qutebrowser/userscripts/add-doi ~/.config/qutebrowser/userscripts/add-doi

# Research feed (python-utils' research/feed.py): its config, and a daily timer
ln -sf ~/.dotfiles/rcfiles/research-feed.toml ~/.config/research-feed.toml
mkdir -p ~/.config/systemd/user
ln -sf ~/.dotfiles/rcfiles/systemd/research-feed.service ~/.config/systemd/user/research-feed.service
ln -sf ~/.dotfiles/rcfiles/systemd/research-feed.timer ~/.config/systemd/user/research-feed.timer
systemctl --user daemon-reload && systemctl --user enable --now research-feed.timer

# Backup: restic snapshots of ~ on the pi, every evening
# (restic itself: the release binary in ~/.local/bin, `restic self-update`)
ln -sf ~/.dotfiles/bin/backup ~/.local/bin/backup
ln -sf ~/.dotfiles/rcfiles/systemd/backup.service ~/.config/systemd/user/backup.service
ln -sf ~/.dotfiles/rcfiles/systemd/backup.timer ~/.config/systemd/user/backup.timer
systemctl --user daemon-reload && systemctl --user enable --now backup.timer

# The pi's archive, mounted on demand in ~/nas (rclone: the release binary in
# ~/.local/bin, `rclone selfupdate`), and `archive put|get|ls` to move folders there
ln -sf ~/.dotfiles/bin/archive ~/.local/bin/archive
ln -sf ~/.dotfiles/rcfiles/systemd/nas.service ~/.config/systemd/user/nas.service
systemctl --user daemon-reload && systemctl --user enable --now nas.service

# Adding a DOI from zathura (rcfiles/zathura/zathurarc: b and B)
ln -sf ~/.dotfiles/bin/zathura-doi ~/.local/bin/zathura-doi
