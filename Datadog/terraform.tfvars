dd_monitor_name = "Response time"
dd_monitor_type = "metric alert"
dd_monitor_message = "Message"
dd_message_email = "your@email.com"
dd_monitor_tags = []
dd_monitor_timeout = 0
dd_monitor_delay = 300
dd_monitor_interval = "0"
dd_monitor_esc_message = "Warning"

#available: Alert threshold=critical,Warning threshold=warning, 
#Alert recovery threshold= critical_recovery, Warning recovery threshold = warning_recovery
dd_monitor_tresholds = {
    critical = 0.5
}
#variables for query
##Metric
query_metric = "network.http.response_time"
##from
query_from = "instance"
##excluding 

##avg by
query_average = "avg"

##Trigger when the metric is
query_math = ">="
##the treshold (on average = avg, at least once = max, at all times = min, in total = sum)
query_times = "max"
##during the last
query_during = "last_5m"
##value
query_triger_value = "0.5"

#variables for instance and datadog monitor
web_instance_name = "tomcat"
project = "smooth-era-287810"
region = "us-central1"
zone = "us-central1-c"
name = "datadog"

