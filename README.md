# AWS Traffic Prediction and Management System

A fully autonomous AWS-based system for real-time traffic analysis, vehicle detection, and congestion prediction using computer vision and machine learning.

## 🚀 Features

- **Real-time Image Processing**: Upload traffic images for instant analysis
- **Vehicle Detection**: YOLOv8-based detection of cars, trucks, buses, bikes, and ambulances
- **Congestion Analysis**: Automatic congestion scoring and clearance time prediction
- **Smart Notifications**: SNS-based alerts for high congestion and emergency vehicles
- **Interactive Dashboard**: React-based web interface for monitoring and analytics
- **Scalable Architecture**: Built on AWS serverless services for automatic scaling
- **Historical Analytics**: Track traffic patterns and trends over time

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React App     │    │   S3 Bucket     │    │   Lambda        │
│   (Frontend)    │───▶│   (Images)      │───▶│   (Processor)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                       ┌─────────────────┐            ▼
                       │   DynamoDB      │    ┌─────────────────┐
                       │   (Results)     │◀───│   SageMaker     │
                       └─────────────────┘    │   (YOLOv8)      │
                              │               └─────────────────┘
                              ▼
                       ┌─────────────────┐
                       │   SNS Topics    │
                       │   (Alerts)      │
                       └─────────────────┘
```

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Node.js >= 16
- Python 3.9+
- Git

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd aws-traffic-prediction-system
```

### 2. Deploy Infrastructure

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Deploy everything
./scripts/deploy.sh
```

This script will:
- Build and package Lambda functions
- Deploy AWS infrastructure using Terraform
- Upload SageMaker model artifacts
- Build the React frontend
- Create deployment configuration

### 3. Test the System

```bash
# Run comprehensive tests
./scripts/test.sh
```

### 4. Deploy Frontend

The React frontend can be deployed to:
- **AWS Amplify** (recommended)
- **S3 + CloudFront**
- **Any static hosting service**

For AWS Amplify:
```bash
cd frontend
npm install
npm run build
# Upload build/ folder to Amplify
```

## 🔧 Configuration

### Environment Variables

The system uses the following configuration (automatically set by deploy.sh):

```bash
AWS_REGION=us-east-1
S3_BUCKET=traffic-prediction-new-images-bucket
DYNAMODB_TABLE=traffic-prediction-new-analysis-results
SNS_TRAFFIC_TOPIC=TrafficAlerts
SNS_HIGH_PRIORITY_TOPIC=HighPriorityAlerts
SAGEMAKER_ENDPOINT=yolov8-traffic-detection-endpoint
```

### Customization

Edit `terraform/variables.tf` to customize:
- AWS region
- Resource names
- Congestion thresholds
- Lambda memory/timeout settings

## 📊 Usage

### 1. Upload Traffic Images

1. Navigate to the Upload page in the dashboard
2. Select a location (e.g., "Main Street Junction")
3. Upload a traffic image (JPG, PNG, etc.)
4. Wait for analysis (10-30 seconds)

### 2. Monitor Results

- **Dashboard**: Overview of current traffic metrics
- **Analytics**: Historical trends and patterns
- **Alerts**: Real-time notifications for congestion and emergencies

### 3. API Integration

The system exposes Lambda functions that can be called directly:

```python
import boto3
import json

lambda_client = boto3.client('lambda')

# Analyze image directly
response = lambda_client.invoke(
    FunctionName='traffic-prediction-new-traffic-analyzer',
    Payload=json.dumps({
        'image_data': base64_encoded_image,
        'location': 'Main Street Junction'
    })
)
```

## 🏗️ Infrastructure Components

### AWS Services Used

- **S3**: Image storage and Lambda deployment packages
- **Lambda**: Image processing and traffic analysis
- **SageMaker**: YOLOv8 model hosting for vehicle detection
- **DynamoDB**: Traffic analysis results and historical data
- **SNS**: Alert notifications
- **CloudWatch**: Logging and monitoring
- **IAM**: Security and permissions

### Terraform Modules

- `main.tf`: Core configuration and providers
- `s3.tf`: S3 buckets and policies
- `dynamodb.tf`: Database tables and indexes
- `lambda.tf`: Lambda functions and triggers
- `sagemaker.tf`: ML model and endpoint
- `sns.tf`: Notification topics
- `iam.tf`: Roles and policies

## 🔍 Monitoring and Logs

### CloudWatch Logs

- **Traffic Analyzer**: `/aws/lambda/traffic-prediction-new-traffic-analyzer`
- **S3 Event Processor**: `/aws/lambda/traffic-prediction-new-s3-event-processor`

### Key Metrics

- Image processing latency
- Vehicle detection accuracy
- Congestion prediction accuracy
- System error rates

## 🚨 Alerts and Notifications

### Alert Types

1. **High Priority**: Ambulance detected
2. **Traffic Congestion**: Congestion score > threshold (default: 0.7)

### SNS Topics

- `TrafficAlerts`: General traffic congestion alerts
- `HighPriorityAlerts`: Emergency vehicle alerts

### Setting Up Notifications

```bash
# Subscribe to email notifications
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789012:TrafficAlerts \
  --protocol email \
  --notification-endpoint your-email@example.com
```

## 🔧 Development

### Local Development

1. **Frontend**:
   ```bash
   cd frontend
   npm install
   npm start
   ```

2. **Lambda Functions**:
   ```bash
   # Test locally with SAM or serverless framework
   cd lambda_src/traffic_analyzer
   python3 lambda_function.py
   ```

### Adding New Features

1. **New Vehicle Types**: Update detection logic in `lambda_src/traffic_analyzer/lambda_function.py`
2. **Additional Metrics**: Modify analysis functions and DynamoDB schema
3. **UI Components**: Add new React components in `frontend/src/components/`

## 🧪 Testing

### Unit Tests

```bash
# Test Lambda functions
cd lambda_src/traffic_analyzer
python3 -m pytest tests/

# Test frontend
cd frontend
npm test
```

### Integration Tests

```bash
# Run full system test
./scripts/test.sh
```

### Load Testing

Use tools like Artillery or JMeter to test:
- Image upload throughput
- Lambda concurrency limits
- DynamoDB write capacity

## 🔒 Security

### IAM Permissions

The system uses least-privilege IAM roles:
- Lambda execution role with minimal required permissions
- SageMaker execution role for model access
- S3 bucket policies for secure access

### Data Protection

- Images are stored in private S3 buckets
- DynamoDB data is encrypted at rest
- All API calls use HTTPS
- No sensitive data in logs

## 📈 Scaling

### Automatic Scaling

- **Lambda**: Scales automatically based on S3 events
- **DynamoDB**: On-demand billing with auto-scaling
- **SageMaker**: Can be configured for auto-scaling

### Multi-Region Deployment

To deploy across multiple regions:
1. Update `terraform/variables.tf` with region list
2. Use Terraform workspaces or modules
3. Configure cross-region replication for S3

## 🗑️ Cleanup

To destroy all resources:

```bash
./scripts/destroy.sh
```

**Warning**: This will permanently delete all data and resources.

## 📚 API Reference

### Lambda Functions

#### Traffic Analyzer
- **Function**: `traffic-prediction-new-traffic-analyzer`
- **Input**: S3 event or direct image data
- **Output**: Traffic analysis results

#### S3 Event Processor
- **Function**: `traffic-prediction-new-s3-event-processor`
- **Input**: S3 object created event
- **Output**: Triggers traffic analyzer

### DynamoDB Schema

#### Traffic Analysis Table
```json
{
  "frame_id": "string (partition key)",
  "timestamp": "string (sort key)",
  "location": "string",
  "vehicle_counts": {
    "cars": "number",
    "trucks": "number",
    "buses": "number",
    "bikes": "number",
    "ambulances": "number",
    "total": "number"
  },
  "congestion_score": "number",
  "clearance_time_minutes": "number",
  "ambulance_detected": "boolean"
}
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the CloudWatch logs
2. Review the test script output
3. Check AWS service status
4. Open an issue in the repository

## 🔄 Updates and Maintenance

### Regular Maintenance

1. **Model Updates**: Retrain YOLOv8 model with new data
2. **Security Updates**: Keep dependencies updated
3. **Monitoring**: Review CloudWatch metrics and logs
4. **Cost Optimization**: Monitor AWS costs and optimize resources

### Version Updates

To update the system:
1. Update code in respective directories
2. Run `./scripts/deploy.sh` to update infrastructure
3. Test with `./scripts/test.sh`
4. Deploy frontend updates

---

**Built with ❤️ using AWS, React, and Terraform**
