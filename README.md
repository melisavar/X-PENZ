# X-Penz - Serverless Expense Tracker
> Cloud-native expense tracking app built on AWS — manual entry, voice input, and receipt OCR.

![AWS](https://img.shields.io/badge/AWS-Serverless-FF9900?style=flat&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)
![Lambda](https://img.shields.io/badge/Lambda-Python%203.13%20%2F%20Node.js%2020-FF9900?style=flat&logo=aws-lambda&logoColor=white)
![DynamoDB](https://img.shields.io/badge/DynamoDB-NoSQL-4053D6?style=flat&logo=amazon-dynamodb&logoColor=white)
![CloudFront](https://img.shields.io/badge/CloudFront-HTTPS-FF9900?style=flat)

**Live demo:** https://d1sputezr8e7ol.cloudfront.net

## What it does?
X-Penz lets users track personal or small business expenses through three input methods:

- **Manual entry** - fill out a form with amount, vendor, category, and date
- **Voice input** - speak a sentence like *"I spent 30 dollars at Subway for food"* and the app parses it automatically
- **Receipt image upload** - upload a photo of a receipt and Amazon Textract extracts the vendor, date, and total via OCR

The dashboard shows this month's total, last month's total, average spend per transaction, and a full expense history table.

---

## Architecture

```
Browser
  │
  ▼
CloudFront (HTTPS CDN)
  │
  ▼
S3 — static frontend (HTML/CSS/JS)
  │
  ▼
API Gateway (REST API)
  │
  ├── POST /manual-extract  → manualExtractor  (Python) → DynamoDB
  ├── POST /voice-extract   → voiceExtractor   (Python) → DynamoDB
  ├── GET  /expenses        → getExpenses      (Node.js) ← DynamoDB
  └── GET  /generate-URL   → generateURL      (Python) → pre-signed S3 URL
                                                                │
                                                         S3 receipts bucket
                                                                │
                                                     S3 event trigger (PUT)
                                                                │
                                                       imageExtractor (Python)
                                                                │
                                                        Amazon Textract
                                                                │
                                                            DynamoDB
```

---

## Tech stack

| Layer | Service | Why |
|---|---|---|
| Compute | AWS Lambda | Serverless, auto-scaling, no idle cost |
| API | Amazon API Gateway | Managed REST endpoints, HTTPS, CORS |
| Database | Amazon DynamoDB | Serverless NoSQL, pay-per-request |
| Storage | Amazon S3 (×2) | Frontend hosting + receipt images |
| OCR | Amazon Textract | Managed ML text extraction |
| CDN | Amazon CloudFront | HTTPS, global edge caching |
| IaC | Terraform | Full infrastructure as code |
| Languages | Python 3.13 / Node.js 20 | Lambda functions |

---

## Project structure

```
XPENZ/
├── backend/
│   ├── manualExtractor.py   # Form input → DynamoDB
│   ├── voiceExtractor.py    # Voice text parsing → DynamoDB
│   ├── imageExtractor.py    # S3 trigger → Textract OCR → DynamoDB
│   ├── getExpenses.js       # Scan DynamoDB → return JSON
│   └── generateURL.py       # Generate pre-signed S3 upload URL
├── frontend/
│   ├── index.html           # Landing page
│   ├── dashboard.html       # Monthly summary + recent expenses
│   ├── expenses.html        # Full expenses table
│   ├── add-expense.html     # Add expense (3 input method tabs)
│   ├── add-expense.js       # Frontend logic for all 3 methods
│   └── style.css            # Dark glassmorphism theme
├── terraform/
│   ├── main.tf              # Provider config
│   ├── variables.tf         # Input variables
│   ├── storage.tf           # DynamoDB + S3 buckets
│   ├── iam.tf               # Lambda execution role + permissions
│   ├── lambda.tf            # All 5 Lambda functions
│   ├── api_gateway.tf       # REST API + routes + CORS
│   ├── cloudfront.tf        # CloudFront distribution
│   ├── outputs.tf           # API URL, bucket names, live URL
│   └── terraform.tfvars.example
└── .gitignore
```

---

## Deploy it yourself

### Prerequisites
- AWS account (free tier works — runs at $0/month)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configured with your credentials

### Steps

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/x-penz.git
cd x-penz

# 2. Configure your deployment
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars — set aws_region and project_name

# 3. Deploy all AWS infrastructure
cd terraform
terraform init
terraform apply

# 4. Copy the api_gateway_url from the Terraform output
# Open frontend/add-expense.js, dashboard.html, expenses.html
# Replace the placeholder API URL with your real one

# 5. Upload frontend to S3
cd ..
aws s3 sync frontend/ s3://YOUR_FRONTEND_BUCKET --delete

# 6. Clear CloudFront cache
aws cloudfront create-invalidation --distribution-id YOUR_CF_ID --paths "/*"
```

Your app is live at the live_url printed by Terraform.

---

## Cost

Runs within AWS free tier limits — approximately $0/month for personal use.

All services used (Lambda, DynamoDB, S3, API Gateway, CloudFront, ACM) have free tier allocations that comfortably cover light personal usage.

---

