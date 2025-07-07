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

## 6.数据源和数据面板初始化配置

```yaml
#数据源在config文件夹中配置
(1)datasources.yaml
apiVersion: 1
deleteDatasources:
  - name: Prometheus
    orgId: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    orgId: 1
    uid: prometheus
    url: http://192.168.2.193:9090   #这里的地址是你的prometheus服务的地址
    isDefault: true
(2)default-provider.yaml
apiVersion: 1
providers:
- name: 'default-provider'
  orgId: 1
  folder: dashboards
  folderUid: ''
  type: file
  disableDeletion: false
  editable: true
  updateIntervalSeconds: 10
  options:
    path: /etc/grafana/dashboards     
    #在这里指定从容器中读取dashboards文件的路径，该文件可以在docker-compose中的grafana挂载中找到yaml文件
    foldersFromFilesStructure: true

#仪表板文件配置两个初始节点监视器面板
disk.json：Server disk usage is shown
node-exporter-grafana.json：Server disk, io, cpu usage is displayed
```

## 7.访问地址

```sh
prometheus：http://IP:3000

grafana：http://IP:9090

alertmanager：http://IP:9093
```