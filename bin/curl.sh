#!/bin/bash -
#===============================================================================
#          FILE:  curl.sh
#   DESCRIPTION:  curl
#
#        AUTHOR:  dengwei dengwei@venus.com
#       VERSION:  1.0
#===============================================================================

if [ $# -eq 0 ] || [ "$1" == "-h" ]; then
    echo "Usage: `basename $0` [-s] full_url"
    echo "       -s for https url"
    exit
fi

localip=`ifconfig | grep "inet " | grep -v "127.0.0.1" | grep -v "192.168.101." | awk '{print $2}' | awk -F. '{print $1"."$2"."$3}'`
echo local ip: $localip--

if [ "$localip" == "192.168.2" ]; then
    ip=192.168.2.41
elif [ "$localip" == "192.168.1" ]; then
    ip=192.168.1.228
elif [ "$localip" == "192.168.54" ]; then
    ip=192.168.54.102
else
    exit 1
fi

<< BLOCK
ips=`~/bin/set_proxy.sh -l | grep Server | uniq | awk '{print $2}'`
for ip in $ips; do
    break
done
BLOCK

port=3128
common_arg="-s -o /tmp/test.log -v --trace-time"

if [ "$1" == "-s" ]; then
    common_arg=${common_arg}" --ssl"
    port=3128
    shift
fi

# --header "cache-control: no-cache"

rm -f /tmp/test.log

echo curl -w "\\n" --proxy ${ip}:${port} ${common_arg} $@

echo =============================================================
echo curl -w "\\n" --proxy ${ip}:${port} ${common_arg} $@
time curl -w "\n" --proxy ${ip}:${port} ${common_arg} $@

#echo -------------------------------------------------------------

#echo curl -w "\\n" ${common_arg} $@
#time curl -w "\n" ${common_arg} $@
echo =============================================================

#rm -f /tmp/test.log
