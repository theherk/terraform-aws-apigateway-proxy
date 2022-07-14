locals {
  use_authorizer = var.authorizer != null
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
    for_each = length(var.ip_whitelist) != 0 && var.source_vpce == null ? toset([1]) : toset([])

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
    for_each = length(var.ip_whitelist) != 0 && var.source_vpce != null ? toset([1]) : toset([])

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
    for_each = var.source_vpce != null ? toset([1]) : toset([])

    content {
      actions   = ["execute-api:Invoke"]
      effect    = "Deny"
      resources = ["${aws_api_gateway_rest_api.this.execution_arn}/*"]

      condition {
        test     = "StringNotEquals"
        variable = "aws:SourceVpce"
        values   = [var.source_vpce]
      }

      principals {
        type        = "*"
        identifiers = ["*"]
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  # checkov:skip=CKV_AWS_158: Not encrypted.

  name              = "/api-gw/${var.name}"
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
    destination_arn = aws_cloudwatch_log_group.this.arn
    format          = jsonencode(var.access_log_format)
  }
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
  count = var.domain_name != null ? 1 : 0

  domain_name              = var.domain_name
  regional_certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = [contains(["EDGE", "REGIONAL"], var.endpoint_type) ? var.endpoint_type : "REGIONAL"]
  }
}

resource "aws_route53_record" "this" {
  count = var.domain_name != null ? 1 : 0

  name    = aws_api_gateway_domain_name.this[0].domain_name
  type    = "A"
  zone_id = var.zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.this[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.this[0].regional_zone_id
  }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  count = var.domain_name != null ? 1 : 0

  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this[0].domain_name
}
