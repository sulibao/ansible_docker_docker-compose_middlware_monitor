# ansible+docker+docker-compose
本文档用于通过ansible容器快速部署多个docker+docker-compose环境。

# 1.安装前

## 修改变量文件group_vars/all.yml

```yaml
vim group_vars/all.yml
 
docker_data_dir: /app/docker_data   #docker的数据目录

```

## 修改ansible主机清单

```yaml
[ansible]   
192.168.2.190           #该节点运行ansible容器，它将在其他节点上部署docker+docker-compose
[other_node01]  
192.168.2.191
[other_node02] 
192.168.2.192

[other_nodes:children]
other_node01
other_node02

[ansible_cluster:children]
ansible
other_node01
other_node02
```

# 2.安装

```sh
bash setup.sh
```