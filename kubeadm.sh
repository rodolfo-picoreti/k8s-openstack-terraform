#!/bin/bash

####
#### USAGE:
####   ./kubeadm.sh master <TOKEN>
####   ./kubeadm.sh slave <TOKEN> <MASTER_IP>
####

if [[ $EUID != 0 ]]; then
	sudo -E "$0" "$@"
	exit $?
fi

ROLE=$1
TOKEN=$2
MASTER_IP=$3

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
fi