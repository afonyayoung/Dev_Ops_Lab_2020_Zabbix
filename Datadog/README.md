# DATADOG
This example contains code to create the following configuration:
1. Create instance in GCP with istalled tomcat and datadog agent.
1. Create datadog monitor, that monitors response time of created tomcat server and send alert when the response time is above or equal 500ms. 
## Quick start
1. Before applying change `project` and all necessary variables in `terraform.tfvars` 
1. Set your GCP credentials as the environment variables:
    * export GOOGLE_CLOUD_KEYFILE_JSON=/path/to/file
1. Set your Datadog credentials
    * export DD_APP_KEY=your_app_key
    * export DD_API_KEY=your_api_key
1. Run `terraform init`
1. Run `terraform apply -var api_key=$DD_API_KEY` (or `terraform apply` api_key will be requested).
1. To clean up and delete all resources after you're done, run `terraform destroy -var api_key=$DD_API_KEY` (or `terraform destroy` api_key will be requested).

[Screenshots](Datadog_Screenshots.pdf)