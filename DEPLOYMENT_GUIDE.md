# AWS Traffic Prediction System - Deployment Guide

This guide provides step-by-step instructions for deploying the AWS Traffic Prediction and Management System.

## 🚀 Quick Start (Windows)

### Prerequisites

1. **AWS CLI**: Install and configure with appropriate permissions
2. **Terraform**: Install Terraform >= 1.0
3. **Node.js**: Install Node.js >= 16
4. **Python**: Install Python 3.9+
5. **PowerShell**: Windows PowerShell 5.1 or PowerShell Core

### Step 1: Setup AWS CLI

```powershell
# Run the AWS CLI setup script
.\scripts\setup-aws-cli.ps1

# Or manually configure AWS CLI
aws configure
```

### Step 2: Deploy Infrastructure

```powershell
# Deploy everything with default settings
.\scripts\deploy.ps1

# Or deploy with custom region
.\scripts\deploy.ps1 -AWSRegion "us-west-2"
```

### Step 3: Test the System

```powershell
# Run comprehensive tests
.\scripts\test.ps1

# Or test with custom region
.\scripts\test.ps1 -AWSRegion "us-west-2"
```

### Step 4: Deploy Frontend

The React frontend can be deployed to:

#### Option A: AWS Amplify (Recommended)
1. Go to AWS Amplify Console
2. Create new app from GitHub
3. Connect your repository
4. Build settings: `npm run build`
5. Deploy

#### Option B: S3 + CloudFront
1. Upload `frontend/build/` contents to S3 bucket
2. Enable static website hosting
3. Create CloudFront distribution
4. Configure custom domain (optional)

#### Option C: Local Development
```powershell
cd frontend
npm install
npm start
```

## 🐧 Linux/macOS Quick Start

### Prerequisites

Same as Windows, but use bash scripts instead of PowerShell.

### Step 1: Setup AWS CLI

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run the AWS CLI setup script
./scripts/setup-aws-cli.sh

# Or manually configure AWS CLI
aws configure
```

### Step 2: Deploy Infrastructure

```bash
# Deploy everything
./scripts/deploy.sh
```

### Step 3: Test the System

```bash
# Run comprehensive tests
./scripts/test.sh
```

### Step 4: Deploy Frontend

Same options as Windows, but use standard deployment methods.

## 🔧 Configuration

### Environment Variables

The system automatically configures these environment variables:

```bash
AWS_REGION=us-east-1
S3_BUCKET=traffic-prediction-new-images-bucket
DYNAMODB_TABLE=traffic-prediction-new-analysis-results
SNS_TRAFFIC_TOPIC=TrafficAlerts
SNS_HIGH_PRIORITY_TOPIC=HighPriorityAlerts
SAGEMAKER_ENDPOINT=yolov8-traffic-detection-endpoint
```

### Custom Configuration

Edit `terraform/terraform.tfvars` to customize:

```hcl
aws_region = "us-west-2"
environment = "prod"
s3_bucket_name = "my-traffic-images-bucket"
congestion_threshold = 0.8
lambda_memory_size = 2048
```

## 📊 Monitoring

### CloudWatch Dashboard

Access the CloudWatch dashboard:
1. Go to AWS CloudWatch Console
2. Navigate to Dashboards
3. Find "traffic-prediction-new-dashboard"

### Key Metrics

- **Lambda Duration**: Function execution time
- **Lambda Errors**: Error rate and count
- **DynamoDB Throttles**: Database performance
- **S3 Object Count**: Storage usage
- **SNS Messages**: Notification volume

### Alerts

The system automatically creates CloudWatch alarms for:
- High Lambda error rates
- Long Lambda execution times
- DynamoDB throttling
- High congestion events
- Ambulance detections

## 🧪 Testing

### Manual Testing

1. **Upload Test Image**:
   - Go to the Upload page
   - Select a location
   - Upload a traffic image
   - Wait for analysis results

2. **Check Results**:
   - View dashboard for metrics
   - Check analytics for trends
   - Monitor alerts for notifications

### Automated Testing

```powershell
# Run health check
.\scripts\health-check.ps1

# Run full test suite
.\scripts\test.ps1
```

## 🔍 Troubleshooting

### Common Issues

1. **AWS Credentials Not Configured**
   ```powershell
   aws configure
   ```

2. **Terraform State Locked**
   ```powershell
   cd terraform
   terraform force-unlock <lock-id>
   ```

3. **Lambda Function Not Found**
   - Check if deployment completed successfully
   - Verify IAM permissions
   - Check CloudWatch logs

4. **S3 Bucket Access Denied**
   - Verify bucket policy
   - Check IAM permissions
   - Ensure bucket exists

### Debugging Steps

1. **Check CloudWatch Logs**:
   - `/aws/lambda/traffic-prediction-new-traffic-analyzer`
   - `/aws/lambda/traffic-prediction-new-s3-event-processor`

2. **Verify IAM Permissions**:
   ```powershell
   aws iam get-user
   aws iam list-attached-user-policies --user-name <username>
   ```

3. **Test Individual Components**:
   ```powershell
   # Test S3 access
   aws s3 ls s3://<bucket-name>/
   
   # Test DynamoDB access
   aws dynamodb describe-table --table-name <table-name>
   
   # Test Lambda function
   aws lambda invoke --function-name <function-name> response.json
   ```

## 🗑️ Cleanup

To destroy all resources:

```powershell
# Windows
.\scripts\destroy.ps1

# Linux/macOS
./scripts/destroy.sh
```

**Warning**: This will permanently delete all data and resources.

## 📈 Scaling

### Horizontal Scaling

- **Lambda**: Automatically scales based on S3 events
- **DynamoDB**: On-demand billing with auto-scaling
- **SageMaker**: Configure auto-scaling for endpoints

### Vertical Scaling

- **Lambda Memory**: Increase in `terraform/variables.tf`
- **DynamoDB Capacity**: Adjust in Terraform configuration
- **SageMaker Instance**: Change instance type in configuration

## 🔒 Security

### IAM Permissions

The system uses least-privilege IAM roles:
- Lambda execution role with minimal required permissions
- SageMaker execution role for model access
- S3 bucket policies for secure access

### Data Protection

- Images stored in private S3 buckets
- DynamoDB data encrypted at rest
- All API calls use HTTPS
- No sensitive data in logs

## 📚 API Usage

### Direct Lambda Invocation

```python
import boto3
import json
import base64

lambda_client = boto3.client('lambda')

# Analyze image directly
response = lambda_client.invoke(
    FunctionName='traffic-prediction-new-traffic-analyzer',
    Payload=json.dumps({
        'image_data': base64_encoded_image,
        'location': 'Main Street Junction'
    })
)

result = json.loads(response['Payload'].read())
```

### S3 Event Processing

Images uploaded to `s3://<bucket>/images/` automatically trigger analysis.

### DynamoDB Queries

```python
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('traffic-prediction-new-analysis-results')

# Query recent analyses
response = table.query(
    KeyConditionExpression='frame_id = :frame_id',
    ExpressionAttributeValues={':frame_id': 'junction_1_1703123456'}
)
```

## 🆘 Support

### Getting Help

1. **Check Logs**: CloudWatch logs for detailed error information
2. **Run Health Check**: Use the health check script
3. **Review Documentation**: Check README.md for detailed information
4. **AWS Support**: Use AWS Support for infrastructure issues

### Common Commands

```powershell
# Check system health
.\scripts\health-check.ps1

# View recent logs
aws logs tail /aws/lambda/traffic-prediction-new-traffic-analyzer --follow

# Get deployment status
terraform show

# List all resources
aws resourcegroupstaggingapi get-resources --resource-type-filters "AWS::S3::Bucket"
```

---

**For more detailed information, see the main README.md file.**
