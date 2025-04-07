# ansible_redis_sentinel
This documentation is for quickly deploying multiple docker+docker-compose environments via ansible containers

# 1.Before installation

## Modify the variable file group_vars/all.yml

```yaml
vim group_vars/all.yml
 
docker_data_dir: /app/docker_data   #Installed docker data directory

```

## Modify the host manifest file

```yaml
[ansible]   
192.168.2.190           #The node running the ansible container, which will deploy docker+docker-compose over other nodes
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

# 2.Installation

```sh
bash setup.sh
```