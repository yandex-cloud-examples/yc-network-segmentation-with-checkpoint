output "path_for_private_ssh_key" {
  value = "./pt_key.pem"
}

output "fw-mgmt-server_ip_address" {
  value = yandex_compute_instance.mgmt-server.network_interface.0.ip_address
}

output "fw_mgmt_ip_address" {
  value = yandex_compute_instance.fw.network_interface.0.ip_address
}

output "fw_public_ip_address" {
  value = yandex_compute_instance.fw.network_interface.1.nat_ip_address
}

output "fw_gaia_portal_mgmt-server_password" {
  value = "admin"
}

output "fw_smartconsole_mgmt-server_password" {
  value = "${random_password.pass-sms[0].result}"
  sensitive = true
}

output "fw_sic-password" {
  value = "${random_password.pass-sic[0].result}"
  sensitive = true
}

output "jump-vm_public_ip_address_jump-vm" {
  value = yandex_vpc_address.public-ip-jump-vm.external_ipv4_address.0.address
}

output "jump-vm_path_for_WireGuard_client_config" {
  value = "./jump-vm-wg.conf"
}

output "dmz-web-server_ip_address" {
  value = "${cidrhost(var.subnet_prefix_list[2], 100)}"
}