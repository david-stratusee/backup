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
    if [ "${local_file}" != "" ]; then
        echo scp ${local_file} ${dsthost}:/home/david/${remote_file}
        scp ${local_file} ${dsthost}:/home/david/${remote_file}
    else
        echo scp ${dsthost}:/home/david/${remote_file} .
        scp ${dsthost}:/home/david/${remote_file} .
    fi
else
    echo ssh ${dsthost}
    ssh ${dsthost}
fi

