#!/bin/bash -
#===============================================================================
#          FILE: test_perf.sh
#         USAGE: ./test_perf.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 2015年02月12日 10:45
#      REVISION:  ---
#===============================================================================

ulimit -c unlimited

args="-a 4 -b 1 -t 300"
#list="ds_512.txt ds_100k.txt ds_1k.txt ds_10k.txt"
list="512 100k 1k 10k"
if [ $# -gt 0 ]; then
    userstr=_$1
else
    userstr=""
fi

for file in $list; do
    ../multi_test -f ../data/dsext_${file}.txt -d direct${userstr} -o ../result/aie_10min${userstr}.csv ${args} >>../result/aie_10min${userstr}.log 2>&1
    sleep 60

    ../multi_test -f ../data/dsext_${file}.txt -d s_direct${userstr} -o ../result/aie_10min${userstr}.csv -s ${args} >>../result/aie_10min${userstr}.log 2>&1
    sleep 60
done

