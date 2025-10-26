# Outputs for the traffic prediction system

output "s3_bucket_name" {
  description = "Name of the S3 bucket for traffic images"
  value       = aws_s3_bucket.traffic_images.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for traffic images"
  value       = aws_s3_bucket.traffic_images.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for traffic analysis results"
  value       = aws_dynamodb_table.traffic_analysis.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for traffic analysis results"
  value       = aws_dynamodb_table.traffic_analysis.arn
}

output "sns_traffic_alerts_topic_arn" {
  description = "ARN of the SNS topic for traffic alerts"
  value       = aws_sns_topic.traffic_alerts.arn
}

output "sns_high_priority_topic_arn" {
  description = "ARN of the SNS topic for high priority alerts"
  value       = aws_sns_topic.high_priority_alerts.arn
}

output "sagemaker_endpoint_name" {
  description = "Name of the SageMaker endpoint"
  value       = aws_sagemaker_endpoint.yolov8_endpoint.name
}

output "lambda_traffic_analyzer_function_name" {
  description = "Name of the traffic analyzer Lambda function"
  value       = aws_lambda_function.traffic_analyzer.function_name
}

output "lambda_s3_event_processor_function_name" {
  description = "Name of the S3 event processor Lambda function"
  value       = aws_lambda_function.s3_event_processor.function_name
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}
