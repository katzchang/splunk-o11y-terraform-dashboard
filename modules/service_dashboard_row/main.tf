terraform {
  required_providers {
    signalfx = {
      source  = "splunk-terraform/signalfx"
      version = ">= 9.15.0"
    }
  }
}

variable "service_name" {
  type        = string
  description = "Target Service Name"
}

variable "realm" {
  type        = string
  description = "SignalFx realm"
}

variable "detector_request_rate" {
  type        = string
  description = "Detector: Request Rate"
}

variable "detector_request_latency" {
  type        = string
  description = "Detector: Request Latency"
}

variable "detector_error_rate" {
  type        = string
  description = "Detector: Error Rate"
}


# チャート1: テキスト
resource "signalfx_text_chart" "apm_link_chart" {
  name = "."
  markdown = <<EOF
${var.service_name}

* [APM](https://app.${var.realm}.signalfx.com/#/apm/service?endTime=Now&service=${var.service_name}&startTime=-1d)
EOF
}

# チャート2: リクエストレート
resource "signalfx_time_chart" "request_rate_chart" {
  name        = "${var.service_name}: Request rate"
  description = "Requests/sec processed by each endpoint of the service"
  program_text = <<EOF
service = '${var.service_name}'

filter_ = filter('sf_environment', '*') and filter('sf_service', service) and filter('sf_operation', '*') and filter('sf_kind', 'SERVER', 'CONSUMER') and (not filter('sf_dimensionalized', '*')) and (not filter('sf_serviceMesh', '*'))
groupby = ['sf_environment', 'sf_service', 'sf_operation', 'sf_httpMethod']
allow_missing = ['sf_httpMethod']

A = histogram('spans', filter=filter_).count(by=groupby, allow_missing=allow_missing).rate(by=groupby, allow_missing=allow_missing).publish(label='A')

alerts(detector_id='${var.detector_request_rate}', filter=filter('sf_service', service)).publish()
EOF
  plot_type          = "AreaChart"
  stacked            = true
  unit_prefix        = "Metric"
  time_range         = 900
  minimum_resolution = 10
  max_delay          = 30
  disable_sampling   = true
}

# チャート3: レイテンシ
resource "signalfx_time_chart" "request_latency_chart" {
  name        = "${var.service_name}: Request latency (p90)"
  description = "90th percentile response time by endpoint of the service"
  program_text = <<EOF
service = '${var.service_name}'

filter_ = filter('sf_environment', '*') and filter('sf_service', service) and filter('sf_operation', '*') and filter('sf_kind', 'SERVER', 'CONSUMER') and (not filter('sf_dimensionalized', '*')) and (not filter('sf_serviceMesh', '*'))
groupby = ['sf_environment', 'sf_service', 'sf_operation', 'sf_httpMethod']
allow_missing = ['sf_httpMethod']

A = histogram('spans', filter=filter_).percentile(pct=90, by=groupby, allow_missing=allow_missing).publish(label='p90')

alerts(detector_id='${var.detector_request_latency}', filter=filter('sf_service', service)).publish()
EOF
  plot_type          = "LineChart"
  unit_prefix        = "Metric"
  time_range         = 900
  minimum_resolution = 10
  max_delay          = 30
  disable_sampling   = true
}

# チャート4: エラーレート
resource "signalfx_time_chart" "error_rate_chart" {
  name        = "${var.service_name}: Error rate"
  description = "Error rate on requests made to endpoints of the service"
  program_text = <<EOF
service = '${var.service_name}'

filter_ = filter('sf_environment', '*') and filter('sf_service', service) and filter('sf_operation', '*') and filter('sf_kind', 'SERVER', 'CONSUMER') and (not filter('sf_dimensionalized', '*')) and (not filter('sf_serviceMesh', '*'))
groupby = ['sf_environment', 'sf_service', 'sf_operation', 'sf_httpMethod']
allow_missing = ['sf_httpMethod']

A = histogram('spans', filter=filter_ and filter('sf_error', 'true')).count(by=groupby, allow_missing=allow_missing).fill(0).publish(label='A', enable=False)
B = histogram('spans', filter=filter_).count(by=groupby, allow_missing=allow_missing).fill(0).publish(label='B', enable=False)
C = combine(100*((A if A is not None else 0) / B)).publish(label='C')

alerts(detector_id='${var.detector_error_rate}', filter=filter('sf_service', service)).publish()
EOF
  plot_type          = "LineChart"
  unit_prefix        = "Metric"
  time_range         = 900
  minimum_resolution = 10
  max_delay          = 30
  disable_sampling   = true
}

output "charts" {
  value = [
    signalfx_text_chart.apm_link_chart.id,
    signalfx_time_chart.request_rate_chart.id,
    signalfx_time_chart.request_latency_chart.id,
    signalfx_time_chart.error_rate_chart.id
  ]
}
