1. Run the bootstrap script to download dependencies.
2. Activate the Openstack *openrc.sh* environment.
3. Build the base cpu image: `./packer build image/cpu/build.json`
4. Init terraform in this folder: `./terraform init`
5. Generate a join token `sudo kubeadm token create --print-join-command`
6. Apply the script to create slave nodes (Change the variables accordingly):
```
  ./terraform apply \
    -var "k8_master_ip=192.168.1.105" \
    -var "k8_token=8vbnqi.r34juhn1qhvuvjsv" \
    -var "k8_discovery_hash=sha256:43abced7b7e92dd377b37d5a993974a237671f7883d63e9c926965b3ed24256f"
```
