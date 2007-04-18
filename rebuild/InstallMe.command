#!/bin/sh -x
cd "`dirname \"$0\"`"

PREFIX=/usr
sudo -v

sudo install -p -m 755 rebuild $PREFIX/bin
sudo install -p -m 644 rebuild.1 $PREFIX/share/man/man1

sudo install -d -m 755 /etc/rebuild
for conf in rebuild.conf/*; do sudo install -b $conf /etc/rebuild; done
