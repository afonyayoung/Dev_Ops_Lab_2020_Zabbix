output "Kibana_test" {
  value = "http://${google_compute_instance.server.network_interface[0].access_config[0].nat_ip}:5601"
}
output "Test_elasticsearch_health"{
  value = "http://${google_compute_instance.server.network_interface[0].access_config[0].nat_ip}:9200/_cluster/health?pretty"
}
output "Test_elasticsearch_indexes"{
  value = "http://${google_compute_instance.server.network_interface[0].access_config[0].nat_ip}:9200/_cat/indices?v"
}
output "Tomcat"{
  value = "http://${google_compute_instance.logstash_server.network_interface[0].access_config[0].nat_ip}:8080"
}