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

# Notifications (dunst, started by EXWM)
mkdir -p ~/.config/dunst
ln -sf ~/.dotfiles/rcfiles/dunstrc ~/.config/dunst/dunstrc

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
