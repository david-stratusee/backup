#!/bin/bash -
#===============================================================================
#          FILE: start_sslsplit1.sh
#         USAGE: ./start_sslsplit1.sh
#   DESCRIPTION:
#        AUTHOR: dengwei
#       CREATED: 2015年04月23日 01:19
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

sudo sysctl -w net.ipv4.ip_forward=1

sudo iptables -t nat -F
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports 8443
#sudo iptables -t nat -A PREROUTING -p tcp --dport 587 -j REDIRECT --to-ports 8443
#sudo iptables -t nat -A PREROUTING -p tcp --dport 465 -j REDIRECT --to-ports 8443
#sudo iptables -t nat -A PREROUTING -p tcp --dport 993 -j REDIRECT --to-ports 8443
#sudo iptables -t nat -A PREROUTING -p tcp --dport 5222 -j REDIRECT --to-ports 8080
sudo iptables -t nat -A POSTROUTING -j MASQUERADE

sudo iptables -t nat -L

rm -rf ./log_data
mkdir ./log_data
rm -f connections.log

CERT_DIR=/home/david/work/keys/squid_cert
./sslsplit -P -l connections.log -S ./log_data/ -k ${CERT_DIR}/holonet.key -c ${CERT_DIR}/holonet.pem -C ${CERT_DIR}/holonet_ca.pem ssl 0.0.0.0 8443 tcp 0.0.0.0 8080
