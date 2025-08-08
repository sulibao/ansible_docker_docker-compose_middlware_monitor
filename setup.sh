#!/bin/bash

set -e
export path=`pwd`
export capath="/opt/.certs"
export docker_data=$(awk -F': ' '/docker_data_dir:/ {print $2}' group_vars/all.yml)
export ansible_log_dir="$path/log"
export ansible_image_url="registry.cn-chengdu.aliyuncs.com/su03/ansible:latest"
export docker_package_url_x86="https://sulibao.oss-cn-chengdu.aliyuncs.com/docker/amd/docker-27.2.0.tgz"
export docker_package_url_arm="https://sulibao.oss-cn-chengdu.aliyuncs.com/docker/arm/docker-27.2.0.tgz"
export target_file_x86="$path/packages/docker/x86/docker-27.2.0.tgz"
export target_file_arm="$path/packages/docker/arm/docker-27.2.0.tgz"
export target_docker_filedir_x86="$path/roles/docker/files/x86/docker-27.2.0.tgz"
export target_docker_filedir_arm="$path/roles/docker/files/arm/docker-27.2.0.tgz"
export ssh_pass="sulibao"
export os_arch=$(uname -m)

function get_arch_package() {
  if [ -f /etc/redhat-release ]; then
    OS="RedHat"
  elif [ -f /etc/kylin-release ]; then
    OS="kylin"
  else
    echo "Unknow linux distribution."
  fi
  if [[ "$os_arch" == "x86_64" ]]; then
    ARCH="x86"
    echo -e "Detected Operating System: $OS, Architecture：X86"
    mkdir -p $ansible_log_dir
    if [ -f "$target_file_x86" ]; then
      echo "The file $target_file_x86 already exists, skip download."
    else
      mkdir -p "$(dirname "$target_file_x86")" && \
      mkdir -p "$(dirname "$target_docker_filedir_x86")"
      curl -C - -o "$target_file_x86" "$docker_package_url_x86"
      if [ $? -eq 0 ]; then
        echo "The file downloaded successfully."
      else
        echo "Failed to download the file."
      fi
    fi
  elif [[ "$os_arch" == "aarch64" ]]; then
    ARCH="arm64"
    echo -e "Detected Operating System: $OS, Architecture: ARM64"
    mkdir -p $ansible_log_dir
    if [ -f "$target_file_arm" ]; then
      echo "The file $target_file_arm already exists, skip download."
    else
      mkdir -p "$(dirname "$target_file_arm")" && \
      mkdir -p "$(dirname "$target_docker_filedir_arm")"
      curl -C - -o "$target_file_arm" "$docker_package_url_arm"
      if [ $? -eq 0 ]; then
        echo "The file downloaded successfully."
      else
        echo "Failed to download the file."
      fi
    fi
  else
    echo -e "Unsupported architecture detected: $os_arch"
    exit 1
  fi
}

function check_docker() {
  echo "Make sure docker is installed and running."
  if ! [ -x "$(command -v docker)" ]; then
    echo "docker not find."
    create_docker_group_and_user
    install_docker
  else
    echo "docker exists."
  fi
  if ! systemctl is-active --quiet docker; then
    echo "docker is not running."
    create_docker_group_and_user
    install_docker
  else
    echo "docker is running."
  fi
}

function check_docker_compose() {
  if ! [ -x "$(command -v docker-compose)" ]; then
    echo "docker-compose not find."
    install_docker_compose   
  else
    echo "docker-compose exist."
  fi
}

function create_docker_group_and_user() {
  if ! getent group docker >/dev/null 2>&1; then
    groupadd docker
    echo "docker group created successfully."
  else
    echo "docker group already exists."
  fi
  if ! id -u docker >/dev/null 2>&1; then
    useradd -m -s /bin/bash -g docker docker
    echo "docker user has been created and added to docker group."
  else
    echo "docker user already exists."
  fi
}

function install_docker() {
  echo "Installing docker."
  if [[ "$ARCH" == "x86" ]]
  then
    export DOCKER_OFFLINE_PACKAGE=$target_file_x86 && \
    cp -v -f $target_file_x86 $target_docker_filedir_x86
  else
    export DOCKER_OFFLINE_PACKAGE=$target_file_arm && \
    cp -v -f $target_file_arm $target_docker_filedir_arm
  fi
  tar axvf $DOCKER_OFFLINE_PACKAGE -C /usr/bin/ --strip-components=1
  cp -v -f $path/packages/docker/docker.service /usr/lib/systemd/system/
  test -d /etc/docker || mkdir -p /etc/docker
  envsubst '$docker_data' < $path/packages/docker/daemon.json > /etc/docker/daemon.json
  systemctl stop firewalld
  systemctl disable firewalld
  systemctl daemon-reload
  systemctl enable docker.service --now
  systemctl restart docker || :
  maxSecond=60
  for i in $(seq 1 $maxSecond); do
    if systemctl is-active --quiet docker; then
      break
    fi
    sleep 1
  done
  if ((i == maxSecond)); then
    echo "Failed to start the docker server, please check the docker start log."
    exit 1
  fi
  echo "Docker has started successfully and the installation is complete."
}

function install_docker_compose {
  echo "Installing docker-compose."
  if [[ "$ARCH" == "x86" ]]
  then
    export DOCKER_COMPOSE_OFFLINE_PACKAGE=$path/packages/docker-compose/x86/docker-compose-linux-x86_64
    cp -v -f $DOCKER_COMPOSE_OFFLINE_PACKAGE /usr/local/bin/docker-compose && \
    chmod 0755 /usr/local/bin/docker-compose
  else
    export DOCKER_COMPOSE_OFFLINE_PACKAGE=$path/packages/docker-compose/arm/docker-compose-linux-aarch64
    cp -v -f $DOCKER_COMPOSE_OFFLINE_PACKAGE /usr/local/bin/docker-compose && \
    chmod 0755 /usr/local/bin/docker-compose
  fi
}

function install_monitor {
  echo "Installing monitor with docker-compose."
  if [ -f ./docker-compose.yml ]; then
    docker-compose -f docker-compose.yml up -d 
  else
    echo "docker-compose.yml file for monitor is not exists, please check the file."
    exit 1
  fi
  echo "Installed monitor system."
}

function main() {
  get_arch_package
  check_docker
  check_docker_compose
  install_monitor
}

main