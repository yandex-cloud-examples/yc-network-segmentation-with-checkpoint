//Create Security Groups-------------------

// Create security group for switcher NLB in management segment
resource "yandex_vpc_security_group" "mgmt-sg" {
  name        = "mgmt-sg"
  description = "Security group for mgmt segment"
  folder_id   = yandex_resourcemanager_folder.folder[0].id
  network_id  = yandex_vpc_network.vpc[0].id

  ingress {
    protocol            = "ANY"
    description         = "internal communications between FW management server and FWs"
    v4_cidr_blocks = [
      "${cidrhost(var.subnet_prefix_list[0], 10)}/32",
      "${cidrhost(var.subnet_prefix_list[0], 100)}/32"
    ]
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP from Jump VM"
    security_group_id   = yandex_vpc_security_group.mgmt-jump-vm-sg.id
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP"
    predefined_target   = "self_security_group"
  }  

  ingress {
    protocol            = "TCP"
    description         = "SSH from Jump VM"
    port                = 22
    security_group_id   = yandex_vpc_security_group.mgmt-jump-vm-sg.id
  }

  ingress {
    protocol            = "TCP"
    description         = "Communication from Jump VM between SmartConsole applications and Security Management Server (CPMI)"
    port                = 19009
    security_group_id   = yandex_vpc_security_group.mgmt-jump-vm-sg.id
  }

  ingress {
    protocol            = "TCP"
    description         = "Communication from Jump VM between SmartConsole applications and Security Management Server (CPMI)"
    port                = 18190
    security_group_id   = yandex_vpc_security_group.mgmt-jump-vm-sg.id
  }

  ingress {
    protocol            = "TCP"
    description         = "HTTPS from Jump VM"
    port                = 443
    security_group_id   = yandex_vpc_security_group.mgmt-jump-vm-sg.id
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security group for Jump VM in management segment
resource "yandex_vpc_security_group" "mgmt-jump-vm-sg" {
  name        = "mgmt-jump-vm-sg"
  description = "Security group for Jump VM"
  folder_id   = yandex_resourcemanager_folder.folder[0].id
  network_id  = yandex_vpc_network.vpc[0].id

  ingress {
    protocol            = "UDP"
    description         = "WireGuard from trusted public IP addresses"
    port                = var.wg_port
    v4_cidr_blocks      = var.trusted_ip_for_access_jump-vm
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH from trusted public IP addresses"
    port                = 22
    v4_cidr_blocks      = var.trusted_ip_for_access_jump-vm
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security groups for FW in public segment
resource "yandex_vpc_security_group" "public-fw-sg" {
  name        = "public-fw-sg"
  description = "Security group for FW in public segment"
  folder_id   = yandex_resourcemanager_folder.folder[1].id
  network_id  = yandex_vpc_network.vpc[1].id

  ingress {
    protocol            = "TCP"
    description         = "public app"
    port                = var.public_app_port
    v4_cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security groups for web-servers in dmz segment
resource "yandex_vpc_security_group" "dmz-web-sg" {
  name        = "dmz-web-sg"
  description = "Security group for web-servers in dmz segment"
  folder_id   = yandex_resourcemanager_folder.folder[2].id
  network_id  = yandex_vpc_network.vpc[2].id

  ingress {
    protocol            = "TCP"
    description         = "public app internal port"
    port                = var.internal_app_port
    v4_cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH from management segment"
    port                = 22
    v4_cidr_blocks      = [var.subnet_prefix_list[0]]
  }

 egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security group for other segments, the one below is for testing purpose only, for production it should be changed accordingly
resource "yandex_vpc_security_group" "segment-sg" {
  count       = length(var.security_segment_names) - 2
  name        = "${var.security_segment_names[count.index + 2]}-sg"
  description = "Security group for ${var.security_segment_names[count.index + 2]} segment"
  folder_id   = yandex_resourcemanager_folder.folder[count.index + 2].id
  network_id  = yandex_vpc_network.vpc[count.index + 2].id

  ingress {
    protocol            = "TCP"
    description         = "HTTPS"
    port                = 443
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH"
    port                = 22
    predefined_target   = "self_security_group"
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP"
    predefined_target   = "self_security_group"
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

