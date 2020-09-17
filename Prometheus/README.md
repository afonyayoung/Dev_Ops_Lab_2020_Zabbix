# Prometheus
This folder contain code, that create two servers in GCP. One of them contain node exporter for prometheus. The second contains: Prometheus server, alertmanager, grafana & blackbox. Code will also create datasource and 2 simple dashboards for grafana: one for linux and one for http. 
## Quick start
1. Before applying change `project` and all necessary variables in `terraform.tfvars` 
1. Set your GCP credentials as the environment variables:
    * export GOOGLE_CLOUD_KEYFILE_JSON=/path/to/file
1. Run `terraform init`
1. Run `terraform apply`
1. To clean up and delete all resources after you're done, run `terraform destroy`

[Screenshots](Prometheus_Screenshots.pdf)