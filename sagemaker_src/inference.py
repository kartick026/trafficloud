import json
import base64
import io
import logging
import numpy as np
from PIL import Image
import torch
import torchvision.transforms as transforms

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Mock YOLOv8 model for demonstration
# In production, you would load a pre-trained YOLOv8 model here
class MockYOLOv8Model:
    def __init__(self):
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        logger.info(f"Model initialized on device: {self.device}")
    
    def predict(self, image):
        """
        Mock prediction function
        In production, this would run actual YOLOv8 inference
        """
        # Mock detection results
        detections = [
            {
                'class': 'car',
                'confidence': 0.85,
                'bbox': [100, 100, 200, 200]
            },
            {
                'class': 'truck',
                'confidence': 0.92,
                'bbox': [300, 150, 450, 300]
            },
            {
                'class': 'ambulance',
                'confidence': 0.88,
                'bbox': [500, 200, 600, 350]
            }
        ]
        
        return detections

# Initialize model
model = MockYOLOv8Model()

def input_fn(request_body, request_content_type):
    """
    Parse input data from the request
    """
    try:
        if request_content_type == 'application/json':
            data = json.loads(request_body)
            image_base64 = data['image']
            confidence_threshold = data.get('confidence_threshold', 0.5)
            
            # Decode base64 image
            image_data = base64.b64decode(image_base64)
            image = Image.open(io.BytesIO(image_data)).convert('RGB')
            
            return {
                'image': image,
                'confidence_threshold': confidence_threshold
            }
        else:
            raise ValueError(f"Unsupported content type: {request_content_type}")
    
    except Exception as e:
        logger.error(f"Error in input_fn: {str(e)}")
        raise

def predict_fn(input_data, model):
    """
    Run inference on the input data
    """
    try:
        image = input_data['image']
        confidence_threshold = input_data['confidence_threshold']
        
        # Run model prediction
        detections = model.predict(image)
        
        # Filter by confidence threshold
        filtered_detections = [
            det for det in detections 
            if det['confidence'] >= confidence_threshold
        ]
        
        return {
            'detections': filtered_detections,
            'image_shape': image.size,
            'total_detections': len(filtered_detections)
        }
    
    except Exception as e:
        logger.error(f"Error in predict_fn: {str(e)}")
        raise

def output_fn(prediction, content_type):
    """
    Format the prediction output
    """
    try:
        if content_type == 'application/json':
            return json.dumps(prediction)
        else:
            raise ValueError(f"Unsupported content type: {content_type}")
    
    except Exception as e:
        logger.error(f"Error in output_fn: {str(e)}")
        raise

# Handler for SageMaker endpoint
def handler(data, context):
    """
    Main handler function for SageMaker endpoint
    """
    try:
        # Parse input
        input_data = input_fn(data, context.content_type)
        
        # Run prediction
        prediction = predict_fn(input_data, model)
        
        # Format output
        output = output_fn(prediction, context.accept)
        
        return output
    
    except Exception as e:
        logger.error(f"Error in handler: {str(e)}")
        return json.dumps({'error': str(e)})
