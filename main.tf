locals {
  use_authorizer = var.authorizer != null

  # To support earlier implementations, we still allow the use of `source_vpce`,
  # even though we should be able to whitelist multiple source vpc endpoints.
  # Therefore, we create a list of the combination of the two properties.
  source_vpc_endpoints = distinct(concat(compact([var.source_vpce]), var.source_vpc_endpoints))
}

data "aws_iam_policy_document" "this" {
  statement {
    actions   = ["execute-api:Invoke"]
    resources = ["${aws_api_gateway_rest_api.this.execution_arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.ip_whitelist) != 0 && length(local.source_vpc_endpoints) == 0 ? toset([1]) : toset([])

    content {
      actions   = ["execute-api:Invoke"]
      effect    = "Deny"
      resources = ["${aws_api_gateway_rest_api.this.execution_arn}/*"]

      condition {
        test     = "NotIpAddress"
        variable = "aws:SourceIp"
        values   = var.ip_whitelist
      }

      principals {
        type        = "*"
        identifiers = ["*"]
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.ip_whitelist) != 0 && length(local.source_vpc_endpoints) != 0 ? toset([1]) : toset([])

    content {
      actions   = ["execute-api:Invoke"]
      effect    = "Deny"
      resources = ["${aws_api_gateway_rest_api.this.execution_arn}/*"]

      condition {
        test     = "NotIpAddress"
        variable = "aws:VpcSourceIp"
        values   = var.ip_whitelist
      }

      principals {
        type        = "*"
        identifiers = ["*"]
      }
    }
  }

  dynamic "statement" {
    for_each = length(local.source_vpc_endpoints) != 0 ? toset([1]) : toset([])

    content {
      actions   = ["execute-api:Invoke"]
      effect    = "Deny"
      resources = ["${aws_api_gateway_rest_api.this.execution_arn}/*"]

      condition {
        test     = "StringNotEquals"
        variable = "aws:SourceVpce"
        values   = local.source_vpc_endpoints
      }

      principals {
        type        = "*"
        identifiers = ["*"]
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "access" {
  # checkov:skip=CKV_AWS_158: Not encrypted.
  name              = "/api-gw/${var.name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "exec" {
  # checkov:skip=CKV_AWS_158: Not encrypted.
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.this.id}/${var.stage_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_api_gateway_rest_api" "this" {
  description        = var.description
  name               = var.name
  binary_media_types = var.binary_media_types

  endpoint_configuration {
    types = [var.endpoint_type]
  }
}

resource "aws_api_gateway_rest_api_policy" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  policy      = data.aws_iam_policy_document.this.json
}

resource "aws_api_gateway_method_settings" "s_all" {
  method_path = "*/*"
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name

  settings {
    data_trace_enabled     = true
    logging_level          = "INFO"
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }
}

resource "aws_api_gateway_stage" "this" {
  # checkov:skip=CKV_AWS_120: Caching not enabled.
  # checkov:skip=CKV2_AWS_4: Logging is enabled; bug maybe.
  # checkov:skip=CKV2_AWS_29: WAF added outside module.

  stage_name           = var.stage_name
  rest_api_id          = aws_api_gateway_rest_api.this.id
  deployment_id        = aws_api_gateway_deployment.this.id
  xray_tracing_enabled = var.xray_tracing_enabled

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access.arn
    format          = jsonencode(var.access_log_format)
  }

  depends_on = [
    aws_cloudwatch_log_group.access,
    aws_cloudwatch_log_group.exec
  ]
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      data.aws_iam_policy_document.this.json,
      aws_api_gateway_resource.depth_0,
      aws_api_gateway_resource.depth_1,
      aws_api_gateway_resource.depth_2,
      aws_api_gateway_resource.depth_3,
      aws_api_gateway_resource.depth_4,
      aws_api_gateway_method.this,
      aws_api_gateway_integration.this,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_integration.this]
}

resource "aws_api_gateway_domain_name" "this" {
  for_each = toset(concat(try([coalesce(var.domain_name)], []), var.domain_names_alternate))

  domain_name              = each.key
  regional_certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = [contains(["EDGE", "REGIONAL"], var.endpoint_type) ? var.endpoint_type : "REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  for_each = toset(concat(try([coalesce(var.domain_name)], []), var.domain_names_alternate))

  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this[each.key].domain_name
}

resource "aws_route53_record" "this" {
  count = var.domain_name != null ? 1 : 0

  name    = aws_api_gateway_domain_name.this[var.domain_name].domain_name
  type    = "A"
  zone_id = var.zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.this[var.domain_name].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.this[var.domain_name].regional_zone_id
  }
}
