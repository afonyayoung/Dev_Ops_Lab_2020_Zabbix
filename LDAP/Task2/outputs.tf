output "URL_LDAP_server" {
  value = "http://${google_compute_instance.ldap_server.network_interface[0].access_config[0].nat_ip}/ldapadmin"
}
output "SSH_LDAP_client"{
  value = "ssh my_user@${google_compute_instance.ldap_client.network_interface[0].access_config[0].nat_ip} (or add -i /path/to/private_key)"
}