#!/bin/bash -
#===============================================================================
#          FILE: test.sh
#         USAGE: ./test.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 2015年01月18日 07:47
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#ulimit -n 19999
#echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
#echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse

#desc=$1
#output=$2
req=100000
agent=400
rampup=10
during=60

list="ds_512.txt ds_1k.txt ds_10k.txt ds_100k.txt"
first_file=0

for file in $list; do
    if [ ${first_file} -ne 0 ]; then
        sleep 10
    else
        first_file=1
    fi
    #echo ./multi_test -a ${agent} -f data/${file} -d \"${desc}\" -o ${output} -r ${rampup} -t ${during}
    #./multi_test -a ${agent} -f data/${file} -d "${desc}" -o ${output} -r ${rampup} -t ${during}
    echo ./multi_test -f data/${file} $@
    ./multi_test -f data/${file} $@
done

