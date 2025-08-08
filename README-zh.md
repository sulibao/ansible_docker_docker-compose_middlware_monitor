# ansible_keepalived
本文档说明了如何使用ansible+keepalived(DR)+lvs+nfs+httpd快速实现web的负载均衡

## 示例服务器

| IP                     | 用途                             |
| ---------------------- | -------------------------------- |
| 192.168.2.190（test1） | keepalived-master/lvs-config/nfs |
| 192.168.2.191（test2） | keepalived-slave/lvs-config      |
| 192.168.2.192（test3） | httpd                            |
| 192.168.2.193（test4） | httpd                            |

## 安装前

### 修改变量文件"./group_vars/all.yml"

```yaml
vim group_vars/all.yml
 
docker_data_dir: /app/docker_data
# 主
keepalived_masterIP: 192.168.2.190   
# 从
keepalived_slaveIP: 192.168.2.191    
# routerid，主从需要不一致
keepalived_master_routerid: LVS_DEVEL1   
keepalived_slave_routerid: LVS_DEVEL2
# 网卡名称，主从按实际情况填写
keepalived_master_interface: ens33    
keepalived_slave_interface: ens33
# router组id，主从需要一致
keepalived_virtual_router_id: "51"   
# 优先级，主>从
keepalived_master_priority: "100"   
keepalived_slave_priority: "80"
# password，主从一致
keepalived_auth_pass: "1111"   
# 需要设置的VIP地址
keepalived_vip: 192.168.2.100    
keepalived_web01: 192.168.2.192
keepalived_web01_port: "80"
keepalived_web02: 192.168.2.193
keepalived_web02_port: "80"
# nfs共享的目录
nfs_share_dir: /app/share   
nfs_ipv6_disabled: true
```

### 修改主机清单

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

### 修改setup.sh安装脚本

```sh
# 服务器root密码，这里要求两台台服务器密码一致
export ssh_pass="sulibao"  

```

## 安装

```sh
bash setup.sh
```

## 验证httpd负载效果

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
# 查看两台web的访问日志
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



## 检查项

### VIP故障迁移

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

### VIP所在服务器上查看ipvsadm规则是否正常生成

```
[root@test1 ansible_docker_docker-compose-main]# ipvsadm -Ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  192.168.2.100:80 rr
  -> 192.168.2.192:80             Route   1      0          0         
  -> 192.168.2.193:80             Route   1      0          0
```

### WEB服务器上查看是否生成回环网卡连接和到达VIP的路由条目

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

