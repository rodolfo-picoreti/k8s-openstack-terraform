1. Run the bootstrap script to download dependencies.
2. Activate the openstrack *openrc.sh* enviroment.
3. Build the base cpu image: `./packer build image/cpu/build.json`
4. Build the base gpu image: `./packer build image/gpu/build.json`
5. Init terraform in this folder: `./terraform init`
6. Generate public and private keypair for the vms: `ssh-keygen -f k8`
7. Config terraform variables:
```shell
export TF_VAR_password=$OS_PASSWORD
export TF_VAR_hostname=$(echo $OS_AUTH_URL | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
``` 
8. Create cluster `./terraform apply`
9. Copy kubernetes credentials from master node to your machine:
```shell
scp -i k8 ubuntu@<MASTER_IP>:.kube/config $HOME/.kube/config
``` 
