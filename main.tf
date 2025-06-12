terraform {
  required_providers {
    signalfx = {
      source  = "splunk-terraform/signalfx"
      version = ">= 9.15.0" # 最新バージョンに合わせてください
    }
  }
}

# --- 変数の宣言 ---
variable "signalfx_auth_token" {
  type        = string
  description = "SignalFx API authentication token."
  sensitive   = true
}

variable "signalfx_realm" {
  type = string
  default = "us1"
}

variable "services" {
  type    = list(string)
  default = [
    "frontend",
    "checkoutservice",
    "paymentservice",
    "adservice"
  ]
}

variable "detector_request_rate" {
  type = string
  default = "xxxxxxxx"
}

variable "detector_request_latency" {
  type = string
  default = "xxxxxxxx"
}

variable "detector_error_rate" {
  type = string
  default = "xxxxxxxx"
}

provider "signalfx" {
  # SignalFx APIトークンとレルムを設定
  auth_token = "${var.signalfx_auth_token}"
  api_url = "https://api.${var.signalfx_realm}.signalfx.com" # ご利用のレルムに合わせて変更
}

module "service_rows" {
  source       = "./modules/service_dashboard_row"
  for_each     = toset(var.services)
  service_name = each.value
  realm        = var.signalfx_realm
  detector_request_rate = var.detector_request_rate
  detector_request_latency = var.detector_request_latency
  detector_error_rate = var.detector_error_rate

  providers = {
    signalfx = signalfx
  }
}

resource "signalfx_dashboard_group" "my_dashboard_group" {
  name = "My team dashboard group"
}

resource "signalfx_dashboard" "service_health" {
  name            = "My Service Health Dashboard"
  dashboard_group = signalfx_dashboard_group.my_dashboard_group.id

  dynamic "chart" {
    for_each = flatten([
      for idx, svc in var.services : [
        {
          chart_id = module.service_rows[svc].charts[0]
          column   = 0
          width    = 1
          height   = 1
          row      = idx
        },
        {
          chart_id = module.service_rows[svc].charts[1]
          column   = 1
          width    = 3
          height   = 1
          row      = idx
        },
        {
          chart_id = module.service_rows[svc].charts[2]
          column   = 4
          width    = 4
          height   = 1
          row      = idx
        },
        {
          chart_id = module.service_rows[svc].charts[3]
          column   = 8
          width    = 4
          height   = 1
          row      = idx
        }
      ]
    ])
    content {
      chart_id = chart.value.chart_id
      column   = chart.value.column
      width    = chart.value.width
      height   = chart.value.height
      row      = chart.value.row
    }
  }
}
