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
    echo -e "Usage: \n\t-m for module(c|u|aie|l2tp|...)\n\t-f for local file\n\t-r for remote_file"
}

dsthost=""
local_file=""
remote_file=""
while getopts 'm:f:r:h' opt; do
    case $opt in
        m) 
            case $OPTARG in
                "c")
                    dsthost="aie.centos"
                    ;;
                "u")
                    dsthost="aie.ubuntu"
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

if [ "${remote_file}" != "" ]; then
    start_dir="/home/david/"
    if [ "${remote_file:0:1}" == "/" ]; then
        start_dir=""
    fi

    if [ "${local_file}" != "" ]; then
        echo scp ${local_file} ${dsthost}:${start_dir}${remote_file}
        scp ${local_file} ${dsthost}:${start_dir}${remote_file}
    else
        echo scp ${dsthost}:${start_dir}${remote_file} .
        scp ${dsthost}:${start_dir}${remote_file} .
    fi
elif [ "${local_file}" != "" ]; then
    echo scp ${local_file} ${dsthost}:/home/david/
    scp ${local_file} ${dsthost}:/home/david/
else
    echo ssh ${dsthost}
    ssh ${dsthost}
fi
