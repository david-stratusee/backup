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

netname="en0"
os_name=`uname -s`
is_linux=0

function proxy_help()
{
    echo "$1 -c: delete proxy and restore route"
    echo "$1 -l: show proxy route"
    if [ ${is_linux} -eq 0 ]; then
        echo "$1 -v: use vmware local proxy"
    fi
    echo "$1 -b: use box aie proxy"
}

function reset_gw()
{
    if [ ${is_linux} -gt 0 ]; then
        echo route delete -net 0.0.0.0/0
        sudo route delete -net 0.0.0.0/0

        echo route add -net 0.0.0.0/0 gw $1
        sudo route add -net 0.0.0.0/0 gw $1
    else
        echo route -n delete -net 0.0.0.0/0
        sudo route -n delete -net 0.0.0.0/0

        echo route -n add -net 0.0.0.0/0 $1
        sudo route -n add -net 0.0.0.0/0 $1
    fi
}

if [ "${os_name}" == "Linux" ] || [ "${os_name}" == "linux" ]; then
    is_linux=1
    netname="eno16777736"
fi

if [ $# -eq 0 ] || [ "$1" == "-h" ]; then
    proxy_help `basename $0`
    exit 0
fi

if [ "$1" == "-c" ]; then
    local_ip=`ifconfig ${netname} | egrep -o "inet[ \t]+.*[ \t]+netmask" | awk '{print $2}'`
    gw=`echo $local_ip | awk -F"." '{print $1"."$2"."$3".1"}'`
    echo ${gw}
    reset_gw ${gw}

    if [ -f /etc/sysconfig/network-scripts/ifcfg-${netname} ]; then
        sudo sed -i -e 's/^DEFROUTE=.*/DEFROUTE="yes"/g' /etc/sysconfig/network-scripts/ifcfg-${netname}
        dhpid=`ps -ef | grep dhcl | grep ${netname} | awk '{print $2}'`
        if [ "$dhpid" != "" ]; then
            sudo kill $dhpid
        fi
        sudo dhclient ${netname}
    fi
elif [ ${is_linux} -eq 0 ] && [ "$1" == "-v" ]; then
    reset_gw 192.168.66.128
elif [ "$1" == "-b" ]; then
    if [ -f /etc/sysconfig/network-scripts/ifcfg-${netname} ]; then
        sudo sed -i -e 's/^DEFROUTE=.*/DEFROUTE="no"/g' /etc/sysconfig/network-scripts/ifcfg-${netname}
        dhpid=`ps -ef | grep dhcl | grep ${netname} | awk '{print $2}'`
        if [ "$dhpid" != "" ]; then
            sudo kill $dhpid
        fi
        sudo dhclient ${netname}
    fi

    reset_gw 192.168.3.119
elif [ "$1" != "-l" ]; then
    echo "unknown argument"
    proxy_help `basename $0`
    exit 1
fi

netstat -nr
