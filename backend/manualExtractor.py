import json
import boto3
import uuid
from decimal import Decimal
from datetime import datetime
import os

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME', 'expense-table')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))

        amount  = body.get('amount')
        vendor  = body.get('vendor', 'Unknown').strip()
        category = body.get('category', 'Other').strip()
        date    = body.get('date', datetime.now().strftime('%Y-%m-%d'))

        if amount is None:
            return {
                'statusCode': 400,
                'headers': {'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'amount is required'})
            }

        item = {
            'id':       str(uuid.uuid4()),
            'user':     'user',
            'amount':   Decimal(str(amount)),
            'vendor':   vendor,
            'category': category,
            'date':     date,
            'method':   'manual',
            'total':    Decimal(str(amount))
        }

        table.put_item(Item=item)

        return {
            'statusCode': 200,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'message': 'Expense added!', 'data': item}, default=str)
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }
