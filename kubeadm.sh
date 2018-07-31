#!/bin/bash

if [[ $EUID != 0 ]]; then
	sudo -E "$0" "$@"
	exit $?
fi

sed -i "/pool/c\pool ${CHRONY_SERVER_IP?"CHRONY_SERVER_IP not set"} iburst" /etc/chrony/chrony.conf
service chrony restart

swapoff -a 
kubeadm reset

if [[ ${K8_NODE_TYPE} == "master" ]]; then
	echo "[[[[[[[[[[[[ Master Setup ]]]]]]]]]]]] "
	kubeadm init --token ${K8_TOKEN} --token-ttl 0
	mkdir -p /home/ubuntu/.kube
	cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
	chown ubuntu /home/ubuntu/.kube/config
	kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
	kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v1.10/nvidia-device-plugin.yml
fi

if [[ ${K8_NODE_TYPE} == "slave" ]]; then
	echo "[[[[[[[[[[[[ Slave Setup ]]]]]]]]]]]] "
	kubeadm join ${K8_MASTER_IP}:6443 --token ${K8_TOKEN} --discovery-token-unsafe-skip-ca-verification

	if [[ ${GPU_ENABLED} == true ]]; then
		sed -i '/Service/a Environment="KUBELET_EXTRA_ARGS=--feature-gates=DevicePlugins=true"' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
		systemctl daemon-reload
		systemctl restart kubelet
	fi

	echo "net.core.rmem_max=26214400
	net.core.rmem_default=26214400" >> /etc/sysctl.conf
	sysctl -p 
fi