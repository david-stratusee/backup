#!/bin/bash -
#===============================================================================
#          FILE: network_restart.sh
#         USAGE: ./network_restart.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 11/26/2014 20:55
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

sudo ifdown enp0s3 && sudo ifup enp0s3
sudo kill `ps -ef | grep "sslsplit " | grep -v grep | awk '{print $2}'`

ifconfig
