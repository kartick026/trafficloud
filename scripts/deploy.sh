#!/bin/bash

# AWS Traffic Prediction System Deployment Script
# This script deploys the entire infrastructure and application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-"us-east-1"}
PROJECT_NAME="traffic-prediction-new"
TERRAFORM_DIR="terraform"
LAMBDA_DIR="lambda_src"
FRONTEND_DIR="frontend"
SAGEMAKER_DIR="sagemaker_src"

echo -e "${BLUE}🚀 Starting AWS Traffic Prediction System Deployment${NC}"
echo "=================================================="

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 is not installed. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites are installed${NC}"

# Check AWS credentials
echo -e "${YELLOW}🔐 Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials are configured${NC}"

# Create necessary directories
echo -e "${YELLOW}📁 Creating necessary directories...${NC}"
mkdir -p lambda_packages
mkdir -p sagemaker_packages

# Build Lambda packages
echo -e "${YELLOW}📦 Building Lambda packages...${NC}"

# Traffic Analyzer Lambda
echo "Building traffic analyzer Lambda..."
cd $LAMBDA_DIR/traffic_analyzer
pip3 install -r requirements.txt -t .
zip -r ../../lambda_packages/traffic_analyzer.zip .
cd ../..

# S3 Event Processor Lambda
echo "Building S3 event processor Lambda..."
cd $LAMBDA_DIR/s3_event_processor
pip3 install -r requirements.txt -t .
zip -r ../../lambda_packages/s3_event_processor.zip .
cd ../..

echo -e "${GREEN}✅ Lambda packages built successfully${NC}"

# Build SageMaker package
echo -e "${YELLOW}📦 Building SageMaker package...${NC}"
cd $SAGEMAKER_DIR
pip3 install -r requirements.txt -t .
zip -r ../sagemaker_packages/yolov8-model.tar.gz .
cd ..

echo -e "${GREEN}✅ SageMaker package built successfully${NC}"

# Deploy Terraform infrastructure
echo -e "${YELLOW}🏗️  Deploying Terraform infrastructure...${NC}"
cd $TERRAFORM_DIR

# Initialize Terraform
terraform init

# Plan deployment
echo "Planning Terraform deployment..."
terraform plan -out=tfplan

# Apply deployment
echo "Applying Terraform deployment..."
terraform apply tfplan

echo -e "${GREEN}✅ Infrastructure deployed successfully${NC}"

# Get outputs
echo -e "${YELLOW}📊 Getting deployment outputs...${NC}"
S3_BUCKET=$(terraform output -raw s3_bucket_name)
DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name)
SNS_TRAFFIC_TOPIC=$(terraform output -raw sns_traffic_alerts_topic_arn)
SNS_HIGH_PRIORITY_TOPIC=$(terraform output -raw sns_high_priority_topic_arn)
SAGEMAKER_ENDPOINT=$(terraform output -raw sagemaker_endpoint_name)

echo "S3 Bucket: $S3_BUCKET"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo "SNS Traffic Topic: $SNS_TRAFFIC_TOPIC"
echo "SNS High Priority Topic: $SNS_HIGH_PRIORITY_TOPIC"
echo "SageMaker Endpoint: $SAGEMAKER_ENDPOINT"

cd ..

# Upload SageMaker model to S3
echo -e "${YELLOW}📤 Uploading SageMaker model to S3...${NC}"
aws s3 cp sagemaker_packages/yolov8-model.tar.gz s3://$S3_BUCKET/models/

# Build and deploy React frontend
echo -e "${YELLOW}🌐 Building React frontend...${NC}"
cd $FRONTEND_DIR

# Install dependencies
npm install

# Build the application
npm run build

echo -e "${GREEN}✅ Frontend built successfully${NC}"

# Create deployment configuration
echo -e "${YELLOW}⚙️  Creating deployment configuration...${NC}"
cat > ../deployment-config.json << EOF
{
  "aws_region": "$AWS_REGION",
  "s3_bucket": "$S3_BUCKET",
  "dynamodb_table": "$DYNAMODB_TABLE",
  "sns_traffic_topic": "$SNS_TRAFFIC_TOPIC",
  "sns_high_priority_topic": "$SNS_HIGH_PRIORITY_TOPIC",
  "sagemaker_endpoint": "$SAGEMAKER_ENDPOINT",
  "deployment_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

cd ..

# Create environment file for frontend
echo -e "${YELLOW}📝 Creating environment configuration...${NC}"
cat > $FRONTEND_DIR/.env << EOF
REACT_APP_AWS_REGION=$AWS_REGION
REACT_APP_S3_BUCKET=$S3_BUCKET
REACT_APP_DYNAMODB_TABLE=$DYNAMODB_TABLE
REACT_APP_SNS_TRAFFIC_TOPIC=$SNS_TRAFFIC_TOPIC
REACT_APP_SNS_HIGH_PRIORITY_TOPIC=$SNS_HIGH_PRIORITY_TOPIC
REACT_APP_SAGEMAKER_ENDPOINT=$SAGEMAKER_ENDPOINT
EOF

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo "=================================================="
echo -e "${BLUE}Next steps:${NC}"
echo "1. Deploy the React frontend to AWS Amplify or S3"
echo "2. Configure SNS subscriptions for notifications"
echo "3. Test the system by uploading traffic images"
echo "4. Monitor logs in CloudWatch"
echo ""
echo -e "${BLUE}Configuration saved to: deployment-config.json${NC}"
echo -e "${BLUE}Frontend environment file: $FRONTEND_DIR/.env${NC}"
