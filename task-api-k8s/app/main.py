from flask import Flask, jsonify, request
from prometheus_flask_exporter import PrometheusMetrics
from botocore import UNSIGNED
from botocore.client import Config
import boto3
from botocore.exceptions import ClientError
from datetime import datetime
import uuid
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Add Prometheus metrics
metrics = PrometheusMetrics(app, path='/metrics')
metrics.info('task_api_info', 'Task API Information', version='1.0.0')

# DynamoDB setup
DYNAMODB_ENDPOINT = os.getenv('DYNAMODB_ENDPOINT', 'http://localhost:8000')
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')

logger.info(f"Connecting to DynamoDB at: {DYNAMODB_ENDPOINT}")

dynamodb = boto3.resource(
    'dynamodb',
    endpoint_url=DYNAMODB_ENDPOINT,
    region_name=AWS_REGION,
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID', 'fakeAccessKey'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY', 'fakeSecretKey')
)

logger.info(f"AWS_ACCESS_KEY_ID from env: {os.getenv('AWS_ACCESS_KEY_ID', 'NOT SET')}")
logger.info(f"DYNAMODB_ENDPOINT: {DYNAMODB_ENDPOINT}")

TABLE_NAME = 'tasks'

def get_table():
    """Get or create DynamoDB table"""
    try:
        # Try to create the table (will fail if exists, which is fine)
        table = dynamodb.create_table(
            TableName=TABLE_NAME,
            KeySchema=[
                {'AttributeName': 'id', 'KeyType': 'HASH'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'id', 'AttributeType': 'S'}
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        table.wait_until_exists()
        logger.info(f"Table '{TABLE_NAME}' created successfully")
        return table
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceInUseException':
            # Table already exists, just return it
            logger.info(f"Table '{TABLE_NAME}' already exists")
            table = dynamodb.Table(TABLE_NAME)
            return table
        else:
            logger.error(f"Error with table: {e}")
            raise

@app.route('/', methods=['GET'])
def root():
    return jsonify({
        "service": "Task Management API",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "tasks": "/tasks",
            "metrics": "/metrics"
        }
    }), 200

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    try:
        # Test DynamoDB connection
        table = get_table()
        return jsonify({
            "status": "healthy",
            "database": "connected",
            "table": TABLE_NAME
        }), 200
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({
            "status": "unhealthy",
            "error": str(e)
        }), 503

@app.route('/tasks', methods=['GET'])
def get_tasks():
    """Get all tasks"""
    try:
        table = get_table()
        response = table.scan()
        tasks = response.get('Items', [])
        logger.info(f"Retrieved {len(tasks)} tasks")
        return jsonify(tasks), 200
    except Exception as e:
        logger.error(f"Error getting tasks: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/tasks', methods=['POST'])
def create_task():
    """Create a new task"""
    try:
        data = request.get_json()
        
        if not data or 'title' not in data:
            return jsonify({"error": "Title is required"}), 400
        
        task_id = str(uuid.uuid4())
        task = {
            "id": task_id,
            "title": data.get("title"),
            "description": data.get("description", ""),
            "status": data.get("status", "pending"),
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        }
        
        table = get_table()
        table.put_item(Item=task)
        
        logger.info(f"Created task: {task_id}")
        return jsonify(task), 201
    except Exception as e:
        logger.error(f"Error creating task: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/tasks/<task_id>', methods=['GET'])
def get_task(task_id):
    """Get a specific task"""
    try:
        table = get_table()
        response = table.get_item(Key={'id': task_id})
        
        if 'Item' not in response:
            return jsonify({"error": "Task not found"}), 404
        
        return jsonify(response['Item']), 200
    except Exception as e:
        logger.error(f"Error getting task {task_id}: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/tasks/<task_id>', methods=['PUT'])
def update_task(task_id):
    """Update a task"""
    try:
        table = get_table()
        data = request.get_json()
        
        # Check if task exists
        response = table.get_item(Key={'id': task_id})
        if 'Item' not in response:
            return jsonify({"error": "Task not found"}), 404
        
        # Build update expression
        update_expr = "SET updated_at = :updated_at"
        expr_attr_values = {':updated_at': datetime.now().isoformat()}
        expr_attr_names = {}
        
        if 'title' in data:
            update_expr += ", title = :title"
            expr_attr_values[':title'] = data['title']
        
        if 'description' in data:
            update_expr += ", description = :desc"
            expr_attr_values[':desc'] = data['description']
        
        if 'status' in data:
            update_expr += ", #status = :status"
            expr_attr_values[':status'] = data['status']
            expr_attr_names['#status'] = 'status'
        
        # Update item
        response = table.update_item(
            Key={'id': task_id},
            UpdateExpression=update_expr,
            ExpressionAttributeValues=expr_attr_values,
            ExpressionAttributeNames=expr_attr_names if expr_attr_names else None,
            ReturnValues="ALL_NEW"
        )
        
        logger.info(f"Updated task: {task_id}")
        return jsonify(response['Attributes']), 200
    except Exception as e:
        logger.error(f"Error updating task {task_id}: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/tasks/<task_id>', methods=['DELETE'])
def delete_task(task_id):
    """Delete a task"""
    try:
        table = get_table()
        
        # Check if task exists
        response = table.get_item(Key={'id': task_id})
        if 'Item' not in response:
            return jsonify({"error": "Task not found"}), 404
        
        # Delete item
        table.delete_item(Key={'id': task_id})
        
        logger.info(f"Deleted task: {task_id}")
        return jsonify({"message": "Task deleted successfully", "id": task_id}), 200
    except Exception as e:
        logger.error(f"Error deleting task {task_id}: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    logger.info("Starting Task API...")
    logger.info(f"DynamoDB endpoint: {DYNAMODB_ENDPOINT}")
    app.run(host='0.0.0.0', port=5000, debug=True)
