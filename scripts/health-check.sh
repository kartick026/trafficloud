#!/bin/bash

# Health Check Script for AWS Traffic Prediction System
# This script performs comprehensive health checks on all system components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo -e "${BLUE}🏥 AWS Traffic Prediction System Health Check${NC}"
echo "============================================="
echo "Region: $AWS_REGION"
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# Health check results
HEALTH_STATUS="HEALTHY"
ISSUES=()

# Function to check service health
check_service() {
    local service_name="$1"
    local check_command="$2"
    local expected_status="$3"
    
    echo -n "Checking $service_name... "
    
    if eval "$check_command" &> /dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        ISSUES+=("$service_name: $expected_status")
        HEALTH_STATUS="UNHEALTHY"
        return 1
    fi
}

# 1. S3 Bucket Health
echo -e "${YELLOW}📦 S3 Bucket Health${NC}"
check_service "S3 Bucket Access" "aws s3 ls s3://$S3_BUCKET/ --region $AWS_REGION" "Bucket should be accessible"

# Check bucket policy
echo -n "Checking S3 bucket policy... "
if aws s3api get-bucket-policy --bucket $S3_BUCKET --region $AWS_REGION &> /dev/null; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${YELLOW}⚠️  No bucket policy (this may be normal)${NC}"
fi

# 2. DynamoDB Health
echo -e "${YELLOW}🗄️  DynamoDB Health${NC}"
check_service "DynamoDB Table" "aws dynamodb describe-table --table-name $DYNAMODB_TABLE --region $AWS_REGION" "Table should exist and be accessible"

# Check table status
echo -n "Checking table status... "
TABLE_STATUS=$(aws dynamodb describe-table --table-name $DYNAMODB_TABLE --region $AWS_REGION --query 'Table.TableStatus' --output text 2>/dev/null || echo "UNKNOWN")
if [ "$TABLE_STATUS" = "ACTIVE" ]; then
    echo -e "${GREEN}✅ ACTIVE${NC}"
else
    echo -e "${YELLOW}⚠️  Status: $TABLE_STATUS${NC}"
fi

# 3. Lambda Functions Health
echo -e "${YELLOW}⚡ Lambda Functions Health${NC}"
TRAFFIC_ANALYZER_FUNCTION="traffic-prediction-new-traffic-analyzer"
S3_EVENT_PROCESSOR_FUNCTION="traffic-prediction-new-s3-event-processor"

check_service "Traffic Analyzer Lambda" "aws lambda get-function --function-name $TRAFFIC_ANALYZER_FUNCTION --region $AWS_REGION" "Function should exist"

check_service "S3 Event Processor Lambda" "aws lambda get-function --function-name $S3_EVENT_PROCESSOR_FUNCTION --region $AWS_REGION" "Function should exist"

# Check Lambda function states
echo -n "Checking Lambda function states... "
TRAFFIC_ANALYZER_STATE=$(aws lambda get-function --function-name $TRAFFIC_ANALYZER_FUNCTION --region $AWS_REGION --query 'Configuration.State' --output text 2>/dev/null || echo "UNKNOWN")
S3_EVENT_PROCESSOR_STATE=$(aws lambda get-function --function-name $S3_EVENT_PROCESSOR_FUNCTION --region $AWS_REGION --query 'Configuration.State' --output text 2>/dev/null || echo "UNKNOWN")

if [ "$TRAFFIC_ANALYZER_STATE" = "Active" ] && [ "$S3_EVENT_PROCESSOR_STATE" = "Active" ]; then
    echo -e "${GREEN}✅ Both functions active${NC}"
else
    echo -e "${YELLOW}⚠️  Traffic Analyzer: $TRAFFIC_ANALYZER_STATE, S3 Processor: $S3_EVENT_PROCESSOR_STATE${NC}"
fi

# 4. SageMaker Health
echo -e "${YELLOW}🤖 SageMaker Health${NC}"
check_service "SageMaker Endpoint" "aws sagemaker describe-endpoint --endpoint-name $SAGEMAKER_ENDPOINT --region $AWS_REGION" "Endpoint should exist"

# Check endpoint status
echo -n "Checking endpoint status... "
ENDPOINT_STATUS=$(aws sagemaker describe-endpoint --endpoint-name $SAGEMAKER_ENDPOINT --region $AWS_REGION --query 'EndpointStatus' --output text 2>/dev/null || echo "UNKNOWN")
if [ "$ENDPOINT_STATUS" = "InService" ]; then
    echo -e "${GREEN}✅ InService${NC}"
elif [ "$ENDPOINT_STATUS" = "UNKNOWN" ]; then
    echo -e "${YELLOW}⚠️  Endpoint not found (may be expected for mock deployment)${NC}"
else
    echo -e "${YELLOW}⚠️  Status: $ENDPOINT_STATUS${NC}"
fi

# 5. SNS Topics Health
echo -e "${YELLOW}📢 SNS Topics Health${NC}"
check_service "Traffic Alerts Topic" "aws sns get-topic-attributes --topic-arn $SNS_TRAFFIC_TOPIC --region $AWS_REGION" "Topic should exist"

check_service "High Priority Topic" "aws sns get-topic-attributes --topic-arn $SNS_HIGH_PRIORITY_TOPIC --region $AWS_REGION" "Topic should exist"

# 6. CloudWatch Logs Health
echo -e "${YELLOW}📊 CloudWatch Logs Health${NC}"
TRAFFIC_ANALYZER_LOG_GROUP="/aws/lambda/traffic-prediction-new-traffic-analyzer"
S3_EVENT_PROCESSOR_LOG_GROUP="/aws/lambda/traffic-prediction-new-s3-event-processor"

check_service "Traffic Analyzer Log Group" "aws logs describe-log-groups --log-group-name-prefix $TRAFFIC_ANALYZER_LOG_GROUP --region $AWS_REGION" "Log group should exist"

check_service "S3 Event Processor Log Group" "aws logs describe-log-groups --log-group-name-prefix $S3_EVENT_PROCESSOR_LOG_GROUP --region $AWS_REGION" "Log group should exist"

# 7. IAM Roles Health
echo -e "${YELLOW}🔐 IAM Roles Health${NC}"
LAMBDA_EXECUTION_ROLE="traffic-prediction-new-lambda-execution-role"
SAGEMAKER_EXECUTION_ROLE="traffic-prediction-new-sagemaker-execution-role"

check_service "Lambda Execution Role" "aws iam get-role --role-name $LAMBDA_EXECUTION_ROLE --region $AWS_REGION" "Role should exist"

check_service "SageMaker Execution Role" "aws iam get-role --role-name $SAGEMAKER_EXECUTION_ROLE --region $AWS_REGION" "Role should exist"

# 8. Recent Activity Check
echo -e "${YELLOW}📈 Recent Activity Check${NC}"

# Check recent DynamoDB activity
echo -n "Checking recent DynamoDB activity... "
RECENT_ITEMS=$(aws dynamodb scan --table-name $DYNAMODB_TABLE --region $AWS_REGION --select COUNT --query 'Count' --output text 2>/dev/null || echo "0")
if [ "$RECENT_ITEMS" -gt 0 ]; then
    echo -e "${GREEN}✅ $RECENT_ITEMS items found${NC}"
else
    echo -e "${YELLOW}⚠️  No items in table (may be normal if no images processed)${NC}"
fi

# Check recent Lambda invocations
echo -n "Checking recent Lambda invocations... "
TRAFFIC_ANALYZER_INVOCATIONS=$(aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Invocations --dimensions Name=FunctionName,Value=$TRAFFIC_ANALYZER_FUNCTION --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 3600 --statistics Sum --region $AWS_REGION --query 'Datapoints[0].Sum' --output text 2>/dev/null || echo "0")
if [ "$TRAFFIC_ANALYZER_INVOCATIONS" != "None" ] && [ "$TRAFFIC_ANALYZER_INVOCATIONS" -gt 0 ]; then
    echo -e "${GREEN}✅ $TRAFFIC_ANALYZER_INVOCATIONS invocations in last hour${NC}"
else
    echo -e "${YELLOW}⚠️  No recent invocations${NC}"
fi

# 9. Error Rate Check
echo -e "${YELLOW}🚨 Error Rate Check${NC}"

# Check Lambda error rate
echo -n "Checking Lambda error rate... "
ERRORS=$(aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Errors --dimensions Name=FunctionName,Value=$TRAFFIC_ANALYZER_FUNCTION --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 3600 --statistics Sum --region $AWS_REGION --query 'Datapoints[0].Sum' --output text 2>/dev/null || echo "0")
INVOCATIONS=$(aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Invocations --dimensions Name=FunctionName,Value=$TRAFFIC_ANALYZER_FUNCTION --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 3600 --statistics Sum --region $AWS_REGION --query 'Datapoints[0].Sum' --output text 2>/dev/null || echo "0")

if [ "$INVOCATIONS" != "None" ] && [ "$INVOCATIONS" -gt 0 ]; then
    ERROR_RATE=$(echo "scale=2; $ERRORS * 100 / $INVOCATIONS" | bc 2>/dev/null || echo "0")
    if (( $(echo "$ERROR_RATE < 5" | bc -l) )); then
        echo -e "${GREEN}✅ Error rate: ${ERROR_RATE}%${NC}"
    else
        echo -e "${RED}❌ High error rate: ${ERROR_RATE}%${NC}"
        ISSUES+=("High Lambda error rate: ${ERROR_RATE}%")
        HEALTH_STATUS="UNHEALTHY"
    fi
else
    echo -e "${YELLOW}⚠️  No recent invocations to calculate error rate${NC}"
fi

# 10. Performance Check
echo -e "${YELLOW}⚡ Performance Check${NC}"

# Check Lambda duration
echo -n "Checking Lambda duration... "
DURATION=$(aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Duration --dimensions Name=FunctionName,Value=$TRAFFIC_ANALYZER_FUNCTION --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 3600 --statistics Average --region $AWS_REGION --query 'Datapoints[0].Average' --output text 2>/dev/null || echo "0")
if [ "$DURATION" != "None" ] && [ "$DURATION" -gt 0 ]; then
    DURATION_MS=$(echo "scale=0; $DURATION" | bc 2>/dev/null || echo "0")
    if [ "$DURATION_MS" -lt 30000 ]; then
        echo -e "${GREEN}✅ Average duration: ${DURATION_MS}ms${NC}"
    else
        echo -e "${YELLOW}⚠️  High duration: ${DURATION_MS}ms${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No recent duration data${NC}"
fi

# Summary
echo ""
echo "============================================="
if [ "$HEALTH_STATUS" = "HEALTHY" ]; then
    echo -e "${GREEN}🎉 System Status: HEALTHY${NC}"
else
    echo -e "${RED}🚨 System Status: UNHEALTHY${NC}"
    echo ""
    echo -e "${RED}Issues found:${NC}"
    for issue in "${ISSUES[@]}"; do
        echo -e "${RED}  - $issue${NC}"
    done
fi

echo ""
echo -e "${BLUE}Health Check Summary:${NC}"
echo "  - S3 Bucket: $(aws s3 ls s3://$S3_BUCKET/ --region $AWS_REGION &> /dev/null && echo "✅ OK" || echo "❌ FAILED")"
echo "  - DynamoDB Table: $(aws dynamodb describe-table --table-name $DYNAMODB_TABLE --region $AWS_REGION &> /dev/null && echo "✅ OK" || echo "❌ FAILED")"
echo "  - Lambda Functions: $(aws lambda get-function --function-name $TRAFFIC_ANALYZER_FUNCTION --region $AWS_REGION &> /dev/null && echo "✅ OK" || echo "❌ FAILED")"
echo "  - SNS Topics: $(aws sns get-topic-attributes --topic-arn $SNS_TRAFFIC_TOPIC --region $AWS_REGION &> /dev/null && echo "✅ OK" || echo "❌ FAILED")"
echo "  - CloudWatch Logs: $(aws logs describe-log-groups --log-group-name-prefix $TRAFFIC_ANALYZER_LOG_GROUP --region $AWS_REGION &> /dev/null && echo "✅ OK" || echo "❌ FAILED")"

echo ""
echo -e "${BLUE}Next steps:${NC}"
if [ "$HEALTH_STATUS" = "UNHEALTHY" ]; then
    echo "1. Review the issues listed above"
    echo "2. Check CloudWatch logs for detailed error information"
    echo "3. Verify IAM permissions"
    echo "4. Re-run deploy.sh if necessary"
else
    echo "1. System is running normally"
    echo "2. Monitor CloudWatch dashboards for ongoing health"
    echo "3. Test with image uploads"
    echo "4. Set up SNS subscriptions for alerts"
fi
