#!/bin/bash -
#===============================================================================
#          FILE: set_dns.sh
#         USAGE: ./set_dns.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 12/22/2014 13:55
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

if [ $# -gt 0 ] && [ "$1" == "-h" ]; then
    echo "default is set dns, -c means clear dns, -l means list dns."
    exit 0
fi

if [ $# -gt 0 ] && [ "$1" == "-c" ]; then
    #sudo sed -i -e 's/nameserver .*$//g' /etc/resolvconf/resolv.conf.d/head
    sudo sed -i '/^nameserver .*$/d' /etc/resolvconf/resolv.conf.d/head
    sudo resolvconf -u
    exit 0
fi

if [ $# -gt 0 ] && [ "$1" == "-l" ]; then
    grep -v "^# " /etc/resolv.conf
    exit 0
fi

sudo bash -c "echo nameserver 10.0.0.2 >> /etc/resolvconf/resolv.conf.d/head"
sudo resolvconf -u
