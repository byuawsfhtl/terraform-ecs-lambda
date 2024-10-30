output "lambda_api_lambda_arns" {
    description = "The ARNs of the Lambda functions from all api_endpoint instances"
    value       = module.lambda_api.lambda_api_lambda_arns
}