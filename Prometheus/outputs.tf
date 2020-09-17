output "Grafana_url" {
  value = "http://${google_compute_instance.server.network_interface[0].access_config[0].nat_ip}:3000"
}
