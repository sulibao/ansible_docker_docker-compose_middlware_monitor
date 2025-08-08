# ansible+docker+docker-compose
This document is intended to illustrate the process of quickly deploying multiple Docker + Docker-Compose environments using Ansible containers.

# 1.Before install

## Modify the variables file "./group_vars/all.yml"

```yaml
vim group_vars/all.yml
# Docker's data directory
docker_data_dir: /app/docker_data

```

## Modify ansible host list

```yaml
[ansible]   
# This node runs an Ansible container, and it will deploy Docker + Docker Compose on other nodes.
192.168.2.190
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

# 2.Install

```sh
bash setup.sh
```