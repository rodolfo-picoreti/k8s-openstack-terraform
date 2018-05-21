provider "openstack" {
  user_name   = "admin"
  tenant_name = "admin"
  domain_name = "Default"
  password    = "<????????????????????????>"
  auth_url    = "http://10.30.0.2:5000"
  region      = "RegionOne"
  version     = "~> 1.4"
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "k8_key"
  public_key = "${file("k8.pub")}"
}

data "openstack_compute_flavor_v2" "medium" {
  vcpus = 2
  ram   = 2048
}

data "openstack_compute_flavor_v2" "xlarge" {
  vcpus = 16
  ram   = 32768
}

data "openstack_images_image_v2" "ubuntu" {
  name        = "k8s"
  most_recent = true
}

resource "openstack_compute_instance_v2" "master" {
  name            = "k8s-master"
  image_id        = "${data.openstack_images_image_v2.ubuntu.id}"
  flavor_id       = "${data.openstack_compute_flavor_v2.medium.id}"
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

resource "openstack_compute_instance_v2" "slave" {
  count           = 3
  name            = "k8s-slave-${count.index}"
  image_id        = "${data.openstack_images_image_v2.ubuntu.id}"
  flavor_id       = "${data.openstack_compute_flavor_v2.xlarge.id}"
  security_groups = ["default"]
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"

  network {
    name = "external"
  }
}

resource "null_resource" "slave" {
  depends_on = ["null_resource.master"]
  count      = "${length(openstack_compute_instance_v2.slave.*.name)}"

  connection {
    host        = "${element(openstack_compute_instance_v2.slave.*.access_ip_v4, count.index)}"
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
      "/tmp/kubeadm.sh slave ovbixr.bnelcf374oaz4pnt ${openstack_compute_instance_v2.master.access_ip_v4}",
    ]
  }
}
