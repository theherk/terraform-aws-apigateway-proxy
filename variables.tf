variable "access_log_format" {
  description = "Format for access log entries."
  type        = map(any)

  default = {
    "requestId"      = "$context.requestId",
    "ip"             = "$context.identity.sourceIp",
    "requestTime"    = "$context.requestTime",
    "httpMethod"     = "$context.httpMethod",
    "routeKey"       = "$context.routeKey",
    "status"         = "$context.status",
    "protocol"       = "$context.protocol",
    "responseLength" = "$context.responseLength",
    "domainName"     = "$context.domainName",
    "error.message"  = "$context.error.message",
    "contextPath"    = "$context.path",
  }
}

variable "associate_vpc_endpoints" {
  description = "List of vpc endpoints to associate with PRIVATE type api in endpoint configuration. This would be a subset of `source_vpc_endpoints`. It is only needed if invoking the api via generated Route53 alias, rather than with `x-apigw-api-id` header. You can read more about this here: https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-private-apis.html#associate-private-api-with-vpc-endpoint."
  type        = list(string)
  default     = null
}

variable "authorizer" {
  description = "Lambda authorizer."
  type        = any
  default     = null
}

variable "authorizer_identity_source" {
  description = "(Optional) Source of the identity in an incoming request. Defaults to `method.request.header.Authorization`. For REQUEST type, this may be a comma-separated list of values, including headers, query string parameters and stage variables - e.g., `method.request.header.SomeHeaderName,method.request.querystring.SomeQueryStringName,stageVariables.SomeStageVariableName`"
  type        = string
  default     = null
}

variable "binary_media_types" {
  description = "List of binary media types supported by the REST API."
  type        = list(string)
  default     = []
}

variable "certificate_arn" {
  description = "Certificate arn for api domain."
  type        = string
  default     = null
}

variable "description" {
  description = "API description."
  type        = string
  default     = "API Gateway for proxying requests."
}

variable "domain_name" {
  description = "Primary domain name to access the api."
  type        = string
  default     = null
}

variable "domain_names_alternate" {
  description = "Alternate domain names to access the api. `domain_name` is the domain for which the Route53 record will be added; not these. These alternate names are for subject alternative names in the given certificate."
  type        = list(string)
  default     = []
}

variable "endpoint_type" {
  description = "API endpoint type."
  type        = string
  default     = "REGIONAL"
}

variable "ip_whitelist" {
  description = "List of IP addresses that can reach the api."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Number of days logs will be kept in CloudWatch."
  type        = number
  default     = 365
}

variable "method_settings" {
  description = "Settings for all API path methods. For descriptions see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings#settings"

  type = object({
    cache_data_encrypted                       = optional(bool)
    cache_ttl_in_seconds                       = optional(number)
    caching_enabled                            = optional(bool)
    data_trace_enabled                         = optional(bool)
    logging_level                              = optional(string)
    metrics_enabled                            = optional(bool)
    require_authorization_for_cache_control    = optional(bool)
    throttling_burst_limit                     = optional(number)
    throttling_rate_limit                      = optional(number)
    unauthorized_cache_control_header_strategy = optional(string)
  })

  default = {
    data_trace_enabled     = true
    logging_level          = "INFO"
    throttling_burst_limit = 3
    throttling_rate_limit  = 2
  }

  validation {
    condition = (
      var.method_settings.logging_level == null ? true :
      contains(["ERROR", "INFO", "OFF"], var.method_settings.logging_level)
    )

    error_message = "If given logging_level must be ERROR, INFO, or OFF."
  }

  validation {
    condition = (
      var.method_settings.unauthorized_cache_control_header_strategy == null ? true :
      contains(
        ["FAIL_WITH_403", "SUCCEED_WITH_RESPONSE_HEADER", "SUCCEED_WITHOUT_RESPONSE_HEADER"],
        var.method_settings.unauthorized_cache_control_header_strategy
      )
    )

    error_message = "If given unauthorized_cache_control_header_strategy must be FAIL_WITH_403, SUCCEED_WITH_RESPONSE_HEADER, or SUCCEED_WITHOUT_RESPONSE_HEADER."
  }
}

variable "methods" {
  description = <<-DESC
    Methods with resource associations and integration configuration.

    This is a complex type manual configuration is not recommended. It is recommended to use [terraform-aws-apigateway-route-builder](https://github.com/theherk/terraform-aws-apigateway-route-builder/) to generate this data. Nevertheless, a description of the type's attributes are:

    ```
    methods = {
      "0|v1|POST" = {
        config = {
          "uri"    = "example.com/v1"
        }
        depth        = 0
        key          = "0|v1|POST"
        method       = "POST"
        resource_key = "0|v1"
        root         = false
      }
    }
    ```
  DESC
  type = map(object({ # keyed by depth | path | verb
    config = object({ # method configuration
      authorization                  = optional(string)
      cache_key_parameters           = optional(list(string))
      cache_namespace                = optional(string)
      connection_id                  = optional(string)
      connection_type                = optional(string)
      content_handling               = optional(string)
      credentials                    = optional(string)
      integration_request_parameters = optional(map(string), { "integration.request.path.proxy" = "method.request.path.proxy" })
      method_request_parameters      = optional(map(string), { "method.request.path.proxy" = true })
      passthrough_behavior           = optional(string)
      request_templates              = optional(map(string))
      skip_verification              = optional(bool)
      timeout_milliseconds           = optional(number)
      type                           = optional(string, "HTTP_PROXY")
      uri                            = optional(string, "") # uri to proxy when applicable

      responses = optional(list(object({
        status_code            = string
        selection_pattern      = optional(string)
        integration_parameters = optional(map(string))
        method_parameters      = optional(map(bool))
      })), [])
    })
    depth        = number # nested depth of containing resource
    key          = string # same as object key
    method       = string # HTTP verb for methd
    resource_key = string # key of containing resource
    root         = bool   # belongs in the root resource
  }))
}

variable "resources" {
  description = <<-DESC
    Resources keyed by the route's depth and path, and containing: depth, parent_key, path_part.

    This is a complex type manual configuration is not recommended. It is recommended to use [terraform-aws-apigateway-route-builder](https://github.com/theherk/terraform-aws-apigateway-route-builder/) to generate this data. Nevertheless, a description of the type's attributes are:

    ```
    resources = {
      "0|v1" = {
        depth      = 0
        parent_key = null
        path_part  = "v1"
      }
    }
    ```
  DESC
  type = map(object({   # key by depth | path
    depth      = number # nested depth
    parent_key = string # key of containing resource
    path_part  = string # individual, last path component
  }))
}

variable "name" {
  description = "Name of the api."
  type        = string
}

variable "permissions_boundary" {
  description = "ARN of the boundary policy to attach to roles."
  type        = string
  default     = null
}

variable "routing_policy" {
  description = "Routing policy applied to the alias A record when `domain_name` is given. This can be useful if you intend to failover to an alternate API. It is not required, and when not given, a simple routing policy will be used."
  default     = null

  type = object({
    set_identifier = string

    cidr = optional(object({
      collection_id = string
      location_name = string
    }))

    failover = optional(object({
      type = string
    }))

    geolocation = optional(object({
      continent   = string
      country     = string
      subdivision = optional(string)
    }))

    geoproximity = optional(object({
      aws_region       = optional(string)
      bias             = optional(string)
      local_zone_group = optional(string)

      coordinates = optional(object({
        latitude  = string
        longitude = string
      }))
    }))

    latency = optional(object({
      region = string
    }))

    weighted = optional(object({
      weight = number
    }))
  })
}

variable "source_vpc_endpoints" {
  description = "Source VPC endpoints to whitelist. Required in addition to ip_whitelist for private endpoint type."
  type        = list(string)
  default     = []
}

variable "source_vpce" {
  description = "Source VPC endpoint to whitelist. Required in addition to ip_whitelist for private endpoint type. Deprecated, but provided for compatibility. Use `source_vpc_endpoints` instead."
  type        = string
  default     = null
}

variable "stage_name" {
  description = "Name of the api stage to deploy."
  type        = string
}

variable "throttling_burst_limit" {
  description = "(DEPRECATED) Use `method_settings` instead. This will still work until removed, but will be superseded by `methods_settings`. Specifies the throttling burst limit. Should be used in combination with throttling_rate_limit."
  type        = number
  default     = null
}

variable "throttling_rate_limit" {
  description = "(DEPRECATED) Use `method_settings` instead. This will still work until removed, but will be superseded by `methods_settings`. Specifies the throttling rate limit. Should be used in combination with throttling_burst_limit."
  type        = number
  default     = null
}

variable "xray_tracing_enabled" {
  description = "Whether active tracing with X-ray is enabled."
  type        = bool
  default     = null
}

variable "vpc_link_id" {
  description = "vpc link id for proxy integrations. Can be given per route, but will be default if given when not found in route."
  type        = string
  default     = null
}

variable "zone_id" {
  description = "DNS zone for api. Only applicable if `domain_name` given."
  type        = string
  default     = null
}
