#!/bin/bash -
#===============================================================================
#          FILE: create_passwd.sh
#         USAGE: ./create_passwd.sh
#        AUTHOR: dengwei (), david@stratusee.com
#  ORGANIZATION: 
#       CREATED: 2015/09/15 10:15
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

domain=$1
passwd=$2
domlen=${#domain}

all_str=${domain}.${passwd}.${domlen}

#echo $all_str
md5_ret=`md5 -q -s $all_str`
#echo $md5_ret

domlen=6
let ret2_start=domlen+1
let ret2_len=16-ret2_start
ret1=${md5_ret:0:${domlen}} 
ret2=${md5_ret:${ret2_start}:${ret2_len}} 

echo $ret1@$ret2
