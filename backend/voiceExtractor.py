#Scans the receipt in voice, returns the data to dynamoDB
#voice to text extract

import json
import boto3
import uuid
import re
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('expense-table')

def extract_info(text):
    #"I spent 25 dollars at Subway for food"
    amount_match = re.search(r'\b(\d+(?:\.\d{1,2})?)\s*dollars?\b', text, re.IGNORECASE)
    vendor_match = re.search(r'at\s+([a-zA-Z0-9&.\'-]+)', text, re.IGNORECASE)
    category_match = re.search(r'for\s+([a-zA-Z\s]+)', text, re.IGNORECASE)

    amount = float(amount_match.group(1)) if amount_match else 0.0
    vendor = vendor_match.group(1).strip().title() if vendor_match else "Unknown"
    category = category_match.group(1).strip().capitalize() if category_match else "Uncategorized"

    return amount, vendor, category

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        voice_text = body.get('voiceText', '')

        if not voice_text:
            return {
                'statusCode': 400,
                'headers': {'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'voiceText is required'})
            }

        amount, vendor, category = extract_info(voice_text)

        item = {
            'id': str(uuid.uuid4()),
            'user': 'melisa',
            'amount': Decimal(str(amount)),
            'vendor': vendor,
            'category': category,
            'date': datetime.now().strftime('%Y-%m-%d'),
            'method': 'voice',
            'total': Decimal(str(amount))
        }

        table.put_item(Item=item)

        return {
            'statusCode': 200,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'message': 'Expense recorded!', 'data': item}, default=str)
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }
