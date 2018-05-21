#!/bin/bash

####
#### USAGE:
####   ./kubeadm.sh master <TOKEN>
####   ./kubeadm.sh slave <TOKEN> <MASTER_IP> gpu
####   ./kubeadm.sh slave <TOKEN> <MASTER_IP> cpu
####

if [[ $EUID != 0 ]]; then
	sudo -E "$0" "$@"
	exit $?
fi

ROLE=$1
TOKEN=$2
MASTER_IP=$3
TYPE=$4

swapoff -a 
kubeadm reset

if [[ $ROLE == "master" ]]; then
	echo "[[[[[[[[[[[[ Master Setup ]]]]]]]]]]]] "
	kubeadm init --token $TOKEN --token-ttl 0
	mkdir -p /home/ubuntu/.kube
	cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
	chown ubuntu /home/ubuntu/.kube/config
	kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
fi

if [[ $ROLE == "slave" ]]; then
	echo "[[[[[[[[[[[[ Slave Setup ]]]]]]]]]]]] "
	kubeadm join $MASTER_IP:6443 --token $TOKEN --discovery-token-unsafe-skip-ca-verification

	if [[ $TYPE == "gpu" ]]; then
		sed -i '/Service/a Environment="KUBELET_EXTRA_ARGS=--feature-gates=DevicePlugins=true"' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
		systemctl daemon-reload
		systemctl restart kubelet
	fi

	echo "net.core.rmem_max=26214400
	net.core.rmem_default=26214400" >> /etc/sysctl.conf
	sysctl -p 
fi