#!/bin/bash

# Author owner: chenqiangzhishen@163.com

# This script aim to check mysqld service status.
# If the mysqld is dead, keepalived should be demoted.

# check the mysql service for three times,
# if mysql service is really dead, should kill the keepalived.
for check_times in `seq 1 3`; do
    sudo netstat -anp | grep 13388 | grep LISTEN > /dev/null 2>&1
    if [[ $? -eq 1 ]]; then
        sleep 1
        if [ $check_times -eq 3 ]; then
            sudo pkill keepalived
        fi
    fi
done

