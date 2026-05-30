variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}


variable "ssh_public_key" {
  description = "Public SSH key for server access"
  type        = string
}
