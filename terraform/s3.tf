# S3 bucket for traffic images
resource "aws_s3_bucket" "traffic_images" {
  bucket = var.s3_bucket_name

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "traffic_images" {
  bucket = aws_s3_bucket.traffic_images.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "traffic_images" {
  bucket = aws_s3_bucket.traffic_images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "traffic_images" {
  bucket = aws_s3_bucket.traffic_images.id

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# S3 bucket for Lambda deployment packages
resource "aws_s3_bucket" "lambda_deployments" {
  bucket = "${local.project_name}-lambda-deployments-${random_string.bucket_suffix.result}"

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "lambda_deployments" {
  bucket = aws_s3_bucket.lambda_deployments.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "lambda_deployments" {
  bucket = aws_s3_bucket.lambda_deployments.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Random string for unique bucket naming
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}
