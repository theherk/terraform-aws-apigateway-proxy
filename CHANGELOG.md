# Changelog

## [3.0.0](https://github.com/theherk/terraform-aws-apigateway-proxy/compare/2.7.1...3.0.0) (2026-11-04)


### ⚠ BREAKING CHANGES

* Data trace logging is no longer enabled by default and log retention drops from 365 to 30 days. Set method_settings.data_trace_enabled and log_retention_days explicitly to keep the previous behavior.

### Features

* Disable data trace by default and retain logs for 30 days ([4f5d13c](https://github.com/theherk/terraform-aws-apigateway-proxy/commit/4f5d13c447e0eb01e42b1db1b68f6dd742985874))
