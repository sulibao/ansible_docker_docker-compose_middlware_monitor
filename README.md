# ansible_keepalived
This document explains how to use ansible + keepalived (DR) + lvs + nfs + httpd to quickly achieve web load balancing.

## Example server list

| IP                     | Purpose                          |
| ---------------------- | -------------------------------- |
| 192.168.2.190（test1） | keepalived-master/lvs-config/nfs |
| 192.168.2.191（test2） | keepalived-slave/lvs-config      |
| 192.168.2.192（test3） | httpd                            |
| 192.168.2.193（test4） | httpd                            |

## Before install

### Modify the variables filr "./group_vars/all.yml"

```yaml
vim group_vars/all.yml
 
docker_data_dir: /app/docker_data
# master
keepalived_masterIP: 192.168.2.190
# slave
keepalived_slaveIP: 192.168.2.191
# routerid,the values need to be different
keepalived_master_routerid: LVS_DEVEL1   
keepalived_slave_routerid: LVS_DEVEL2
# Network card name. Fill in "master-slave" according to the actual situation
keepalived_master_interface: ens33    
keepalived_slave_interface: ens33
# Router group ID, master-slave consistency is required
keepalived_virtual_router_id: "51"   
# Priority: Main > Subordinate
keepalived_master_priority: "100"   
keepalived_slave_priority: "80"
#password, master-slave consistency
keepalived_auth_pass: "1111"   
# Required VIP Address Settings
keepalived_vip: 192.168.2.100    
keepalived_web01: 192.168.2.192
keepalived_web01_port: "80"
keepalived_web02: 192.168.2.193
keepalived_web02_port: "80"
# nfs directory for share
nfs_share_dir: /app/share
nfs_ipv6_disabled: true
```

### Modify the host list

```yaml
[keepalived_master]   
192.168.2.190
[keepalived_slave]  
192.168.2.191
[keealived_web01]
192.168.2.192
[keealived_web02]
192.168.2.193
[nfs_server]
192.168.2.190

[keepalived_cluster:children]
keepalived_master
keepalived_slave

[web_cluster:children]
keealived_web01
keealived_web02

[all_nodes:children]
keepalived_master
keepalived_slave
keealived_web01
keealived_web02
```

### Modify the setup.sh install file

```sh
# Server root password. It is required that the passwords for both servers be the same.
export ssh_pass="sulibao"  

```

## Install 

```sh
bash setup.sh
```

## Verify the performance of httpd

```bash
[root@test2 ~]# for i in {1..10};do curl 192.168.2.100; done
test_web
test_web
test_web
test_web
test_web
test_web
test_web
test_web
test_web
test_web
# check the access logs from two web servers
[root@test3 httpd]# cat access_log
192.168.2.191 - - [29/May/2025:14:45:35 +0800] "GET / HTTP/1.1" 200 9 "-" "curl/7.29.0"
192.168.2.191 - - [29/May/2025:14:45:35 +0800] "GET / HTTP/1.1" 200 9 "-" "curl/7.29.0"
192.168.2.191 - - [29/May/2025:14:45:35 +0800] "GET / HTTP/1.1" 200 9 "-" "curl/7.29.0"
192.168.2.191 - - [29/May/2025:14:45:35 +0800] "GET / HTTP/1.1" 200 9 "-" "curl/7.29.0"
192.168.2.191 - - [29/May/2025:14:45:35 +0800] "GET / HTTP/1.1" 200 9 "-" "curl/7.29.0"
[root@test4 httpd]# cat access_log
192.168.2.191 - - [29/May/2025:14:45:35 +0800] "GET / HTTP/1.1" 200 9 "-" "curl/7.29.0"
192.168.2.191 - - [29/May/2025:14:45:35 +0800] "GET / HTTP/1.1" 200 9 "-" "curl/7.29.0"
192.168.2.191 - - [29/May/2025:14:45:35 +0800] "GET / HTTP/1.1" 200 9 "-" "curl/7.29.0"
192.168.2.191 - - [29/May/2025:14:45:35 +0800] "GET / HTTP/1.1" 200 9 "-" "curl/7.29.0"
192.168.2.191 - - [29/May/2025:14:45:35 +0800] "GET / HTTP/1.1" 200 9 "-" "curl/7.29.0"
```



## Check the entry

### VIP failure switching

```
[root@test1 ansible_docker_docker-compose-main]# ip a| grep ens33
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 192.168.2.190/24 brd 192.168.2.255 scope global noprefixroute ens33
    inet 192.168.2.100/32 scope global ens33
[root@test2 ~]# ip a | grep ens33
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 192.168.2.191/24 brd 192.168.2.255 scope global noprefixroute ens33
    
[root@test1 ansible_docker_docker-compose-main]# systemctl stop keepalived #停止keepalived
[root@test1 ansible_docker_docker-compose-main]# ip a| grep ens33
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 192.168.2.190/24 brd 192.168.2.255 scope global noprefixroute ens33
[root@test2 ~]# ip a | grep ens33
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 192.168.2.191/24 brd 192.168.2.255 scope global noprefixroute ens33
    inet 192.168.2.100/32 scope global ens33
```

### Check whether the ipvsadm rules are generated normally on the server where the VIP is located.

```
[root@test1 ansible_docker_docker-compose-main]# ipvsadm -Ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  192.168.2.100:80 rr
  -> 192.168.2.192:80             Route   1      0          0         
  -> 192.168.2.193:80             Route   1      0          0
```

### Check on the WEB server whether the loopback network card connection and the routing entries for reaching the VIP have been generated.

```
[root@test3 httpd]# ip a|grep lo
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    inet 192.168.2.100/32 brd 192.168.2.100 scope global lo:100
    inet 192.168.2.192/24 brd 192.168.2.255 scope global noprefixroute ens33
[root@test3 httpd]# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.2.1     0.0.0.0         UG    100    0        0 ens33
192.168.2.0     0.0.0.0         255.255.255.0   U     100    0        0 ens33
192.168.2.100   0.0.0.0         255.255.255.255 UH    0      0        0 lo

[root@test4 httpd]# ip a | grep lo
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    inet 192.168.2.100/32 brd 192.168.2.100 scope global lo:100
    inet 192.168.2.193/24 brd 192.168.2.255 scope global noprefixroute ens33
[root@test4 httpd]# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.2.1     0.0.0.0         UG    100    0        0 ens33
192.168.2.0     0.0.0.0         255.255.255.0   U     100    0        0 ens33
192.168.2.100   0.0.0.0         255.255.255.255 UH    0      0        0 lo
```

