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

if [ $# -eq 0 ]; then
    echo ssh dev-aie.stratusee.com
    ssh dev-aie.stratusee.com
elif [ $# -eq 1 ]; then
    echo scp dev-aie.stratusee.com:/home/david/$1 .
    scp dev-aie.stratusee.com:/home/david/$1 .
else
    echo scp $1 dev-aie.stratusee.com:/home/david/$2
    scp $1 dev-aie.stratusee.com:/home/david/$2
fi

