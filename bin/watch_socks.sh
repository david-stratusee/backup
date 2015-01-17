#!/bin/bash -

while [ 1 -eq 1 ]; do
    pidcount=`ps -ef | grep -v grep | grep -c "ssh -D"`
    if [ $pidcount -eq 0 ]; then
        echo -e " ["`date +'%H:%M:%S'`"] ssh -D 8099 -fqCnN $1@$2 -p $3"
        ssh -D 8099 -fqCnN $1@$2 -p $3
    else
        check_proxy=`${HOME}/bin/check_proxy.py "127.0.0.1:8099"`
        if [ ${check_proxy} -ne 1 ]; then
            sshpid=`ps -ef | grep "ssh -D" | grep -v grep | awk '{print $2}'`
            echo kill $sshpid
            kill $sshpid
        fi
    fi
    sleep 1
done
