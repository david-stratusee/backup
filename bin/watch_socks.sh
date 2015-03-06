#!/bin/bash -

port=""
aliveinterval=""
username=$1
hostname=$2
if [ $3 -ne 22 ]; then
    port=" -p $3"
fi
if [ $4 -gt 0 ]; then
    aliveinterval=" -o \"ServerAliveInterval $4\""
fi

ssh_args="-fqCnN"
#ssh_args="-fqnN"
socks_port=8099

while [ 1 -eq 1 ]; do
    pidcount=`ps -ef | grep -v grep | grep -c "ssh -D"`
    if [ $pidcount -eq 0 ]; then
        echo -e " ["`date +'%H:%M:%S'`"] ssh -D ${socks_port} ${ssh_args} ${username}@${hostname}${port}${aliveinterval}"
        ssh -D ${socks_port} ${ssh_args} ${username}@${hostname}${port}${aliveinterval}
    else
        check_proxy=`${HOME}/bin/check_proxy.py "127.0.0.1:${socks_port}"`
        if [ ${check_proxy} -ne 1 ]; then
            sshpid=`ps -ef | grep "ssh -D" | grep -v grep | awk '{print $2}'`
            echo kill $sshpid
            kill $sshpid
        fi
    fi
    sleep 1
done
