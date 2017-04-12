#!/bin/bash

# Author owner: chenqiangzhishen@163.com

# TODO: please use an IP that never use in your env
VIP='10.209.224.253'
# TODO: maybe you should use eth0|1 interface in your env
INTERFACE=bond0

MYSQL_IMAGE=mysql:5.6.35
KEEPALIVED_IMAGE=solnetcloud/keepalived:1.2.7

function fail() {
    echo "$@"
    exit 1
}

echo "start to deploy master...."

if [ ! -d /etc/mysql-custom ]; then
    sudo mkdir -p /etc/mysql-custom
fi

if [ -f mysql13388.cnf ]; then
    sudo cp -f mysql13388.cnf /etc/mysql-custom/
else
    fail "[FAIL]: please put mysql13388.cnf in the current dir"
fi

# docker remove existed containers
sudo docker rm -f mysql_master > /dev/null 2>&1 | true
sudo docker rm -f mysql_slave > /dev/null 2>&1 | true

# rm mysql data file
sudo rm -rf /data1/mysql

sudo docker run --name mysql_master --net=host --restart=on-failure \
     -v /etc/mysql-custom:/etc/mysql/conf.d \
     -v /data1/mysql:/var/lib/mysql \
     -e MYSQL_ROOT_PASSWORD=Passw0rd \
     -d $MYSQL_IMAGE mysqld --server-id=161733388 > /dev/null 2>&1
[[ $? == 0 ]] && echo "[OK]: docker run mysql_master" || fail "[FAIL]: docker run mysql_master"

# waiting for mysql master create finished
sleep 20

sudo docker exec mysql_master /usr/bin/mysql -uroot -pPassw0rd -AN -e 'GRANT REPLICATION SLAVE ON *.* TO "replica"@"%" IDENTIFIED BY "repl_slave";' > /dev/null 2>&1
[[ $? == 0 ]] && echo "[OK]: mysql grant replication slave" || fail "[FAIL]: mysql grant replication slave"

sudo docker exec mysql_master /usr/bin/mysql -uroot -pPassw0rd -AN -e 'flush privileges;' > /dev/null 2>&1
[[ $? == 0 ]] && echo "[OK]: mysql flush privileges" || fail "[FAIL]: mysql flush privileges"

sudo docker rm -f keepalived | true > /dev/null 2>&1

# delete vip dev to avoid old vip existed
sudo ip a | grep $VIP > /dev/null 2>&1
[[ $? == 0 ]] && sudo ip a del $VIP dev $INTERFACE > /dev/null 2>&1

sudo docker run --name=keepalived --restart=on-failure \
     --net=host --privileged=true \
     --volume=$PWD/:/ka-data/scripts/ \
     -d $KEEPALIVED_IMAGE --master --override-check check-mysql-status.sh --enable-check --auth-pass pass --vrid 52 $INTERFACE 101 $VIP/24/$INTERFACE > /dev/null 2>&1
[[ $? == 0 ]] && echo "[OK]: docker run keepalived" || fail "[FAIL]: docker run keepalived"

echo "================================="
echo "[OK]: master deploy finished"
