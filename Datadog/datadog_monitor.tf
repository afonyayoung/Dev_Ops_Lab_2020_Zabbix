provider "datadog" {
}
resource "datadog_monitor" "test" {
  name                = var.dd_monitor_name
  type                = var.dd_monitor_type
  query               = local.dd_monitor_query
  message             = local.dd_message
  tags                = var.dd_monitor_tags
  notify_audit        = false
  locked              = false
  timeout_h           = var.dd_monitor_timeout
  no_data_timeframe   = null
  require_full_window = true
  new_host_delay      = var.dd_monitor_delay
  notify_no_data      = false
  renotify_interval   = var.dd_monitor_interval
  escalation_message  = var.dd_monitor_esc_message
  include_tags        = true
  thresholds          = var.dd_monitor_tresholds
}