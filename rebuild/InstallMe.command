#!/bin/sh -x
cd "`dirname \"$0\"`"

PREFIX=/usr
sudo -v

sudo install -p -m 755 rebuild $PREFIX/bin
sudo install -p -m 755 rebuild_choosedc $PREFIX/bin
sudo install -p -m 644 dymoduleinit.d $PREFIX/lib
sudo install -p -m 644 rebuild.1 $PREFIX/share/man/man1
sudo install -p -m 644 testtango.d $PREFIX/share/rebuild

sudo install -d -m 755 $PREFIX/etc/rebuild
for conf in rebuild.conf/*; do sudo install -b $conf $PREFIX/etc/rebuild; done
