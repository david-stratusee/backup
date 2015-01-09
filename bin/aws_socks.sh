#!/bin/bash -
#===============================================================================
#          FILE: new_socks.sh
#         USAGE: ./new_socks.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 2015/01/05 21:18
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#-------------------------------------------------------------------------------
# config here
# 1. modify username
# 2. add proxy.pac to /Library/WebServer/Documents/proxy.pac
#-------------------------------------------------------------------------------
username=david

#host_port="dev-aie.stratusee.com:22"
host_port="54.174.130.103:22"
#host_port="us.stratusee.com:2221"

ETH="Wi-Fi"
#-------------------------------------------------------------------------------
# config end
#-------------------------------------------------------------------------------

function show_proxy()
{
    echo ===========================
    echo "pac_proxy state:"
    networksetup -getautoproxyurl ${ETH}
    echo ===========================
    ps -ef | grep "ssh -D" | grep -v grep
    ps -ef | grep "watch_socks" | grep -v grep
    echo ===========================
}

function fill_and_run_proxy()
{
    remote_host=`echo ${host_port} | awk -F":" '{print $1}'`
    remote_port=`echo ${host_port} | awk -F":" '{print $2}'`
    if [ "${remote_port}" == "22" ]; then
        remote_port=""
    else
        remote_port=" -p ${remote_port}"
    fi

    echo "#!/bin/bash -"    >/tmp/watch_socks.sh
    echo "while [ 1 -eq 1 ]; do" >>/tmp/watch_socks.sh
    echo "    pidcount=\`ps -ef | grep -v grep | grep -c \"ssh -D\"\`" >>/tmp/watch_socks.sh
    echo "    if [ \$pidcount -eq 0 ]; then" >>/tmp/watch_socks.sh
    echo "        echo -e \" [\"\`date +'%H:%M:%S'\`\"] ssh -D 8099 -f -q -C -N ${username}@${remote_host}${remote_port}\"" >>/tmp/watch_socks.sh
    echo "        ssh -D 8099 -f -q -C -N ${username}@${remote_host}${remote_port}" >>/tmp/watch_socks.sh
    echo "    fi" >>/tmp/watch_socks.sh
    echo "    sleep 1" >>/tmp/watch_socks.sh
    echo "done" >>/tmp/watch_socks.sh
    chmod +x /tmp/watch_socks.sh

    /tmp/watch_socks.sh >>/tmp/watch_socks.log 2>&1 &
}

function kill_process()
{
    pidc=`ps -ef | grep -v grep | grep -c "$@"`
    if [ $pidc -gt 0 ]; then
        echo "kill $@"
        sshpid=`ps -ef | grep "$@" | grep -v grep | awk '{print $2}'`
        kill $sshpid
    fi
}

if [ $# -gt 0 ] && [ "$1" == "-h" ]; then
    echo "-c for clear socks proxy"
    echo "-l for  show socks proxy"
    echo "ip for   set socks proxy and http proxy"
    echo "no args for set socks proxy and DIRECT"
    exit 0
elif [ $# -gt 0 ] && [ "$1" == "-c" ]; then
    kill_process "watch_socks"
    kill_process "ssh -D"

    httpd_count=`ps -ef | grep -v grep | grep -c httpd`
    if [ ${httpd_count} -gt 0 ]; then
        sudo apachectl graceful-stop
    fi
    sudo networksetup -setautoproxystate ${ETH} off
elif [ $# -gt 0 ] && [ "$1" == "-l" ]; then
    show_proxy
    exit 0
else
    sudo networksetup -setautoproxystate ${ETH} off
    if [ $# -gt 0 ]; then
        sudo cp -f /Library/WebServer/Documents/proxy.pac /Library/WebServer/Documents/proxy_aie.pac
        sudo sed -i -e "s/'DIRECT'/'PROXY $1:3128'/g" /Library/WebServer/Documents/proxy_aie.pac
        sudo networksetup -setautoproxyurl ${ETH} "http://127.0.0.1/proxy_aie.pac"
        sudo apachectl start
    else
        sudo networksetup -setautoproxyurl ${ETH} "https://david-stratusee.github.io/proxy.pac"
    fi

    echo start socks
    fill_and_run_proxy

    sudo networksetup -setautoproxystate ${ETH} on
fi

show_proxy

