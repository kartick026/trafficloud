# CloudWatch monitoring and alerting configuration

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "traffic_dashboard" {
  dashboard_name = "${local.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.traffic_analyzer.function_name],
            [".", "Errors", ".", "."],
            [".", "Invocations", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Traffic Analyzer Lambda Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", aws_dynamodb_table.traffic_analysis.name],
            [".", "ConsumedWriteCapacityUnits", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "DynamoDB Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/S3", "NumberOfObjects", "BucketName", aws_s3_bucket.traffic_images.bucket, "StorageType", "AllStorageTypes"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "S3 Object Count"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/SNS", "NumberOfMessagesPublished", "TopicName", aws_sns_topic.traffic_alerts.name],
            [".", ".", ".", aws_sns_topic.high_priority_alerts.name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "SNS Messages Published"
          period  = 300
        }
      }
    ]
  })

  tags = local.common_tags
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.project_name}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors lambda errors"
  alarm_actions       = [aws_sns_topic.high_priority_alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.traffic_analyzer.function_name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${local.project_name}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "60000" # 1 minute
  alarm_description   = "This metric monitors lambda duration"
  alarm_actions       = [aws_sns_topic.traffic_alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.traffic_analyzer.function_name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttles" {
  alarm_name          = "${local.project_name}-dynamodb-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors DynamoDB throttles"
  alarm_actions       = [aws_sns_topic.traffic_alerts.arn]

  dimensions = {
    TableName = aws_dynamodb_table.traffic_analysis.name
  }

  tags = local.common_tags
}

# Custom metrics for traffic analysis
resource "aws_cloudwatch_log_metric_filter" "ambulance_detections" {
  name           = "${local.project_name}-ambulance-detections"
  log_group_name = aws_cloudwatch_log_group.traffic_analyzer_logs.name
  pattern        = "[timestamp, request_id, level, message=\"Ambulance detected\"]"

  metric_transformation {
    name      = "AmbulanceDetections"
    namespace = "TrafficPrediction"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "high_congestion" {
  name           = "${local.project_name}-high-congestion"
  log_group_name = aws_cloudwatch_log_group.traffic_analyzer_logs.name
  pattern        = "[timestamp, request_id, level, message=\"High traffic congestion detected\"]"

  metric_transformation {
    name      = "HighCongestionEvents"
    namespace = "TrafficPrediction"
    value     = "1"
  }
}

# CloudWatch Alarms for custom metrics
resource "aws_cloudwatch_metric_alarm" "ambulance_detection_rate" {
  alarm_name          = "${local.project_name}-ambulance-detection-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "AmbulanceDetections"
  namespace           = "TrafficPrediction"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "High rate of ambulance detections"
  alarm_actions       = [aws_sns_topic.high_priority_alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "congestion_events" {
  alarm_name          = "${local.project_name}-congestion-events"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HighCongestionEvents"
  namespace           = "TrafficPrediction"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "High number of congestion events"
  alarm_actions       = [aws_sns_topic.traffic_alerts.arn]

  tags = local.common_tags
}
