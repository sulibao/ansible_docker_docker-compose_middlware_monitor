# ansible_minio_cluster

This document is intended to explain how to use Ansible, Docker, and Docker Compose to quickly deploy a highly available and distributed Minio cluster with four replicas.

## Example server list

| IP                     | purpose|
| :--------------------- | ------ |
| 192.168.2.190（test1） | Minio1 |
| 192.168.2.191（test2） | Minio2 |
| 192.168.2.192（test3） | Minio3 |
| 192.168.2.193（test4） | Minio4 |



## Before install

### Modify variables file "./group_vars/all.yml"

```bash
# docker's data directory
docker_data_dir: /app/docker_data   
# minio data directory
minio_data: /app/minio_data   
# minio access port
minio_port: 9000       
# minio-console access port      
minio_console_port: 9001      
# minio image
image_minio: "registry.cn-chengdu.aliyuncs.com/su03/minio:RELEASE.2024-05-28T17-19-04Z"
# minio-ak
minio_ak: "admin"  
# minio-sk  
minio_sk: "admin@2025"   
```

### Modify ansible host list

```bash
# The following are the IP addresses of the 4 nodes for deploying Minio
[minio01]  
192.168.2.190
[minio_others01]
192.168.2.191
[minio_others02]
192.168.2.192
[minio_others03]
192.168.2.193
```

### Modify the install file setup.sh

```bash
vim setup.sh
# This should be filled in with the password of the server's root user.
export ssh_pass="sulibao"     
```

## Install

```
bash setup.sh
```

## Verification after Installation

- Command line verification

```bash
# Enter any node, any Minio container
docker exec -it minio_data-minio-1 bash  
# Set the alias of any node 
bash-5.1# mc alias set mycluster http://test1:9000 admin admin@2025   
mc: Configuration written to `/tmp/.mc/config.json`. Please update your access credentials.
mc: Successfully created `/tmp/.mc/share`.
mc: Initialized share uploads `/tmp/.mc/share/uploads.json` file.
mc: Initialized share downloads `/tmp/.mc/share/downloads.json` file.
Added `mycluster` successfully. 

# Check the cluster status. As shown below, it is a normal 4-replica online state.
bash-5.1# mc admin info mycluster    
●  test1:9000
   Uptime: 16 minutes 
   Version: 2024-05-28T17:19:04Z
   Network: 4/4 OK 
   Drives: 1/1 OK 
   Pool: 1

●  test2:9000
   Uptime: 20 minutes 
   Version: 2024-05-28T17:19:04Z
   Network: 4/4 OK 
   Drives: 1/1 OK 
   Pool: 1

●  test3:9000
   Uptime: 54 seconds 
   Version: 2024-05-28T17:19:04Z
   Network: 4/4 OK 
   Drives: 1/1 OK 
   Pool: 1

●  test4:9000
   Uptime: 20 minutes 
   Version: 2024-05-28T17:19:04Z
   Network: 4/4 OK 
   Drives: 1/1 OK 
   Pool: 1

┌──────┬───────────────────────┬─────────────────────┬──────────────┐
│ Pool │ Drives Usage          │ Erasure stripe size │ Erasure sets │
│ 1st  │ 0.5% (total: 200 GiB) │ 4                   │ 1            │
└──────┴───────────────────────┴─────────────────────┴──────────────┘

4 drives online, 0 drives offline, EC:2

```

- The data directory for file upload verification on the page has been synchronized (access method: http://any-node IP:9000, admin/admin@2025)

```
[root@test1 app]# ll minio_data/test/
total 0
drwxr-xr-x 2 root root 21 Apr  7 22:41 制作tomcat镜像.md
[root@test2 app]# ll minio_data/test/
total 0
drwxr-xr-x 2 root root 21 Apr  7 22:41 制作tomcat镜像.md
[root@test3 app]# ll minio_data/test/
total 0
drwxr-xr-x 2 root root 21 Apr  7 22:41 制作tomcat镜像.md
[root@test4 app]# ll minio_data/test/
total 0
drwxr-xr-x 2 root root 21 Apr  7 22:41 制作tomcat镜像.md
```

