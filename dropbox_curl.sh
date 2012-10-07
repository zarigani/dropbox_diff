#!/bin/bash

EMAIL_ADRESS=$1
PASSWORD=$2
FILE_NAME=$3

curl -L -c cookie.txt -o output.html https://www.dropbox.com/login
TOKEN=`cat output.html | grep -e '<input type="hidden" name="t" value=".*" />' | grep -o 'value=".*"' | grep -o '".*"' | grep -o '[^"].*[^"]'`
curl -L -b cookie.txt -c login_cookie.txt -o output.html \
     --data-urlencode "t=$TOKEN" \
     --data-urlencode "login_email=$EMAIL_ADRESS" \
     --data-urlencode "login_password=$PASSWORD" \
     https://www.dropbox.com/login
curl -L -b login_cookie.txt -o output.html "https://www.dropbox.com/revisions/$FILE_NAME"
