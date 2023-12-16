//-------------id for cloud in Yandex Cloud
cloud_id = "b1g8dn6s3v2eiid9dbci"

// List of security segment names (the first one for management, the second for public internet, the third one for dmz, you can add more segments after the third one)
security_segment_names = ["mgmt", "public", "dmz"]

// List of prefixes for subnets corresponding to list of security segment names. One prefix per security segment.
subnet_prefix_list = ["192.168.1.0/24", "172.16.1.0/24", "10.160.1.0/24"]

//-------------TCP port used for public application published in DMZ
public_app_port = "80" 
//-------------and corresponding internal port for the same application
internal_app_port = "8080"

//-------------Define list of trusted public IP addresses for connection to Jump VM 
trusted_ip_for_access_jump-vm = ["A.A.A.A/32", "B.B.B.B/24"]

//-------------Jump VM Wireguard settings
jump_vm_admin_username = "admin"
wg_port = "51820" 
