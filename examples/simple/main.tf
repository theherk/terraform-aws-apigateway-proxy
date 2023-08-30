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
  resources = {
    "0|v1" = {
      depth      = 0
      parent_key = null
      path_part  = "v1"
    }
    "1|v1/{proxy+}" = {
      depth      = 1
      parent_key = "0|v1"
      path_part  = "{proxy+}"
    }
  }

  methods = {
    "0|v1|ANY" = {
      config = {
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
        uri                            = "https://example.com/v1"
      }
      depth        = 0
      key          = "0|v1|ANY"
      method       = "ANY"
      resource_key = "0|v1"
      root         = false
    }
    "1|v1/{proxy+}|ANY" = {
      config = {
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
        uri                            = "https://example.com/v1/{proxy}"
      }
      depth        = 1
      key          = "1|v1/{proxy+}|ANY"
      method       = "ANY"
      resource_key = "1|v1/{proxy+}"
      root         = false
    }
  }
}

module "api" {
  source = "../../../terraform-aws-apigateway-proxy"

  name        = "h4s-simple"
  stage_name  = "dev"
  vpc_link_id = "afp3wd"

  resources = local.resources
  methods   = local.methods
}
