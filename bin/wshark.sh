#!/bin/bash -
#===============================================================================
#          FILE: tshark.sh
#         USAGE: ./tshark.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 2014/12/12 10:15
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

if [ $# -gt 0 ] && [ "$1" == "-h" ]; then
    echo "for icap: wshark.sh \"tcp port 1344\" -i lo"
    echo "for http: wshark.sh \"tcp port 3127\" -i enp0s3"
    exit 0
fi

filter=$1
shift

sudo tshark -O "http,message-http,icap" -d "tcp.port==3127,http" -f "$filter and greater 80" $@
#sudo tshark -V -d "tcp.port==3127,http" -f "$filter and greater 80" $@
