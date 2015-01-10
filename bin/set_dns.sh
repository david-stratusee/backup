#!/bin/bash -
#===============================================================================
#          FILE: setdns.sh
#         USAGE: ./setdns.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 2014/12/14 11:37
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

if [ $# -gt 0 ] && [ "$1" == "-h" ]; then
    echo "default is set dns, -c means clear dns, -l means list dns."
    echo "All for Wi-Fi"
    exit 0
fi

if [ $# -gt 0 ] && [ "$1" == "-c" ]; then
    sudo networksetup -setdnsservers Wi-Fi empty
    sudo dscacheutil -flushcache
    exit 0
fi

if [ $# -gt 0 ] && [ "$1" == "-l" ]; then
    networksetup -getdnsservers Wi-Fi
    exit 0
fi

setdns="10.0.0.2"
if [ $# -gt 0 ]; then
    setdns=$@
fi

sudo networksetup -setdnsservers Wi-Fi ${setdns}
sudo dscacheutil -flushcache
$0 -l
