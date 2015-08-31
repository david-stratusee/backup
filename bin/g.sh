#!/bin/bash -
#===============================================================================
#          FILE: aws.sh
#         USAGE: ./aws.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 2014/08/14 12:14
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
. tools.sh

function gohelp()
{
    echo -e "Usage: \n\t-m for module(b|c|u|g|r|aie|l2tp|...)\n\t-f for local file\n\t-r for remote_file\n\t-c for command\n\t-e for exit\n\e-l show session"
}

dsthost=""
dstip=""
ssh_dstport=""
scp_dstport=""
local_file=""
remote_file=""
cmd=""
do_exit=0
while getopts 'm:f:r:c:elh' opt; do
    case $opt in
        l)
            ps -ef | grep -v grep | grep sockets
            exit 0
            ;;
        e)
            do_exit=1
            ;;
        m) 
            case $OPTARG in
                "c")
                    dsthost="aie.centos"
                    ;;
                "u")
                    dsthost="us.stratusee.com"
                    ssh_dstport=" -p 2226"
                    scp_dstport=" -P 2226"
                    ;;
                "g")
                    dsthost="github.com"
                    ;;
                "b")
                    dsthost="aie.box"
                    ;;
                "r")
                    dsthost="python-crazyman.rhcloud.com"
                    ;;
                *)
                    dsthost="dev-${OPTARG}.stratusee.com"
                    ;;
            esac
            ;;
        f)
            local_file=$OPTARG
            ;;
        r)
            remote_file=$OPTARG
            ;;
        c)
            cmd=$OPTARG
            ;;
        h|*)
            gohelp
            exit 0
    esac
done

if [ "${dsthost}" == "" ]; then
    echo "dsthost is none"
    gohelp
    exit 0
fi
dstip=`get_dnsip ${dsthost}`

if [ ${do_exit} -ne 0 ]; then
    ssh -O stop ${dstip}${ssh_dstport}
    ps_count=`ps -ef | grep -v grep | grep -c ${dstip}`
    if [ ${ps_count} -gt 0 ]; then
        sleep 1
        ps_count=`ps -ef | grep -v grep | grep -c ${dstip}`
        if [ ${ps_count} -gt 0 ]; then
            ssh -O exit ${dstip}${ssh_dstport}
        fi
    fi
    exit 0
fi

if [ "${remote_file}" != "" ]; then
    start_dir="/home/david/"
    if [ "${remote_file:0:1}" == "/" ]; then
        start_dir=""
    fi

    if [ "${local_file}" != "" ]; then
        echo scp -r${scp_dstport} ${local_file} ${dstip}:${start_dir}${remote_file}
        scp -r${scp_dstport} ${local_file} ${dstip}:${start_dir}${remote_file}
    else
        echo scp -r${scp_dstport} ${dstip}:${start_dir}${remote_file} .
        scp -r${scp_dstport} ${dstip}:${start_dir}${remote_file} .
    fi
elif [ "${local_file}" != "" ]; then
    echo scp -r${scp_dstport} ${local_file} ${dstip}:/home/david/
    scp -r${scp_dstport} ${local_file} ${dstip}:/home/david/
else
    echo ssh${ssh_dstport} ${dstip} ${cmd}
    ssh${ssh_dstport} ${dstip} ${cmd}
fi
