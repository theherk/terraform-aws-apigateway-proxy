terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.64"
    }
  }
}

locals {
  routes = [
    {
      path    = "/v1"
      methods = ["POST"]
      config = {
        # # Default if not given, but must give to override with null for OPTIONS.
        # connection_type = "VPC_LINK"
        #
        integration_request_parameters = { "integration.request.path.proxy" = "method.request.path.proxy" }
        method_request_parameters      = { "method.request.path.proxy" = true }
        request_templates              = {}
        responses                      = []
        type                           = null
        uri                            = "https://example.com/v1"
      }
    },
    {
      path    = "/lambda"
      methods = ["POST"]
      config = {
        integration_request_parameters = { "integration.request.header.X-Authorization" = "'static'" }
        method_request_parameters      = {}
        request_templates              = { "application/xml" = "{\"body\" : $input.json('$')}" }
        responses                      = []
        type                           = "AWS_PROXY"
        uri                            = aws_lambda_function.this.invoke_arn
      }
    },
    {
      path    = "/mock"
      methods = ["GET"]
      config = {
        integration_request_parameters = { "integration.request.header.X-Authorization" = "'static'" }
        method_request_parameters      = {}
        request_templates              = { "application/xml" = "{\"body\" : $input.json('$')}" }
        responses                      = []
        type                           = "MOCK"
        uri                            = null
      }
    },
    {
      path = "/v1/{proxy+}"
      # Here ["ANY"] could be used except we want to catch all OPTIONS below.
      methods = ["DELETE", "GET", "HEAD", "PATCH", "POST", "PUT"]
      config = {
        integration_request_parameters = { "integration.request.path.proxy" = "method.request.path.proxy" }
        method_request_parameters      = { "method.request.path.proxy" = true }
        request_templates              = {}
        responses                      = []
        type                           = null
        uri                            = "https://example.com/v1/{proxy}"
      }
    },
    {
      path    = "/{proxy+}"
      methods = ["OPTIONS"]
      config = {
        integration_request_parameters = {}
        method_request_parameters      = {}
        request_templates              = { "application/json" = jsonencode({ statusCode = 200 }) }
        type                           = "MOCK"
        uri                            = ""

        responses = [{
          status_code = 200

          integration_parameters = {
            "method.response.header.Access-Control-Allow-Headers"     = "'*'"
            "method.response.header.Access-Control-Allow-Methods"     = "'*'"
            "method.response.header.Access-Control-Allow-Origin"      = "'*'"
            "method.response.header.Access-Control-Allow-Credentials" = "'true'"
          }

          method_parameters = {
            "method.response.header.Access-Control-Allow-Headers"     = true
            "method.response.header.Access-Control-Allow-Methods"     = true
            "method.response.header.Access-Control-Allow-Origin"      = true
            "method.response.header.Access-Control-Allow-Credentials" = true
          }
        }]
      }
    }
  ]
}

module "builder" {
  source = "../../../terraform-aws-apigateway-route-builder"

  expand_any            = true
  generate_base_proxies = false
  routes                = local.routes
}

module "api" {
  source = "../../../terraform-aws-apigateway-proxy"

  authorizer           = aws_lambda_function.this
  certificate_arn      = "arn:aws:acm:eu-west-1:123412341234:certificate/id"
  description          = "A more complex api proxy."
  domain_name          = "api.example.com"
  endpoint_type        = "PRIVATE"
  name                 = "h4s-complete"
  permissions_boundary = "arn:aws:iam::123412341234:policy/PermissionBoundaryPolicy"
  resources            = module.builder.resources
  stage_name           = "dev"
  vpc_link_id          = "ab3def"
  xray_tracing_enabled = true
  zone_id              = "Z..."

  access_log_format = {
    "requestId"  = "$context.requestId",
    "ip"         = "$context.identity.sourceIp",
    "httpMethod" = "$context.httpMethod",
  }

  # With the optional implementation in terraform 1.3 this is simply:
  # methods = module.builder.methods
  methods = { for k, m in module.builder.methods : k => {
    depth        = m.depth
    key          = m.key
    method       = m.method
    resource_key = m.resource_key
    root         = m.root
    config = merge({
      cache_key_parameters           = null
      cache_namespace                = null
      connection_id                  = null
      connection_type                = null
      content_handling               = null
      credentials                    = null
      integration_request_parameters = null
      method_request_parameters      = null
      passthrough_behavior           = null
      request_templates              = null
      skip_verification              = null
      timeout_milliseconds           = null
      type                           = null
      uri                            = null
    }, m.config)
  } }
}

data "aws_iam_policy_document" "this_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name = "h4s-example-lambda"

  assume_role_policy = data.aws_iam_policy_document.this_assume_role.json
}

resource "aws_lambda_function" "this" {
  filename         = "lambda.zip"
  function_name    = "h4s-example"
  handler          = "exports.example"
  role             = aws_iam_role.this.arn
  runtime          = "nodejs16.x"
  source_code_hash = filebase64sha256("lambda.zip")
}
