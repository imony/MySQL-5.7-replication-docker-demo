MySQLによるフルメッシュ型相互レプリケーション

# このドキュメントが伝えること
MySQLを使っていわゆる全マスターと呼ばれる相互レプリケーションを行うために必要な知識と、それを踏まえた上でレプリケーション動作を試せるデモンストレーション環境を後置する方法について書いています。  
このドキュメントを頭から読むのをお勧めします。ですが、とりあえずサンプルを動かしてみたい場合には、3.デモ構築の手順に沿って動かした上で他の項目を読むのもいいかもしれません。

# ドキュメント構成
このドキュメントでは、MySQLに関する相互レプリケーションについて以下の構成で説明します。
1. 前提知識
2. 設定解説
3. デモ構築


----------------------------
# [前提知識] MySQLでレプリケーションする上で知っておくといいこと
## MySQLサーバデーモンは同時にマスターにもスレーブにもなれる
MySQLサーバデーモンは、他のMySQLサーバデーモンに対して主側（マスター）にも従側（スレーブ）にもなれます。また、誰かのマスターになりつつ、同時に誰かのスレーブにもなることができます。同時にマスターかつスレーブになれる特性を利用すると、A -> B -> C -> Aという風に主従関係をリング状に結ぶことでリング型全マスターの相互レプリケーションが構築できます。

## MySQL 5.7からは複数のマスターを持つことができる（マルチマスター機能）
MySQL 5.6までは、スレーブはそれぞれ１つのマスターしか持てませんでした。しかしMySQL 5.7からは、MySQLサーバデーモンは複数のマスターを持つことができるようになりました。マルチマスター機能と呼ばれています。これを実現するために新たに*チャネル*という概念がMySQLに導入されました。チャネルとはスレーブにおいてどのマスターとの通信かを識別するものです。スレーブはチャネルを用いることで、複数あるマスターを区別できます。
これにより、各々のMySQLサーバデーモンが自分以外のMySQLサーバデーモン全てをマスターとすることで、フルメッシュ型全マスターの相互レプリケーションを実現できます。  
後述するデモ構築の章では、このフルメッシュ型全マスターの相互レプリケーションの構築について記述しています。

## GTID（グローバルトランザクションID）について
設定項目にGTID関連の設定項目があるため、ここでGTIDに触れておきます。GTIDとは、個々のトランザクションに世界で固有のIDを付与する機能です。GTIDは次のようなフォーマットで表現されます。
```
発信元MySQLサーバUUID : トランザクションID
```
詳細の明言は避けますが、循環レプリケーションやマスターの切り替えにおいて効果を発揮するものです。今回のデモ構築においてもGTIDを利用する設定となっています。ただし、GTIDに対応していないSQL文があるため注意が必要です。


----------------------------
# [設定解説]  設定ファイルと項目の説明
レプリケーション向けMySQLの設定ファイルの項目について説明します。設定ファイルはMySQLサーバデーモン毎に１つ用意します。設定ファイルの設置場所やファイル名についてはここでは言及しません。それぞれの環境のドキュメントを参照してください。
まずは後述するデモ環境におけるとあるMySQLサーバデーモンの設定ファイルを示しますので、フォーマットの雰囲気をつかんでください。
mysqldの設定ファイル (mysql.cnf)
  ```
  [mysqld]
  character-set-server=utf8
  gtid_mode=ON
  enforce_gtid_consistency=ON
  server-id=10
  log_bin=/var/log/mysql/mysql-bin.log
  log_slave_updates
  master_info_repository=TABLE
  relay_log_info_repository=TABLE
  ```
  設定項目について説明します。

  |項目名|設定値|説明|
  |——-|——-|——-|
  |Character-set-server|utf8 など|テキストカラムの文字コードを指定します|
  |gtid_mode|ON/OFF|グローバルトランザクションIDの使用・不使用を指定します|
  |enforce_gtid_consistency|WARN/ON|グローバルトランザクションID非互換のSQL文を使った場合の挙動を指定します。WARN:警告をだす/ON:エラーとする|
  |server-id|int値|MySQLサーバデーモンの識別IDを指定します|
  |log_bin|パス文字列|MySQLサーバデーモンで行われたcommitログをバイナリデータでログ格納先パスに保存します|
  |log_slave_updates|なし|スレーブとしてマスターから受け取ったcommitの実行ログを保存することを指定します|
  |master_info_repository|TABLE/FILE|commitログの格納先を指定する。TABLEに設定するとクラッシュセーフに役立つ|
  |relay_log_info_repository|TABLE/FILE|マスターから送られてきたログの格納先を指定する。同上|



----------------------------
# [デモ構築] dockerですぐ試せるデモンストレーション環境の構築
## デモンストレーション環境の概要
  ここでは、以下のMySQLレプリケーションのデモンストレーションを行います。
  * ３つのMySQLサーバデーモンの相互レプリケーション（全マスター）
  * フルメッシュ型
  * 各々のMySQLサーバデーモンは異なる１つのテーブルを担当（書き込み）している
  * それぞれの担当テーブルが他のMySQLサーバデーモンにも共有されて、どのMySQLでも同じテーブルデータを持つ

## デモ動作要件
docker及びdocker-composeの動作する環境が必要になります。
以下のサイトを参考にして、インストールしてください。
https://docs.docker.com/engine/installation/
https://docs.docker.com/compose/install/

## 実行手順
デモンストレーションに必要なファイルをGitHubよりダウンロードできます。それをダウンロードした後、docker-composeで各MySQLコンテナを起動します。最後にmyqlreplicationdemo_mysqld_1コンテナに入り、MySQLスレーブ機能を立ち上げるコマンドスクリプトを実行します。以下に手順を示します。
```
$ git clone https://github.com/imony/MySQL-5.7-replication-docker-demo.git
$ cd MySQL-5.7-replication-docker-demo
$ docker-compose up -d           # 3つのdockerコンテナを立ち上げます
$ docker exec -it mysqlreplicationdemo_mysqld_1 bash     # コンテナの一つmysqlreplicationdemo_mysqld_1に入ります
(Docker) # sh /tmp/connector_mysqld.sh     # 各コンテナのMySQLスレーブ機能を起動するコマンドを実行します
```
以降は、いずれかのMySQLサーバデーモンで行われたcommitが他のMySQLサーバデーモンにも反映（レプリケーション）されます。いずれかのコンテナに入ってMySQLのデータベースを更新すると、他のコンテナのMySQLにも更新が反映されています。
一応、
* mysqlreplicationdemo_mysqld_1 はデータベースtestdbを担当
* mysqlreplicationdemo_mysqld2_1 はデータベースtestdb2を担当
* mysqlreplicationdemo_mysqld3_1 はデータベースtestdb3を担当  

としていますが、どのコンテナのMySQLでどのテーブルを更新しても反映されます。


## 注意事項
Docker-composeでMySQLコンテナを起動した場合は、Docker-composeの起動コマンドが完了するまでは、他のMySQLからのスレーブ登録コマンドを受け付けるポートが開きません。そのため、起動後に各MySQLサーバデーモンがスレーブ登録を行うためのスクリプト(mysqld:/tmp/connector_mysqld.shに格納されている）を手動で実行する必要があります。
