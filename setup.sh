#!/bin/bash

ln -sf ~/.dotfiles/.bash_aliases ~/.bash_aliases

# ln -sf ~/.dotfiles/.emacs ~/.emacs

#rm -f ~/.config/doom/*
ln -sf ~/.dotfiles/doom/init.el ~/.config/doom/init.el
ln -sf ~/.dotfiles/doom/packages.el ~/.config/doom/packages.el
ln -sf ~/.dotfiles/doom/config.el ~/.config/doom/config.el
ln -sf ~/.dotfiles/doom/config-local.el ~/.config/doom/config-machine.el

ln -sf ~/.dotfiles/exwm/start-exwm.sh ~/.config/exwm/start-exwm.sh
ln -sf ~/.dotfiles/exwm/exwm.desktop ~/.config/exwm/exwm.desktop
ln -sf ~/.dotfiles/exwm/desktop.el ~/.config/exwm/desktop.el

# I did not manage to make it a hardlink, and soft link does not work (exwm not in WM list)
sudo cp ~/.config/exwm/exwm.desktop /usr/share/xsessions/exwm.desktop
