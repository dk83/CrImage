##!/bin/bash
#
Init="/etc/init.d";
Bin="/usr/local/sbin";
# Link Protection.py
File="CrImage"
sudo ln -s "${PWD}/${File}.init"  "${Init}/${File}"
sudo ln -s "${PWD}/${File}.sh"    "/etc/${File}"
sudo ln -s "${PWD}/${File}.sh"    "${Bin}/${File}"
sudo update-rc.d "${File}" defaults

# Link PiShrink
sudo ln -s "${PWD}/PiShrink.sh" "${Bin}/PiShrink"
