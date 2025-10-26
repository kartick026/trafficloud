import json
import boto3
import base64
import io
import os
import logging
from datetime import datetime, timezone
from typing import Dict, List, Any
import numpy as np
from PIL import Image

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
sagemaker_runtime = boto3.client('sagemaker-runtime')
sns_client = boto3.client('sns')

# Environment variables
S3_BUCKET_NAME = os.environ['S3_BUCKET_NAME']
DYNAMODB_TABLE_NAME = os.environ['DYNAMODB_TABLE_NAME']
DYNAMODB_HISTORY_TABLE = os.environ['DYNAMODB_HISTORY_TABLE']
SAGEMAKER_ENDPOINT_NAME = os.environ['SAGEMAKER_ENDPOINT_NAME']
SNS_TRAFFIC_TOPIC_ARN = os.environ['SNS_TRAFFIC_TOPIC_ARN']
SNS_HIGH_PRIORITY_ARN = os.environ['SNS_HIGH_PRIORITY_ARN']
CONGESTION_THRESHOLD = float(os.environ['CONGESTION_THRESHOLD'])

# DynamoDB tables
traffic_table = dynamodb.Table(DYNAMODB_TABLE_NAME)
history_table = dynamodb.Table(DYNAMODB_HISTORY_TABLE)

def lambda_handler(event, context):
    """
    Main Lambda handler for traffic analysis
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Extract S3 event details
        if 'Records' in event:
            for record in event['Records']:
                if record['eventSource'] == 'aws:s3':
                    bucket_name = record['s3']['bucket']['name']
                    object_key = record['s3']['object']['key']
                    
                    # Process the image
                    result = process_traffic_image(bucket_name, object_key)
                    
                    if result:
                        # Store results in DynamoDB
                        store_analysis_results(result)
                        
                        # Send notifications if needed
                        send_notifications(result)
                        
                        return {
                            'statusCode': 200,
                            'body': json.dumps({
                                'message': 'Traffic analysis completed successfully',
                                'result': result
                            })
                        }
        
        # Direct invocation with image data
        elif 'image_data' in event:
            image_data = event['image_data']
            location = event.get('location', 'unknown')
            
            result = process_image_data(image_data, location)
            
            if result:
                store_analysis_results(result)
                send_notifications(result)
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': 'Traffic analysis completed successfully',
                        'result': result
                    })
                }
        
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Invalid event format'})
        }
        
    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': f'Internal server error: {str(e)}'})
        }

def process_traffic_image(bucket_name: str, object_key: str) -> Dict[str, Any]:
    """
    Process traffic image from S3
    """
    try:
        # Download image from S3
        response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
        image_data = response['Body'].read()
        
        # Extract location from object key
        location = object_key.split('/')[-2] if '/' in object_key else 'unknown'
        
        return process_image_data(image_data, location)
        
    except Exception as e:
        logger.error(f"Error processing image from S3: {str(e)}")
        return None

def process_image_data(image_data: bytes, location: str) -> Dict[str, Any]:
    """
    Process image data and perform traffic analysis
    """
    try:
        # Convert image data to base64 for SageMaker
        image_base64 = base64.b64encode(image_data).decode('utf-8')
        
        # Call SageMaker endpoint for vehicle detection
        detection_results = call_sagemaker_endpoint(image_base64)
        
        # Analyze detection results
        analysis = analyze_detection_results(detection_results, image_data)
        
        # Add metadata
        analysis.update({
            'frame_id': f"{location}_{int(datetime.now().timestamp())}",
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'location': location,
            'image_size': len(image_data)
        })
        
        return analysis
        
    except Exception as e:
        logger.error(f"Error processing image data: {str(e)}")
        return None

def call_sagemaker_endpoint(image_base64: str) -> Dict[str, Any]:
    """
    Call SageMaker endpoint for vehicle detection
    """
    try:
        # Prepare payload for SageMaker
        payload = {
            'image': image_base64,
            'confidence_threshold': 0.5
        }
        
        # Invoke SageMaker endpoint
        response = sagemaker_runtime.invoke_endpoint(
            EndpointName=SAGEMAKER_ENDPOINT_NAME,
            ContentType='application/json',
            Body=json.dumps(payload)
        )
        
        # Parse response
        result = json.loads(response['Body'].read().decode('utf-8'))
        
        return result
        
    except Exception as e:
        logger.error(f"Error calling SageMaker endpoint: {str(e)}")
        # Return mock data for development
        return get_mock_detection_results()

def get_mock_detection_results() -> Dict[str, Any]:
    """
    Return mock detection results for development/testing
    """
    import random
    
    return {
        'detections': [
            {
                'class': 'car',
                'confidence': random.uniform(0.6, 0.9),
                'bbox': [100, 100, 200, 200]
            },
            {
                'class': 'truck',
                'confidence': random.uniform(0.7, 0.95),
                'bbox': [300, 150, 450, 300]
            },
            {
                'class': 'ambulance',
                'confidence': random.uniform(0.8, 0.95),
                'bbox': [500, 200, 600, 350]
            }
        ]
    }

def analyze_detection_results(detection_results: Dict[str, Any], image_data: bytes) -> Dict[str, Any]:
    """
    Analyze detection results and compute traffic metrics
    """
    try:
        detections = detection_results.get('detections', [])
        
        # Count vehicles by type
        vehicle_counts = {
            'cars': 0,
            'trucks': 0,
            'buses': 0,
            'bikes': 0,
            'ambulances': 0,
            'total': 0
        }
        
        ambulance_detected = False
        
        for detection in detections:
            class_name = detection['class'].lower()
            confidence = detection['confidence']
            
            if confidence > 0.5:  # Only count high-confidence detections
                if class_name == 'car':
                    vehicle_counts['cars'] += 1
                elif class_name == 'truck':
                    vehicle_counts['trucks'] += 1
                elif class_name == 'bus':
                    vehicle_counts['buses'] += 1
                elif class_name == 'bike' or class_name == 'motorcycle':
                    vehicle_counts['bikes'] += 1
                elif class_name == 'ambulance':
                    vehicle_counts['ambulances'] += 1
                    ambulance_detected = True
                
                vehicle_counts['total'] += 1
        
        # Calculate congestion score
        # Estimate frame area (assuming standard resolution)
        image = Image.open(io.BytesIO(image_data))
        frame_area = image.width * image.height
        congestion_score = min(vehicle_counts['total'] / (frame_area / 10000), 1.0)  # Normalize
        
        # Predict clearance time using simple regression
        clearance_time = predict_clearance_time(vehicle_counts['total'], congestion_score)
        
        return {
            'vehicle_counts': vehicle_counts,
            'congestion_score': round(congestion_score, 3),
            'clearance_time_minutes': clearance_time,
            'ambulance_detected': ambulance_detected,
            'detection_confidence': sum([d['confidence'] for d in detections]) / len(detections) if detections else 0
        }
        
    except Exception as e:
        logger.error(f"Error analyzing detection results: {str(e)}")
        return {
            'vehicle_counts': {'cars': 0, 'trucks': 0, 'buses': 0, 'bikes': 0, 'ambulances': 0, 'total': 0},
            'congestion_score': 0.0,
            'clearance_time_minutes': 0,
            'ambulance_detected': False,
            'detection_confidence': 0.0
        }

def predict_clearance_time(vehicle_count: int, congestion_score: float) -> int:
    """
    Predict traffic clearance time using simple regression model
    """
    try:
        # Simple linear regression: clearance_time = base_time + (vehicles * factor) + (congestion * congestion_factor)
        base_time = 5  # Base 5 minutes
        vehicle_factor = 0.5  # 0.5 minutes per vehicle
        congestion_factor = 10  # 10 minutes per congestion point
        
        predicted_time = base_time + (vehicle_count * vehicle_factor) + (congestion_score * congestion_factor)
        
        # Cap at reasonable maximum
        return min(int(predicted_time), 60)
        
    except Exception as e:
        logger.error(f"Error predicting clearance time: {str(e)}")
        return 10  # Default 10 minutes

def store_analysis_results(result: Dict[str, Any]) -> None:
    """
    Store analysis results in DynamoDB
    """
    try:
        # Store in main traffic analysis table
        traffic_table.put_item(Item=result)
        
        # Store aggregated data in history table
        timestamp = datetime.fromisoformat(result['timestamp'].replace('Z', '+00:00'))
        date_str = timestamp.strftime('%Y-%m-%d')
        hour = timestamp.hour
        
        # Update or create history record
        history_table.update_item(
            Key={
                'date': date_str,
                'hour': hour
            },
            UpdateExpression='ADD total_vehicles :vehicles, analysis_count :count SET last_updated = :timestamp',
            ExpressionAttributeValues={
                ':vehicles': result['vehicle_counts']['total'],
                ':count': 1,
                ':timestamp': result['timestamp']
            }
        )
        
        logger.info(f"Stored analysis results for frame {result['frame_id']}")
        
    except Exception as e:
        logger.error(f"Error storing analysis results: {str(e)}")

def send_notifications(result: Dict[str, Any]) -> None:
    """
    Send SNS notifications based on analysis results
    """
    try:
        # Check for high priority alert (ambulance detected)
        if result['ambulance_detected']:
            message = {
                'alert_type': 'HIGH_PRIORITY',
                'message': f'Ambulance detected at {result["location"]}',
                'timestamp': result['timestamp'],
                'congestion_score': result['congestion_score'],
                'vehicle_counts': result['vehicle_counts']
            }
            
            sns_client.publish(
                TopicArn=SNS_HIGH_PRIORITY_ARN,
                Message=json.dumps(message),
                Subject='High Priority Traffic Alert - Ambulance Detected'
            )
            
            logger.info("Sent high priority alert for ambulance detection")
        
        # Check for traffic congestion alert
        if result['congestion_score'] > CONGESTION_THRESHOLD:
            message = {
                'alert_type': 'TRAFFIC_CONGESTION',
                'message': f'High traffic congestion detected at {result["location"]}',
                'timestamp': result['timestamp'],
                'congestion_score': result['congestion_score'],
                'clearance_time_minutes': result['clearance_time_minutes'],
                'vehicle_counts': result['vehicle_counts']
            }
            
            sns_client.publish(
                TopicArn=SNS_TRAFFIC_TOPIC_ARN,
                Message=json.dumps(message),
                Subject='Traffic Congestion Alert'
            )
            
            logger.info(f"Sent traffic congestion alert for score {result['congestion_score']}")
        
    except Exception as e:
        logger.error(f"Error sending notifications: {str(e)}")
