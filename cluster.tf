provider "openstack" {
  user_name   = "admin"
  tenant_name = "admin"
  domain_name = "Default"
  password    = ""
  auth_url    = "http://10.30.0.2:5000"
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
      "/tmp/kubeadm.sh master ovbixr.bnelcf374oaz4pnt",
    ]
  }
}

resource "openstack_compute_instance_v2" "gpu_slave" {
  count           = 3
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
      "/tmp/kubeadm.sh slave ovbixr.bnelcf374oaz4pnt ${openstack_compute_instance_v2.master.access_ip_v4} gpu",
    ]
  }
}

#resource "openstack_compute_instance_v2" "cpu_slave" {
#  count           = 1
#  name            = "k8s-cpu-slave-${count.index}"
#  image_name      = "k8s-cpu"
#  flavor_name     = "m1.xlarge"
#  security_groups = ["default"]
#  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
#
#  network {
#    name = "external"
#  }
#}
#
#resource "null_resource" "cpu_slave" {
#  depends_on = ["null_resource.master"]
#  count      = "${length(openstack_compute_instance_v2.cpu_slave.*.name)}"
#
#  connection {
#    host        = "${element(openstack_compute_instance_v2.cpu_slave.*.access_ip_v4, count.index)}"
#    type        = "ssh"
#    user        = "ubuntu"
#    private_key = "${file("k8")}"
#  }
#
#  provisioner "file" {
#    source      = "kubeadm.sh"
#    destination = "/tmp/kubeadm.sh"
#  }
#
#  provisioner "remote-exec" {
#    inline = [
#      "chmod +x /tmp/kubeadm.sh",
#      "/tmp/kubeadm.sh slave ovbixr.bnelcf374oaz4pnt ${openstack_compute_instance_v2.master.access_ip_v4} cpu",
#    ]
#  }
#}
#

