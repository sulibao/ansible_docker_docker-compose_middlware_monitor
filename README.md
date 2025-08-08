# prom_alert_node-exporter

This document is intended to illustrate the rapid deployment of Prometheus (via docker-compose) along with Alertmanager, Node-Exporter, and Grafana.

The usage method is as follows (note: Before performing this operation, you need to modify the parameters in each file according to your actual parameters as per the README file):

```bash
# Execute the following command
bash setup.sh / bash -x setup.sh
```

## setup.sh

Define functions for installing Docker, Docker Compose, and the monitoring system. During the installation process, the main operation is to run this file.

Note: Before installation, you can check the `data-root` parameter in `./packages/daemon.json`. This parameter indicates the directory for storing Docker data. The default is `/data/docker_data`. If necessary, you can modify it yourself.

## docker-compose.yml

Define the parameters of the images and configuration files required for deployment

## alertmanager.yml

Define the configuration parameters for alarm emails

```yaml
global:
  resolve_timeout: 5m
  # Mail server address, need to connect to the port
  smtp_smarthost: 'smtp.qq.com:465'   
  # Email address  
  smtp_from: 'xxx'        
  # Email authentication user address, usually the same as smtp_from        
  smtp_auth_username: 'xxx'
  # Email authorization code 
  smtp_auth_password: 'xxx'
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
  # Alert receiving email address
  - to: 'xxx'  
```

## rules.yml

The place where the necessary alert rules need to be defined

## blackbox.yml

Define the parameters of the black box description file

## prometheus.yml

Equipped with monitoring, alerts, etc.

## modify variables file ".env"

```bash
# promethues image and version
prometheus_image="registry.cn-chengdu.aliyuncs.com/su03/prometheus:2.46.0-debian-11-r5"
# alertmanager image and version
alertmanager_image="registry.cn-chengdu.aliyuncs.com/su03/alertmanager:0.25.0-debian-11-r171"
# grafana image and version
grafana_image="registry.cn-chengdu.aliyuncs.com/su03/grafana:9.3.6"
# grafana login user
grafana_user="admin"
# grafana login password
grafana_password="admin"
# pushgateway image and version
pushgateway_image="registry.cn-chengdu.aliyuncs.com/su03/pushgateway:v1.6.2"
# blackbox_exporter image and version
blackbox_image="registry.cn-chengdu.aliyuncs.com/su03/blackbox-exporter:0.25.0"
# node_exporter image and version
nodeexporter_image="registry.cn-chengdu.aliyuncs.com/su03/node-exporter:1.6.1-debian-11-r8"
# Prometheus data source address. This line mainly affects the value of "datasources.url" in the file "./config/datasources.yaml".
prometheus_url="http://192.168.2.193:9090"
```

## Dashboard json file

```bash
# The dashboard file is configured by default with two initial node monitor panels.
disk.json：Server disk usage is shown
node-exporter-grafana.json：Server disk, io, cpu usage is displayed
```

## Access point

```bash
prometheus：http://IP:9090

grafana：http://IP:3000,Log in using the user and password defined in the `.env` file

alertmanager：http://IP:9093
```