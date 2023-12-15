//-------------id for cloud in Yandex Cloud
cloud_id = "b1g8dn6s3v2eiid9dbci"

//-------------TCP port used for public application published in DMZ
public_app_port = "80" 
//-------------and corresponding internal port for the same application
internal_app_port = "8080"

//-------------Define list of trusted public IP addresses for connection to Jump VM 
trusted_ip_for_access_jump-vm = ["A.A.A.A/32", "B.B.B.B/24"]

//-------------Jump VM Wireguard settings
jump_vm_admin_username = "admin"
wg_port = "51820" 
