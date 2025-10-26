# SageMaker configuration for YOLOv8 model

# SageMaker model
resource "aws_sagemaker_model" "yolov8_traffic_model" {
  name               = var.sagemaker_model_name
  execution_role_arn = aws_iam_role.sagemaker_execution_role.arn

  primary_container {
    image = "763104351884.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/pytorch-inference:2.0.0-cpu-py310-ubuntu20.04-sagemaker"
    
    model_data_url = "s3://${aws_s3_bucket.lambda_deployments.bucket}/models/yolov8-model.tar.gz"
    
    environment = {
      SAGEMAKER_PROGRAM = "inference.py"
      SAGEMAKER_SUBMIT_DIRECTORY = "/opt/ml/code"
      SAGEMAKER_CONTAINER_LOG_LEVEL = "20"
      SAGEMAKER_REGION = data.aws_region.current.name
    }
  }

  tags = local.common_tags
}

# SageMaker endpoint configuration
resource "aws_sagemaker_endpoint_configuration" "yolov8_endpoint_config" {
  name = "${var.sagemaker_model_name}-endpoint-config"

  production_variants {
    variant_name           = "primary"
    model_name            = aws_sagemaker_model.yolov8_traffic_model.name
    initial_instance_count = 1
    instance_type         = "ml.t2.medium"
    initial_variant_weight = 100
  }

  tags = local.common_tags
}

# SageMaker endpoint
resource "aws_sagemaker_endpoint" "yolov8_endpoint" {
  name                 = "${var.sagemaker_model_name}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.yolov8_endpoint_config.name

  tags = local.common_tags
}

# S3 bucket for SageMaker model artifacts
resource "aws_s3_bucket" "sagemaker_models" {
  bucket = "${local.project_name}-sagemaker-models-${random_string.bucket_suffix.result}"

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "sagemaker_models" {
  bucket = aws_s3_bucket.sagemaker_models.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "sagemaker_models" {
  bucket = aws_s3_bucket.sagemaker_models.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
