#!/bin/bash -x
DSSS="`which dsss`"
DSSS="`dirname $DSSS`"
export LD_LIBRARY_PATH="$DSSS/../lib:$LD_LIBRARY_PATH"
cd lib || exit 1
dsss build || exit 1
dsss install || exit 1
cd ../bin || exit 1
dsss build || exit 1
ldd bin | grep libDG-lib
./bin
if [ "$?" != "4" ]
then
    echo 'bin should have returned 4!'
fi
dsss uninstall lib
dsss distclean
cd ../lib
dsss distclean
