#!/bin/bash -
#===============================================================================
#          FILE: start_polipo.sh
#         USAGE: ./start_polipo.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 2015年02月27日 23:39
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

function kill_process()
{
    pidc=`ps -ef | grep -v grep | grep -c "$@"`
    if [ $pidc -gt 0 ]; then
        sshpid=`ps -ef | grep "$@" | grep -v grep | awk '{print $2}'`
        echo "kill $@, pid: ${sshpid}"
        sudo kill $sshpid
    fi
}

if [ $# -gt 0 ]; then
    if [ "$1" == "-c" ]; then
        kill_process "watch_socks"
        kill_process "ssh -D"
        kill_process polipo
    elif [ "$1" == "-h" ]; then
        echo "Usage: `basename $0` [-c]"
    fi
    exit 0
fi

username=david
remote_host=dev-aie.stratusee.com
remote_port=22

rm -f /tmp/proxy.pac
wget --no-check-certificate -nv https://david-stratusee.github.io/proxy.pac -P /tmp/
sudo cp -f /tmp/proxy.pac /etc/polipo/proxy.pac

${HOME}/bin/watch_socks.sh ${username} ${remote_host} ${remote_port} >>/tmp/watch_socks.log 2>&1 &

sudo pkill polipo
sudo /usr/local/bin/polipo

sudo /usr/local/squid/sbin/squid -k kill
sudo proxychains4 /usr/local/squid/sbin/squid -d 3 -N
