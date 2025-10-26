# AWS Traffic Prediction System Deployment Script (PowerShell)
# This script deploys the entire infrastructure and application

param(
    [string]$AWSRegion = "us-east-1"
)

# Configuration
$ProjectName = "traffic-prediction-new"
$TerraformDir = "terraform"
$LambdaDir = "lambda_src"
$FrontendDir = "frontend"
$SageMakerDir = "sagemaker_src"

Write-Host "🚀 Starting AWS Traffic Prediction System Deployment" -ForegroundColor Blue
Write-Host "=================================================="

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow

# Check if AWS CLI is installed
try {
    aws --version | Out-Null
    Write-Host "✅ AWS CLI is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check if Terraform is installed
try {
    terraform version | Out-Null
    Write-Host "✅ Terraform is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check if Node.js is installed
try {
    node --version | Out-Null
    Write-Host "✅ Node.js is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check if Python is installed
try {
    python --version | Out-Null
    Write-Host "✅ Python is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Python is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check AWS credentials
Write-Host "🔐 Checking AWS credentials..." -ForegroundColor Yellow
try {
    aws sts get-caller-identity | Out-Null
    Write-Host "✅ AWS credentials are configured" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS credentials not configured. Please run 'aws configure' first." -ForegroundColor Red
    exit 1
}

# Create necessary directories
Write-Host "📁 Creating necessary directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "lambda_packages" | Out-Null
New-Item -ItemType Directory -Force -Path "sagemaker_packages" | Out-Null

# Build Lambda packages
Write-Host "📦 Building Lambda packages..." -ForegroundColor Yellow

# Traffic Analyzer Lambda
Write-Host "Building traffic analyzer Lambda..."
Set-Location "$LambdaDir/traffic_analyzer"
pip install -r requirements.txt -t .
Compress-Archive -Path * -DestinationPath "../../lambda_packages/traffic_analyzer.zip" -Force
Set-Location "../.."

# S3 Event Processor Lambda
Write-Host "Building S3 event processor Lambda..."
Set-Location "$LambdaDir/s3_event_processor"
pip install -r requirements.txt -t .
Compress-Archive -Path * -DestinationPath "../../lambda_packages/s3_event_processor.zip" -Force
Set-Location "../.."

Write-Host "✅ Lambda packages built successfully" -ForegroundColor Green

# Build SageMaker package
Write-Host "📦 Building SageMaker package..." -ForegroundColor Yellow
Set-Location $SageMakerDir
pip install -r requirements.txt -t .
Compress-Archive -Path * -DestinationPath "../sagemaker_packages/yolov8-model.tar.gz" -Force
Set-Location ".."

Write-Host "✅ SageMaker package built successfully" -ForegroundColor Green

# Deploy Terraform infrastructure
Write-Host "🏗️  Deploying Terraform infrastructure..." -ForegroundColor Yellow
Set-Location $TerraformDir

# Initialize Terraform
terraform init

# Plan deployment
Write-Host "Planning Terraform deployment..."
terraform plan -out=tfplan

# Apply deployment
Write-Host "Applying Terraform deployment..."
terraform apply tfplan

Write-Host "✅ Infrastructure deployed successfully" -ForegroundColor Green

# Get outputs
Write-Host "📊 Getting deployment outputs..." -ForegroundColor Yellow
$S3Bucket = terraform output -raw s3_bucket_name
$DynamoDBTable = terraform output -raw dynamodb_table_name
$SNSTrafficTopic = terraform output -raw sns_traffic_alerts_topic_arn
$SNSHighPriorityTopic = terraform output -raw sns_high_priority_topic_arn
$SageMakerEndpoint = terraform output -raw sagemaker_endpoint_name

Write-Host "S3 Bucket: $S3Bucket"
Write-Host "DynamoDB Table: $DynamoDBTable"
Write-Host "SNS Traffic Topic: $SNSTrafficTopic"
Write-Host "SNS High Priority Topic: $SNSHighPriorityTopic"
Write-Host "SageMaker Endpoint: $SageMakerEndpoint"

Set-Location ".."

# Upload SageMaker model to S3
Write-Host "📤 Uploading SageMaker model to S3..." -ForegroundColor Yellow
aws s3 cp sagemaker_packages/yolov8-model.tar.gz s3://$S3Bucket/models/

# Build and deploy React frontend
Write-Host "🌐 Building React frontend..." -ForegroundColor Yellow
Set-Location $FrontendDir

# Install dependencies
npm install

# Build the application
npm run build

Write-Host "✅ Frontend built successfully" -ForegroundColor Green

# Create deployment configuration
Write-Host "⚙️  Creating deployment configuration..." -ForegroundColor Yellow
$Config = @{
    aws_region = $AWSRegion
    s3_bucket = $S3Bucket
    dynamodb_table = $DynamoDBTable
    sns_traffic_topic = $SNSTrafficTopic
    sns_high_priority_topic = $SNSHighPriorityTopic
    sagemaker_endpoint = $SageMakerEndpoint
    deployment_timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json

$Config | Out-File -FilePath "../deployment-config.json" -Encoding UTF8

# Create environment file for frontend
Write-Host "📝 Creating environment configuration..." -ForegroundColor Yellow
$EnvContent = @"
REACT_APP_AWS_REGION=$AWSRegion
REACT_APP_S3_BUCKET=$S3Bucket
REACT_APP_DYNAMODB_TABLE=$DynamoDBTable
REACT_APP_SNS_TRAFFIC_TOPIC=$SNSTrafficTopic
REACT_APP_SNS_HIGH_PRIORITY_TOPIC=$SNSHighPriorityTopic
REACT_APP_SAGEMAKER_ENDPOINT=$SageMakerEndpoint
"@

$EnvContent | Out-File -FilePath ".env" -Encoding UTF8

Set-Location ".."

Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host "=================================================="
Write-Host "Next steps:" -ForegroundColor Blue
Write-Host "1. Deploy the React frontend to AWS Amplify or S3"
Write-Host "2. Configure SNS subscriptions for notifications"
Write-Host "3. Test the system by uploading traffic images"
Write-Host "4. Monitor logs in CloudWatch"
Write-Host ""
Write-Host "Configuration saved to: deployment-config.json" -ForegroundColor Blue
Write-Host "Frontend environment file: $FrontendDir/.env" -ForegroundColor Blue
