// Create passwords for mgmt server (change this after first login)
resource "random_password" "pass-sms" {
  count   = 1
  length  = 10
  special = false
}

// Create SIC activation key (one-time password) between management server and firewalls 
resource "random_password" "pass-sic" {
  count   = 1
  length  = 13
  special = false
}

locals {
  fw_interfaces = flatten([[{
    // mgmt fw interface
    subnet_id           = yandex_vpc_subnet.subnet[0].id
    ip_address          = "${cidrhost(var.subnet_prefix_list[0], 10)}" 
    nat                 = false
    nat_ip_address      = null
    security_group_ids  = [yandex_vpc_security_group.mgmt-sg.id] 
  }],[{
    // public fw interface
    subnet_id           = yandex_vpc_subnet.subnet[1].id
    ip_address          = "${cidrhost(var.subnet_prefix_list[1], 10)}" 
    nat                 = true
    nat_ip_address      = yandex_vpc_address.public-ip-fw.external_ipv4_address.0.address
    security_group_ids  = [yandex_vpc_security_group.public-fw-sg.id]
  }],
  [
    // dmz and ohter fw interfaces
    for i in range(length(var.security_segment_names) - 2) : {
      subnet_id           = yandex_vpc_subnet.subnet[i + 2].id
      ip_address          = "${cidrhost(var.subnet_prefix_list[i + 2], 10)}" 
      nat                 = false
      nat_ip_address      = null
      security_group_ids  = [yandex_vpc_security_group.segment-sg[i].id]
    }
  ]])
}

// Create Check Point FW
resource "yandex_compute_instance" "fw" {
  folder_id = yandex_resourcemanager_folder.folder[0].id
  name        = "fw"
  platform_id = "standard-v3"
  zone        = var.az_name
  hostname    = "fw"
  
  resources {
    cores  = 4
    memory = 8
  }
  
  boot_disk {
    initialize_params {
      image_id = "fd8lv3k0bcm4a5v49mff"
      type     = "network-ssd"
      size     = 120
    }
  }

  dynamic "network_interface" {
    for_each = local.fw_interfaces
    content {
      subnet_id           = network_interface.value.subnet_id
      ip_address          = network_interface.value.ip_address
      nat                 = network_interface.value.nat
      nat_ip_address      = network_interface.value.nat_ip_address
      security_group_ids = network_interface.value.security_group_ids
    }
  }

  metadata = {
    serial-port-enable = 1
    user-data = templatefile("./templates/check-init_gw.tpl.yaml",
    {
      ssh_key = "${chomp(tls_private_key.ssh.public_key_openssh)}"
      pass_sic = "${random_password.pass-sic[0].result}"
      gw = "${cidrhost(var.subnet_prefix_list[1], 1)}"
    })
  }
}

//Create Check Point management server
resource "yandex_compute_instance" "mgmt-server" {
  folder_id = yandex_resourcemanager_folder.folder[0].id
  name        = "mgmt-server"
  platform_id = "standard-v3"
  zone        = var.az_name
  hostname    = "mgmt-server"
  
  resources {
    cores  = 4
    memory = 8
  }
  boot_disk {
    initialize_params {
      image_id = "fd8hcf4gjv3adselqajo"
      type     = "network-ssd"
      size     = 120
    }
  }

  network_interface {
    // mgmt-int
    subnet_id  = yandex_vpc_subnet.subnet[0].id
    ip_address = "${cidrhost(var.subnet_prefix_list[0], 100)}"
    nat = false
    security_group_ids = [yandex_vpc_security_group.mgmt-sg.id]
  }

  metadata = {
    serial-port-enable = 1
    user-data = templatefile("./templates/check-init-sms.tpl.yaml",
    {
      ssh_key = "${chomp(tls_private_key.ssh.public_key_openssh)}",
      pass = "${random_password.pass-sms[0].result}"
    })
  }
}