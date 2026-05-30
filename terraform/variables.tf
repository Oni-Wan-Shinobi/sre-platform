variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}


variable "ssh_public_key" {
  description = "Public SSH key for server access"
  type        = string
}

variable "management_ip" {
  description = "IP address of management node (sre-main) allowed to access k3s API"
  type        = string
}
