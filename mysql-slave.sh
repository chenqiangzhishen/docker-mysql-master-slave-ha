#!/bin/bash

# Author owner: chenqiangzhishen@163.com

# TODO: please use an IP that never use before according to your env
VIP='10.209.224.253'
# TODO: use the mysql master host ip in your env
MYSQL_MASTER_IP='10.209.224.18'
# TODO: maybe you should use eth0|1 interface in your env
INTERFACE=bond0

MYSQL_IMAGE=mysql:5.6.35
KEEPALIVED_IMAGE=solnetcloud/keepalived:1.2.7

function fail() {
    echo "$@"
    exit 1
}

echo "start to deploy slave..."

if [ ! -d /etc/mysql-custom ]; then
    sudo mkdir -p /etc/mysql-custom
fi

if [ -f mysql13388.cnf ]; then
    sudo cp -f mysql13388.cnf /etc/mysql-custom/
else
    fail "please put mysql13388.cnf in the current dir"
fi

# docker remove existed containers
sudo docker rm -f mysql_master > /dev/null 2>&1 | true
sudo docker rm -f mysql_slave > /dev/null 2>&1 | true

# rm mysql data file
sudo rm -rf /data1/mysql

sudo docker run --name mysql_slave --net=host --restart=always \
     -v /etc/mysql-custom:/etc/mysql/conf.d \
     -v /data1/mysql:/var/lib/mysql \
     -e MYSQL_ROOT_PASSWORD=Passw0rd \
     -d $MYSQL_IMAGE mysqld --server-id=161833388 > /dev/null 2>&1
[[ $? == 0 ]] && echo "[OK]: docker run mysql_slave" || fail "[FAIL]: docker run mysql_slave"

# waiting for mysql slave create finished
sleep 20

sudo docker exec mysql_slave /usr/bin/mysql -uroot -pPassw0rd -AN -e "CHANGE MASTER TO master_host='$MYSQL_MASTER_IP', master_port=13388, master_user='replica', master_password='repl_slave', MASTER_AUTO_POSITION=1;" > /dev/null 2>&1
[[ $? == 0 ]] && echo "[OK]: mysql set to change master" || fail "[FAIL]: mysql set to change master"

sudo docker exec mysql_slave /usr/bin/mysql -uroot -pPassw0rd -e "start slave;\G;" > /dev/null 2>&1
[[ $? == 0 ]] && echo "[OK]: mysql start slave" || fail "[FAIL]: mysql start slave"

ret=$(sudo docker exec mysql_slave /usr/bin/mysql -uroot -pPassw0rd -e "show slave status \G;" | grep Running | grep Yes | wc -l) > /dev/null 2>&1
[[ $ret -eq 2 ]] && echo "[OK]: slave synced with master" || fail "[FAIL]: slave synced with master"

sudo docker rm -f keepalived > /dev/null 2>&1 | true

# delete vip dev to avoid old vip existed
sudo ip a | grep $VIP > /dev/null 2>&1
[[ $? == 0 ]] && sudo ip a del $VIP dev $INTERFACE > /dev/null 2>&1

sudo docker run --restart=on-failure --log-driver=syslog \
     --net=host --privileged=true --name=keepalived \
     --volume=$PWD/:/ka-data/scripts/ \
     -d $KEEPALIVED_IMAGE \
     --override-check check-mysql-status.sh --enable-check \
     --auth-pass pass --vrid 52 $INTERFACE 99 $VIP/24/$INTERFACE > /dev/null 2>&1
[[ $? == 0 ]] && echo "[OK]: docker run keepalived" || fail "[FAIL]: docker run keepalived"

echo "================================"
echo "[OK]: slave deploy finished"
