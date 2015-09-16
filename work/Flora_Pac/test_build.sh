#!/bin/sh

rm -f delegated-apnic-latest*
wget http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest
if [ $? -ne 0 ]; then
    exit 1
fi

./flora_pac -x "SOCKS5 127.0.0.1:15500; DIRECT" -c delegated-apnic-latest
rm -f delegated-apnic-latest

dest_path="../../../david-stratusee.github.io"
if [ $# -gt 0 ]; then
    dest_path=$1
fi
echo cp ./flora_pac.pac ${dest_path}/proxy.pac
cp ./flora_pac.pac ${dest_path}/proxy.pac
if [ -f /Library/WebServer/Documents/proxy.pac ]; then
    cp -f flora_pac.pac /Library/WebServer/Documents/proxy.pac
fi
rm -f flora_pac.pac

cd $dest_path
pwd
echo git_commit.sh -a add -m "fix" proxy.pac
git_commit.sh -a add -m "fix" proxy.pac
echo git push
git push
