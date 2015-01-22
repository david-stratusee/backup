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

ulimit -n 19999
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
#python run.py -r 10 -a 80 -x cms.xml
python 
