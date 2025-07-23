# Splunk Observability - Service Health Dashboard Template

このTerraform構成は、Splunk Observability Cloud 向けのダッシュボードテンプレートをデプロイするためのものです。

## 前提条件

- Terraform がインストールされている必要があります  
  👉 [Terraformのインストールガイド](https://developer.hashicorp.com/terraform/downloads)
- Splunk ObservabilityのToken管理画面から、APIが有効になっているトークンを作成・取得してください。

## 使い方

```bash
# プロバイダーの初期化
terraform init
```

```bash
# 設定内容の確認
terraform plan
```

```bash
# ダッシュボードの作成
terraform apply
```

## 変数

| 変数名                   | 型           | 説明                                     | デフォルト値            |
|------------------------|--------------|------------------------------------------|-------------------------|
| `signalfx_auth_token`  | string       | SignalFx API token                       | (なし / 必須)           |
| `signalfx_realm`       | string       | SignalFx の realm                        | `"us1"`                |
| `services`             | list(string) | ダッシュボード対象となるサービス名リスト | `["frontend", "checkoutservice", "paymentservice", "adservice"]` |
| `detector_request_rate`| string       | リクエストレート用の Detector ID        | `"xxxxxxxx"`           |
| `detector_request_latency` | string   | レイテンシー用の Detector ID            | `"xxxxxxxx"`           |
| `detector_error_rate`  | string       | エラーレート用の Detector ID            | `"xxxxxxxx"`           |

## モジュール構成

この構成は以下のモジュールを利用しています：

- `modules/service_dashboard_row/`: ダッシュボードの1行を定義するモジュール
