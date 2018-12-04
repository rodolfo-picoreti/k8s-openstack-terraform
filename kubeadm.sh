#!/bin/bash

if [[ $EUID != 0 ]]; then
	sudo -E "$0" "$@"
	exit $?
fi

swapoff -a 

###
echo "net.core.rmem_max=26214400
net.core.rmem_default=26214400" >> /etc/sysctl.conf
sysctl -p 


###  Create route to our local net
ip ro add 192.168.1.0/24 via 10.61.0.32
echo "up ip ro add 192.168.1.0/24 via 10.61.0.32" >> /etc/network/interfaces.d/50-cloud-init.cfg


###
kubeadm reset
kubeadm join ${K8_MASTER_IP}:6443 --token ${K8_TOKEN} --discovery-token-ca-cert-hash ${K8_DISCOVERY_HASH}

