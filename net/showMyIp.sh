#!/bin/bash

IP=`curl http://ipecho.net/plain`
#IP=`curl ifconfig.me`
#IP=`wget -O - -q icanhazip.com`
#IP=`curl ident.me`
#IP=`curl v4.ident.me`
#IP=`curl v6.ident.me`
#IP=`dig +short myip.opendns.com @resolver1.opendns.com`
IP=`curl ipv4.ipogre.com`

echo "External IP: $IP"
