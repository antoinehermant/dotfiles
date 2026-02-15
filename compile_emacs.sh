#!/usr/bin/env sh

cd emacs
make clean
./configure --prefix=/usr/local/emacs29.3-x11 --with-native-compilation --with-x-toolkit=gtk3 --with-imagemagick --with-modules --with-sqlite3 --without-compress-install --with-mailutils --with-tree-sitter --with-json
make -j 6 NATIVE_FULL_AOT=1
sudo make install
