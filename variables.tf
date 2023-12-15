variable "cloud_id" {
  type        = string
  description = "cloud id for resources"
  default     = null
}

variable "az_name" {
  type        = string
  description = "Availability zone name for resources"
  default     = "ru-central1-d"
}

variable "security_segment_names" {
  type = list(string)
  description = "List of security segment names (the first one for management, the second for public internet, the third one for dmz, you can add more segments after the third one)"
  default = ["mgmt", "public", "dmz"]
}

variable "subnet_prefix_list" {
  type        = list(string)
  description = "List of prefixes for subnets corresponding to list of security segment names. One prefix per security segment."
  default     = ["192.168.1.0/24", "172.16.1.0/24", "10.160.1.0/24"]
}

variable "public_app_port" {
  type        = number
  description = "TCP port used for public application published in dmz"
  default     = null 
}

variable "internal_app_port" {
  type        = number
  description = "Internal port for public application published in dmz"
  default     = null 
}

variable "trusted_ip_for_access_jump-vm" {
  type        = list(string)
  description = "List of trusted public IP addresses for connection to Jump VM"
  default     = null
}

variable "jump_vm_admin_username" {
  type        = string
  description = "Jump VM admin username"
  default     = null 
}

variable "wg_port" {
  type        = number
  description = "Jump VM Wireguard port"
  default     = null 
}
