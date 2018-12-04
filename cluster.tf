variable "k8_master_ip" {}
variable "k8_token" {}
variable "k8_discovery_hash" {}

provider "openstack" {
  version     = "~> 1.4"
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "k8s"
}

resource "openstack_compute_instance_v2" "cpu_slave" {
  count           = 2
  name            = "k8s-cpu-slave-${count.index}"
  image_name      = "k8s-cpu"
  flavor_name     = "p1.scale"
  security_groups = ["default"]
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"

  network {
    name = "provider"
  }
}

resource "null_resource" "cpu_slave" {
  depends_on = ["null_resource.master"]
  count      = "${length(openstack_compute_instance_v2.cpu_slave.*.name)}"

  connection {
    host        = "${element(openstack_compute_instance_v2.cpu_slave.*.access_ip_v4, count.index)}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${openstack_compute_keypair_v2.keypair.private_key}"
  }

  provisioner "file" {
    source      = "kubeadm.sh"
    destination = "/tmp/kubeadm.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/kubeadm.sh",
      "export K8_MASTER_IP=${var.k8_master_ip}",
      "export K8_TOKEN=${var.k8_token}",
      "export K8_DISCOVERY_HASH=${var.k8_discovery_hash}",
      "/tmp/kubeadm.sh",
    ]
  }
}
