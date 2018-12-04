## Creating the base image

```bash
(cd ../../ && ./bootstrap.sh) # Make sure you have packer
# Fill enviroment variables OS credentials, i.e:
. <PATH_TO_YOUR_FILE>/admin-openrc.sh 
# Change the following accordingly to your OS setup:
export UBUNTU_IMAGE_NAME="Ubuntu"
export FLAVOR_NAME="m1.small"
# Provider network ID
export PROVIDER_NET_ID="11c1428e-b2a2-454c-a4e9-a37a3d063345"

# Create the image
../../packer build build.json
```