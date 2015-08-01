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
    echo -e "Usage: \n\t-m for module(c|u|g|aie|l2tp|...)\n\t-f for local file\n\t-r for remote_file\n\t-c for command\n\t-e for exit\n\e-s show session"
}

dsthost=""
local_file=""
remote_file=""
cmd=""
do_exit=0
while getopts 'm:f:r:c:esh' opt; do
    case $opt in
        s)
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
                    dsthost="aie.ubuntu"
                    ;;
                "g")
                    dsthost="github.com"
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
    ssh -O stop ${dsthost}
    ps_count=`ps -ef | grep -v grep | grep -c ${dsthost}`
    if [ ${ps_count} -gt 0 ]; then
        sleep 1
        ps_count=`ps -ef | grep -v grep | grep -c ${dsthost}`
        if [ ${ps_count} -gt 0 ]; then
            ssh -O exit ${dsthost}
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
        echo scp -r ${local_file} ${dsthost}:${start_dir}${remote_file}
        scp -r ${local_file} ${dsthost}:${start_dir}${remote_file}
    else
        echo scp -r ${dsthost}:${start_dir}${remote_file} .
        scp -r ${dsthost}:${start_dir}${remote_file} .
    fi
elif [ "${local_file}" != "" ]; then
    echo scp -r ${local_file} ${dsthost}:/home/david/
    scp -r ${local_file} ${dsthost}:/home/david/
else
    echo ssh -q ${dsthost} ${cmd}
    ssh -q ${dsthost} ${cmd}
fi
