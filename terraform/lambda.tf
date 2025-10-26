# Lambda functions for traffic prediction system

# Lambda function for image processing and traffic analysis
resource "aws_lambda_function" "traffic_analyzer" {
  function_name = "${local.project_name}-traffic-analyzer"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  filename         = "lambda_packages/traffic_analyzer.zip"
  source_code_hash = data.archive_file.traffic_analyzer_zip.output_base64sha256

  environment {
    variables = {
      S3_BUCKET_NAME           = aws_s3_bucket.traffic_images.bucket
      DYNAMODB_TABLE_NAME      = aws_dynamodb_table.traffic_analysis.name
      DYNAMODB_HISTORY_TABLE   = aws_dynamodb_table.traffic_history.name
      SAGEMAKER_ENDPOINT_NAME  = aws_sagemaker_endpoint.yolov8_endpoint.name
      SNS_TRAFFIC_TOPIC_ARN    = aws_sns_topic.traffic_alerts.arn
      SNS_HIGH_PRIORITY_ARN    = aws_sns_topic.high_priority_alerts.arn
      CONGESTION_THRESHOLD     = var.congestion_threshold
    }
  }

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.traffic_analyzer_logs
  ]
}

# CloudWatch log group for traffic analyzer
resource "aws_cloudwatch_log_group" "traffic_analyzer_logs" {
  name              = "/aws/lambda/${local.project_name}-traffic-analyzer"
  retention_in_days = 14

  tags = local.common_tags
}

# Lambda function for S3 event processing
resource "aws_lambda_function" "s3_event_processor" {
  function_name = "${local.project_name}-s3-event-processor"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60
  memory_size   = 256

  filename         = "lambda_packages/s3_event_processor.zip"
  source_code_hash = data.archive_file.s3_event_processor_zip.output_base64sha256

  environment {
    variables = {
      TRAFFIC_ANALYZER_FUNCTION_NAME = aws_lambda_function.traffic_analyzer.function_name
    }
  }

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.s3_event_processor_logs
  ]
}

# CloudWatch log group for S3 event processor
resource "aws_cloudwatch_log_group" "s3_event_processor_logs" {
  name              = "/aws/lambda/${local.project_name}-s3-event-processor"
  retention_in_days = 14

  tags = local.common_tags
}

# S3 event trigger for Lambda
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = aws_s3_bucket.traffic_images.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_event_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "images/"
    filter_suffix       = ".jpg"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

# Permission for S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_event_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.traffic_images.arn
}

# Data sources for Lambda packages
data "archive_file" "traffic_analyzer_zip" {
  type        = "zip"
  source_dir  = "lambda_src/traffic_analyzer"
  output_path = "lambda_packages/traffic_analyzer.zip"
}

data "archive_file" "s3_event_processor_zip" {
  type        = "zip"
  source_dir  = "lambda_src/s3_event_processor"
  output_path = "lambda_packages/s3_event_processor.zip"
}
