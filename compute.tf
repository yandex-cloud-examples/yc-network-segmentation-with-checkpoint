// Create ssh keys for compute resources
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "pt_key.pem"
  file_permission = "0600"
}

data "yandex_compute_image" "ubuntu_image" {
  family = "ubuntu-2204-lts"
}

data "yandex_compute_image" "nginx_image" {
  family = "lemp"
}

// Create Jump VM
resource "yandex_compute_instance" "jump-vm" {
  folder_id = yandex_resourcemanager_folder.folder[0].id
  name        = "jump-vm"
  hostname    = "jump-vm"
  platform_id = "standard-v3"
  zone        = var.az_name

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      type     = "network-hdd"
      size     = 10
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet[0].id
    ip_address = "${cidrhost(var.subnet_prefix_list[0], 101)}"
    nat                = true
    nat_ip_address = yandex_vpc_address.public-ip-jump-vm.external_ipv4_address.0.address
    security_group_ids = [yandex_vpc_security_group.mgmt-jump-vm-sg.id] 
  }

  metadata = {
    user-data = templatefile("./templates/cloud-init_jump-vm.tpl.yaml",
    {
      jump_vm_ssh_key_pub = "${chomp(tls_private_key.ssh.public_key_openssh)}",
      jump_vm_admin_username = var.jump_vm_admin_username,
      wg_port           = var.wg_port,
      wg_client_dns     = "${cidrhost(var.subnet_prefix_list[0], 2)}",
      wg_public_ip      = "${yandex_vpc_address.public-ip-jump-vm.external_ipv4_address.0.address}",
      wg_allowed_ip     = "${join(",", var.subnet_prefix_list)}"
    })
  }
}

// Wait for SSH connection to Jump VM 
resource "null_resource" "wait_for_ssh_jump_vm" {
  connection {
    type = "ssh"
    user = "${var.jump_vm_admin_username}"
    private_key = local_file.private_key.content
    host = yandex_vpc_address.public-ip-jump-vm.external_ipv4_address.0.address
  }
 
 // Wait for WireGuard client config to be updated with keys in cloud-init process
  provisioner "remote-exec" {
    inline = [
      "while [ ! -f ~/jump-vm-wg.conf ]; do sleep 5; echo \"Waiting for jump-vm-wg.conf to be created...\"; done",
      "while grep -q CLIENT_PSK ~/jump-vm-wg.conf; do sleep 5; echo \"Waiting for jump-vm-wg.conf to be updated with keys...\"; done"
    ]
  }
 
  depends_on = [
    yandex_compute_instance.jump-vm,
    local_file.private_key,
    yandex_vpc_address.public-ip-jump-vm
  ]
}

// Download WireGuard client config from Jump VM
resource "null_resource" "get_wg_client_config" {
  provisioner "local-exec" {
    command = "scp -i pt_key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${var.jump_vm_admin_username}@${yandex_vpc_address.public-ip-jump-vm.external_ipv4_address.0.address}:jump-vm-wg.conf jump-vm-wg.conf"
  }
 
  depends_on = [
    null_resource.wait_for_ssh_jump_vm
  ]
}

// Create web-server in dmz segment
resource "yandex_compute_instance" "dmz-web-server" {
  folder_id = yandex_resourcemanager_folder.folder[2].id
  name        = "dmz-web-server"
  hostname    = "dmz-web-server"
  platform_id = "standard-v3"
  zone        = var.az_name

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.nginx_image.id
      type     = "network-hdd"
      size     = 10
    }
  }

  network_interface {
    subnet_id           = yandex_vpc_subnet.subnet[2].id
    ip_address          = "${cidrhost(var.subnet_prefix_list[2], 100)}"
    nat                 = false
    security_group_ids  = [yandex_vpc_security_group.dmz-web-sg.id, yandex_vpc_security_group.segment-sg[0].id] 
  }

  metadata = {
    user-data = templatefile("./templates/cloud-init_dmz-web-server.tpl.yaml",
    {
      ssh_key_pub = "${chomp(tls_private_key.ssh.public_key_openssh)}",
      nginx_port  = var.internal_app_port,
    })
  }
}


