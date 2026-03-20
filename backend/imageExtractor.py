#Scans the receipt in s3, returns the data to dynamoDB
#image to text extract

import json
import boto3
import uuid
from decimal import Decimal
from datetime import datetime
import re
import os

dynamodb = boto3.resource('dynamodb')
textract = boto3.client('textract')

table_name = os.environ.get('TABLE_NAME', 'expense-table')
table = dynamodb.Table(table_name)

def extract_total(text_lines):
    keywords = ["total", "amount due", "balance due", "grand total", "total amount"]
    candidates = []

    for line in reversed(text_lines):
        line_clean = line.lower().replace(":", "").replace(",", ".")
        if any(kw in line_clean for kw in keywords):
            matches = re.findall(r'\d+\.\d{2}', line_clean)
            for match in matches:
                value = float(match)
                if 1.0 < value < 10000:
                    candidates.append(value)

    if not candidates:
        all_numbers = []
        for line in text_lines:
            line = line.replace(",", ".")
            matches = re.findall(r'\d+\.\d{2}', line)
            for match in matches:
                value = float(match)
                if 1.0 < value < 10000:
                    all_numbers.append(value)
        return max(all_numbers) if all_numbers else None

    return max(candidates)

def extract_vendor(text_lines):
    for line in text_lines[:6]:
        if any(keyword in line.lower() for keyword in ["co", "inc", "ltd", "restaurant", "hotel", ".com", ".ca", ".ch"]):
            return line.strip()
    return text_lines[0] if text_lines else "Unknown Vendor"

def categorize(vendor_name):
    vendor_name = vendor_name.lower()
    keywords = {
        "clothing": ["zara", "h&m", "uniqlo", "prada", "gucci"],
        "food": ["mcdonalds", "subway", "burger", "restaurant", "oyster", "hotel"],
        "gas": ["shell", "esso", "petrol", "fuel"],
        "groceries": ["costco", "walmart", "supermarket"],
        "rent": ["landlord", "apartment", "housing"],
        "online shopping": ["amazon", "ebay"],
        "entertainment": ["netflix", "spotify"],
        "transportation": ["uber", "lyft"]
    }
    for category, names in keywords.items():
        for name in names:
            if name in vendor_name:
                return category.capitalize()
    return "Other"

def extract_date(text_lines):
    date_patterns = [
        r'(\d{2}[./-]\d{2}[./-]\d{4})',
        r'(\d{4}[./-]\d{2}[./-]\d{2})',
        r'(\d{2}[./-]\d{2}[./-]\d{2})'
    ]

    for line in text_lines:
        for pattern in date_patterns:
            match = re.search(pattern, line)
            if match:
                date_str = match.group(1)
                for fmt in ("%d.%m.%Y", "%d/%m/%Y", "%d-%m-%Y", "%Y-%m-%d", "%d.%m.%y", "%d/%m/%y"):
                    try:
                        parsed = datetime.strptime(date_str, fmt)
                        if parsed.year >= 2000:  # sanity check
                            return parsed.strftime("%Y-%m-%d")
                    except ValueError:
                        continue
    return datetime.now().strftime("%Y-%m-%d")

def lambda_handler(event, context):
    try:
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']

        response = textract.detect_document_text(
            Document={'S3Object': {'Bucket': bucket, 'Name': key}}
        )

        text_lines = [item['Text'] for item in response['Blocks'] if item['BlockType'] == 'LINE']
        
        total = extract_total(text_lines)
        vendor = extract_vendor(text_lines)
        category = categorize(vendor)
        date = extract_date(text_lines)

        item = {
            'id': str(uuid.uuid4()),
            'user': 'melisa',
            'amount': Decimal(str(total)) if total else Decimal("0.00"),
            'vendor': vendor,
            'category': category,
            'date': date,
            'method': 'image',
            'total': Decimal(str(total)) if total else Decimal("0.00")
        }

        table.put_item(Item=item)

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Expense extracted successfully!', 'data': item}, default=str)
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Error extracting expense: {str(e)}'
        }
