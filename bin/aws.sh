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

module="aie"
local_file=""
remote_file=""
while getopts 'm:f:r:h' opt; do
    case $opt in
        m) 
            module=$OPTARG
            ;;
        f)
            local_file=$OPTARG
            ;;
        r)
            remote_file=$OPTARG
            ;;
        h|*)
            echo -e "Usage: \n\t-m for module\n\t-f for local file\n\t-r for remote_file"
            exit 0
    esac
done

if [ "${remote_file}" != "" ]; then
    if [ "${local_file}" != "" ]; then
        echo scp ${local_file} dev-${module}.stratusee.com:/home/david/${remote_file}
        scp ${local_file} dev-${module}.stratusee.com:/home/david/${remote_file}
    else
        echo scp dev-${module}.stratusee.com:/home/david/${remote_file} .
        scp dev-${module}.stratusee.com:/home/david/${remote_file} .
    fi
else
    echo ssh dev-${module}.stratusee.com
    ssh dev-${module}.stratusee.com
fi

