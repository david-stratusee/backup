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
host_port=${available_host_port[0]}

aliveinterval=0

function show_proxy_stat()
{
    ps auxf | grep -v grep | egrep --color=auto "(ssh -D|CMD|watch_socks|sslsplit|ttdnsd)"
    echo ===========================
    if [ -f /tmp/watch_socks.log ]; then
        echo "/tmp/watch_socks.log:"
        grep "ssh -D" /tmp/watch_socks.log
        echo ===========================
    fi
}

function kill_process()
{
    pidc=`ps -ef | grep -v "grep" | grep -c "$@"`
    if [ $pidc -gt 0 ]; then
        sshpid=`ps -ef | grep -v "grep" | grep "$@" | awk '{print $2}'`
        for p in $sshpid; do
            echo "kill $@, pid: ${p}"
            sudo kill $p
        done
    fi
}

function kill_sslsplit()
{
    pidc=`ps -ef | grep -v "proxychains" | grep -v "grep" | grep -c "sslsplit"`
    if [ $pidc -gt 0 ]; then
        sshpid=`ps -ef | grep -v "proxychains" | grep -v "grep" | grep "sslsplit" | awk '{print $2}'`
        for p in $sshpid; do
            echo "kill sslsplit, pid: ${p}"
            sudo kill $p
        done
    fi
}

function clear_proxy()
{
    kill_process "watch_socks"
    kill_process "ssh -D"
    #kill_process "ttdnsd"
    kill_sslsplit

    #ttdns_nat=`sudo iptables-save | grep 5353`
    #if [ ${ttdns_nat} -ne 0 ]; then
    #    sudo iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5353
    #fi
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

ssh_num=`ps -ef | grep -v grep | grep -c "ssh -D"`
if [ ${ssh_num} -eq 0 ]; then
    clear_proxy

    #rm -f /tmp/proxy.pac
    #wget --no-check-certificate -nv https://david-stratusee.github.io/proxy.pac -P /tmp/
    #sudo cp -f /tmp/proxy.pac /etc/polipo/proxy.pac

    remote_host=`echo ${host_port} | awk -F":" '{print $1}'`
    remote_port=`echo ${host_port} | awk -F":" '{print $2}'`
    nslookup ${remote_host} >/tmp/watch_socks.log
    ${HOME}/bin/watch_socks.sh ${username} ${remote_host} ${remote_port} ${aliveinterval} >>/tmp/watch_socks.log 2>&1 &
    #sudo /usr/local/bin/polipo logLevel=0xFF

    #ttdns_nat=`sudo iptables-save | grep 5353`
    #if [ ${ttdns_nat} -eq 0 ]; then
    #    sudo iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5353
    #fi
    #sudo TSOCKS_CONF_FILE=tsocks.conf ttdnsd -b 127.0.0.1 -p 5353 -P /var/lib/ttdnsd/pid -f /etc/ttdnsd.conf
fi

kill_process "aie_watchdog"
kill_sslsplit
sudo mv -f /tmp/sslsplit.log /tmp/sslsplit.log.bak
#sudo mv -f /tmp/memtm_ssl.heap /tmp/memtm_ssl.heap.bak
sleep 1
tcmalloc_path=`whereis libtcmalloc.so | awk '{for (i=1;i<=NF;i++) print $i}' | grep libtcmalloc.so`
#script_prefix="LD_PRELOAD=${tcmalloc_path} HEAPCHECK=normal HEAPPROFILE=/tmp/memtm_ssl.heap PPROF_PATH=/usr/bin/pprof HEAP_CHECK_TEST_POINTER_ALIGNMENT=1 HEAP_CHECK_MAX_LEAKS=100"
script_prefix="LD_PRELOAD=${tcmalloc_path} HEAPCHECK=normal PPROF_PATH=/usr/bin/pprof HEAP_CHECK_TEST_POINTER_ALIGNMENT=1 HEAP_CHECK_MAX_LEAKS=100"
sudo ${script_prefix} /usr/bin/proxychains4 /usr/local/holonet/bin/sslsplit ssl 0.0.0.0 8443 tcp 0.0.0.0 8081 autossl 0.0.0.0 8082 1>/tmp/sslsplit.log 2>&1 &
sleep 1
sudo /usr/local/holonet/bin/aie_watchdog

echo "show state:"
sleep 1
show_proxy_stat
