# ansible_redis_sentinel
此文档用于说明通过ansible+docker-compose快速搭建一主两从redis+三sentinel集群的操作，此项目适用于三台服务器设备。

## 示例服务器列表

![img](https://i-blog.csdnimg.cn/direct/b74cdabc5c8c469a8be4e1490bac85b4.png)

# 大致架构逻辑

![img](https://i-blog.csdnimg.cn/direct/e66236daca6c4c4789201a813967067b.png)

# 安装前

## 修改变量文件group_vars/all.yml

```yaml
vim group_vars/all.yml
 
docker_data_dir: /app/docker_data   #安装的docker数据目录
data_dir: /app     #存放redis文件的数据目录
redis_sentinel_port: 26379    #sentinel端口
redis_pass: "sulibao"     #redis认证密码
image_redis: "registry.cn-chengdu.aliyuncs.com/su03/redis:7.2.7"   #redis和sentinel使用的镜像
```

## 修改主机清单文件

```yaml
[root@test1 redis_data]# cat hosts 
[redis_master]    #初始master的地址
192.168.2.190
[redis_slave1]    #初始slave1的地址
192.168.2.191 
[redis_slave2]    #初始slave2的地址
192.168.2.192
 
[redis_slave:children]
redis_slave1
redis_slave2
 
[redis:children]
redis_master
redis_slave1
redis_slave2
```

# 安装

```sh
bash setup.sh
```

# 验证redis-master故障转移

```sh
#初始集群信息，test1为master，test2、test3为slave
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
 
 
#模拟master（test1）挂机，出现新master（test2），test3仍为slave
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
 
#旧master（test1）恢复，成为slave角色。此时master为test2，test1、test3为slave
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

# 涉及redis镜像(X86版本，Baidu Net Disk)

redis:7.2.7版本镜像文件：

链接: https://pan.baidu.com/s/1D4xQkrSU4opm-9RVhk6Gmg?pwd=aiw3 

提取码: aiw3