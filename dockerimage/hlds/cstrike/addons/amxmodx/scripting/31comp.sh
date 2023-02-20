#!/bin/bash

# AMX Mod X
#
# by the AMX Mod X Development Team
#  originally developed by OLO
#
# This file is part of AMX Mod X.

# new code contributed by \malex\


amxxfile="`echo $@ | sed -e 's/\.sma$/.amxx/'`"
echo -n "Compiling $sourcefile ..."
./amxxpc $@ -o../plugins/$amxxfile >> temp.txt
echo "done"

less temp.txt
rm temp.txt
