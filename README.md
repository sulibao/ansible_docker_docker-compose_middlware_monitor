# ansible_redis_sentinel

This document explains how to use Ansible and docker-compose to quickly deploy a single-master, dual-slave, and three-sentry Redis cluster on three machines.

## Example server list

| IP                     | Purpose        |
| ---------------------- | -------------- |
| 192.168.2.190（test1） | Initial master |
| 192.168.2.191（test2） | Initial slave1 |
| 192.168.2.192（test3） | Initial slave2 |

## General framework logic

![](https://i-blog.csdnimg.cn/direct/5046d57775684d5d8a9b6e92e3e6afa6.png)

## Before install

### Modify variables file "./group_vars/all.yml"

```yaml
vim group_vars/all.yml
# docker's data directory
docker_data_dir: /app/docker_data   
# redis's data directory
data_dir: /app
# sentinel port
redis_sentinel_port: 26379    
# redis auth password
redis_pass: "sulibao"    
# redis and sentinel image
image_redis: "registry.cn-chengdu.aliyuncs.com/su03/redis:7.2.7"   
```

### Modify host list

```yaml
[root@test1 redis_data]# cat hosts 
[redis_master]  
# Initial redis-master address 
192.168.2.190
[redis_slave1] 
# Initial redis-slave1 address 
192.168.2.191 
[redis_slave2]
# Initial redis-slave2 address
192.168.2.192
 
[redis_slave:children]
redis_slave1
redis_slave2
 
[redis:children]
redis_master
redis_slave1
redis_slave2
```

### Modify install file setup.sh 

```sh
# Server root password. It is required that the passwords for all three servers be the same.
export ssh_pass="sulibao"  

```

## Install

```sh
bash setup.sh
```

## Verify the failover of the redis-master

```sh
# Initial cluster information: test1 is the primary node, while test2 and test3 are secondary nodes.
docker exec -it redis-master bash
root@test1:/data# redis-cli -a sulibao role
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
1) "master"
2) (integer) 35726
3) 1) 1) "192.168.2.191"
      2) "6379"
      3) "35726"
   2) 1) "192.168.2.192"
      2) "6379"
      3) "35585"
 
 
# The primary server (test1) has been suspended, and a new primary server (test2) has been established. Server test3 remains as a secondary server.
[root@test1 redis_data]# docker stop redis-master
redis-master
[root@test2 ~]# docker exec -it redis-slave1 bash
root@test2:/data# redis-cli -a sulibao role
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
1) "master"
2) (integer) 68953
3) 1) 1) "192.168.2.192"
      2) "6379"
      3) "68953"
 
# Restore the original master (test1) to the slave role. Now, the master is test2, while test1 and test3 are slaves.
[root@test1 redis_data]# docker start redis-master
redis-master
root@test2:/data# redis-cli -a sulibao role
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
1) "master"
2) (integer) 87291
3) 1) 1) "192.168.2.192"
      2) "6379"
      3) "87291"
   2) 1) "192.168.2.190"
      2) "6379"
      3) "87291"
```