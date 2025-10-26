import json
import boto3
import logging
import os

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
lambda_client = boto3.client('lambda')

# Environment variables
TRAFFIC_ANALYZER_FUNCTION_NAME = os.environ['TRAFFIC_ANALYZER_FUNCTION_NAME']

def lambda_handler(event, context):
    """
    S3 event processor that triggers traffic analysis
    """
    try:
        logger.info(f"Received S3 event: {json.dumps(event)}")
        
        # Process each S3 record
        for record in event['Records']:
            if record['eventSource'] == 'aws:s3':
                bucket_name = record['s3']['bucket']['name']
                object_key = record['s3']['object']['key']
                
                # Check if it's an image file
                if is_image_file(object_key):
                    logger.info(f"Processing image: {object_key}")
                    
                    # Invoke traffic analyzer Lambda function
                    invoke_traffic_analyzer(bucket_name, object_key)
                else:
                    logger.info(f"Skipping non-image file: {object_key}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'S3 event processed successfully',
                'processed_records': len(event['Records'])
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing S3 event: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': f'Error processing S3 event: {str(e)}'
            })
        }

def is_image_file(object_key: str) -> bool:
    """
    Check if the file is an image based on extension
    """
    image_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.gif', '.tiff']
    object_key_lower = object_key.lower()
    
    return any(object_key_lower.endswith(ext) for ext in image_extensions)

def invoke_traffic_analyzer(bucket_name: str, object_key: str):
    """
    Invoke the traffic analyzer Lambda function
    """
    try:
        # Prepare payload for traffic analyzer
        payload = {
            'Records': [
                {
                    'eventSource': 'aws:s3',
                    's3': {
                        'bucket': {
                            'name': bucket_name
                        },
                        'object': {
                            'key': object_key
                        }
                    }
                }
            ]
        }
        
        # Invoke Lambda function asynchronously
        response = lambda_client.invoke(
            FunctionName=TRAFFIC_ANALYZER_FUNCTION_NAME,
            InvocationType='Event',  # Asynchronous invocation
            Payload=json.dumps(payload)
        )
        
        logger.info(f"Invoked traffic analyzer for {object_key}, response: {response['StatusCode']}")
        
    except Exception as e:
        logger.error(f"Error invoking traffic analyzer: {str(e)}")
        raise
