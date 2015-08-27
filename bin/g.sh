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

function gohelp()
{
    echo -e "Usage: \n\t-m for module(b|c|u|g|aie|l2tp|...)\n\t-f for local file\n\t-r for remote_file\n\t-c for command\n\t-e for exit\n\e-l show session"
}

dsthost=""
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

if [ ${do_exit} -ne 0 ]; then
    ssh -O stop ${dsthost}${ssh_dstport}
    ps_count=`ps -ef | grep -v grep | grep -c ${dsthost}`
    if [ ${ps_count} -gt 0 ]; then
        sleep 1
        ps_count=`ps -ef | grep -v grep | grep -c ${dsthost}`
        if [ ${ps_count} -gt 0 ]; then
            ssh -O exit ${dsthost}${ssh_dstport}
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
        echo scp -r${scp_dstport} ${local_file} ${dsthost}:${start_dir}${remote_file}
        scp -r${scp_dstport} ${local_file} ${dsthost}:${start_dir}${remote_file}
    else
        echo scp -r${scp_dstport} ${dsthost}:${start_dir}${remote_file} .
        scp -r${scp_dstport} ${dsthost}:${start_dir}${remote_file} .
    fi
elif [ "${local_file}" != "" ]; then
    echo scp -r${scp_dstport} ${local_file} ${dsthost}:/home/david/
    scp -r${scp_dstport} ${local_file} ${dsthost}:/home/david/
else
    echo ssh${ssh_dstport} ${dsthost} ${cmd}
    ssh${ssh_dstport} ${dsthost} ${cmd}
fi
