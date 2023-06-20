data "aws_iam_policy_document" "authorizer_assume_role" {
  count = var.authorizer != null ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "authorizer" {
  count = var.authorizer != null ? 1 : 0

  statement {
    actions   = ["lambda:invokeFunction"]
    resources = [var.authorizer.arn]
  }
}

resource "aws_iam_role" "authorizer" {
  count = var.authorizer != null ? 1 : 0

  name_prefix          = var.authorizer.function_name
  assume_role_policy   = data.aws_iam_policy_document.authorizer_assume_role[0].json
  permissions_boundary = var.permissions_boundary
}

resource "aws_iam_policy" "authorizer" {
  count = var.authorizer != null ? 1 : 0

  name_prefix = var.authorizer.function_name
  policy      = data.aws_iam_policy_document.authorizer[0].json
}

resource "aws_iam_role_policy_attachment" "authorizer" {
  count = var.authorizer != null ? 1 : 0

  role       = aws_iam_role.authorizer[0].name
  policy_arn = aws_iam_policy.authorizer[0].arn
}

resource "aws_api_gateway_authorizer" "authorizer" {
  count = var.authorizer != null ? 1 : 0

  name                             = var.authorizer.function_name
  authorizer_credentials           = aws_iam_role.authorizer[0].arn
  identity_source                  = var.authorizer_identity_source
  authorizer_result_ttl_in_seconds = 0
  authorizer_uri                   = var.authorizer.invoke_arn
  rest_api_id                      = aws_api_gateway_rest_api.this.id
  type                             = "REQUEST"
}
