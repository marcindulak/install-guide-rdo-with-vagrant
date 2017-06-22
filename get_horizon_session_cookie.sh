#!/bin/bash

# obtain session cookie for horizon dashboard
# based on https://ask.openstack.org/en/question/94959/testing-horizon-with-curl/

CURL=curl
COOKIE_FILE=./cookie.txt
HORIZON_URL=http://controller

usage()
{
    echo "$0 -u HORIZON_USER -p HORIZON_PASSWORD -d HORIZON_DOMAIN"
}

while getopts u:d:p: option
do
    case "${option}"
        in
        u)  HORIZON_USER=${OPTARG};;
        p)  HORIZON_PASSWORD=${OPTARG};;
        p)  HORIZON_DOMAIN=${OPTARG};;
        *)  usage
            exit 1;;
    esac
done

if test -z $HORIZON_USER;
then
    HORIZON_USER=admin
fi
if test -z $HORIZON_PASSWORD;
then
    HORIZON_PASSWORD=ADMINpass
fi
if test -z $HORIZON_DOMAIN;
then
    HORIZON_DOMAIN=default
fi

# remove cookie file
if test -f $COOKIE_FILE; then
    rm -f $COOKIE_FILE
fi
#first curl to get the token on cookie file
$CURL -L -c $COOKIE_FILE -b $COOKIE_FILE --output /dev/null -s "$HORIZON_URL/dashboard/auth/login/"
TOKEN=`cat $COOKIE_FILE | grep csrftoken | sed 's/^.*csrftoken\s*//'`
DATA="username=$HORIZON_USER&password=$HORIZON_PASSWORD&domain=$HORIZON_DOMAIN&csrfmiddlewaretoken=$TOKEN"
#now we can authenticate
$CURL -L -c $COOKIE_FILE -b $COOKIE_FILE --output /dev/null -s -d "$DATA" --referer "$HORIZON_URL/dashboard/" "$HORIZON_URL/dashboard/auth/login/"
#verify the presence of sessionid
SESSIONID=`cat $COOKIE_FILE | grep sessionid | sed 's/^.*sessionid\s*//'`
if [ "$SESSIONID" == "" ]; then
    echo "Error: sessionid not present on file $COOKIE_FILE ...Exit"
    exit 1
fi
COOKIE=`$CURL -L -v -c $COOKIE_FILE -b $COOKIE_FILE --output /dev/null -s "$HORIZON_URL/dashboard/project" 2>&1 | grep "< Set-Cookie:" | tail -1 | cut -d: -f2`
echo $COOKIE

