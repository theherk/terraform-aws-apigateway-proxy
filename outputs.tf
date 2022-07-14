output "api" {
  value = aws_api_gateway_rest_api.this
}

output "stage" {
  value = aws_api_gateway_stage.this
}
