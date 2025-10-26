# Variables for AWS Traffic Prediction System

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "s3_bucket_name" {
  description = "Name for the S3 bucket storing traffic images"
  type        = string
  default     = "traffic-prediction-new-images-bucket"
}

variable "dynamodb_table_name" {
  description = "Name for the DynamoDB table storing traffic data"
  type        = string
  default     = "traffic-prediction-new-analysis-results"
}

variable "sns_topic_traffic_alerts" {
  description = "Name for the traffic alerts SNS topic"
  type        = string
  default     = "TrafficAlerts"
}

variable "sns_topic_high_priority" {
  description = "Name for the high priority alerts SNS topic"
  type        = string
  default     = "HighPriorityAlerts"
}

variable "congestion_threshold" {
  description = "Congestion score threshold for alerts"
  type        = number
  default     = 0.7
}

variable "sagemaker_model_name" {
  description = "Name for the SageMaker model"
  type        = string
  default     = "yolov8-traffic-detection"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 1024
}
