#!/bin/bash

FILE_PATH=$1
FILE_NAME="${FILE_PATH##*/}"
REVISION_FILE_PATH="https://www.dropbox.com/revisions/$FILE_NAME"

read -p 'email-adress: ' EMAIL_ADRESS
read -s -p 'password: ' PASSWORD; echo

curl -L -c cookie.txt -o output.html https://www.dropbox.com/login
TOKEN=`cat output.html | grep -e '<input type="hidden" name="t" value=".*" />' | grep -o 'value=".*"' | grep -o '".*"' | grep -o '[^"].*[^"]'`
curl -L -b cookie.txt -c login_cookie.txt -o output.html \
     --data-urlencode "t=$TOKEN" \
     --data-urlencode "login_email=$EMAIL_ADRESS" \
     --data-urlencode "login_password=$PASSWORD" \
     https://www.dropbox.com/login

curl -L -w "%{url_effective}" -b login_cookie.txt -o output.html $REVISION_FILE_PATH
echo
URLS=(`cat output.html|grep -o '<a href="https://dl-web.dropbox.com/get/.*</a>'|grep -o '"https://.*"'|grep -o '[^"].*[^"]'`)
echo ${URLS[@]}
CONTENTS=`curl -s -b login_cookie.txt ${URLS[1]}`
echo -en $CONTENTS|diff -u - $FILE_PATH