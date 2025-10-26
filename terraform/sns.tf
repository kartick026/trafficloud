# SNS topics for traffic alerts
resource "aws_sns_topic" "traffic_alerts" {
  name = var.sns_topic_traffic_alerts

  tags = local.common_tags
}

resource "aws_sns_topic" "high_priority_alerts" {
  name = var.sns_topic_high_priority

  tags = local.common_tags
}

# SNS topic policies
resource "aws_sns_topic_policy" "traffic_alerts" {
  arn = aws_sns_topic.traffic_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.traffic_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_policy" "high_priority_alerts" {
  arn = aws_sns_topic.high_priority_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.high_priority_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}