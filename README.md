# terraform aws apigateway proxy

Terraform module to create an api gateway that proxies requests. It also can create a domain name and supports an authorizer that can be provided by giving a lambda.

This module supports a very powerful route declaration. You can declare a full set of paths, each with different method configuration.

In addition, it has two more clever tricks up its sleeves. It will by default, for any routes given with path ending in `{proxy+}` and method config uri ending in `{proxy}`, generate another route for proxying the base route. For example, if a route given is:

``` hcl
{
  path    = "/v1/{proxy+}"
  methods = ["ANY"]
  config  = { uri = "example.com/v1/{proxy}" }
}
```

and no other routes are given with path "/v1" and url "example.com", then a default base proxy path should be created, such as:

``` hcl
{
  path    = "/v1"
  methods = ["ANY"]
  config  = { uri = "example.com/v1" }
}
```

If the preceding statement is not true, then this assumes your explicit configuration is correct. You can override this behavior by passing `generate_base_proxies = false`.

Additionally, it will automatically include any nested resources that aren't explicitly declared, but are nevertheless required for a given method's depth.

## Usage

This module is intended to be used in conjunction with [terraform-aws-apigateway-route-builder](https://github.com/theherk/terraform-aws-apigateway-route-builder/), but it is not a dependency. You can construct the `methods` and `resources` objects explicitly, but these are meant to be somewhat opinionated abstractions.

``` hcl
module "api" {
  source = "theherk/apigateway-proxy/aws"

  name        = "h4s-simple"
  stage_name  = "dev"
  vpc_link_id = "ab3ced"

  resources = module.builder.resources
  methods   = module.builder.methods
}
```

### Examples

- [Simple](examples/simple)
- [Complete](examples/complete)

### Private

Private rest api's can be created too, by passing `PRIVATE` as the `endpoint_type`. In this case the whitelist is used in conduction with given `source_vpce` to build the resource policy.

## Contributing

To work on this repository, you need to install the [pre-commit](https://github.com/pre-commit/pre-commit) hooks, and dependencies from [pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform).

    make pre-commit

That should be the easy way, but if you use another package manager than `apt`, `brew`, or `yum` or want to configure these differently on your system, you can do so by following the guidance [here](https://github.com/antonbabenko/pre-commit-terraform#1-install-dependencies). For instance, you can set this up to use docker for running checks rather than installing directly to your filesystem.

After doing this, several checks will be run when attempting commits.

---

_note_: The following is generated by `terraform docs`.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.64 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.22.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_authorizer.authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_authorizer) | resource |
| [aws_api_gateway_base_path_mapping.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_deployment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_domain_name.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_domain_name) | resource |
| [aws_api_gateway_integration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_method.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method_settings.s_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_resource.depth_0](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.depth_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.depth_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.depth_3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.depth_4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_rest_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_rest_api_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api_policy) | resource |
| [aws_api_gateway_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_iam_policy_document.authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.authorizer_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_log_format"></a> [access\_log\_format](#input\_access\_log\_format) | Format for access log entries. | `map(any)` | <pre>{<br>  "contextPath": "$context.path",<br>  "domainName": "$context.domainName",<br>  "error.message": "$context.error.message",<br>  "httpMethod": "$context.httpMethod",<br>  "ip": "$context.identity.sourceIp",<br>  "protocol": "$context.protocol",<br>  "requestId": "$context.requestId",<br>  "requestTime": "$context.requestTime",<br>  "responseLength": "$context.responseLength",<br>  "routeKey": "$context.routeKey",<br>  "status": "$context.status"<br>}</pre> | no |
| <a name="input_authorizer"></a> [authorizer](#input\_authorizer) | Lambda authorizer. | `any` | `null` | no |
| <a name="input_binary_media_types"></a> [binary\_media\_types](#input\_binary\_media\_types) | List of binary media types supported by the REST API. | `list(string)` | `[]` | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | Certificate arn for api domain. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | API description. | `string` | `"API Gateway for proxying requests."` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Primary domain name to access the api. | `string` | `null` | no |
| <a name="input_domain_names_alternate"></a> [domain\_names\_alternate](#input\_domain\_names\_alternate) | Alternate domain names to access the api. `domain_name` is the domain for which the Route53 record will be added; not these. These alternate names are for subject alternative names in the given certificate. | `list(string)` | `[]` | no |
| <a name="input_endpoint_type"></a> [endpoint\_type](#input\_endpoint\_type) | API endpoint type. | `string` | `"REGIONAL"` | no |
| <a name="input_ip_whitelist"></a> [ip\_whitelist](#input\_ip\_whitelist) | List of IP addresses that can reach the api. | `list(string)` | `[]` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days logs will be kept in CloudWatch. | `number` | `365` | no |
| <a name="input_methods"></a> [methods](#input\_methods) | Methods with resource associations and integration configuration.<br><br>This is a complex type manual configuration is not recommended. It is recommended to use [terraform-aws-apigateway-route-builder](https://github.com/theherk/terraform-aws-apigateway-route-builder/) to generate this data. Nevertheless, a description of the type's attributes are:<pre>methods = {<br>  "0|v1|POST" = {<br>    config = {<br>      "uri"    = "example.com/v1"<br>    }<br>    depth        = 0<br>    key          = "0|v1|POST"<br>    method       = "POST"<br>    resource_key = "0|v1"<br>    root         = false<br>  }<br>}</pre> | <pre>map(object({ # keyed by depth | path | verb<br>    config = object({ # method configuration<br>      cache_key_parameters           = list(string)<br>      cache_namespace                = string<br>      connection_id                  = string<br>      connection_type                = string<br>      content_handling               = string<br>      credentials                    = string<br>      integration_request_parameters = map(string)<br>      method_request_parameters      = map(string)<br>      passthrough_behavior           = string<br>      request_templates              = map(string)<br>      skip_verification              = bool<br>      timeout_milliseconds           = number<br>      type                           = string<br>      uri                            = string # uri to proxy when applicable<br>    })<br>    depth        = number # nested depth of containing resource<br>    key          = string # same as object key<br>    method       = string # HTTP verb for methd<br>    resource_key = string # key of containing resource<br>    root         = bool   # belongs in the root resource<br>  }))</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the api. | `string` | n/a | yes |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | ARN of the boundary policy to attach to roles. | `string` | `null` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Resources keyed by the route's depth and path, and containing: depth, parent\_key, path\_part.<br><br>This is a complex type manual configuration is not recommended. It is recommended to use [terraform-aws-apigateway-route-builder](https://github.com/theherk/terraform-aws-apigateway-route-builder/) to generate this data. Nevertheless, a description of the type's attributes are:<pre>resources = {<br>  "0|v1" = {<br>    depth      = 0<br>    parent_key = null<br>    path_part  = "v1"<br>  }<br>}</pre> | <pre>map(object({   # key by depth | path<br>    depth      = number # nested depth<br>    parent_key = string # key of containing resource<br>    path_part  = string # individual, last path component<br>  }))</pre> | n/a | yes |
| <a name="input_source_vpce"></a> [source\_vpce](#input\_source\_vpce) | Source VPC endpoint to whitelist. Required in addition to ip\_whitelist for private endpoint type. | `string` | `null` | no |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | Name of the api stage to deploy. | `string` | n/a | yes |
| <a name="input_throttling_burst_limit"></a> [throttling\_burst\_limit](#input\_throttling\_burst\_limit) | Specifies the throttling burst limit. Should be used in combination with throttling\_rate\_limit. | `number` | `null` | no |
| <a name="input_throttling_rate_limit"></a> [throttling\_rate\_limit](#input\_throttling\_rate\_limit) | Specifies the throttling rate limit. Should be used in combination with throttling\_burst\_limit. | `number` | `null` | no |
| <a name="input_vpc_link_id"></a> [vpc\_link\_id](#input\_vpc\_link\_id) | vpc link id for proxy integrations. Can be given per route, but will be default if given when not found in route. | `string` | `null` | no |
| <a name="input_xray_tracing_enabled"></a> [xray\_tracing\_enabled](#input\_xray\_tracing\_enabled) | Whether active tracing with X-ray is enabled. | `bool` | `null` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | DNS zone for api. Only applicable if `domain_name` given. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api"></a> [api](#output\_api) | n/a |
| <a name="output_stage"></a> [stage](#output\_stage) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
