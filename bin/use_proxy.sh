#!/bin/bash -
#===============================================================================
#          FILE: use_proxy.sh
#         USAGE: ./use_proxy.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 2015/04/24 14:08
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

function proxy_help()
{
    echo "$1 -c: delete proxy and restore route"
    echo "$1 -l: show proxy route"
    echo "$1 -v: use vmware local proxy"
    echo "$1 -b: use box aie proxy"
}

function reset_gw()
{
    echo route -n delete -net 0.0.0.0/0
    sudo route -n delete -net 0.0.0.0/0

    echo route -n add -net 0.0.0.0/0 $1
    sudo route -n add -net 0.0.0.0/0 $1
}

if [ $# -eq 0 ] || [ "$1" == "-h" ]; then
    proxy_help `basename $0`
    exit 0
fi

if [ "$1" == "-c" ]; then
    local_ip=`ifconfig en0 | egrep -o "inet .* netmask" | awk '{print $2}'`
    gw=`echo $local_ip | awk -F"." '{print $1"."$2"."$3".1"}'`
    echo ${gw}

    reset_gw ${gw}
elif [ "$1" == "-v" ]; then
    reset_gw 192.168.66.128
elif [ "$1" == "-b" ]; then
    reset_gw 192.168.3.119
elif [ "$1" != "-l" ]; then
    echo "unknown argument"
    proxy_help `basename $0`
    exit 1
fi

netstat -nr
