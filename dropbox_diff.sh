#!/bin/bash

# Dropboxへログインする
dropbox_login() {
	read -p 'email-adress: ' EMAIL_ADRESS
	read -s -p 'password: ' PASSWORD; echo
	
	curl -L -c $COOKIE_PATH -o $OUTPUT_PATH https://www.dropbox.com/login
	TOKEN=`cat $OUTPUT_PATH | grep -e '<input type="hidden" name="t" value=".*" />' | grep -o 'value=".*"' | grep -o '".*"' | grep -o '[^"].*[^"]'`
	curl -L -b $COOKIE_PATH -c $COOKIE_PATH \
	     --data-urlencode "t=$TOKEN" \
	     --data-urlencode "login_email=$EMAIL_ADRESS" \
	     --data-urlencode "login_password=$PASSWORD" \
	     https://www.dropbox.com/login > /dev/null
  chmod 600 $COOKIE_PATH $OUTPUT_PATH
}

# ファイルのバージョン管理のページを取得する
revision_files_page() {
	curl -L -w "%{url_effective}" -b $COOKIE_PATH -o $OUTPUT_PATH $REVISION_FILE_URL
}

# バージョンごとのファイルのURLを抜き出す
extract_file_urls() {
	cat $OUTPUT_PATH|grep -o '<a href="https://dl-web.dropbox.com/get/.*</a>'|grep -o '"https://.*"'|grep -o '[^"].*[^"]'
}

# 指定したバージョンのファイルをダウンロードする
download_revision_file() {
	curl -s -b $COOKIE_PATH -o "$2" ${URLS[$(($MAX_VERSION - $1))]}
}

# 特定のバイナリファイルをテキスト変換する
pre_command() {
  case "$FILE_PATH" in
    *.scpt )  echo 'osadecompile' ;;
    *.rtf )   echo 'textutil -convert txt -stdout' ;;
    * )       echo 'cat' ;;
  esac
}

# URLエンコード
urlencode() {
  ruby -r cgi -e "puts CGI.escape('$1')"
}

# URLデコード
urldecode() {
  ruby -r cgi -e "puts CGI.unescape('$1')"
}

# Dropboxのバージョン管理のWebページをブラウザで開く
option_open() {
	echo "\`open location \"$REVISION_FILE_URL\"\`"
	open "$REVISION_FILE_URL"
}

# 対話的な操作のヘルプを表示する
option_help() {
	echo "# Example (When Version3 is newest.) :"
	echo "#    ''      \`diff Version2 Version3\`"
	echo "#    '3'     \`diff Version2 Version3\`"
	echo "#    '2'     \`diff Version1 Version2\`"
	echo "#    '1 3'   \`diff Version1 Version3\`"
	echo "#    'o'     Open Dropbox web page."
	echo "#    'h'     Show this help."
	echo "#    'q'     Quit this command."
}




FILE_PATH=$1
DROPBOX_PATH="${FILE_PATH##*/Dropbox/}"
REVISION_FILE_URL="https://www.dropbox.com/revisions/$DROPBOX_PATH"

# $TMPDIRを利用できる環境かどうか判定して、作業ファイルの保存場所を設定する
if [ -n $TMPDIR ]; then
  [ -d "${TMPDIR}com.bebekoubou.dropbox_diff" ] || mkdir "${TMPDIR}com.bebekoubou.dropbox_diff"
  COOKIE_PATH="${TMPDIR}com.bebekoubou.dropbox_diff/cookie"
  OUTPUT_PATH="${TMPDIR}com.bebekoubou.dropbox_diff/output"
  CONTENTS_PATH="${TMPDIR}com.bebekoubou.dropbox_diff/contents_"
else
  COOKIE_PATH="${HOME}/.com.bebekoubou.dropbox_diff.cookie"
  OUTPUT_PATH="${HOME}/.com.bebekoubou.dropbox_diff.output"
  CONTENTS_PATH="${HOME}/.com.bebekoubou.dropbox_diff.contents_"
fi

# リダイレクトした時だけログインし直す（3回試行）
for i in `seq 1 4`
do
  [ `revision_files_page` = $REVISION_FILE_URL ] && break
  [ $i = 4 ] && exit
  dropbox_login
done

# ファイルのURLを配列にして、バージョンの個数を取得する
URLS=(`extract_file_urls`)
MAX_VERSION=${#URLS[@]}

# 対話的に操作する
while :
do
	# バージョンリストを表示
  echo
	echo '*** Version list(Top is newest) ***'
  [ $MAX_VERSION = 0 ] && echo 'Dropbox is busy. Try [o]pen.'
  [ $MAX_VERSION = 1 ] && echo 'Version is only one.' && exit
	for (( i = $MAX_VERSION; i > 0 ; --i ))
	do
		echo -e "    $i: Version$i"
	done
  
  # 入力待ち
	read -p 'Select( number  [o]pen  [h]elp  [q]uit )> ' VER1 VER2
  
  # 入力コマンドの処理、バージョン番号を取得、入力値のエラー処理
	if [[ $VER1 = "q" ]]; then
		echo 'quit'
		exit
	elif [[ $VER1 = "o" ]]; then
		option_open
		continue
	elif [[ $VER1 = "h" ]]; then
		option_help
		continue
	elif [[ $VER1 =~ ^[0-9]*$ ]] && [[ $VER2 =~ ^[0-9]*$ ]]; then
		if [[ -z "$VER1" ]]; then
			VER1=$MAX_VERSION
		fi
		if [[ -z "$VER2" ]]; then
			VER2=$VER1
			VER1=`expr $VER1 - 1`
		fi
		if [[ $VER1 -gt 0 ]] && [[ $VER1 -le $MAX_VERSION ]] && [[ $VER2 -gt 0 ]] && [[ $VER2 -le $MAX_VERSION ]]; then
			break
		fi
	fi
	echo 'error!'
	exit
done
echo "\`diff Version$VER1 Version$VER2\`"
echo

# 指定バージョンをダウンロードする
if [[ $(($MAX_VERSION - $VER1)) = 0 ]]; then
	CONTENTS_1="$FILE_PATH"
else
	CONTENTS_1="${CONTENTS_PATH}1"
  download_revision_file $VER1 $CONTENTS_1
fi
if [[ $(($MAX_VERSION - $VER2)) = 0 ]]; then
	CONTENTS_2="$FILE_PATH"
else
	CONTENTS_2="${CONTENTS_PATH}2"
  download_revision_file $VER2 $CONTENTS_2
fi

# diff出力
diff -u <(`pre_command` "$CONTENTS_1") <(`pre_command` "$CONTENTS_2")
echo
