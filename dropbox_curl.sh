#!/bin/bash

FILE_PATH=$1
DROPBOX_PATH="${FILE_PATH##*/Dropbox/}"
REVISION_FILE_URL="https://www.dropbox.com/revisions/$DROPBOX_PATH"




dropbox_login() {
	read -p 'email-adress: ' EMAIL_ADRESS
	read -s -p 'password: ' PASSWORD; echo
	
	curl -L -c cookie.txt -o output.html https://www.dropbox.com/login
	TOKEN=`cat output.html | grep -e '<input type="hidden" name="t" value=".*" />' | grep -o 'value=".*"' | grep -o '".*"' | grep -o '[^"].*[^"]'`
	curl -L -b cookie.txt -c login_cookie.txt -o output.html \
	     --data-urlencode "t=$TOKEN" \
	     --data-urlencode "login_email=$EMAIL_ADRESS" \
	     --data-urlencode "login_password=$PASSWORD" \
	     https://www.dropbox.com/login
}

revision_files_page() {
	curl -L -w "%{url_effective}" -b login_cookie.txt -o output.html $REVISION_FILE_URL
}

extract_file_urls() {
	cat output.html|grep -o '<a href="https://dl-web.dropbox.com/get/.*</a>'|grep -o '"https://.*"'|grep -o '[^"].*[^"]'
}

download_revision_file() {
	curl -s -b login_cookie.txt ${URLS[$1]}
}




# リダイレクトした時だけログインし直す
RES=`revision_files_page`
if [ $RES != $REVISION_FILE_URL ]; then
	dropbox_login
	revision_files_page
fi

echo
URLS=(`extract_file_urls`)
echo ${URLS[@]}
CONTENTS=`download_revision_file 1`
echo -en $CONTENTS|diff -u - $FILE_PATH
