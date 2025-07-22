# prom_alert_node-exporter

以下文件用于通过docker-compose快速部署prometheus(email)+alertmanager+node-exporter+grafana。

使用方法如下（提示：在执行此操作之前，您需要按照README文件将每个文件中的参数更改为您的实际参数）：

```sh
Install: docker-compose <-f docker-compose.yml> up -d
Uninstall: docker-compose <-f docker-compose.yml> down
```

## 1.docker-compose.yml
定义部署所需的映像和配置文件参数

## 2.alertmanager.yml

定义告警邮件配置参数

```yaml
global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.qq.com:465'   #邮件服务器地址，需要指定连接端口
  smtp_from: 'xxx'                #邮箱地址
  smtp_auth_username: 'xxx'       #Email认证用户地址，通常与smtp_from相同
  smtp_auth_password: 'xxx'       #电子邮件授权码
  smtp_require_tls: false
 
route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'test-alertmanager'
 
receivers:
- name: 'test-alertmanager'
  email_configs:
  - to: 'xxx'               #警告接收电子邮件地址
```

## 3.rules.yml

这是您定义需要的警报规则的地方

## 4.blackbox.yml

定义黑盒描述文件参数

## 5.prometheus.yml

配置了监视、警报等

## 6.修改变量文件.env

```bash
#promethues镜像和版本
prometheus_image="registry.cn-chengdu.aliyuncs.com/su03/prometheus:2.46.0-debian-11-r5"
#alertmanager镜像和版本
alertmanager_image="registry.cn-chengdu.aliyuncs.com/su03/alertmanager:0.25.0-debian-11-r171"
#grafana镜像和版本
grafana_image="registry.cn-chengdu.aliyuncs.com/su03/grafana:9.3.6"
#grafana登录用户
grafana_user="admin"
#grafana登录密码
grafana_password="admin"
#pushgateway镜像和版本
pushgateway_image="registry.cn-chengdu.aliyuncs.com/su03/pushgateway:v1.6.2"
#blackbox_exporter镜像和版本
blackbox_image="registry.cn-chengdu.aliyuncs.com/su03/blackbox-exporter:0.25.0"
#node_exporter镜像和版本
nodeexporter_image="registry.cn-chengdu.aliyuncs.com/su03/node-exporter:1.6.1-debian-11-r8"
#prometheus数据源地址，此行主要影响到./config/datasources.yaml中datasources.url的值
prometheus_url="http://8.137.21.201:9090"
```

## 7.面板json文件

```bash
#仪表板文件配置了两个初始节点监视器面板
disk.json：Server disk usage is shown
node-exporter-grafana.json：Server disk, io, cpu usage is displayed
```

## 8.访问地址

```bash
prometheus：http://IP:3000

grafana：http://IP:9090,使用`.env`文件中定义的用户和密码进行登录

alertmanager：http://IP:9093
```