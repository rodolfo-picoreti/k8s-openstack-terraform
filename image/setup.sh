#!/bin/bash

if [[ $EUID != 0 ]]; then
	sudo -E "$0" "$@"
	exit $?
fi

apt-get update
apt-get install -y docker.io

apt-get update && apt-get install -y apt-transport-https curl
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