#!/bin/bash

ln -sf ~/.dotfiles/.bash_aliases ~/.bash_aliases

# ln -sf ~/.dotfiles/.emacs ~/.emacs

#rm -f ~/.config/doom/*
ln -sf ~/.dotfiles/doom/init.el ~/.config/doom/init.el
ln -sf ~/.dotfiles/doom/packages.el ~/.config/doom/packages.el
ln -sf ~/.dotfiles/doom/config.el ~/.config/doom/config.el
