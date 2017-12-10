#!/bin/bash

mysql -h mysqld -P 3306 --protocol=tcp -u root -psecret -e 'STOP SLAVE;';
mysql -h mysqld -P 3306 --protocol=tcp -u root -psecret -e 'CHANGE REPLICATION FILTER REPLICATE_DO_DB=(testdb2, testdb3);';
mysql -h mysqld -P 3306 --protocol=tcp -u root -psecret -e 'CHANGE MASTER TO MASTER_HOST="mysqld2", MASTER_PORT=3306, MASTER_AUTO_POSITION=1, MASTER_HEARTBEAT_PERIOD=60 FOR CHANNEL "ch2";';
mysql -h mysqld -P 3306 --protocol=tcp -u root -psecret -e 'START SLAVE USER="user1onmysqld2" PASSWORD="mysqlpasswd" FOR CHANNEL "ch2";';
mysql -h mysqld -P 3306 --protocol=tcp -u root -psecret -e 'CHANGE MASTER TO MASTER_HOST="mysqld3", MASTER_PORT=3306, MASTER_AUTO_POSITION=1, MASTER_HEARTBEAT_PERIOD=60 FOR CHANNEL "ch3";';
mysql -h mysqld -P 3306 --protocol=tcp -u root -psecret -e 'START SLAVE USER="user1onmysqld3" PASSWORD="mysqlpasswd" FOR CHANNEL "ch3";';


mysql -h mysqld2 -P 3306 --protocol=tcp -u root -psecret -e 'STOP SLAVE;';
mysql -h mysqld2 -P 3306 --protocol=tcp -u root -psecret -e 'CHANGE REPLICATION FILTER REPLICATE_DO_DB=(testdb, testdb3);';
mysql -h mysqld2 -P 3306 --protocol=tcp -u root -psecret -e 'CHANGE MASTER TO MASTER_HOST="mysqld", MASTER_PORT=3306, MASTER_AUTO_POSITION=1, MASTER_HEARTBEAT_PERIOD=60 FOR CHANNEL "ch1";';
mysql -h mysqld2 -P 3306 --protocol=tcp -u root -psecret -e 'START SLAVE USER="user2onmysqld1" PASSWORD="mysqlpasswd" FOR CHANNEL "ch1";';
mysql -h mysqld2 -P 3306 --protocol=tcp -u root -psecret -e 'CHANGE MASTER TO MASTER_HOST="mysqld3", MASTER_PORT=3306, MASTER_AUTO_POSITION=1, MASTER_HEARTBEAT_PERIOD=60 FOR CHANNEL "ch3";';
mysql -h mysqld2 -P 3306 --protocol=tcp -u root -psecret -e 'START SLAVE USER="user2onmysqld3" PASSWORD="mysqlpasswd" FOR CHANNEL "ch3";';


mysql -h mysqld3 -P 3306 --protocol=tcp -u root -psecret -e 'STOP SLAVE;';
mysql -h mysqld3 -P 3306 --protocol=tcp -u root -psecret -e 'CHANGE REPLICATION FILTER REPLICATE_DO_DB=(testdb, testdb2);';
mysql -h mysqld3 -P 3306 --protocol=tcp -u root -psecret -e 'CHANGE MASTER TO MASTER_HOST="mysqld", MASTER_PORT=3306, MASTER_AUTO_POSITION=1, MASTER_HEARTBEAT_PERIOD=60 FOR CHANNEL "ch1";';
mysql -h mysqld3 -P 3306 --protocol=tcp -u root -psecret -e 'START SLAVE USER="user3onmysqld1" PASSWORD="mysqlpasswd" FOR CHANNEL "ch1";';
mysql -h mysqld3 -P 3306 --protocol=tcp -u root -psecret -e 'CHANGE MASTER TO MASTER_HOST="mysqld2", MASTER_PORT=3306, MASTER_AUTO_POSITION=1, MASTER_HEARTBEAT_PERIOD=60 FOR CHANNEL "ch2";';
mysql -h mysqld3 -P 3306 --protocol=tcp -u root -psecret -e 'START SLAVE USER="user3onmysqld2" PASSWORD="mysqlpasswd" FOR CHANNEL "ch2";';
