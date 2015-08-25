#!/bin/bash -
#===============================================================================
#          FILE: dnschef.sh
#         USAGE: ./dnschef.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 2015年08月25日 17:07
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

function kill_dnschef_1
{
    local val=0
    pidc=`ps -ef | grep -v "nohup" | grep -v "grep" | grep -c "dnschef.py"`
    if [ $pidc -gt 0 ]; then
        sshpid=`ps -ef | grep -v "nohup" | grep -v "grep" | grep "dnschef.py" | awk '{print $2}'`
        for p in $sshpid; do
            echo "kill $@, pid: ${p}"
            sudo kill $p
            val=1
        done
    fi

    return $val
}

echo pkill dnschef.py
kill_dnschef_1
result=$?

if [ $# -gt 0 ] && [ "$1" == "-c" ]; then
    exit 0
fi

if [ $result -gt 0 ]; then
    sleep 1
fi

echo start dnschef.py
#sudo nohup ${HOME}/bin/dnschef.py --file ${HOME}/bin/dnschef.ini --logfile /tmp/dnschef.log --nameservers 208.67.220.220#53#tcp,208.67.222.222#53#tcp,209.244.0.3#53#tcp,209.244.0.4#53#tcp -i 0.0.0.0 -q 1>/dev/null 2>&1 &
sudo nohup ${HOME}/bin/dnschef.py --file ${HOME}/bin/dnschef.ini --nameservers 208.67.220.220#53#tcp,208.67.222.222#53#tcp,209.244.0.3#53#tcp,209.244.0.4#53#tcp -i 0.0.0.0 -q 1>/dev/null 2>&1 &
sleep 1
echo show result

ps axf | grep dnschef
