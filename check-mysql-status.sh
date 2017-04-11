#!/bin/bash

# Author owner: chenqiangzhishen@163.com

# This script aim to check mysqld service status.
# if the mysqld is dead, keepalived should be demoted.
# keepalived will check the script return code,
# if true, means the script execute success and the VIP should not shift,
# if false, means mysqld service in bad status, keepalived should be demoted,
# and the VIP should shift to slave node.
sudo netstat -anp | grep 13388 | grep LISTEN > /dev/null 2>&1

# for check_times in `seq 1 3`; do
#     sudo netstat -anp | grep 13388 | grep LISTEN > /dev/null 2>&1
#     if [[ $? -eq 1 ]]; then
#         sleep 1
#         if [ $check_times -eq 3 ]; then
#             sudo pkill keepalived
#         fi
#     fi
# done

