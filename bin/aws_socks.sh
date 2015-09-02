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
. tools.sh

#-------------------------------------------------------------------------------
# config here
# 1. modify username
# 2. add proxy.pac to /Library/WebServer/Documents/proxy.pac
#-------------------------------------------------------------------------------
username=david

available_host_port=("david:dev-aie.stratusee.com:22" "david:dev-aie2.stratusee.com:22" "david:us.stratusee.com:2226", "55dff01689f5cf34c30000e0:python-crazyman.rhcloud.com:22")
host_port=${available_host_port[3]}

ETH="Wi-Fi"
aliveinterval=0
SHADOW_DIR=${HOME}/work/openshift/shadowsocks
#-------------------------------------------------------------------------------
# config end
#-------------------------------------------------------------------------------

function show_proxy()
{
    echo ===========================
    echo proxy.pac: ${local_proxydir}
    echo "pac_proxy state:"
    networksetup -getautoproxyurl ${ETH}
    echo ===========================
    ps -ef | grep -v grep | egrep --color=auto "(ssh -D|CMD|local.js|httpd)"
    echo ===========================
}

function fill_and_run_proxy()
{
    curdir=`pwd`
    cd ${SHADOW_DIR}
    nohup node local.js -s 'wss://shadowsocks-crazyman.rhcloud.com:8443' >/tmp/rhc.log 2>&1 &
    cd $curdir
}

function kill_process()
{
    pidc=`ps -ef | grep -v grep | grep -c "$@"`
    if [ $pidc -gt 0 ]; then
        sshpid=`ps -ef | grep "$@" | grep -v grep | awk '{print $2}'`
        for p in $sshpid; do
            echo "kill $@, pid: ${p}"
            sudo kill $p
        done
    fi
}

function print_avail_host()
{
    nhost=0
    echo "available socks host-port is:[${#available_host_port[*]}]"
    for node in ${available_host_port[*]}; do
        if [ "${host_port}" == "${node}" ]; then
            echo " [${nhost}] $node [***]"
        else
            echo " [${nhost}] $node"
        fi

        nhost=`expr ${nhost} + 1`
    done
}

function check_host_port()
{
    check_value=$1
    for node in ${available_host_port[*]}; do
        if [ "${check_value}" == "${node}" ]; then
            return 0
        fi
    done

    return 1
}

function update_pac()
{
    has_wget=$1
    if [ $has_wget -eq 0 ]; then
        rm -f /tmp/proxy.pac
        echo wget -T 10 -nv http://david-stratusee.github.io/proxy.pac -P /tmp/
        wget -T 10 -nv http://david-stratusee.github.io/proxy.pac -P /tmp/
        if [ $? -eq 0 ]; then
            sudo mv /tmp/proxy.pac ${local_proxydir}/
        elif [ ! -f ${local_proxydir}/proxy.pac ]; then
            echo "can not get proxy.pac, exit..."
            return 1
        else
            echo "can not get proxy.pac from github, so just use old one"
        fi
    fi

    return 0
}

function stop_apache()
{
    httpd_count=`ps -ef | grep -v grep | grep -c httpd`
    if [ ${httpd_count} -gt 0 ]; then
        sudo apachectl graceful-stop
    fi
}

function start_apache()
{
    stop_apache
    sudo apachectl start
}

function aws_socks_help()
{
    echo "------------------------------------"
    echo "Help Usage     : "
    echo "-a NUM         : set ServerAliveInterval for sshtunnel, default 0, recommand 7200"
    echo "-c             : for clear socks proxy"
    echo "-r             : for reboot socks proxy"
    echo "-e ETH         : for ETH-TYPE, default Wi-Fi, only used by MacOS"
    echo "-f             : for local file for pac, only for Safari"
    echo "-l             : for query socks proxy"
    echo "-i IP          : for set socks proxy and http proxy"
    echo "-p NUM|IP:PORT : set socks proxy's host_port"
    print_avail_host
    echo "no args for set socks proxy and DIRECT"
    echo "------------------------------------"
}

IP=""
MODE="normal"
restart=0
use_local_web=1
while getopts 'a:e:p:i:hcrlf' opt; do
    case $opt in
        a)
            aliveinterval=$OPTARG
            ;;
        e) 
            ETH=$OPTARG
            ;;
        f)
            use_local_web=0
            ;;
        i)  
            IP=$OPTARG
            ping -q -c 1 ${IP} >/dev/null
            if [ $? -ne 0 ]; then
                echo "${IP} is unreachable"
                exit 1
            fi
            ;;
        c|r)
            if [ "${MODE}" == "normal" ]; then
                MODE="clear"
                if [ "$opt" == 'r' ]; then
                    restart=1
                fi
            else
                echo "clear and query mode should not be used at same time"
                aws_socks_help
                exit 1
            fi
            ;;
        l)
            if [ "${MODE}" == "normal" ]; then
                MODE="query"
            else
                echo "clear and query mode should not be used at same time"
                aws_socks_help
                exit 1
            fi
            ;;
        p)
            isdigit=`echo $OPTARG | grep -c "^[0-9]$"`
            if [ $isdigit -gt 0 ] && [ $OPTARG -lt ${#available_host_port[*]} ]; then
                host_port=${available_host_port[$OPTARG]}
            else
                check_host_port $OPTARG
                if [ $? -eq 0 ]; then
                    host_port=$OPTARG
                else
                    echo "invalid host_port format"
                    aws_socks_help
                    exit 1
                fi
            fi
            ;;
        h|*)
            aws_socks_help
            exit 0
    esac
done

if [ ${use_local_web} -gt 0 ]; then
    local_proxydir="/Library/WebServer/Documents/"
else
    local_proxydir="/Applications/Safari.app/Contents/Resources"
fi

if [ "${MODE}" == "clear" ] || [ "${MODE}" == "normal" ]; then
    remote_host=`echo ${host_port} | awk -F":" '{print $2}'`
    remote_ip=`get_dnsip ${remote_host}`

    kill_process "local.js"
    kill_process $remote_host
    kill_process $remote_ip
    kill_process "ssh -D"
    kill_process `echo $host_port | awk -F":" '{print $2}'`

    stop_apache
    sudo networksetup -setautoproxystate ${ETH} off

    if [ ${restart} -gt 0 ]; then
        MODE="normal"
    fi
fi

if [ "${MODE}" == "normal" ]; then
    which wget >/dev/null
    has_wget=$?

    sudo networksetup -setautoproxystate ${ETH} off
    if [ "${IP}" == "" ]; then
        update_pac $has_wget
        if [ $? -ne 0 ]; then
            exit 1
        fi

        if [ ! -f ${local_proxydir}/proxy.pac ]; then
            sudo networksetup -setautoproxyurl ${ETH} "http://david-stratusee.github.io/proxy.pac"
        else
            if [ ${use_local_web} -gt 0 ]; then
                start_apache
                sudo networksetup -setautoproxyurl ${ETH} "http://127.0.0.1/proxy.pac"
            else
                sudo networksetup -setautoproxyurl ${ETH} "file://localhost${local_proxydir}/proxy.pac"
            fi
        fi
    else
        update_pac $has_wget
        if [ $? -ne 0 ]; then
            exit 1
        fi

        sudo cp -f ${local_proxydir}/proxy.pac ${local_proxydir}/proxy_aie.pac
        sudo sed -i "" -e "s/'DIRECT'/'PROXY ${IP}:3128'/g" ${local_proxydir}/proxy_aie.pac
        if [ ${use_local_web} -gt 0 ]; then
            start_apache
            sudo networksetup -setautoproxyurl ${ETH} "http://127.0.0.1/proxy_aie.pac"
        else
            sudo networksetup -setautoproxyurl ${ETH} "file://localhost${local_proxydir}/proxy_aie.pac"
        fi
    fi

    fill_and_run_proxy
    sudo networksetup -setautoproxystate ${ETH} on
fi
show_proxy

