# Returns a presigned S3 PUT URL so the browser can upload receipts directly
import boto3
import json
import os

s3          = boto3.client('s3')
BUCKET_NAME = os.environ.get('RECEIPTS_BUCKET', 'xpenz-receipts')

def lambda_handler(event, context):
    try:
        params   = event.get('queryStringParameters') or {}
        filename = params.get('filename', '').strip()
        filetype = params.get('filetype', 'image/jpeg').strip()

        if not filename:
            return {
                'statusCode': 400,
                'headers': {'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'filename query param is required'})
            }

        upload_url = s3.generate_presigned_url(
            'put_object',
            Params={
                'Bucket':      BUCKET_NAME,
                'Key':         filename,
                'ContentType': filetype,
            },
            ExpiresIn=300  # URL valid for 5 minutes
        )

        return {
            'statusCode': 200,
            'headers': {'Access-Control-Allow-Origin': '*'},
            # Frontend (add-expense.js) reads data.uploadURL
            'body': json.dumps({'uploadURL': upload_url})
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }
