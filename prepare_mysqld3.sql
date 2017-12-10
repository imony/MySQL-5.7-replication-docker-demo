
CREATE USER user1onmysqld3 IDENTIFIED BY 'mysqlpasswd';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO user1onmysqld3;
FLUSH PRIVILEGES;

CREATE USER user2onmysqld3 IDENTIFIED BY 'mysqlpasswd';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO user2onmysqld3;
FLUSH PRIVILEGES;

DROP DATABASE IF EXISTS testdb3;
CREATE DATABASE testdb3;
USE testdb3;
CREATE TABLE tb1(tb1col VARCHAR(10));
CREATE TABLE tb2(tb2col VARCHAR(10));

STOP SLAVE;
CHANGE REPLICATION FILTER REPLICATE_DO_DB=(testdb, testdb2);

CHANGE MASTER TO MASTER_HOST='mysqld', MASTER_PORT=3306, MASTER_AUTO_POSITION=1, MASTER_HEARTBEAT_PERIOD=60 FOR CHANNEL 'ch1';
START SLAVE USER='user3onmysqld1' PASSWORD='mysqlpasswd' FOR CHANNEL 'ch1';

CHANGE MASTER TO MASTER_HOST='mysqld2', MASTER_PORT=3306, MASTER_AUTO_POSITION=1, MASTER_HEARTBEAT_PERIOD=60 FOR CHANNEL 'ch2';
START SLAVE USER='user3onmysqld2' PASSWORD='mysqlpasswd' FOR CHANNEL 'ch1';
