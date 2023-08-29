resource "aws_api_gateway_resource" "depth_0" {
  for_each = { for k, r in var.resources : k => r if r.depth == 0 }

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "depth_1" {
  for_each = { for k, r in var.resources : k => r if r.depth == 1 }

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.depth_0[each.value.parent_key].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "depth_2" {
  for_each = { for k, r in var.resources : k => r if r.depth == 2 }

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.depth_1[each.value.parent_key].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "depth_3" {
  for_each = { for k, r in var.resources : k => r if r.depth == 3 }

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.depth_2[each.value.parent_key].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "depth_4" {
  for_each = { for k, r in var.resources : k => r if r.depth == 4 }

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.depth_3[each.value.parent_key].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_method" "this" {
  for_each = var.methods

  authorization      = coalesce(each.value.config.authorization, local.use_authorizer ? "CUSTOM" : "NONE")
  authorizer_id      = local.use_authorizer && each.value.config.authorization != "NONE" ? aws_api_gateway_authorizer.authorizer[0].id : null
  http_method        = each.value.method
  rest_api_id        = aws_api_gateway_rest_api.this.id
  request_parameters = each.value.config.method_request_parameters == {} ? null : each.value.config.method_request_parameters

  resource_id = (each.value.root
    ? aws_api_gateway_rest_api.this.root_resource_id
    : element([
      aws_api_gateway_resource.depth_0,
      aws_api_gateway_resource.depth_1,
      aws_api_gateway_resource.depth_2,
      aws_api_gateway_resource.depth_3,
      aws_api_gateway_resource.depth_4,
    ], each.value.depth)[each.value.resource_key].id
  )
}

resource "aws_api_gateway_integration" "this" {
  for_each = { for m in var.methods : m.key => merge(m, {
    connection_type = try(coalesce(
      m.config.connection_type,
      contains(["HTTP", "HTTP_PROXY"], coalesce(m.config.type, "HTTP_PROXY")) ? "VPC_LINK" : null
    ), null)
    type = coalesce(m.config.type, "HTTP_PROXY")
  }) }

  cache_key_parameters    = each.value.config.cache_key_parameters
  cache_namespace         = each.value.config.cache_namespace
  connection_type         = each.value.connection_type
  content_handling        = each.value.config.content_handling
  credentials             = each.value.config.credentials
  http_method             = aws_api_gateway_method.this[each.key].http_method
  integration_http_method = contains(["AWS", "AWS_PROXY", "HTTP", "HTTP_PROXY"], each.value.config.type) ? aws_api_gateway_method.this[each.key].http_method : null
  request_parameters      = each.value.config.integration_request_parameters == {} ? null : each.value.config.integration_request_parameters
  request_templates       = each.value.config.request_templates
  rest_api_id             = aws_api_gateway_rest_api.this.id
  timeout_milliseconds    = each.value.config.timeout_milliseconds
  type                    = each.value.type
  uri                     = each.value.config.uri

  connection_id = try(coalesce(
    each.value.config.connection_id,
    each.value.connection_type == "VPC_LINK" ? var.vpc_link_id : null
  ), null)

  passthrough_behavior = try(coalesce(
    each.value.config.passthrough_behavior,
    each.value.connection_type == "VPC_LINK" ? "WHEN_NO_MATCH" : null
  ), null)

  resource_id = (each.value.root
    ? aws_api_gateway_rest_api.this.root_resource_id
    : element([
      aws_api_gateway_resource.depth_0,
      aws_api_gateway_resource.depth_1,
      aws_api_gateway_resource.depth_2,
      aws_api_gateway_resource.depth_3,
      aws_api_gateway_resource.depth_4,
    ], each.value.depth)[each.value.resource_key].id
  )

  dynamic "tls_config" {
    for_each = coalesce(each.value.config.skip_verification, false) ? [1] : []

    content {
      insecure_skip_verification = true
    }
  }
}

resource "aws_api_gateway_method_response" "this" {
  for_each = { for mr in flatten([
    for m in var.methods : [
      for r in m.config.responses : {
        method   = m
        response = r
      }
    ]
  ]) : "${mr.method.key}|${mr.response.status_code}" => mr }

  http_method         = aws_api_gateway_method.this[each.value.method.key].http_method
  rest_api_id         = aws_api_gateway_rest_api.this.id
  response_parameters = each.value.response.method_parameters
  status_code         = each.value.response.status_code

  resource_id = (each.value.method.root
    ? aws_api_gateway_rest_api.this.root_resource_id
    : element([
      aws_api_gateway_resource.depth_0,
      aws_api_gateway_resource.depth_1,
      aws_api_gateway_resource.depth_2,
      aws_api_gateway_resource.depth_3,
      aws_api_gateway_resource.depth_4,
    ], each.value.method.depth)[each.value.method.resource_key].id
  )
}

resource "aws_api_gateway_integration_response" "this" {
  for_each = { for mr in flatten([
    for m in var.methods : [
      for r in m.config.responses : {
        method   = m
        response = r
      }
    ]
  ]) : "${mr.method.key}|${mr.response.status_code}" => mr }

  rest_api_id         = aws_api_gateway_rest_api.this.id
  http_method         = aws_api_gateway_method.this[each.value.method.key].http_method
  response_parameters = each.value.response.integration_parameters == {} ? null : each.value.response.integration_parameters
  status_code         = aws_api_gateway_method_response.this[each.key].status_code

  resource_id = (each.value.method.root
    ? aws_api_gateway_rest_api.this.root_resource_id
    : element([
      aws_api_gateway_resource.depth_0,
      aws_api_gateway_resource.depth_1,
      aws_api_gateway_resource.depth_2,
      aws_api_gateway_resource.depth_3,
      aws_api_gateway_resource.depth_4,
    ], each.value.method.depth)[each.value.method.resource_key].id
  )

  depends_on = [aws_api_gateway_integration.this]
}
