#!/bin/bash

ln -sf ~/.dotfiles/.bash_aliases ~/.bash_aliases

#rm -f ~/.config/doom/*
ln -sf ~/.dotfiles/doom/* ~/.config/doom/
ln -sf ~/.dotfiles/exwm/* ~/.config/exwm/

# I did not manage to make it a hardlink, and soft link does not work (exwm not in WM list)
sudo cp ~/.config/exwm/exwm.desktop /usr/share/xsessions/exwm.desktop

# neovim + lazyvim
ln -sf ~/.dotfiles/nvim/lua/config/* ~/.config/nvim/lua/config/
ln -sf ~/.dotfiles/nvim/lua/plugins/* ~/.config/nvim/lua/plugins/
