#!/bin/sh

rm -f delegated-apnic-latest*
wget http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest
if [ $? -ne 0 ]; then
    exit 1
fi

./flora_pac -x "SOCKS5 127.0.0.1:15500; DIRECT" -c delegated-apnic-latest
rm -f delegated-apnic-latest

dest_path="../../../david-stratusee.github.io/proxy.pac"
if [ $# -gt 0 ]; then
    dest_path=$1
fi
echo cp ./flora_pac.pac ${dest_path}
cp ./flora_pac.pac ${dest_path}
