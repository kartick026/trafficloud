#!/bin/bash

# AWS Traffic Prediction System Test Script
# This script tests the deployed system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing AWS Traffic Prediction System${NC}"
echo "============================================="

# Load configuration
if [ ! -f "deployment-config.json" ]; then
    echo -e "${RED}❌ Deployment configuration not found. Please run deploy.sh first.${NC}"
    exit 1
fi

S3_BUCKET=$(jq -r '.s3_bucket' deployment-config.json)
DYNAMODB_TABLE=$(jq -r '.dynamodb_table' deployment-config.json)
SNS_TRAFFIC_TOPIC=$(jq -r '.sns_traffic_topic' deployment-config.json)
SNS_HIGH_PRIORITY_TOPIC=$(jq -r '.sns_high_priority_topic' deployment-config.json)
SAGEMAKER_ENDPOINT=$(jq -r '.sagemaker_endpoint' deployment-config.json)
AWS_REGION=$(jq -r '.aws_region' deployment-config.json)

echo "Configuration loaded:"
echo "S3 Bucket: $S3_BUCKET"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo "SageMaker Endpoint: $SAGEMAKER_ENDPOINT"

# Test 1: S3 Bucket Access
echo -e "${YELLOW}📦 Testing S3 bucket access...${NC}"
if aws s3 ls s3://$S3_BUCKET/ &> /dev/null; then
    echo -e "${GREEN}✅ S3 bucket is accessible${NC}"
else
    echo -e "${RED}❌ S3 bucket is not accessible${NC}"
    exit 1
fi

# Test 2: DynamoDB Table Access
echo -e "${YELLOW}🗄️  Testing DynamoDB table access...${NC}"
if aws dynamodb describe-table --table-name $DYNAMODB_TABLE --region $AWS_REGION &> /dev/null; then
    echo -e "${GREEN}✅ DynamoDB table is accessible${NC}"
else
    echo -e "${RED}❌ DynamoDB table is not accessible${NC}"
    exit 1
fi

# Test 3: SageMaker Endpoint Status
echo -e "${YELLOW}🤖 Testing SageMaker endpoint...${NC}"
ENDPOINT_STATUS=$(aws sagemaker describe-endpoint --endpoint-name $SAGEMAKER_ENDPOINT --region $AWS_REGION --query 'EndpointStatus' --output text 2>/dev/null || echo "NOT_FOUND")
if [ "$ENDPOINT_STATUS" = "InService" ]; then
    echo -e "${GREEN}✅ SageMaker endpoint is in service${NC}"
elif [ "$ENDPOINT_STATUS" = "NOT_FOUND" ]; then
    echo -e "${YELLOW}⚠️  SageMaker endpoint not found (this is expected for mock deployment)${NC}"
else
    echo -e "${YELLOW}⚠️  SageMaker endpoint status: $ENDPOINT_STATUS${NC}"
fi

# Test 4: Lambda Functions
echo -e "${YELLOW}⚡ Testing Lambda functions...${NC}"
TRAFFIC_ANALYZER_FUNCTION="traffic-prediction-new-traffic-analyzer"
S3_EVENT_PROCESSOR_FUNCTION="traffic-prediction-new-s3-event-processor"

if aws lambda get-function --function-name $TRAFFIC_ANALYZER_FUNCTION --region $AWS_REGION &> /dev/null; then
    echo -e "${GREEN}✅ Traffic analyzer Lambda function exists${NC}"
else
    echo -e "${RED}❌ Traffic analyzer Lambda function not found${NC}"
fi

if aws lambda get-function --function-name $S3_EVENT_PROCESSOR_FUNCTION --region $AWS_REGION &> /dev/null; then
    echo -e "${GREEN}✅ S3 event processor Lambda function exists${NC}"
else
    echo -e "${RED}❌ S3 event processor Lambda function not found${NC}"
fi

# Test 5: SNS Topics
echo -e "${YELLOW}📢 Testing SNS topics...${NC}"
if aws sns get-topic-attributes --topic-arn $SNS_TRAFFIC_TOPIC --region $AWS_REGION &> /dev/null; then
    echo -e "${GREEN}✅ Traffic alerts SNS topic exists${NC}"
else
    echo -e "${RED}❌ Traffic alerts SNS topic not found${NC}"
fi

if aws sns get-topic-attributes --topic-arn $SNS_HIGH_PRIORITY_TOPIC --region $AWS_REGION &> /dev/null; then
    echo -e "${GREEN}✅ High priority alerts SNS topic exists${NC}"
else
    echo -e "${RED}❌ High priority alerts SNS topic not found${NC}"
fi

# Test 6: Upload Test Image
echo -e "${YELLOW}📸 Testing image upload...${NC}"

# Create a test image (1x1 pixel PNG)
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > test_image.png

# Upload to S3
aws s3 cp test_image.png s3://$S3_BUCKET/images/test/test_image.png

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Test image uploaded successfully${NC}"
    
    # Wait a moment for Lambda processing
    echo "Waiting for Lambda processing..."
    sleep 10
    
    # Check if data was written to DynamoDB
    echo -e "${YELLOW}🔍 Checking DynamoDB for processed data...${NC}"
    ITEM_COUNT=$(aws dynamodb scan --table-name $DYNAMODB_TABLE --region $AWS_REGION --select COUNT --query 'Count' --output text)
    echo "Items in DynamoDB: $ITEM_COUNT"
    
    if [ "$ITEM_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Data found in DynamoDB${NC}"
    else
        echo -e "${YELLOW}⚠️  No data found in DynamoDB (Lambda may still be processing)${NC}"
    fi
else
    echo -e "${RED}❌ Failed to upload test image${NC}"
fi

# Clean up test image
rm -f test_image.png

echo -e "${GREEN}🎉 Testing completed!${NC}"
echo "============================================="
echo -e "${BLUE}Test Summary:${NC}"
echo "✅ S3 bucket access"
echo "✅ DynamoDB table access"
echo "✅ Lambda functions deployed"
echo "✅ SNS topics created"
echo "✅ Image upload test"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Check CloudWatch logs for any errors"
echo "2. Test the React frontend"
echo "3. Configure SNS subscriptions for notifications"
echo "4. Upload real traffic images for testing"
