#!/bin/bash

ln -sf ~/.dotfiles/bash/.bash_aliases ~/.bash_aliases
ln -sf ~/.dotfiles/bash/.bash_functions ~/.bash_functions
ln -sf ~/.dotfiles/bash/.bash_exports ~/.bash_exports
ln -sf ~/.dotfiles/bash/.bash_tweaks ~/.bash_tweaks

# mbsync config
ln -sf ~/.dotfiles/rcfiles/.mbsyncrc ~/.mbsyncrc

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
ln -sf ~/.dotfiles/qutebrowser/themes/* ~/.config/qutebrowser/qutebrowser-themes/themes/
