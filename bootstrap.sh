#!/bin/bash

if [[ $EUID != 0 ]]; then
	sudo -E "$0" "$@"
	exit $?
fi

apt update
apt install wget unzip -y

wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip
unzip terraform_0.11.7_linux_amd64.zip
rm terraform_0.11.7_linux_amd64.zip

wget https://releases.hashicorp.com/packer/1.2.3/packer_1.2.3_linux_amd64.zip
unzip packer_1.2.3_linux_amd64.zip
rm packer_1.2.3_linux_amd64.zip