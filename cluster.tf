variable "password" {}
variable "hostname" {}

provider "openstack" {
  user_name   = "admin"
  tenant_name = "admin"
  domain_name = "Default"
  password    = "${var.password}"
  auth_url    = "http://${var.hostname}:5000"
  region      = "RegionOne"
  version     = "~> 1.4"
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "k8_key"
  public_key = "${file("k8.pub")}"
}

resource "openstack_compute_instance_v2" "master" {
  name            = "k8s-master"
  image_name      = "k8s-cpu"
  flavor_name     = "m1.medium"
  security_groups = ["default"]
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"

  network {
    name = "external"
  }
}

resource "null_resource" "master" {
  connection {
    host        = "${openstack_compute_instance_v2.master.access_ip_v4}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file("k8")}"
  }

  provisioner "file" {
    source      = "kubeadm.sh"
    destination = "/tmp/kubeadm.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/kubeadm.sh",
      "export CHRONY_SERVER_IP=${var.hostname}",
      "export K8_NODE_TYPE=master",
      "export K8_TOKEN=ovbixr.bnelcf374oaz4pnt",
      "/tmp/kubeadm.sh",
    ]
  }
}

resource "openstack_compute_instance_v2" "gpu_slave" {
  count           = 2
  name            = "k8s-gpu-slave-${count.index}"
  image_name      = "k8s-gpu"
  flavor_name     = "g1.xlarge"
  security_groups = ["default"]
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"

  network {
    name = "external"
  }
}

resource "null_resource" "gpu_slave" {
  depends_on = ["null_resource.master"]
  count      = "${length(openstack_compute_instance_v2.gpu_slave.*.name)}"

  connection {
    host        = "${element(openstack_compute_instance_v2.gpu_slave.*.access_ip_v4, count.index)}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file("k8")}"
  }

  provisioner "file" {
    source      = "kubeadm.sh"
    destination = "/tmp/kubeadm.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/kubeadm.sh",
      "export CHRONY_SERVER_IP=${var.hostname}",
      "export K8_NODE_TYPE=slave",
      "export K8_TOKEN=ovbixr.bnelcf374oaz4pnt",
      "export K8_MASTER_IP=${openstack_compute_instance_v2.master.access_ip_v4}",
      "export GPU_ENABLED=true",
      "/tmp/kubeadm.sh",
    ]
  }
}

resource "openstack_compute_instance_v2" "cpu_slave" {
  count           = 2
  name            = "k8s-cpu-slave-${count.index}"
  image_name      = "k8s-cpu"
  flavor_name     = "m1.xlarge"
  security_groups = ["default"]
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"

  network {
    name = "external"
  }
}

resource "null_resource" "cpu_slave" {
  depends_on = ["null_resource.master"]
  count      = "${length(openstack_compute_instance_v2.cpu_slave.*.name)}"

  connection {
    host        = "${element(openstack_compute_instance_v2.cpu_slave.*.access_ip_v4, count.index)}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file("k8")}"
  }

  provisioner "file" {
    source      = "kubeadm.sh"
    destination = "/tmp/kubeadm.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/kubeadm.sh",
      "export CHRONY_SERVER_IP=${var.hostname}",
      "export K8_NODE_TYPE=slave",
      "export K8_TOKEN=ovbixr.bnelcf374oaz4pnt",
      "export K8_MASTER_IP=${openstack_compute_instance_v2.master.access_ip_v4}",
      "export GPU_ENABLED=false",
      "/tmp/kubeadm.sh",
    ]
  }
}
