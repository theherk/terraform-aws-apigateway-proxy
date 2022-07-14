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
    "protocol"       = "$context.protocol"
  }
}

variable "authorizer" {
  description = "Lambda authorizer."
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
  description = "Domain name to access api."
  type        = string
  default     = null
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
      cache_key_parameters           = list(string)
      cache_namespace                = string
      connection_id                  = string
      connection_type                = string
      content_handling               = string
      credentials                    = string
      integration_request_parameters = map(string)
      method_request_parameters      = map(string)
      passthrough_behavior           = string
      request_templates              = map(string)
      skip_verification              = bool
      timeout_milliseconds           = number
      type                           = string
      uri                            = string # uri to proxy when applicable
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

variable "source_vpce" {
  description = "Source VPC endpoint to whitelist. Required in addition to ip_whitelist for private endpoint type."
  type        = string
  default     = null
}

variable "stage_name" {
  description = "Name of the api stage to deploy."
  type        = string
}

variable "throttling_burst_limit" {
  description = "Specifies the throttling burst limit. Should be used in combination with throttling_rate_limit."
  type        = number
  default     = null
}

variable "throttling_rate_limit" {
  description = "Specifies the throttling rate limit. Should be used in combination with throttling_burst_limit."
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
