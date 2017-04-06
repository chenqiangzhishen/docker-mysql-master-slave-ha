# docker-mysql-master-slave-ha
Use docker to create mysql service in master and slave mode with keepalived as HA.

We create mysql service in docker and let it work in master-slave mode to sync database with each other.
to keep HA, we use keepalived which works as docker also.

## how to use

To deploy mysql service, we suggest to prepare two nodes. one is used to deploy mysql-master service, another is
used to deployed msyql-slave.

To use the script is easy, please install mysql-master firstly, then install mysql-slave, please follow the steps below:

  1. copy the config and mysql-master.sh files to mysql-master host node. and specify one VIP to substitute the value of
  env variable VIP in the mysql-master.sh file according your deployment env as well as the variable INTERFACE. and then
  run it.

          `bash ./mysql-master.sh`

  if you see the log `[OK]: master deploy finished`, it means mysql-master service deployed successfully.

  2. copy the config and mysql-slave.sh files to mysql-slave host node. also, we should specify the same VIP and INTERFACE
  in mysql-slave.sh as in mysql-master.sh. please note that we should specify the mysql-master host IP, then run it.

          `bash ./mysql-slave.sh`

  if you see the log `[OK]: slave deploy finished`, it means mysql-slave service deployed successfully.

Now you get a mysql worked in master-slave mode. congratulations!!!

## how to test

1. we can stop keepalived or mysql-master service, it will demoted mysqld in mysql-master host, and VIP shifts it to mysql-slave.

2. we can `telnet VIP:13388` to use mysql in your workstation.
