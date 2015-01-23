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

desc=$1
output=output.csv
#./multi_test $@
./multi_test -w 10000 -t 3000 -f data/ds_512.txt -d "${desc}" -o ${output}
./multi_test -w 10000 -t 3000 -f data/ds_1k.txt -d "${desc}" -o ${output}
./multi_test -w 10000 -t 3000 -f data/ds_10k.txt -d "${desc}" -o ${output}
./multi_test -w 10000 -t 3000 -f data/ds_100k.txt -d "${desc}" -o ${output}
./multi_test -w 10000 -t 3000 -f data/ds_1m.txt -d "${desc}" -o ${output}
