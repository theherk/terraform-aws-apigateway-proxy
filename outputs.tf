output "api" {
  value = aws_api_gateway_rest_api.this
}

output "log_groups" {
  value = {
    access = aws_cloudwatch_log_group.access
    exec   = aws_cloudwatch_log_group.exec
  }
}

output "stage" {
  value = aws_api_gateway_stage.this
}
