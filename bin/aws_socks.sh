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

available_host_port=("dev-aie.stratusee.com:22" "54.174.130.103:22" "us.stratusee.com:2221")
host_port=${available_host_port[1]}

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
    echo "        echo -e \" [\"\`date +'%H:%M:%S'\`\"] ssh -D 8099 -fqCnN ${username}@${remote_host}${remote_port}\"" >>/tmp/watch_socks.sh
    echo "        ssh -D 8099 -fqCnN ${username}@${remote_host}${remote_port}" >>/tmp/watch_socks.sh
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

function print_avail_host()
{
    echo "available socks host:port is: (now is use ${host_port})"
    for node in ${available_host_port[*]}; do
        echo " * $node"
    done
}

IP=""
MODE="normal"
while getopts 'e:p:i:hcl' opt; do
    case $opt in
        e) 
            ETH=$OPTARG
            ;;
        i)  
            IP=$OPTARG
            ping -q -c 1 ${IP} >/dev/null
            if [ $? -ne 0 ]; then
                echo "${IP} is unreachable"
                exit 1
            fi
            ;;
        c)
            if [ "${MODE}" == "normal" ]; then
                MODE="clear"
            else
                echo "clear and query mode should not be used at same time"
            fi
            ;;
        l)
            if [ "${MODE}" == "normal" ]; then
                MODE="query"
            else
                echo "clear and query mode should not be used at same time"
            fi
            ;;
        p)
            host_port=$OPTARG
            comma_count=`echo $host_port | grep -c ":"`
            if [ ${comma_count} -eq 0 ]; then
                echo "invalid host_port format"
                $0 -h
                exit 1
            fi
            ;;
        h|*)
            echo "------------------------------------"
            echo "Help Usage: "
            echo "-c for clear socks proxy"
            echo "-l for query socks proxy"
            echo "-i ip for set socks proxy and http proxy"
            echo "-p to set socks proxy's host_port, format: proxy:port"
            print_avail_host
            echo "no args for set socks proxy and DIRECT"
            echo "------------------------------------"
            exit 0
    esac
done

if [ "${MODE}" == "clear" ]; then
    kill_process "watch_socks"
    kill_process "ssh -D"

    httpd_count=`ps -ef | grep -v grep | grep -c httpd`
    if [ ${httpd_count} -gt 0 ]; then
        sudo apachectl graceful-stop
    fi
    sudo networksetup -setautoproxystate ${ETH} off
elif [ "${MODE}" == "normal" ]; then
    sudo networksetup -setautoproxystate ${ETH} off
    if [ "${IP}" == "" ]; then
        sudo networksetup -setautoproxyurl ${ETH} "https://david-stratusee.github.io/proxy.pac"
    else
        sudo cp -f /Library/WebServer/Documents/proxy.pac /Library/WebServer/Documents/proxy_aie.pac
        sudo sed -i "" -e "s/'DIRECT'/'PROXY ${IP}:3128'/g" /Library/WebServer/Documents/proxy_aie.pac
        sudo networksetup -setautoproxyurl ${ETH} "http://127.0.0.1/proxy_aie.pac"
        sudo apachectl start
    fi

    echo start socks
    fill_and_run_proxy

    sudo networksetup -setautoproxystate ${ETH} on
fi
show_proxy

