#!/bin/bash

# AWS CLI Setup Script for Traffic Prediction System
# This script helps configure AWS CLI with the necessary permissions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 AWS CLI Setup for Traffic Prediction System${NC}"
echo "=================================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed.${NC}"
    echo "Please install AWS CLI first:"
    echo "  https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

echo -e "${GREEN}✅ AWS CLI is installed${NC}"

# Check current configuration
echo -e "${YELLOW}📋 Checking current AWS configuration...${NC}"
if aws sts get-caller-identity &> /dev/null; then
    echo -e "${GREEN}✅ AWS credentials are configured${NC}"
    aws sts get-caller-identity
else
    echo -e "${YELLOW}⚠️  AWS credentials not configured${NC}"
    echo "Please run 'aws configure' to set up your credentials"
    exit 1
fi

# Check required permissions
echo -e "${YELLOW}🔐 Checking required permissions...${NC}"

REQUIRED_SERVICES=(
    "s3"
    "lambda"
    "dynamodb"
    "sagemaker"
    "sns"
    "iam"
    "cloudwatch"
    "logs"
)

MISSING_PERMISSIONS=()

for service in "${REQUIRED_SERVICES[@]}"; do
    if aws $service help &> /dev/null; then
        echo -e "${GREEN}✅ $service access confirmed${NC}"
    else
        echo -e "${RED}❌ $service access denied${NC}"
        MISSING_PERMISSIONS+=("$service")
    fi
done

if [ ${#MISSING_PERMISSIONS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Missing permissions for: ${MISSING_PERMISSIONS[*]}${NC}"
    echo ""
    echo "Please ensure your AWS user/role has the following policies:"
    echo "- AmazonS3FullAccess"
    echo "- AWSLambdaFullAccess"
    echo "- AmazonDynamoDBFullAccess"
    echo "- AmazonSageMakerFullAccess"
    echo "- AmazonSNSFullAccess"
    echo "- IAMFullAccess"
    echo "- CloudWatchFullAccess"
    echo "- CloudWatchLogsFullAccess"
    echo ""
    echo "Or create a custom policy with the minimum required permissions."
    exit 1
fi

echo -e "${GREEN}✅ All required permissions are available${NC}"

# Check AWS region
echo -e "${YELLOW}🌍 Checking AWS region...${NC}"
CURRENT_REGION=$(aws configure get region)
if [ -z "$CURRENT_REGION" ]; then
    echo -e "${YELLOW}⚠️  No default region set${NC}"
    echo "Setting default region to us-east-1..."
    aws configure set region us-east-1
    CURRENT_REGION="us-east-1"
fi

echo -e "${GREEN}✅ AWS region: $CURRENT_REGION${NC}"

# Create IAM policy for the system
echo -e "${YELLOW}📝 Creating IAM policy for Traffic Prediction System...${NC}"

POLICY_DOCUMENT=$(cat << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:GetBucketLocation",
                "s3:GetBucketVersioning",
                "s3:ListBucket",
                "s3:PutBucketVersioning",
                "s3:PutBucketPublicAccessBlock",
                "s3:PutBucketLifecycleConfiguration",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:CreateFunction",
                "lambda:DeleteFunction",
                "lambda:GetFunction",
                "lambda:UpdateFunctionCode",
                "lambda:UpdateFunctionConfiguration",
                "lambda:InvokeFunction",
                "lambda:AddPermission",
                "lambda:RemovePermission",
                "lambda:CreateEventSourceMapping",
                "lambda:DeleteEventSourceMapping",
                "lambda:GetEventSourceMapping",
                "lambda:ListEventSourceMappings"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:CreateTable",
                "dynamodb:DeleteTable",
                "dynamodb:DescribeTable",
                "dynamodb:UpdateTable",
                "dynamodb:PutItem",
                "dynamodb:GetItem",
                "dynamodb:UpdateItem",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sagemaker:CreateModel",
                "sagemaker:DeleteModel",
                "sagemaker:DescribeModel",
                "sagemaker:CreateEndpoint",
                "sagemaker:DeleteEndpoint",
                "sagemaker:DescribeEndpoint",
                "sagemaker:CreateEndpointConfig",
                "sagemaker:DeleteEndpointConfig",
                "sagemaker:DescribeEndpointConfig",
                "sagemaker:InvokeEndpoint"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sns:CreateTopic",
                "sns:DeleteTopic",
                "sns:GetTopicAttributes",
                "sns:SetTopicAttributes",
                "sns:Publish",
                "sns:Subscribe",
                "sns:Unsubscribe"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:CreatePolicy",
                "iam:DeletePolicy",
                "iam:GetPolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:GetRolePolicy"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics",
                "cloudwatch:PutDashboard",
                "cloudwatch:DeleteDashboard",
                "cloudwatch:GetDashboard",
                "cloudwatch:PutMetricAlarm",
                "cloudwatch:DeleteAlarms",
                "cloudwatch:DescribeAlarms"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:DeleteLogGroup",
                "logs:DescribeLogGroups",
                "logs:PutLogEvents",
                "logs:CreateLogStream",
                "logs:DeleteLogStream",
                "logs:DescribeLogStreams"
            ],
            "Resource": "*"
        }
    ]
}
EOF
)

# Save policy to file
echo "$POLICY_DOCUMENT" > traffic-prediction-policy.json

echo -e "${GREEN}✅ IAM policy document created: traffic-prediction-policy.json${NC}"

# Test deployment permissions
echo -e "${YELLOW}🧪 Testing deployment permissions...${NC}"

# Test S3 access
if aws s3 ls &> /dev/null; then
    echo -e "${GREEN}✅ S3 access confirmed${NC}"
else
    echo -e "${RED}❌ S3 access failed${NC}"
fi

# Test Lambda access
if aws lambda list-functions &> /dev/null; then
    echo -e "${GREEN}✅ Lambda access confirmed${NC}"
else
    echo -e "${RED}❌ Lambda access failed${NC}"
fi

# Test DynamoDB access
if aws dynamodb list-tables &> /dev/null; then
    echo -e "${GREEN}✅ DynamoDB access confirmed${NC}"
else
    echo -e "${RED}❌ DynamoDB access failed${NC}"
fi

echo -e "${GREEN}🎉 AWS CLI setup completed successfully!${NC}"
echo "=================================================="
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review the IAM policy: traffic-prediction-policy.json"
echo "2. Attach the policy to your AWS user/role if needed"
echo "3. Run './scripts/deploy.sh' to deploy the system"
echo ""
echo -e "${BLUE}Current configuration:${NC}"
echo "Region: $CURRENT_REGION"
echo "Account: $(aws sts get-caller-identity --query Account --output text)"
echo "User/Role: $(aws sts get-caller-identity --query Arn --output text)"
