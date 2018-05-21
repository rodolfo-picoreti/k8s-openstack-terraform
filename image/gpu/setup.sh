#!/bin/bash

if [[ $EUID != 0 ]]; then
	sudo -E "$0" "$@"
	exit $?
fi

set -e

add-apt-repository universe -y
apt-get update
apt-get install apt-transport-https ca-certificates curl software-properties-common jq moreutils -y

### docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt install docker-ce=18.03.1~ce-0~ubuntu -y

### nvidia
add-apt-repository ppa:graphics-drivers/ppa -y
apt-get update
apt install nvidia-390 -y

### nvidia-docker
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
apt-get update
apt-get install -y nvidia-docker2
pkill -SIGHUP dockerd
jq '."default-runtime"="nvidia"' /etc/docker/daemon.json | sponge /etc/docker/daemon.json

### k8s
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet=1.10.2-00 kubeadm=1.10.2-00 kubectl=1.10.2-00

docker pull k8s.gcr.io/kube-apiserver-amd64:v1.10.2
docker pull k8s.gcr.io/kube-controller-manager-amd64:v1.10.2
docker pull k8s.gcr.io/kube-scheduler-amd64:v1.10.2
docker pull k8s.gcr.io/etcd-amd64:3.1.12