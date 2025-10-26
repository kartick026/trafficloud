# DynamoDB table for traffic analysis results
resource "aws_dynamodb_table" "traffic_analysis" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "frame_id"
  range_key      = "timestamp"

  attribute {
    name = "frame_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "location"
    type = "S"
  }

  global_secondary_index {
    name     = "location-timestamp-index"
    hash_key = "location"
    range_key = "timestamp"
  }

  global_secondary_index {
    name     = "congestion-score-index"
    hash_key = "congestion_score"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.common_tags
}

# DynamoDB table for historical data and model training
resource "aws_dynamodb_table" "traffic_history" {
  name           = "${var.dynamodb_table_name}-history"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "date"
  range_key      = "hour"

  attribute {
    name = "date"
    type = "S"
  }

  attribute {
    name = "hour"
    type = "N"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.common_tags
}
