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

args="-a 4 -b 1 -t 60"
#list="ds_512.txt ds_100k.txt ds_1k.txt ds_10k.txt"
list="512 100k 1k 10k"
if [ $# -gt 0 ]; then
    userstr=_$1
else
    userstr=""
fi

sudo rm -f ../result/1min${userstr}.log
sudo rm -f ../result/1min${userstr}.csv

for file in $list; do
    ../multi_test -f ../data/dsext_${file}.txt -d direct${userstr} -o ../result/1min${userstr}.csv ${args} >>../result/1min${userstr}.log 2>&1
    sleep 30

    ../multi_test -f ../data/dsext_${file}.txt -d s_direct${userstr} -o ../result/1min${userstr}.csv -s ${args} >>../result/1min${userstr}.log 2>&1
    sleep 30
done
