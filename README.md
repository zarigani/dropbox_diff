dropbox_diff
============

Dropboxのバージョン履歴を指定して、その差分を出力するシェルスクリプトです。


使い方
-----

````
$ ./dropbox_diff.sh ~/Dropbox/hello.txt

email-adress: XXXXXXXX@mail.com
password: 

*** Version list(Top is newest) ***
    3: Version3
    2: Version2
    1: Version1
Select( number  [o]pen  [h]elp  [q]uit )> 
`diff Version2 Version3`

--- /dev/fd/63	2012-10-09 01:38:29.000000000 +0900
+++ /dev/fd/62	2012-10-09 01:38:29.000000000 +0900
@@ -1 +1 @@
-hello world
+Hello, world!
````

* 入力なし　`diff -u Version2 Version3`
* 3　　　　`diff -u Version2 Version3`
* 2　　　　`diff -u Version1 Version2`
* 1 3　　　`diff -u Version1 Version3`
* 3 1　　　`diff -u Version3 Version1`
* o　　　　Dropboxのバージョン管理のページを開く（Webブラウザが起動）
* h　　　　helpを出力する
* q　　　　終了する


開発環境
-------

* MacBook Pro Retina
* OSX 10.8.2
* Dropbox v1.4.12
* GNU bash, version 3.2.48(1)-release (x86_64-apple-darwin12)
* git version 1.7.12.1