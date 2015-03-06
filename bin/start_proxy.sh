#!/bin/bash -
#===============================================================================
#          FILE: start_proxy.sh
#         USAGE: ./start_proxy.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 2015年02月27日 23:39
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

username=david
available_host_port=("dev-aie.stratusee.com:22" "dev-aie2.stratusee.com:22" "us.stratusee.com:2221")
host_port=${available_host_port[2]}

aliveinterval=0

function show_proxy_stat()
{
    ps -ef | grep -v grep | egrep --color=auto "(ssh -D|CMD|watch_socks|polipo|squid)"
    echo ===========================
    if [ -f /tmp/watch_socks.log ]; then
        echo "/tmp/watch_socks.log:"
        grep "ssh -D" /tmp/watch_socks.log
        echo ===========================
    fi
}

function kill_process()
{
    pidc=`ps -ef | grep -v grep | grep -c "$@"`
    if [ $pidc -gt 0 ]; then
        sshpid=`ps -ef | grep "$@" | grep -v grep | awk '{print $2}'`
        echo "kill $@, pid: ${sshpid}"
        sudo kill $sshpid
    fi
}

function clear_proxy()
{
    kill_process "watch_socks"
    kill_process "ssh -D"
    kill_process polipo
    sudo /usr/local/squid/sbin/squid -k kill
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

function print_avail_host()
{
    nhost=0
    echo "available socks host:port is:[${#available_host_port[*]}]"
    for node in ${available_host_port[*]}; do
        if [ "${host_port}" == "${node}" ]; then
            echo " [${nhost}] $node [***]"
        else
            echo " [${nhost}] $node"
        fi

        nhost=`expr ${nhost} + 1`
    done
}

function start_proxy_help()
{
    echo "------------------------------------"
    echo "Help Usage: "
    echo "-a NUM         : set ServerAliveInterval for sshtunnel, default 0, recommand 7200"
    echo "-c             : for clear socks proxy"
    echo "-l             : for query socks proxy"
    echo "-p NUM|IP:PORT : set socks proxy's host_port"
    print_avail_host
    echo "no args for set proxy"
    echo "------------------------------------"
}

while getopts 'a:p:hcl' opt; do
    case $opt in
        a)
            aliveinterval=$OPTARG
            ;;
        c)
            clear_proxy
            exit 0
            ;;
        l)
            show_proxy_stat
            exit 0
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
                    start_proxy_help
                    exit 1
                fi
            fi
            ;;
        h|*)
            start_proxy_help
            exit 0
            ;;
    esac
done

clear_proxy

#rm -f /tmp/proxy.pac
#wget --no-check-certificate -nv https://david-stratusee.github.io/proxy.pac -P /tmp/
#sudo cp -f /tmp/proxy.pac /etc/polipo/proxy.pac

remote_host=`echo ${host_port} | awk -F":" '{print $1}'`
remote_port=`echo ${host_port} | awk -F":" '{print $2}'`
nslookup ${remote_host} >/tmp/watch_socks.log
${HOME}/bin/watch_socks.sh ${username} ${remote_host} ${remote_port} ${aliveinterval} >>/tmp/watch_socks.log 2>&1 &
#sudo /usr/local/bin/polipo logLevel=0xFF
sudo /usr/local/bin/polipo

sudo /usr/local/squid/sbin/squid -k kill
sudo nohup proxychains4 /usr/local/squid/sbin/squid -d 3 -N 1>>/tmp/squid.log 2>&1 &

echo "show state:"
sleep 2
show_proxy_stat
