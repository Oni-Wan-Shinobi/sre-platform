output "sre_node_1_ip" {
  description = "Public IP of sre-node-1 (k3s master)"
  value       = hcloud_server.main.ipv4_address
}

output "sre_node_2_ip" {
  description = "Public IP of sre-node-2 (k3s worker)"
  value       = hcloud_server.node2.ipv4_address
}

output "sre_node_1_internal_ip" {
  description = "Internal IP of sre-node-1"
  value       = "10.0.1.10"
}

output "sre_node_2_internal_ip" {
  description = "Internal IP of sre-node-2"
  value       = "10.0.1.11"
}

output "network_id" {
  description = "Hetzner private network ID"
  value       = hcloud_network.main.id
}
