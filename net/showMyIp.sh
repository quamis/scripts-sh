#!/bin/bash


# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)   
	declare $KEY="$VALUE"
done

: ${VERBOSE:="0"};	# 0, 1

# see https://stackoverflow.com/a/2990533/11301
function echoerr() { 
    echo "$@" 1>&2; 
}

function directGetFromURL {
    URL="$1";
    if [ "$VERBOSE" = "1" ]; then
        echoerr "trying: $URL" 
    fi;

    IP=`wget -q -O- "$URL"`;

    if [ "$VERBOSE" = "1" ]; then
        echoerr "      -> $IP"
    fi;

    echo "$IP";
}


IP="";

[ -z "$IP" ] && IP="$(directGetFromURL 'ifconfig.me')";
[ -z "$IP" ] && IP="$(directGetFromURL 'icanhazip.com')";
[ -z "$IP" ] && IP="$(directGetFromURL 'ident.me')";
[ -z "$IP" ] && IP="$(directGetFromURL 'ipecho.net/plain')";

#IP=`curl v4.ident.me`
#IP=`curl v6.ident.me`
#IP=`dig +short myip.opendns.com @resolver1.opendns.com`

echo "External IP: $IP"
