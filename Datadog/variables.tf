#variables for datadog monitor
variable api_key {}
variable dd_monitor_name {}
variable dd_monitor_type {}

locals {
    dd_monitor_query = "${var.query_times}(${var.query_during}):${var.query_average}:${var.query_metric}{${var.query_from}:${var.web_instance_name}} ${var.query_math} ${var.query_triger_value}"
}
#variables for query
variable query_times {}
variable query_during {}
variable query_average {}
variable query_metric {}
variable query_from {}
variable query_math {}
variable query_triger_value {}
##############################

locals {
    dd_message = "${var.dd_monitor_message} @${var.dd_message_email}"
} 
variable dd_monitor_message {}
variable dd_message_email {}


variable dd_monitor_tags {}
variable dd_monitor_timeout {}
variable dd_monitor_delay {}
variable dd_monitor_interval {}
variable dd_monitor_esc_message {}
variable dd_monitor_tresholds {}


variable web_instance_name {}

#variables for GCP
variable project {}
variable region {}
variable zone {}
variable name {}

variable image {
    default = "centos-cloud/centos-7"
}

variable size {
    default = 35
}

variable disk_type {
    default = "pd-ssd"
}
