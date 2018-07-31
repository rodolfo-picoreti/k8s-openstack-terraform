1. Run the bootstrap script to download dependencies.
2. Activate the openstrack *openrc.sh* enviroment.
3. Run `./packer build image/cpu/build.json` to build the base cpu image
4. Run `./packer build image/gpu/build.json` to build the base gpu image
5. Run `./terraform apply -var password=$OS_PASSWORD -var hostname=10.30.0.10`